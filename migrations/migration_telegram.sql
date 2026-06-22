-- ============================================================
-- Migration: add Telegram notification support
-- Run this once in Supabase SQL Editor.
-- ============================================================

alter table public.employees
add column if not exists telegram_chat_id text;

-- That's it. Nothing else changes. Existing employees will simply
-- have telegram_chat_id = NULL until you set it via the owner
-- dashboard's "Set Telegram ID" button.
