# Database Schema Notes

Main tables:

## employees

Used to identify employees.

Important fields expected:
- id
- employee_code
- display_name / name
- notes
- created_at

## stock_units

Main source of truth for every stock unit.

Important fields expected:
- id
- stock_id
- employee_id
- order_id nullable
- status
- uploaded_at
- sold_at nullable
- approved_at nullable
- employee_seen_at nullable
- employee_seen_note nullable
- owner_notes
- employee_notes
- created_at
- updated_at

Important statuses:

- waiting_to_be_sold
- sale_reported
- sold_approved
- issue
- cancelled

Target flow now uses:
- waiting_to_be_sold
- sold_approved
- issue
- cancelled

sale_reported can remain in database for compatibility, but employee should no longer trigger it in the main flow.

## stock_events

Audit/event log.

Useful event types:
- created
- marked_sold
- employee_seen
- edited
- issue
- cancelled

Important SQL migration needed if not already applied:

alter table public.stock_units
add column if not exists employee_seen_at timestamptz;

alter table public.stock_units
add column if not exists employee_seen_note text;

create index if not exists stock_units_employee_seen_at_idx
on public.stock_units (employee_seen_at);