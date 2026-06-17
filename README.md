# Employee Progress Tracker — Supabase Edition

A real-time two-interface stock tracking system built with plain HTML, CSS, vanilla JavaScript, and Supabase as the backend.

---

## Files

| File | Purpose |
|------|---------|
| `index.html` | Employee view — see progress, stock units, report sales |
| `owner.html` | Owner dashboard — create stock, approve sales, view stats |
| `supabase-config.js` | Your Supabase credentials (create from example) |
| `supabase-config.example.js` | Template — copy this and fill in your values |
| `schema.sql` | PostgreSQL schema — run once in Supabase SQL Editor |
| `README.md` | This file |

---

## Setup

### 1. Create a Supabase project

- Go to [https://supabase.com](https://supabase.com) and create a free project.
- Wait for the project to provision (about 1 minute).

### 2. Run the database schema

- In your Supabase project, click **SQL Editor** in the sidebar.
- Paste the full contents of `schema.sql` and click **Run**.
- This creates the `employees`, `stock_units`, and `stock_events` tables with all indexes and triggers.

### 3. Configure credentials

- Copy `supabase-config.example.js` to `supabase-config.js` in the same folder.
- Open `supabase-config.js` and fill in:

```js
const SUPABASE_URL      = "https://your-project.supabase.co";
const SUPABASE_ANON_KEY = "eyJ...";  // your anon/public key
const OWNER_PIN         = "1234";    // change this to your preferred PIN
const DEFAULT_EMPLOYEE_CODE = "EMP-001";
```

- Find your URL and anon key in **Project Settings → API** inside Supabase.
- **Never put the `service_role` key in browser code.**

### 4. Enable Realtime

The schema.sql already includes:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE stock_units;
ALTER PUBLICATION supabase_realtime ADD TABLE stock_events;
```

If it didn't run for any reason, go to **Database → Replication** in Supabase and enable replication for `stock_units`.

### 5. Open the files

Open `index.html` and `owner.html` directly in a browser, or serve them from any static host (Netlify, Vercel, GitHub Pages, etc.).

Both files load `supabase-config.js` from the same directory — keep all files together.

---

## How the Owner uses it

1. Open `owner.html` and enter the owner PIN.
2. **Add an employee** under the Employees section.
3. **Add stock units** — enter the Stock ID, assign to employee, set upload date.
   - Order ID is intentionally left blank at this stage. It is only assigned when a sale is approved.
4. **Monitor the Ledger** — watch for sale reports from the employee in real time (the green dot in the nav bar indicates live connection).
5. **Approve a sale** — when a unit shows "Sale reported", click Approve, enter the Order ID and confirm the sold date.
6. **Flag issues** — if something needs checking, flag the unit with an issue note.
7. **Export** — use JSON or CSV export for records and reports.
8. **Copy weekly report** — generate a formatted text report for sharing.

---

## How the Employee uses it

1. Open `index.html` and select their name from the dropdown.
2. The dashboard immediately shows their current approved units, deposit, salary, level, and progress bar.
3. **My Stock** shows all stock units assigned to them with current status.
4. **Report a sale** — when a unit is sold, click "Report as sold", enter when it sold and an optional note/proof.
   - This sets the status to **"Sale reported — awaiting approval"**.
   - The owner sees this update in real time and can approve it.
5. Once the owner approves, the unit appears as **"Approved sold"** and the deposit/salary/progress updates automatically.

---

## Status system

| Status | Meaning | Counts in stats? |
|--------|---------|-----------------|
| `waiting_to_be_sold` | Stock exists, not yet sold | No |
| `sale_reported` | Employee reported it sold, waiting for owner | No |
| `sold_approved` | Owner confirmed the sale | **Yes** |
| `issue` | Problem flagged, needs attention | No |
| `cancelled` | Removed from stock | No |

Only `sold_approved` records count toward deposit, salary, level, capacity, and weekly stats.

---

## What is real-time?

Both pages subscribe to Supabase Realtime over WebSocket. When the owner approves a sale, the employee's page updates automatically within seconds — no page refresh needed. The green dot in the top navigation bar indicates an active live connection.

---

## Calculation rules

| Units approved | Deposit per unit | Salary per unit |
|---------------|-----------------|----------------|
| 1–20 | 75 coins | 25 coins |
| 21–45 | 60 coins | 40 coins |
| 46+ | 50 coins | 50 coins |

Each approved sold unit generates **100 coins** total earnings.

Every **300 deposit ≈ +1 future stock unit capacity**.

---

## Photo support (coming later)

The `stock_units` table already has `photo_path` and `photo_uploaded_at` columns ready for future use. The plan:

1. Employee photographs the sold item.
2. Upload goes to Supabase Storage bucket named `stock-photos`.
3. Path stored as `stock-photos/{stock_id}/{filename}`.
4. Owner can view the photo linked to the Stock ID when reviewing a sale report.

This is not implemented yet. No photo upload buttons exist in the current UI.

---

## Security notes

The current version is a **prototype**. The owner PIN is a local JavaScript variable — anyone with browser DevTools can bypass it.

**Real security requires:**
- Supabase Auth (email/password or OAuth login)
- Row Level Security (RLS) policies on all tables
- Employee accounts that can only see and update their own stock units
- Owner accounts with full access

The schema.sql includes commented-out RLS examples. Enable them once Supabase Auth is configured.

**Never put the `service_role` key in browser code.** Only the anon key belongs in client-side JavaScript.
