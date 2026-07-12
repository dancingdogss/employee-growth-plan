-- ============================================================================
-- Migration: 20260712_01_owner_auth_foundation
-- Phase 1A — Additive owner-authentication foundation.
--
-- WHAT THIS DOES
--   * Creates public.profiles (role table linked to auth.users)
--   * Enables RLS on public.profiles ONLY
--   * Adds a single self-read policy (authenticated user reads only own row)
--   * Creates the `private` schema + private.employee_growth_is_owner() helper for FUTURE RLS
--   * Adds an updated_at trigger for profiles
--
-- WHAT THIS DELIBERATELY DOES NOT DO
--   * Does NOT touch employees, stock_units, stock_events, stock_types,
--     salary_payouts or owner_messages — no columns, data, grants or RLS on
--     any existing business table are changed.
--   * Does NOT create any INSERT/UPDATE/DELETE policy on profiles, so NO
--     browser client (anon or authenticated) can create an owner row or change
--     its own role. Owner bootstrapping is a MANUAL step in the Supabase SQL
--     Editor (which runs as a superuser and bypasses RLS). See
--     docs/SECURITY_OWNER_AUTH_SETUP.md.
--   * Does NOT auto-promote any user to owner. There is no first-user trigger
--     and no reliance on auth.users.raw_user_meta_data / user_metadata.
--
-- SAFETY
--   * Additive and non-destructive. Idempotent where practical (guarded with
--     IF NOT EXISTS / CREATE OR REPLACE / DROP ... IF EXISTS + recreate).
--   * Reversible via 20260712_01_owner_auth_foundation_rollback.sql.
--   * Cannot lock the current owner page: business-table RLS is unchanged, so
--     owner.html and index.html keep working exactly as today.
--
-- HOW TO APPLY
--   Run this whole file once in the Supabase SQL Editor (as the default
--   privileged role). Then follow docs/SECURITY_OWNER_AUTH_SETUP.md.
-- ============================================================================

-- ── 1. PROFILES TABLE ───────────────────────────────────────────────────────
-- One row per auth user, carrying the authorization role. Independent of the
-- existing `employees` table (no FK between them in this phase).
CREATE TABLE IF NOT EXISTS public.profiles (
  id         uuid        PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  role       text        NOT NULL
             CONSTRAINT profiles_role_check CHECK (role IN ('owner', 'employee')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.profiles      IS 'Authorization roles for auth.users. Owner rows are inserted manually via the SQL Editor only.';
COMMENT ON COLUMN public.profiles.role IS 'Allowed values: owner, employee. Not client-editable (no UPDATE policy).';

-- ── 2. TABLE-LEVEL PRIVILEGES (defence in depth, alongside RLS) ─────────────
-- Anonymous callers get nothing. Authenticated callers get SELECT only; with
-- no INSERT/UPDATE/DELETE grant AND no corresponding policy, clients cannot
-- write this table at all. service_role / postgres are untouched and still
-- bypass RLS for the manual bootstrap.
REVOKE ALL ON TABLE public.profiles FROM anon;
REVOKE ALL ON TABLE public.profiles FROM authenticated;
GRANT  SELECT ON TABLE public.profiles TO authenticated;

-- ── 3. ROW LEVEL SECURITY (profiles ONLY) ───────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Only policy: an authenticated user may read ONLY their own profile row.
-- No anonymous policy exists, so anon requests read nothing.
-- No INSERT/UPDATE/DELETE policy exists, so clients cannot create an owner
-- profile or change their own role. (Intentional — do not add write policies
-- here without a security review.)
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
CREATE POLICY profiles_select_own
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = id);

-- ── 4. PRIVATE SCHEMA ───────────────────────────────────────────────────────
-- Not exposed through PostgREST; holds security helpers for future RLS.
CREATE SCHEMA IF NOT EXISTS private;

-- ── 5. private.employee_growth_is_owner() HELPER ────────────────────────────────────────────
-- Returns TRUE iff the CURRENT authenticated user has role = 'owner'.
--
-- SECURITY DEFINER is used deliberately and is genuinely required here: this
-- function is intended to be called from the RLS policies of OTHER tables in a
-- later phase. As DEFINER (owned by the migration superuser) it reads
-- public.profiles authoritatively without depending on the profiles table's
-- own RLS or on granting business roles broad SELECT on profiles. It is NOT a
-- privilege-escalation path: it takes no arguments, performs no writes, and
-- only reports a boolean about the caller's OWN row (auth.uid()). It cannot be
-- used to act as, or read the data of, anyone else.
CREATE OR REPLACE FUNCTION private.employee_growth_is_owner()
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles AS p
    WHERE p.id = (SELECT auth.uid())
      AND p.role = 'owner'
  );
$$;

COMMENT ON FUNCTION private.employee_growth_is_owner() IS 'TRUE iff current auth.uid() has profiles.role = owner. For use in future RLS policies (scope them TO authenticated).';

-- Minimum execute surface: revoke the implicit PUBLIC grant, allow only
-- authenticated. anon cannot call it (and would only ever get FALSE anyway).
REVOKE ALL ON FUNCTION private.employee_growth_is_owner() FROM PUBLIC;
GRANT  USAGE ON SCHEMA private TO authenticated;   -- required to reference the function
GRANT  EXECUTE ON FUNCTION private.employee_growth_is_owner() TO authenticated;

-- ── 6. updated_at TRIGGER (self-contained, safely qualified) ────────────────
-- A dedicated trigger function in the private schema. Kept independent of the
-- unqualified public.set_updated_at() in schema.sql (which may not match the
-- live database) so this migration and its rollback are self-contained.
CREATE OR REPLACE FUNCTION private.employee_growth_set_profiles_updated_at()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = pg_catalog.now();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION private.employee_growth_set_profiles_updated_at() IS 'BEFORE UPDATE trigger: stamps updated_at. Used by public.profiles.';

REVOKE ALL ON FUNCTION private.employee_growth_set_profiles_updated_at() FROM PUBLIC;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION private.employee_growth_set_profiles_updated_at();

-- ============================================================================
-- End of migration 20260712_01_owner_auth_foundation.
-- Next: docs/SECURITY_OWNER_AUTH_SETUP.md (manual owner bootstrap + verification).
-- ============================================================================
