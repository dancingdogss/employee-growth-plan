# Security Setup — Phase 1A: Owner Authentication Foundation

This document describes the **manual** steps to bootstrap the owner account
after applying `migrations/20260712_01_owner_auth_foundation.sql`.

> **Scope of Phase 1A.** This phase only creates the `public.profiles` table
> (with RLS), the `private` schema, `private.employee_growth_is_owner()`, and an
> `updated_at` trigger. **No existing business table is changed and no business-table RLS is
> enabled.** `owner.html` still uses `OWNER_PIN` and keeps working exactly as
> before. Real owner login wiring and business-table RLS come in later phases.
>
> `supabase-config.js` (containing `SUPABASE_URL` and `SUPABASE_ANON_KEY`) stays
> in the repo. Those are **public frontend configuration**, not secrets. The
> security boundary is Supabase Auth + RLS — not hiding the publishable key.

---

## 0. Apply the migration

In the **Supabase Dashboard → SQL Editor**, paste and run the entire contents
of:

```
migrations/20260712_01_owner_auth_foundation.sql
```

The SQL Editor runs as a privileged role that **bypasses RLS**, which is why it
can seed the owner row in step 4 even though no client ever can.

---

## 1. Create the owner user in Supabase Authentication

1. Go to **Authentication → Users → Add user** (or **Invite**).
2. Create the single owner account with an email and a strong password.
   - Use a real mailbox you control. Do **not** put the password anywhere in
     this repo.
3. If prompted, mark the email as confirmed so the user can sign in.

> Do not create the owner via a public sign-up form. See step 2.

---

## 2. Disable / avoid public signup

So that a random visitor cannot self-register and later be (mis)assigned a
role:

- **Authentication → Providers → Email** → turn **"Allow new users to sign up"
  OFF** (disable public sign-ups). Create users manually from the dashboard.
- Later phases that use **anonymous sign-in** for employees are unaffected by
  this setting; anonymous users receive `role = authenticated` in their JWT but
  have **no `profiles` row**, so `private.employee_growth_is_owner()` returns
  FALSE for them.

> Being any authenticated user grants nothing. Owner power requires a
> `profiles` row with `role = 'owner'`, which only a privileged SQL session can
> create.

---

## 3. Copy the new user's UUID

- **Authentication → Users →** click the owner user → copy the **User UID**
  (a UUID like `00000000-0000-0000-0000-000000000000`).

Keep this UUID handy for the next step. It is not secret, but it must be exact.

---

## 4. Insert the owner profile (manual, SQL Editor)

Run this in the **SQL Editor**, replacing the placeholder with the UUID from
step 3:

```sql
INSERT INTO public.profiles (id, role)
VALUES ('OWNER_AUTH_USER_UUID', 'owner');
```

Notes:

- `OWNER_AUTH_USER_UUID` is a **placeholder** — paste the real UUID between the
  quotes. Do not paste an email, a password, or any key here.
- If you prefer a guarded insert (no-op if it already exists):

  ```sql
  INSERT INTO public.profiles (id, role)
  VALUES ('OWNER_AUTH_USER_UUID', 'owner')
  ON CONFLICT (id) DO NOTHING;
  ```

---

## 5. Verify the profile exists

```sql
SELECT id, role, created_at
FROM public.profiles
WHERE id = 'OWNER_AUTH_USER_UUID';
```

Expected: exactly **one** row with `role = 'owner'`.

You can also confirm the helper resolves correctly. Because
`private.employee_growth_is_owner()` reads `auth.uid()`, test it from an
**authenticated** context (see step 7) rather than the SQL Editor, where
`auth.uid()` is NULL.

---

## 6. Verify anonymous requests cannot read profiles

Using the **public anon key** (the same one in `supabase-config.js`), an
unauthenticated REST call must return **no rows** (RLS denies it):

```bash
# Replace <PROJECT> and <ANON_KEY> with your public project ref / publishable key.
curl -s "https://<PROJECT>.supabase.co/rest/v1/profiles?select=*" \
  -H "apikey: <ANON_KEY>"
```

Expected: `[]` (empty array) — never the owner row. An empty result here is a
**pass**: anonymous callers cannot enumerate roles.

---

## 7. Verify the authenticated owner reads only their own profile

Sign in as the owner to obtain a user access token (JWT), then query:

```bash
# 1) Sign in (returns an access_token in the JSON response).
curl -s "https://<PROJECT>.supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"email":"<OWNER_EMAIL>","password":"<OWNER_PASSWORD>"}'

# 2) Use the returned access_token as the Bearer token.
curl -s "https://<PROJECT>.supabase.co/rest/v1/profiles?select=*" \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <OWNER_ACCESS_TOKEN>"
```

Expected: exactly **one** row — the owner's own profile. Even if other profile
rows existed, the owner would still see only their own (the policy is
`USING (auth.uid() = id)`).

> `<OWNER_EMAIL>`, `<OWNER_PASSWORD>`, `<OWNER_ACCESS_TOKEN>` are placeholders
> you supply at the terminal. Never commit real values.

---

## 8. Recovery — wrong UUID inserted

If you inserted the wrong UUID (e.g. a typo, or a non-owner user), fix it in the
**SQL Editor** (which bypasses RLS):

- **Remove the bad row:**

  ```sql
  DELETE FROM public.profiles
  WHERE id = 'WRONG_UUID';
  ```

- **Insert the correct one:**

  ```sql
  INSERT INTO public.profiles (id, role)
  VALUES ('CORRECT_OWNER_AUTH_USER_UUID', 'owner')
  ON CONFLICT (id) DO NOTHING;
  ```

- **Or correct the role in place** (if the row is right but the role is wrong):

  ```sql
  UPDATE public.profiles
  SET role = 'owner'
  WHERE id = 'CORRECT_OWNER_AUTH_USER_UUID';
  ```

Because clients have **no** INSERT/UPDATE/DELETE access to `profiles`, these
corrections are only possible from a privileged SQL session — which is exactly
the intended security property. You cannot lock yourself out of this table from
a browser, and there is no client path to grant yourself `owner`.

> Full teardown of this phase (if ever needed) is
> `migrations/20260712_01_owner_auth_foundation_rollback.sql`. Note it drops
> `public.profiles` and therefore the owner role row; re-run the forward
> migration and repeat this bootstrap afterwards.

---

## What must be true after Phase 1A

- [ ] `public.profiles` exists with RLS **enabled** and a single `SELECT`-own
      policy.
- [ ] Exactly one `owner` row (your owner user's UUID).
- [ ] Anonymous `GET /rest/v1/profiles` returns `[]`.
- [ ] Authenticated owner sees only their own row.
- [ ] `owner.html` and `index.html` are unchanged and still work as before.
- [ ] No business table (`employees`, `stock_units`, `stock_events`,
      `stock_types`, `salary_payouts`, `owner_messages`) had RLS enabled or
      data changed by this phase.
