# BEEPBIP — Current State

> **Purpose:** The one file every new agent reads first. ≤50 lines. Keep it tight.
> **Update rule:** Whenever something becomes verified-working or newly broken, edit this file in the same turn.
> **Last updated:** 2026-05-02 (Community + Agent Architecture ratified — `MVP_SPEC.md` extended with §3.12 agent, §3.13 communities, §3.14 browseable tier, §4.7 agent runtime, §5.5–§5.7 schema deltas, Phases 7+8. `FOLLOWUPS.md` extended with §1.8, §2.9, §4.3. Open Qs for founder: D-AGENT-4, D-NBHD-1/2, D-B2B-1, D-CHIP-1. New investor-facing narrative at `docs/AGENT_NARRATIVE.md`. Phase 7+8 are post-SoHo-launch; do not interleave with Phases 0–6 work.).

---

## Current sprint focus

Foundation work toward SoHo MVP launch (Phases 0–6). Discovery agent + browseable-tier work (Phases 7–8) is **post-SoHo-launch** — do not start until Phase 6 is complete. See `docs/MVP_SPEC.md` for full scope and `docs/FOLLOWUPS.md` §1 for blocker list.

## Last verified working

- **2026-04-18** — Supabase staging project (`vjtqfmkqvxmqzztbndoo`, US-East-N.Virginia) created, linked, all 12 migrations + reference data pushed.
- **~2026-04-28** — Email/password auth signup → confirm-email → login flow works against staging Supabase (Resend SMTP wired, `onboarding@resend.dev` sender, port 465).
- **~2026-04-28** — User can land on home screen after login with no console errors.
- **~2026-04-28** — Listings vertical scaffolded end-to-end (Domain → Data → Application → Presentation) per `ARCHITECTURE.md`.
- **2026-04-29** — Posts vertical shipped in code: domain interface, Supabase repository, providers (incl. `bannedHashtagsProvider` cache), schema-aligned `PostCreationScreen` (Posting-as Personal/Business pill, Public/Unlisted visibility pill, 72h expiry footer). Compose-menu bottom sheet replaces the bare `+` FAB. **UI not yet smoke-verified** — see broken list below.
- **2026-04-29** — Migration `20260418000001_posts_visibility.sql` pushed to staging (`vjtqfmkqvxmqzztbndoo`) via `supabase db push`. Schema verified directly against the live remote dump: `posts.visibility text NOT NULL DEFAULT 'public'` with `CHECK (visibility IN ('public','unlisted'))`, partial index `idx_posts_neighborhood_public` on `(neighborhood_id, created_at DESC) WHERE visibility='public' AND NOT is_removed`, and new RLS policy `posts_select_active` = `owns_profile(author_profile_id) OR (visibility='public' AND NOT is_removed AND expires_at > now())`. §2.8(h) holds by policy form: unlisted rows are unreachable to any non-owner by construction. Cloud REST `POST /rest/v1/posts` with `visibility` in payload no longer errors with `42703`.
- **2026-05-01** — Business Page MVP scaffolded end-to-end:
  - New feature: `lib/features/business_page/` with `BusinessPageScreen` (cover hero, about + hours + contact + socials, photos strip aggregated from listing images, Services/Items/Events catalog tabs, Updates) and owner-only `BusinessPageEditScreen` (cover, logo, hashtags, hours grid, contact, social handles, Stripe Connect banner).
  - `BusinessProfileModel` + `ProfileRepository` extended with `coverUrl`, `hashtags`, `socialHandles`. `ProfileModel` extended with `isVerified`, `isFoundingBusiness`.
  - Routes: `/business/:profileId` and `/business/:profileId/manage` added to `app_router.dart`. Entry points wired from `ProfileScreen` ("View my business page" CTA for business users) and `ListingDetailScreen` ("Visit business page" link).
  - Edge Functions in `supabase/functions/`: `create-stripe-connect-account` (Connect onboarding), `create-booking-checkout` (auth-validated, server-computed totals + 8 % platform fee, Connect transfer), `stripe-webhook` (handles `checkout.session.completed`, `payment_intent.succeeded`, `account.updated`, `charge.refunded`, idempotent on `stripe_event_id`).
  - Booking CTA on `ListingDetailScreen` is gated by the `bookings.enabled` feature flag (added in migration `20260501140000_business_page_feature_flags.sql`, default OFF in production). The same migration adds `bookings.demo_mode` (default ON) which short-circuits the Stripe call with a polished mock checkout sheet (`BookingDemoSheet`) and a Connect-onboarding preview (`StripeConnectDemoSheet`) so the page is fully clickable without live Stripe credentials. Flip `bookings.demo_mode` OFF and provide `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` (template: `supabase/functions/.env.example`) to switch into the real Stripe path. UI **not yet smoke-verified** — see broken list.

