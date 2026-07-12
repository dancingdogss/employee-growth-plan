-- ============================================================================
-- Migration: 20260712_02_stock_name_and_create_rpc
-- Phase 1C — Unified name-and-quantity stock creation.
--
-- WHAT THIS DOES
--   * Adds public.stock_units.stock_name (user-facing label).
--   * Backfills stock_name from stock_id for existing rows (non-destructive).
--   * Makes stock_name NOT NULL after the backfill.
--   * Gives stock_id an automatic, collision-resistant DEFAULT so new rows never
--     need an owner-entered Stock ID.
--   * Adds the owner-only, transaction-safe RPC public.create_stock_units(...).
--
-- WHAT THIS DELIBERATELY DOES NOT DO
--   * Does NOT drop stock_units.id, stock_id, the unique stock_id index, any
--     foreign key, any status, any financial data, or any existing row.
--   * Does NOT enable RLS on any business table (that is Phase 2).
--   * Does NOT modify authentication objects (profiles, private schema, the
--     private.employee_growth_is_owner() helper) — it only CALLS the helper.
--
-- SAFETY
--   * Additive and reversible via 20260712_02_stock_name_and_create_rpc_rollback.sql.
--   * Idempotent where practical (IF NOT EXISTS / CREATE OR REPLACE).
--
-- HOW TO APPLY
--   Run this whole file once in the Supabase SQL Editor (privileged role).
-- ============================================================================

-- ── 1. stock_name COLUMN ────────────────────────────────────────────────────
ALTER TABLE public.stock_units
  ADD COLUMN IF NOT EXISTS stock_name text;

-- ── 2. BACKFILL from stock_id (only where missing/blank) ────────────────────
-- Preserves every existing record and its stock_id; just supplies a name.
UPDATE public.stock_units
  SET stock_name = stock_id
  WHERE stock_name IS NULL OR btrim(stock_name) = '';

-- ── 3. REQUIRE stock_name from now on (safe: every row backfilled above) ────
ALTER TABLE public.stock_units
  ALTER COLUMN stock_name SET NOT NULL;

-- ── 4. AUTOMATIC internal stock_id DEFAULT ──────────────────────────────────
-- New rows get a collision-resistant reference automatically; the owner never
-- types it. Existing stock_id values are untouched, and the UNIQUE index on
-- stock_id still applies.
ALTER TABLE public.stock_units
  ALTER COLUMN stock_id SET DEFAULT ('SYS-' || gen_random_uuid()::text);

-- ── 5. OWNER-ONLY, TRANSACTIONAL CREATION RPC ───────────────────────────────
-- Creates exactly p_quantity separate stock_units rows (each with the SAME
-- user-facing stock_name and its OWN auto-generated internal stock_id) plus one
-- 'created' stock_events row per unit, all in a single transaction. If any part
-- fails, the whole batch rolls back — no partial creation.
--
-- SECURITY DEFINER is required so the function can insert regardless of future
-- table-level RLS, but it is gated on the FIRST lines by an authentication check
-- and the project-specific private.employee_growth_is_owner() helper, so an
-- anonymous or non-owner caller can never create stock. EXECUTE is granted only
-- to authenticated (never PUBLIC/anon). search_path is pinned empty and every
-- object reference is fully schema-qualified.
CREATE OR REPLACE FUNCTION public.create_stock_units(
  p_employee_id   uuid,
  p_stock_type_id uuid,
  p_stock_name    text,
  p_quantity      integer,
  p_uploaded_at   timestamptz,
  p_owner_note    text DEFAULT NULL
) RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = ''
AS $$
DECLARE
  v_name    text := btrim(coalesce(p_stock_name, ''));
  v_note    text := nullif(btrim(coalesce(p_owner_note, '')), '');
  v_created integer;
BEGIN
  -- AUTHORIZATION — authenticated owner only.
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'authentication required' USING errcode = '28000';
  END IF;
  IF NOT private.employee_growth_is_owner() THEN
    RAISE EXCEPTION 'owner role required' USING errcode = '42501';
  END IF;

  -- VALIDATION (defence in depth alongside the browser form).
  IF v_name = '' THEN
    RAISE EXCEPTION 'stock_name is required';
  END IF;
  IF length(v_name) > 120 THEN
    RAISE EXCEPTION 'stock_name too long (max 120 characters)';
  END IF;
  IF p_quantity IS NULL OR p_quantity < 1 OR p_quantity > 500 THEN
    RAISE EXCEPTION 'quantity must be a whole number between 1 and 500';
  END IF;
  IF p_uploaded_at IS NULL THEN
    RAISE EXCEPTION 'uploaded_at is required';
  END IF;

  -- Employee must exist AND be active.
  IF NOT EXISTS (
    SELECT 1 FROM public.employees e
    WHERE e.id = p_employee_id AND e.active IS TRUE
  ) THEN
    RAISE EXCEPTION 'employee not found or inactive';
  END IF;

  -- Stock type must exist.
  IF NOT EXISTS (
    SELECT 1 FROM public.stock_types st WHERE st.id = p_stock_type_id
  ) THEN
    RAISE EXCEPTION 'stock type not found';
  END IF;

  -- ATOMIC create: N units (auto stock_id via column DEFAULT) + one 'created'
  -- audit event per unit. Both data-modifying CTEs run exactly once; new_events
  -- depends on new_units, so the units are inserted first.
  WITH new_units AS (
    INSERT INTO public.stock_units
      (stock_name, employee_id, stock_type_id, uploaded_at, owner_note, status)
    SELECT v_name, p_employee_id, p_stock_type_id, p_uploaded_at, v_note,
           'waiting_to_be_sold'
    FROM generate_series(1, p_quantity)
    RETURNING id
  ),
  new_events AS (
    INSERT INTO public.stock_events (stock_unit_id, event_type, actor, note)
    SELECT id, 'created', 'owner', 'created via unified add'
    FROM new_units
    RETURNING 1
  )
  SELECT count(*) INTO v_created FROM new_units;

  RETURN json_build_object(
    'created_count', v_created,
    'stock_name',    v_name,
    'employee_id',   p_employee_id,
    'stock_type_id', p_stock_type_id
  );
END;
$$;

COMMENT ON FUNCTION public.create_stock_units(uuid,uuid,text,integer,timestamptz,text)
  IS 'Owner-only. Atomically creates N stock_units (same stock_name, distinct auto stock_id) plus one created event each. Gated by private.employee_growth_is_owner(); EXECUTE granted to authenticated only.';

-- Minimum execute surface: strip the implicit PUBLIC grant and anon, allow only
-- authenticated. A signed-in non-owner still fails the in-function owner check.
REVOKE ALL     ON FUNCTION public.create_stock_units(uuid,uuid,text,integer,timestamptz,text) FROM PUBLIC;
REVOKE ALL     ON FUNCTION public.create_stock_units(uuid,uuid,text,integer,timestamptz,text) FROM anon;
GRANT  EXECUTE ON FUNCTION public.create_stock_units(uuid,uuid,text,integer,timestamptz,text) TO authenticated;

-- ============================================================================
-- End of migration 20260712_02_stock_name_and_create_rpc.
-- ============================================================================
