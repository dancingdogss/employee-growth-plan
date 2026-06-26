-- ============================================================
-- Migration: extend owner_messages for Telegram message tracking
-- Run once in Supabase SQL Editor. All statements are idempotent.
-- ============================================================

-- Additive column additions (legacy columns: id, employee_id, message, sent_at, seen_at are untouched)
ALTER TABLE public.owner_messages
  ADD COLUMN IF NOT EXISTS title               text,
  ADD COLUMN IF NOT EXISTS body                text,
  ADD COLUMN IF NOT EXISTS telegram_chat_id    text,
  ADD COLUMN IF NOT EXISTS telegram_message_id bigint,
  ADD COLUMN IF NOT EXISTS telegram_sent_at    timestamptz,
  ADD COLUMN IF NOT EXISTS dashboard_opened_at timestamptz,
  ADD COLUMN IF NOT EXISTS seen_at             timestamptz,
  ADD COLUMN IF NOT EXISTS owner_hidden_at     timestamptz,
  ADD COLUMN IF NOT EXISTS employee_hidden_at  timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at          timestamptz,
  ADD COLUMN IF NOT EXISTS telegram_error      text,
  ADD COLUMN IF NOT EXISTS created_at          timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at          timestamptz DEFAULT now();

-- Backfill: copy legacy message → body where body is null
UPDATE public.owner_messages
SET body = message
WHERE body IS NULL AND message IS NOT NULL;

-- Backfill: copy sent_at → created_at where created_at is null
UPDATE public.owner_messages
SET created_at = sent_at
WHERE created_at IS NULL AND sent_at IS NOT NULL;

-- Indexes
CREATE INDEX IF NOT EXISTS owner_messages_employee_id_idx
  ON public.owner_messages (employee_id);

CREATE INDEX IF NOT EXISTS owner_messages_created_at_idx
  ON public.owner_messages (created_at DESC);

CREATE INDEX IF NOT EXISTS owner_messages_seen_at_idx
  ON public.owner_messages (seen_at)
  WHERE seen_at IS NULL;

CREATE INDEX IF NOT EXISTS owner_messages_deleted_at_idx
  ON public.owner_messages (deleted_at)
  WHERE deleted_at IS NULL;
