# Next Task

Refactor sold flow.

Current/old flow:
Employee can report/request sold.
Owner approves.

New desired flow:
Employee should not report sold.
Owner marks stock as sold.
Employee only confirms “Mark as seen”.

Owner changes:

- Replace “Approve sale” / “Approve reported sale” with “Mark as sold”.
- Button opens modal.
- Modal requires:
  - Order ID
  - Sold at
  - Optional owner note
- On save:
  - status = sold_approved
  - order_id = entered value
  - sold_at = entered value
  - approved_at = now
  - employee_seen_at = null
  - employee_seen_note = null
- Show employee seen state in owner ledger:
  - Not seen
  - Seen at timestamp

Employee changes:

- Remove/hide Report sold / Request sold.
- If stock status = waiting_to_be_sold:
  show Waiting to be sold, no action.
- If status = sold_approved and employee_seen_at is null:
  show Marked as sold + button Mark as seen.
- If employee clicks Mark as seen:
  update employee_seen_at = now.
- If employee_seen_at exists:
  show Sold — seen by you.

Stats:
- Continue counting only sold_approved.
- employee_seen_at should not affect deposit/salary.