# Do Not Break

Critical rules for Claude:

- Do not change Supabase table names.
- Do not change supabase-config.js.
- Do not remove existing working Supabase connection.
- Do not reintroduce localStorage as source of truth.
- Do not reintroduce duplicate ledger rendering.
- Do not add Order ID to Add Stock form.
- Order ID only belongs in Mark as Sold modal.
- Employee must not be able to mark stock as sold.
- Owner controls sold status.
- Employee can only mark sold update as seen.
- Keep mobile-first UI.
- Use button navigation with scrollIntoView, not <a href="#section">.
- Keep index.html simple for employee.
- Keep owner.html powerful for owner.
- Use clear status labels.