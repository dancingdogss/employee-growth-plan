# Current State

The Supabase connection works.

Confirmed working:

- Owner can log into owner.html with OWNER_PIN.
- Owner can add employee.
- Owner can add stock unit.
- Stock unit appears once in owner.html.
- Stock unit appears in index.html for the employee.
- Owner can approve/mark sold with ORDER ID.
- Employee index.html sees sold_approved status.
- Duplicate UI rendering bug was fixed.
- Database unique index exists on stock_units.stock_id.
- Database unique partial index should exist on stock_units.order_id where order_id is not null.

Current issue / next desired change:

We want to replace employee “Report sold” flow with owner-controlled “Mark as sold” flow.

New desired flow:

- Employee sees stock units.
- Owner marks stock as sold.
- Employee sees “Marked as sold”.
- Employee clicks “Mark as seen”.
- Owner sees employee_seen_at / seen confirmation.