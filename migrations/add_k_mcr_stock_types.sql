-- ============================================================================
-- Migration: add_k_mcr_stock_types
-- Adds two new stock types — K (K Bundle) and MCR (MCR Bundle) — to the
-- EXISTING public.stock_types table. The stock_types table remains the single
-- source of truth; no new table is created.
--
-- SAFETY / NON-DESTRUCTIVE
--   * Only INSERTs K and MCR (upserting on the prefix). It NEVER deletes or
--     modifies the existing C, B, M (or CPREMIUM) rows.
--   * Idempotent: re-running it re-applies the same K / MCR values.
--   * Uses only columns already present in this project's stock_types table:
--       prefix, name, item_unit_cost, quantity_per_stock_sale,
--       capital_per_stock_sale, earnings_per_approved_sale
--     (the same column set as migrations/add_cpremium_stock_type.sql).
--   * The optional `active` column is set only IF it exists (guarded DO block),
--     so this file runs cleanly whether or not that column is present.
--
-- HOW TO APPLY
--   Run this whole file once in the Supabase SQL Editor.
-- ============================================================================

-- ── 1. Ensure prefix is unique so ON CONFLICT can target it ─────────────────
-- Additive and idempotent. Fails only if duplicate prefixes already exist,
-- which the app never creates.
CREATE UNIQUE INDEX IF NOT EXISTS idx_stock_types_prefix
  ON public.stock_types (prefix);

-- ── 2. Upsert K and MCR ─────────────────────────────────────────────────────
INSERT INTO public.stock_types
  (prefix, name, item_unit_cost, quantity_per_stock_sale,
   capital_per_stock_sale, earnings_per_approved_sale)
VALUES
  ('K',   'K Bundle',   50,  4,   200, 100),
  ('MCR', 'MCR Bundle', 50, 10,   500, 100)
ON CONFLICT (prefix) DO UPDATE SET
  name                       = EXCLUDED.name,
  item_unit_cost             = EXCLUDED.item_unit_cost,
  quantity_per_stock_sale    = EXCLUDED.quantity_per_stock_sale,
  capital_per_stock_sale     = EXCLUDED.capital_per_stock_sale,
  earnings_per_approved_sale = EXCLUDED.earnings_per_approved_sale;

-- ── 3. Mark K / MCR active, ONLY if the column exists ───────────────────────
-- Skipped silently on schemas that have no `active` column.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'stock_types'
      AND column_name  = 'active'
  ) THEN
    UPDATE public.stock_types
      SET active = TRUE
      WHERE prefix IN ('K', 'MCR');
  END IF;
END
$$;

-- ============================================================================
-- End of migration add_k_mcr_stock_types.
-- ============================================================================
