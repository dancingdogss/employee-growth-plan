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
- renderLedger must dedupe by id (uniqueById).
- realtime subscription must not create duplicate subscriptions (single realtimeChannel guard).
- Add stock insert should use an isAddingStock lock.
- After insert, call loadStock() instead of manually pushing inserted row.
- Delete should delete by id and refetch.

Current status:
Fixed. Stock appears only once.

---

## Non-negotiable invariants (do not touch)

These fixes are load-bearing. Any future edit must preserve them:
- uniqueById() dedupe in owner.html loadStock/renderLedger.
- isAddingStock and isBulkAdding insert locks.
- Single realtimeChannel guard (`if (realtimeChannel) return;`) in owner.html;
  single `emp-stock-changes` channel in index.html.
- Employee (index.html) must never write status='sold_approved'. Verified: zero
  sold-status writes in index.html. Employee only writes employee_seen_at.

---

# Change Log — UI / UX sessions

## Session A — Employee unseen-sold alert banner (index.html)
Added a top-of-page banner that appears only when the selected employee has
sold_approved units with employee_seen_at = null. Shows live count; tap applies
the "Need seen" filter and scrolls to My Stock. Hides at zero. Updates via
renderAll() so it reacts to realtime owner sold-marking.
Additive only. No schema, query, or owner.html changes.

## Session B — Owner Overview enhancements (owner.html)
Added two blocks inside the Overview section, below the weekly KPIs:
- "Needs your attention": purple row for sold-but-not-seen units (taps to ledger
  filtered sold_notseen), red row for issue units (taps to ledger filtered issue),
  or an "all clear" line.
- "Salary by employee": one card per active employee — sold count, salary earned,
  paid, available (red + "(advance)" when negative). Reuses calcSalaryForEmployee().
Both refresh through renderOverview(). Additive only. No schema/query changes.

## Session C — Employee view polish (index.html)
- Profile selector moved into the top bar as a compact pill dropdown
  (#empSelectMini). Original #empSelect kept hidden in DOM for JS compatibility;
  the two stay in sync via onEmpChangeMini() + syncMiniSelector().
- "Need seen" quick-filter shows a live purple count badge (.qf-badge).
- "Mark all sold units as seen" button in My Stock, shown only when 2+ unseen,
  with a confirm step. Batches a single .in('id', ids) update + best-effort
  audit events. Per-card "Mark as seen" still covers single cases.
Additive only. Employee still cannot set sold status (verified).
