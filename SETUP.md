# SafeCheck-In — turning on the shared backend

The app works out of the box in **local mode** (responses saved only in the
browser you're using). To let managers on different devices share one live
board, connect a free **Supabase** project. ~10 minutes, one time.

---

## 1. Create the Supabase project

1. Go to <https://supabase.com> and sign up (free).
2. **New project** → give it a name (e.g. `oima-safecheck`), set a database
   password (save it somewhere), pick a region near you, **Create**.
3. Wait ~1 minute for it to finish provisioning.

## 2. Create the database tables

1. In the project, open **SQL Editor** → **New query**.
2. Open `supabase-schema.sql` from this repo, copy all of it, paste, **Run**.
   - This creates the `events` and `responses` tables, a summary view,
     turns on realtime + row-level security, and seeds the first event
     ("Gas leak at CalEPA HQ").

## 3. Create the shared passcode login

The "office passcode" is really the password of one shared sign-in account.

1. Go to **Authentication → Users → Add user → Create new user**.
2. Email: `office@safecheck.local`  (any address is fine — just match it in
   step 4). Password: **choose the office passcode** everyone will type.
3. Check **Auto Confirm User** so it's active immediately. **Create user**.

> To change the passcode later, edit this user's password here.

## 4. Point the app at your project

1. In Supabase open **Project Settings → API** and copy:
   - **Project URL**  (e.g. `https://abcd1234.supabase.co`)
   - **anon public** key (the long one labeled `anon` / `public`)
2. Open `config.js` in this repo and fill in:
   ```js
   window.SAFECHECK_CONFIG = {
     SUPABASE_URL: "https://abcd1234.supabase.co",
     SUPABASE_ANON_KEY: "eyJ...the anon key...",
     SHARED_EMAIL: "office@safecheck.local"   // must match step 3
   };
   ```
3. Save, commit, and push. GitHub Pages redeploys in ~1 minute.

That's it. The live site now shows a passcode screen; enter the passcode and
the board syncs live across every device.

---

## How the pieces map

| In the app | In Supabase |
|---|---|
| Passcode screen | Sign-in with the shared user (step 3) |
| The roster (Admin → ✎ Edit roster) | The `employees` table (shared across devices) |
| A person marked Safe / Needs help | A row in `responses` |
| Live updates on other devices | Realtime on `responses` + `employees` |
| "Archive & new event" | Old event set to `archived`, new `active` event created |
| "Saved versions" list | All rows in `events` (via `event_summary`) |

Exported JSON files include the organization header (org code **0270**,
"Office of Information Management and Analysis (OIMA)", California State Water
Resources Control Board).

## Good to know

- **The anon key is safe to publish** — it's designed to be public. Data is
  protected by row-level security: without signing in (the passcode) the key
  can't read or write anything.
- **The passcode gate is enforced at the database**, not just hidden in the
  page — someone poking at the API still can't see responses without it.
- **Everyone shares one passcode.** This is office-level access, not
  per-person accounts. If you later want to know exactly who submitted what,
  the "Reporting as… (your name)" box records a name on each update, and we
  can add real per-user logins as a follow-up.
- **Blank keys = local mode.** Clearing the keys in `config.js` puts the app
  back into browser-only mode (handy for testing).
