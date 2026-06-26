-- Phase 1: Employee private access tokens
-- Run this in the Supabase SQL editor.
-- Safe to run multiple times (uses IF NOT EXISTS / WHERE IS NULL guards).
-- Does NOT remove or alter any existing columns.

ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS employee_access_token text UNIQUE;

-- Backfill: generate a token for every employee that doesn't have one yet
UPDATE public.employees
SET employee_access_token = gen_random_uuid()::text
WHERE employee_access_token IS NULL;

-- Explicit unique index (the UNIQUE constraint above already creates one,
-- but named explicitly so it can be referenced or dropped by name later)
CREATE UNIQUE INDEX IF NOT EXISTS idx_employees_access_token
  ON public.employees (employee_access_token);
