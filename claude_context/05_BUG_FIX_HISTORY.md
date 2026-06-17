# Bug Fix History

## Duplicate stock display bug

Problem:
After adding one stock unit, owner.html showed it twice.

Investigation:
Supabase database contained only one row.
Therefore it was frontend duplication, not database duplication.

Likely cause:
Realtime event + local append/fetch logic duplicated same record in UI.

Fix:
- stock_units array must be replaced from Supabase fetch, not appended.
- renderLedger must dedupe by id.
- realtime subscription must not create duplicate subscriptions.
- Add stock insert should use an isAddingStock lock.
- After insert, call fetchStockUnits() instead of manually pushing inserted row.
- Delete should delete by id and refetch.

Current status:
Fixed. Stock appears only once.