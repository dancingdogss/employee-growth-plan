-- ============================================================
-- schema.sql
-- Employee Progress Tracker — Supabase Database Schema
-- Run this in your Supabase SQL Editor.
-- ============================================================

-- ── 1. EMPLOYEES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS employees (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_code TEXT        NOT NULL UNIQUE,  -- e.g. "EMP-001"
  name          TEXT        NOT NULL,
  notes         TEXT,
  active        BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 2. STOCK UNITS ──────────────────────────────────────────
-- stock_id   : physical ID on the item (always present, unique)
-- order_id   : generated at point of sale — NULL until sold
-- status     : see allowed values below

CREATE TABLE IF NOT EXISTS stock_units (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  stock_id          TEXT        NOT NULL,           -- required, unique physical ID
  order_id          TEXT,                           -- nullable — only assigned when sold
  employee_id       UUID        NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
  status            TEXT        NOT NULL DEFAULT 'waiting_to_be_sold'
                    CHECK (status IN (
                      'waiting_to_be_sold',
                      'sale_reported',
                      'sold_approved',
                      'issue',
                      'cancelled'
                    )),
  uploaded_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  sold_at           TIMESTAMPTZ,                    -- set when sale is reported / approved
  approved_at       TIMESTAMPTZ,                    -- set when owner approves
  sale_note         TEXT,                           -- employee note when reporting sale
  owner_note        TEXT,                           -- owner internal note
  -- Photo fields — prepared for future use, not yet used
  photo_path        TEXT,                           -- Supabase Storage path (future)
  photo_uploaded_at TIMESTAMPTZ,                    -- when photo was attached (future)
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Unique constraint: no two stock units share the same stock_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_stock_units_stock_id
  ON stock_units (stock_id);

-- Index for order_id lookups
CREATE INDEX IF NOT EXISTS idx_stock_units_order_id
  ON stock_units (order_id)
  WHERE order_id IS NOT NULL;

-- Index for filtering by employee
CREATE INDEX IF NOT EXISTS idx_stock_units_employee_id
  ON stock_units (employee_id);

-- Index for filtering by status
CREATE INDEX IF NOT EXISTS idx_stock_units_status
  ON stock_units (status);

-- Index for date range queries
CREATE INDEX IF NOT EXISTS idx_stock_units_uploaded_at
  ON stock_units (uploaded_at DESC);

CREATE INDEX IF NOT EXISTS idx_stock_units_approved_at
  ON stock_units (approved_at DESC)
  WHERE approved_at IS NOT NULL;

-- Auto-update updated_at on every change
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_units_updated_at ON stock_units;
CREATE TRIGGER trg_stock_units_updated_at
  BEFORE UPDATE ON stock_units
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── 3. STOCK EVENTS (audit trail) ───────────────────────────
CREATE TABLE IF NOT EXISTS stock_events (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  stock_unit_id UUID        NOT NULL REFERENCES stock_units(id) ON DELETE CASCADE,
  event_type    TEXT        NOT NULL,  -- 'created','sale_reported','sold_approved','issue','cancelled','edited','note_added'
  actor         TEXT,                  -- 'owner' | 'employee' | employee_code
  note          TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_events_unit_id
  ON stock_events (stock_unit_id);

CREATE INDEX IF NOT EXISTS idx_stock_events_created_at
  ON stock_events (created_at DESC);

-- ── 4. REALTIME ─────────────────────────────────────────────
-- Enable realtime on the tables that the browser subscribes to.
-- Run in Supabase SQL Editor:
ALTER PUBLICATION supabase_realtime ADD TABLE stock_units;
ALTER PUBLICATION supabase_realtime ADD TABLE stock_events;

-- ── 5. ROW LEVEL SECURITY (stub — enable before production) ─
-- Uncomment and configure once Supabase Auth is set up.
-- ALTER TABLE employees   ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE stock_units ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE stock_events ENABLE ROW LEVEL SECURITY;
--
-- Example: owner (authenticated, role = 'owner') can do everything.
-- CREATE POLICY "owner_all" ON stock_units
--   FOR ALL USING (auth.jwt() ->> 'role' = 'owner');
--
-- Example: employee can only see their own units.
-- CREATE POLICY "employee_select_own" ON stock_units
--   FOR SELECT USING (employee_id = auth.uid());
--
-- Example: employee can only report sale on their own waiting units.
-- CREATE POLICY "employee_report_sale" ON stock_units
--   FOR UPDATE USING (
--     employee_id = auth.uid()
--     AND status = 'waiting_to_be_sold'
--   ) WITH CHECK (status = 'sale_reported');

-- ── 6. SEED: example employee ────────────────────────────────
-- Uncomment to insert a test employee:
-- INSERT INTO employees (employee_code, name)
-- VALUES ('EMP-001', 'Test Employee')
-- ON CONFLICT (employee_code) DO NOTHING;
