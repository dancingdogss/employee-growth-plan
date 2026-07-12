-- ============================================================================
-- Rollback: 20260712_02_stock_name_and_create_rpc_rollback
-- Reverses ONLY the objects created by 20260712_02_stock_name_and_create_rpc.sql.
--
-- ⚠ WARNING — DATA LOSS ON stock_name
--   Step 3 DROPS the stock_name column and therefore permanently DISCARDS every
--   owner-entered stock name. The stock_units rows themselves, their internal
--   stock_id, order IDs, sold/approved dates, stock_events and all financial
--   data are NOT affected — but the friendly names cannot be recovered. Only run
--   this to fully undo Phase 1C.
--
-- SAFE OTHERWISE: does NOT delete any stock_units row, and does NOT touch
-- authentication objects or any unrelated business object.
--
-- Run the whole file once in the Supabase SQL Editor.
-- ============================================================================

-- 1. Remove the owner-only creation RPC.
DROP FUNCTION IF EXISTS public.create_stock_units(uuid,uuid,text,integer,timestamptz,text);

-- 2. Remove the automatic stock_id default. Existing stock_id values are kept,
--    and the UNIQUE index on stock_id remains. After this, inserts must supply
--    stock_id explicitly again.
ALTER TABLE public.stock_units
  ALTER COLUMN stock_id DROP DEFAULT;

-- 3. Remove stock_name.
--    ⚠ See header: this discards the user-facing names permanently. No row is
--    deleted; only the column (and its data) is removed.
ALTER TABLE public.stock_units
  DROP COLUMN IF EXISTS stock_name;

-- ============================================================================
-- End of rollback.
-- ============================================================================
