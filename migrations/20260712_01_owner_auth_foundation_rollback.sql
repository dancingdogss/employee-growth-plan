-- ============================================================================
-- Rollback: 20260712_01_owner_auth_foundation_rollback
-- Reverses ONLY the objects created by 20260712_01_owner_auth_foundation.sql.
--
-- SAFE TO RUN: touches nothing outside this phase. It does NOT alter employees,
-- stock_units, stock_events, stock_types, salary_payouts or owner_messages, and
-- changes no RLS setting on any business table.
--
-- WARNING: dropping public.profiles deletes the role rows (including the owner
-- role row). Only run this to undo Phase 1A. After a rollback you must re-run
-- the forward migration and re-bootstrap the owner (see the setup doc) before
-- any later auth phase.
--
-- Run the whole file once in the Supabase SQL Editor.
-- ============================================================================

-- 1. Trigger (also auto-drops with the table, dropped explicitly for clarity).
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;

-- 2. Table — cascades its policy (profiles_select_own) and trigger.
--    Grants on the table disappear with it.
DROP TABLE IF EXISTS public.profiles;

-- 3. Helper functions created by this phase — dropped by their PROJECT-SPECIFIC
--    names only. These names are unique to employee-growth-plan, so this can
--    never remove a generic/shared private.* function (e.g. a plain
--    private.is_owner() or private.set_updated_at()) that another feature owns.
DROP FUNCTION IF EXISTS private.employee_growth_is_owner();
DROP FUNCTION IF EXISTS private.employee_growth_set_profiles_updated_at();

-- 4. Schema usage grant added by this phase.
--    Revoked, but the `private` SCHEMA itself is intentionally LEFT IN PLACE:
--    it may have existed before this migration and may hold unrelated objects.
REVOKE USAGE ON SCHEMA private FROM authenticated;

-- 5. The `private` schema is deliberately NOT dropped. Never use
--    DROP SCHEMA private CASCADE here — it could destroy unrelated objects.
--    If (and only if) you are certain this migration created an otherwise-empty
--    `private` schema, you may remove it manually with a guarded RESTRICT drop,
--    which fails loudly rather than cascading:
-- DROP SCHEMA IF EXISTS private RESTRICT;

-- ============================================================================
-- End of rollback.
-- ============================================================================
