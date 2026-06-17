# Next Task

## Status of previous task — DONE

The sold-flow refactor (owner marks sold, employee only marks seen) is fully
implemented and live in both index.html and owner.html. No longer pending.

The three UI/UX sessions are also done and logged in 05_BUG_FIX_HISTORY.md:
- A: Employee unseen-sold alert banner
- B: Owner Overview "needs attention" + per-employee salary
- C: Employee view polish (compact selector, filter badge, mark-all-seen)

---

## Current task — Owner page ease-of-use

Goal: make owner.html faster to operate day-to-day without breaking invariants.

Candidate improvements (to be scoped per session):
- Compact / merge navigation (9 tabs is a lot on mobile).
- Possibly merge Add Stock + Bulk Add into one section.
- Reduce clicks for the most common owner action (mark sold).
- Keep ledger powerful; do not remove existing filters or actions.

Scope discipline:
- One focused change set per session.
- Surgical str_replace edits, verify invariants + JS parse before delivery.

---

## After that — HUD visual polish (last)

Only once everything above is verified working in the browser:
- Prettify the HUD / dashboard visuals (spacing, hierarchy, color accents).
- Visual only — no logic, query, or schema changes.

---

## Permanent guardrails (every session)

- Do not change supabase-config.js or table names.
- Do not reintroduce duplicate rendering (keep uniqueById).
- Do not add Order ID to Add Stock form (only in Mark as Sold modal).
- Employee must not be able to mark stock sold; owner controls sold status.
- Keep index.html simple; keep owner.html powerful.
- Stats count only sold_approved; employee_seen_at does not affect deposit/salary.