## Known broken / suspicious

- ⚠️ **Business Page MVP — UI not yet smoke-verified.** Code compiles clean (`flutter analyze` reports no errors; only pre-existing `prefer_const_constructors` infos remain). Still needs a human run-through: open the page as a public viewer, enter the editor as the owner, upload a cover + logo, edit hashtags/hours/socials, save, return to viewer. Booking CTA path is gated by `bookings.enabled = false` so it remains hidden until Stripe Connect setup is verified end-to-end on staging.
- ⚠️ **Stripe Connect Edge Functions — never deployed / called yet.** Requires `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_CONNECT_RETURN_URL`, `STRIPE_CONNECT_REFRESH_URL`, `STRIPE_CHECKOUT_SUCCESS_URL`, `STRIPE_CHECKOUT_CANCEL_URL` to be set via `supabase secrets set ...` and the functions deployed via `supabase functions deploy create-stripe-connect-account create-booking-checkout stripe-webhook`. Webhook endpoint must be registered in Stripe with the events listed in `supabase/functions/stripe-webhook/index.ts`.
- ⚠️ **Phase 1 + 2 IA work — UI not yet smoke-verified.** Migration is now applied (see "Last verified working" 2026-04-29) and the schema-level §2.8(h) assertion is satisfied by the new RLS policy. Steps (a)–(g) of the §2.8 Phase-2 smoke (hot-restart, Compose → Share an update, Personal/Business pill, Public/Unlisted pill, `#porn` snackbar reject, public post create, unlisted post create + visibility from a second account) still need a human at the keyboard. Tracked in `FOLLOWUPS.md` §2.8.
- ⚠️ **Forgot-password flow** — reset email may not be arriving reliably. Needs end-to-end re-test on staging. (Surfaced twice in chat history.)
- ⚠️ **Post vs Listing UX coupling** — partially addressed: the home `+` is now a Compose menu (Phase 1 done). Full IA reorg (Discover tab with Map | Feed toggle, Search-tab cleanup, MyListings on Profile) still pending — Phases 3 + 4 in `FOLLOWUPS.md` §2.8.
- ⚠️ **Email confirm redirect** went to a different localhost project (port collision suspected) on at least one signup. Needs reproduction.
- ✅ *Resolved (in code, awaits user smoke):* "Business/Personal toggle missing" and "`#porn` was published successfully" — both were artifacts of the legacy in-memory mock `postsProvider`. The mock was deleted; the new code has a Personal/Business switcher in the Posting-as pill, a client-side `bannedHashtagsProvider` block, and the schema-level `enforce_banned_hashtags` trigger as a backstop.

## Active chats

| Chat | Lane | Status |
|---|---|---|
| `c0145b97` (megachat) | mixed (legacy) | **closed 2026-04-29** — drained into `STATE.md` / `FOLLOWUPS.md` / `ARCHITECTURE.md`; do not reopen |
| `7ba9c5da` | meta / workflow | active — chat workflow restructure |

(When you open a new lane chat per `docs/AGENTS.md`, add a row here in your first turn.)

## Blocking decisions for the founder

No founder decisions currently blocking — see `docs/FOLLOWUPS.md` §1.3 for the remaining open list (D3, D4, D5, D11).

## Where things live

- Spec & scope: `docs/MVP_SPEC.md`
- Architecture rules: `docs/ARCHITECTURE.md`
- Deferred work / open decisions: `docs/FOLLOWUPS.md`
- How to run chats: `docs/AGENTS.md`
- Workspace rules (auto-injected): `.cursor/rules/`
