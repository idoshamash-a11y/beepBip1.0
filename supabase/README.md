# Supabase — BEEPBIP

This folder holds the entire database schema as versioned migrations plus
local‑dev config. It is the source of truth for the BEEPBIP database.

## Prerequisites

- **Docker Desktop** (running) — Supabase CLI spins up Postgres + Auth + Storage + Studio in containers.
- **Supabase CLI** ≥ `1.200`
  - macOS: `brew install supabase/tap/supabase`
  - [Other OSes](https://supabase.com/docs/guides/cli/getting-started)
- **PostGIS knowledge** (nice to have — the schema uses `GEOGRAPHY` heavily).

> The Flutter app does **not** require Docker. You only need it if you want to
> run the DB locally. If you prefer, you can point the app at a cloud Supabase
> project instead and skip the local stack.

## Quick start (local dev)

From the repo root (`beepBip1.0/`):

```bash
supabase start           # boots Postgres, Auth, Storage, Studio, Inbucket
supabase db reset        # drops DB, re-applies all migrations, runs seed.sql
```

After `start`, you’ll see something like:

```
API URL:     http://127.0.0.1:54321
DB URL:      postgresql://postgres:postgres@127.0.0.1:54322/postgres
Studio URL:  http://127.0.0.1:54323
Inbucket:    http://127.0.0.1:54324   # catches outbound emails
anon key:    eyJhbGciOi...             # use in flutter_dotenv
```

Drop those into the Flutter app’s env file (see `lib/core/config/`).

## Layout

```
supabase/
├── config.toml                 # local CLI config (ports, auth providers, etc.)
├── seed.sql                    # runs after migrations on `supabase db reset`
├── migrations/
│   ├── 20260417180000_extensions_and_helpers.sql
│   ├── 20260417180001_enums.sql
│   ├── 20260417180002_users_and_profiles.sql
│   ├── 20260417180003_neighborhoods_postgis.sql
│   ├── 20260417180004_locations.sql
│   ├── 20260417180005_listings.sql
│   ├── 20260417180006_bookings_and_payments.sql
│   ├── 20260417180007_feedback_and_disputes.sql
│   ├── 20260417180008_posts_and_messaging.sql
│   ├── 20260417180009_moderation.sql
│   ├── 20260417180010_rls_policies.sql
│   └── 20260417180011_rpc_functions.sql
└── README.md                   # this file
```

### Migration ordering rules

Filenames are `YYYYMMDDHHMMSS_description.sql`. The CLI applies them in
lexicographic order, so the timestamp prefix is what enforces ordering.

**Never edit a migration that has been applied to staging/prod.** Instead,
create a new dated file:

```bash
supabase migration new add_something_new
# → supabase/migrations/<new-timestamp>_add_something_new.sql
```

### Writing a new migration

1. `supabase migration new <name>` creates an empty file.
2. Edit it. Use `IF NOT EXISTS` / `DROP ... IF EXISTS` / `ON CONFLICT` to keep
   it re‑runnable locally — production only runs it once, but `db reset` runs
   everything fresh.
3. `supabase db reset` to wipe + re‑apply everything including your new file.
4. Verify in Studio (http://127.0.0.1:54323) or with `psql`.
5. Commit the migration file. Never edit it again.

### Linking to a cloud project

Once a Supabase cloud project exists:

```bash
supabase link --project-ref <your-project-ref>
supabase db push                      # applies local migrations to cloud
```

Recommend three cloud projects: `beepbip-dev`, `beepbip-staging`, `beepbip-prod`.

## Schema overview

See [`../docs/MVP_SPEC.md`](../docs/MVP_SPEC.md) §5 for the full data model
rationale. TL;DR:

- **Identity**: `users` ↔ `auth.users`, plus `profiles` (+ `personal_profiles`
  / `business_profiles`), `business_hours`, `interests`.
- **Geo**: `neighborhoods` (PostGIS polygons) + `locations` (PostGIS points).
- **Commerce**: `listings` → `bookings` → `payments` (+ `stripe_accounts`).
- **Trust**: `feedback` (double‑blind), `disputes`, `verifications`, `reports`.
- **Social (thin)**: `posts`, `conversations`, `messages`.
- **Ops**: `banned_hashtags`, `muted_hashtags`, `feature_flags`, `admin_audit_log`.

Every user‑visible table has RLS enabled (migration `...10_rls_policies.sql`).
Writes to money‑moving tables flow through SECURITY DEFINER RPCs (migration
`...11_rpc_functions.sql`).

## Useful commands

```bash
supabase start                   # boot local stack
supabase stop                    # shut it down (keeps data)
supabase stop --no-backup        # shut down + wipe data
supabase db reset                # drop + re‑create local DB
supabase db diff -f <name>       # generate migration from Studio-made changes
supabase migration new <name>    # scaffold a new empty migration
supabase migration list          # show which migrations are applied where
supabase db push                 # push local migrations → linked cloud project
supabase db pull                 # pull cloud schema → new local migration
```

## Edge Functions (Stripe)

Three Edge Functions back the Business Page MVP's booking surface
(see `supabase/functions/`):

- `create-stripe-connect-account` — kicks off Stripe Standard onboarding for a
  business profile and returns the Account Link URL.
- `create-booking-checkout` — creates a `pending` booking and a Stripe
  Checkout Session with `transfer_data.destination` pointing at the seller and
  an 8% `application_fee_amount`.
- `stripe-webhook` — `verify_jwt = false`; advances bookings past `pending`
  and writes `payments` ledger rows on `checkout.session.completed`,
  `payment_intent.succeeded`, etc. Idempotent on `payments.stripe_event_id`.

### Demo mode (no Stripe keys yet)

While `feature_flags.bookings.demo_mode = TRUE`, the Flutter app **never**
calls these functions. The Book / Reserve / Buy CTA opens
`BookingDemoSheet` and the "Connect Stripe" banner opens
`StripeConnectDemoSheet`. This is the default state on the dev DB so you can
demo the whole storefront without Stripe credentials.

The functions still boot cleanly without keys (lazy Stripe-client
construction); they just return `503 stripe_not_configured` when invoked.

### Going live

When the Stripe account is ready:

```bash
cp supabase/functions/.env.example supabase/functions/.env
# edit .env — paste sk_test_… and whsec_…

# Local:
supabase functions serve --env-file supabase/functions/.env

# Remote (linked project):
supabase secrets set --env-file supabase/functions/.env
supabase functions deploy create-stripe-connect-account create-booking-checkout stripe-webhook
```

Then flip the flags:

```sql
UPDATE public.feature_flags SET enabled = FALSE WHERE key = 'bookings.demo_mode';
UPDATE public.feature_flags SET enabled = TRUE  WHERE key = 'bookings.enabled';
```

Point the Stripe Dashboard webhook at
`https://<project-ref>.supabase.co/functions/v1/stripe-webhook` and copy the
signing secret into `STRIPE_WEBHOOK_SECRET`.

## Troubleshooting

- **`supabase start` fails with Docker error** → make sure Docker Desktop is
  running; `docker ps` should not error.
- **Ports already in use** → change ports in `config.toml` and restart.
- **Auth trigger doesn’t fire on signup** → check the `on_auth_user_created`
  trigger exists: `SELECT tgname FROM pg_trigger WHERE tgname LIKE 'trg_on_auth%';`
- **PostGIS functions missing** → the `postgis` extension is created in
  migration 00. Re‑run `supabase db reset` if you somehow skipped it.
