# BEEPBIP — Follow-ups & TODOs

> **Purpose:** One place to track every deferred decision, external dependency, and "check-on-this-later" item from `MVP_SPEC.md`.
> **How to use:** Check items off as they're done. Add new items here (don't scatter them). Review every Monday.
> **Last updated:** 2026-05-02 (Community + Agent Architecture design ratified — added §1.8 agent/community/browseable-tier blockers, §2.9 build-prep operational items, §4.3 V1.5 agent enhancements, §7 resolutions for D-AGENT-1/2/3/5 and D-COMM-1; flagged D-AGENT-4, D-NBHD-1/2, D-B2B-1, D-CHIP-1 for founder).

Legend: 🔴 blocks launch · 🟠 needed during build · 🟡 V1.5 · 🟢 V2+ / watch · ⚪ ongoing

---

## 1. Pre-launch blockers (🔴 must finish before public SoHo launch)

### 1.1 Legal & compliance

- [ ] 🔴 **NY sales tax nexus check** (D12). Confirm with a marketplace-familiar CPA whether the Florida LLC has a marketplace-facilitator obligation under NY Tax Law §1101(e). If yes, enable Stripe Tax and verify collection logic before accepting real payments. Budget: ~$500 for consult.
- [ ] 🔴 **Terms of Service** drafted and reviewed by lawyer (D8). Must cover marketplace role, dispute resolution, limitation of liability, arbitration clause.
- [ ] 🔴 **Privacy Policy** drafted — CCPA + baseline GDPR compliance (D8). Location data, payment data, retention, deletion rights.
- [ ] 🔴 **Seller / Business Agreement** — platform T&Cs addendum to Stripe Connect T&Cs. Covers listing rules, prohibited content, fee schedule, payout terms, termination.
- [ ] 🔴 **Refund policy** — public-facing page explaining escrow, 72h auto-release, buyer protection, dispute process.
- [ ] 🔴 **Content moderation policy** — public-facing page. What's prohibited. How to report. How appeals work.
- [ ] 🔴 **DMCA takedown process** — contact email + 24h SLA for first response.
- [ ] 🔴 **Florida LLC good standing** — confirm registered agent, annual report filed, EIN active. Pull a certificate of good standing if needed for Stripe Connect onboarding.
- [ ] 🔴 **Business liability insurance** — shop for a policy that covers marketplace operations. Minimum $1M coverage. Hiscox, Thimble, Next Insurance offer online quotes for small businesses.

### 1.2 Payments & money movement

- [ ] 🔴 **Stripe Connect platform application** approved for the Florida LLC. Apply early — Stripe review takes 1–2 weeks.
- [ ] 🔴 **Bank account verified** and connected to Stripe Connect platform. (User confirmed US business account exists; just needs linking.)
- [ ] 🔴 **Stripe webhooks** deployed to an Edge Function with signed verification; tested in `staging` Supabase project.
- [ ] 🔴 **Test every edge case** on Stripe Connect before real money flows:
  - Successful charge → payout to seller
  - Partial refund
  - Full refund (platform fee refunded too)
  - Dispute raised → escrow locked
  - Seller Stripe account not yet `charges_enabled` → booking blocked
  - Card declined mid-booking

### 1.3 Platform & product decisions still open

- [ ] 🔴 **D3 — Who does SoHo door-to-door.** Co-founder C solo? C + local part-time? Budget + start date.
- [ ] 🔴 **D4 — Launch date target.** Realistic window: 8–10 weeks from foundation work start. Needs founder alignment so marketing preps accordingly.
- [ ] 🔴 **D5 — Verification rigor V1.** Manual review by C (free, slower, works at 50 businesses) vs. Stripe Identity ($1.50/verify, instant, works at scale). Recommendation: manual for first 100, switch to Stripe Identity once volume justifies.
- [ ] 🔴 **D11 — Banned-hashtags seed list.** ~100-term initial list. Start from open-source [naughty-words](https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words) + SoHo-specific additions (scam keywords, drug-related, controlled categories).
- [ ] 🔴 **D-AGENT-4 — Agent free-tier daily message budget.** Recommendation: 30 messages/day OR 100k tokens/day (whichever first). Business Pro: unlimited with a 1M-token/day abuse ceiling. Founder sign-off needed before agent enable.
- [ ] 🔴 **D-NBHD-1 — Browseable-tier neighborhood set.** Recommendation: Williamsburg, West Village, Lower East Side, Nolita, NoHo. Founder confirmation needed before importer or polygon work begins.
- [ ] 🔴 **D-NBHD-2 — Public-data sources for browseable tier.** Mix to validate with counsel: Google Places (paid, cached) + Yelp Fusion (free tier, attribution required) + NYC OpenData (free, official). Each needs a one-page ToS memo before import code ships. Budget: ~$1k legal.
- [ ] 🔴 **D-B2B-1 — B2B payment path in V1.** Recommendation: V1 uses standard Stripe charges (same path as B2C). Stripe Invoices + net-terms is V2. Need CPA confirmation that "instant-pay" B2B contracts don't trip any 1099/marketplace-facilitator quirks distinct from B2C.
- [ ] 🔴 **D-CHIP-1 — Serial-ID chip default tap behavior.** Recommendation: change default tap from "Copy" to "Open overlap sheet"; expose Copy as a button inside the sheet. Change is small but touches every place a chip renders today. Ship behind feature flag `chip.tap_opens_overlap` so we can roll out the sheet first and flip behavior atomically. Founder OK needed before the flip.

### 1.4 App store & distribution

- [ ] 🔴 **Apple Developer account** active ($99/yr). Required for: TestFlight (sharing test builds with co-founders), App Store submission, and Sign in with Apple.
- [ ] 🔴 **Google Play Developer account** active ($25 one-time). Required for: Internal Testing track (sharing test builds), Play Store submission.
- [ ] 🔴 **App Store Connect** app record created, screenshots prepared, privacy questionnaire filled.
- [ ] 🔴 **Play Console** app record created, data safety form filled.
- [ ] 🔴 **App icon + splash + screenshots** — requires designer.
- [ ] 🔴 **Privacy labels / nutrition facts** (iOS) — match what we actually collect; audit before submission.
- [ ] 🔴 **Sign in with Apple — Apple Service ID + native iOS capability**. The Dart-side scaffolding (`SupabaseAuthRepository.signInWithApple`) is in place; still need:
  - Create an Apple Service ID in the Apple Developer portal.
  - Enable the "Sign in with Apple" capability in Xcode for the iOS target.
  - Configure Apple as an OAuth provider in the Supabase cloud project (Service ID + key + team ID).
  - For Android: wire the web-fallback flow (currently returns `DomainFailure` on Android).
- [ ] 🔴 **Google OAuth client IDs** for iOS, Android, and Web, all linked to Supabase project.
- [ ] 🔴 **Facebook App** configured, Meta business verification completed if we use any advanced scopes.
- [ ] 🔴 **FCM + APNs certificates** installed for push notifications.

### 1.4a Test build distribution (🔴 needed before any external user can install the app)

- [ ] 🔴 **TestFlight** internal testing group set up; co-founders + early invitees added by Apple ID. Requires Apple Developer account (above).
- [ ] 🔴 **Play Internal Testing** track set up; co-founders + early invitees added by Google account. Requires Play Console account (above).
- [ ] 🔴 **iOS code signing** — distribution certificate + provisioning profiles in Apple Developer portal. Codemagic / EAS / GitHub Actions can manage these once accounts exist.
- [ ] 🔴 **Android keystore** generated, backed up to a password manager (NOT in git), and uploaded to Play Console for app signing.
- [ ] 🔴 **CI release pipeline** producing signed `.ipa` and `.aab` artifacts on every `main` push, uploading to TestFlight + Play Internal Testing automatically.

### 1.4b Action checklist for resolving D2 (Business Pro pricing) and D7 (iOS-first) into reality

> **Why this section exists:** D2 and D7 are resolved as decisions (see §7), but the operational steps — accounts to open, products to configure, paperwork to sign — are scattered across §1.4 and §1.5. This checklist orders them so the longest-lead-time items start first, and adds the per-store IAP setup that wasn't previously called out.

**Total cash to apply both decisions:** $124 ($99 Apple Developer + $25 Google Play). Everything else is configuration time.

**Ordered rollout (do top-down — earlier items unblock later ones):**

- [ ] 🔴 **Apple Developer Program enrollment** — $99/yr, [developer.apple.com/programs](https://developer.apple.com/programs/). Longest pole; D-U-N-S verification for the Florida LLC can stall enrollment 0–2 days. Unblocks: TestFlight, Sign in with Apple, App Store Connect subscription products, APNs.
- [ ] 🔴 **Google Play Console enrollment** — $25 one-time, [play.google.com/console](https://play.google.com/console). Identity verification 0–3 days. Unblocks: Play Internal Testing, Play Console subscription products.
- [ ] 🔴 **RevenueCat account** — free up to $2.5k MTR, [revenuecat.com](https://www.revenuecat.com/). Skim the [Flutter quickstart](https://www.revenuecat.com/docs/getting-started/installation/flutter) while Apple is verifying. (`purchases_flutter` is already in `pubspec.yaml` per `MVP_SPEC.md` §A.2.)
- [ ] 🔴 **Apple Paid Apps agreement** — once Apple Developer is approved, go to App Store Connect → Agreements, Tax, and Banking → sign the Paid Apps agreement for the Florida LLC. Apple will not release IAP funds until this is signed, AND App Store Connect's product creation flow checks for it. Do this *before* creating IAP products.
- [ ] 🔴 **Play Console payments profile** — Play Console → Settings → Payments profile → set up the merchant account with the LLC tax + banking details.
- [ ] 🔴 **App Store Connect — Business Pro subscription products:**
  - Create Subscription Group `business_pro` (single group so monthly/annual are upgrade/downgrade peers).
  - Product `business_pro_monthly` — $29.99 USD, "1 Month".
  - Product `business_pro_annual` — $289.99 USD (closest App Store tier to $290), "1 Year".
  - Introductory Offer on both products: "Free", duration 14 days, eligibility = New subscribers. (Apple allows one free-trial per user per group; configuring on both products is correct because users can pick either as their entry point.)
  - Localized display name + description for each product.
- [ ] 🔴 **Play Console — Business Pro subscription products:**
  - Same product IDs (`business_pro_monthly`, `business_pro_annual`) — RevenueCat assumes parity.
  - Same prices ($29.99 / $289.99 USD).
  - Add a 14-day free trial as the base plan offer on each.
- [ ] 🔴 **RevenueCat dashboard configuration:**
  - Create entitlement `business_pro`.
  - Create one offering with two packages: `$rc_monthly` → `business_pro_monthly`, `$rc_annual` → `business_pro_annual`.
  - Wire App Store credentials (App Store Connect API key) and Play Store credentials (Play Service Account JSON).
- [ ] 🔴 **Sign in with Apple — finish the Service ID + Xcode capability** (already partially tracked in §1.4). Service ID in Apple Developer portal → enable capability in Xcode iOS target → configure Apple as OAuth provider in staging Supabase project (Service ID + key + team ID). Dart side already coded in `SupabaseAuthRepository.signInWithApple`.
- [ ] 🔴 **APNs key + Firebase Cloud Messaging linkage** — generate APNs key in Apple Developer portal, upload to the Firebase project (also tracked in §1.4 / §1.5).
- [ ] 🔴 **Android keystore** — generate locally, back up to a password manager (NOT in git), upload to Play Console for app signing. (Duplicated from §1.4a for completeness; check off in both places when done.)

**What's intentionally NOT in this checklist:**

- Anything beyond the SoHo POC (Stripe Tax, multi-currency, Verified badge fee) — those live in §4 / §5.
- The native-Android design parity work — parked at V2 per the D7 resolution (`MVP_SPEC.md` §10, `FOLLOWUPS.md` §7).

### 1.5 Third-party accounts to create

- [x] 🔴 **Supabase staging project (`BeepBip`, ref `vjtqfmkqvxmqzztbndoo`, region East US — N. Virginia)** — created, linked, all 12 migrations + reference data pushed (2026-04-18).
- [ ] 🔴 **Supabase prod project (`beepbip-prod`)** — create when staging is stable. Same workflow:
  - `supabase link --project-ref <ref>` per environment.
  - `supabase db push` to apply our local migrations to the cloud DB.
  - Copy the cloud project URL + publishable key into `.env.prod` (gitignored).
  - Configure the same auth providers we wired locally (Google, Facebook, Apple) per project.
  - Ship a build with `--dart-define=FLAVOR=prod` to point the app at the cloud project.
- [ ] 🔴 **Transactional email — verify own domain in Resend.** Resend account + API key are wired into Supabase Auth → custom SMTP for staging using the shared `onboarding@resend.dev` sender. Before opening to real users, verify the production sending domain (e.g. `beepbip.com`) in Resend (DNS: SPF + DKIM + optional DMARC), update the Supabase SMTP "Sender email" to `hello@beepbip.com` (or chosen address), and customize the Auth email templates (confirmation, magic link, password reset, email change). Mirror the same setup in the prod Supabase project.
- [ ] 🔴 **Supabase Auth — Site URL & Redirect URLs.** Currently using defaults; before opening to real testers, set Authentication → URL Configuration → Site URL to the canonical app URL (web) and add allowed Redirect URLs for: localhost dev, staging web build, mobile deep-link scheme (e.g. `beepbip://auth-callback`), and Apple/Google/Facebook OAuth callback URLs.
- [ ] 🔴 **MapTiler account** — signup, create API key scoped to mobile app, note free-tier ceiling (100k loads/mo).
- [ ] 🔴 **RevenueCat account** — create products matching App Store Connect + Play Console subscription products.
- [ ] 🔴 **Firebase project** for Crashlytics + FCM.
- [ ] 🔴 **PostHog** — either cloud free tier (1M events/mo) or self-host on a $20/mo Hetzner VPS. Recommendation: start with cloud free, self-host when volume exceeds free tier.
- [ ] 🔴 **GitHub Actions secrets** populated for dev/staging builds.
- [ ] 🔴 **Vercel project** for the Next.js admin panel.

### 1.6 Legal docs & policies in-app

- [ ] 🔴 All legal docs linked from signup, settings, and the web marketing site.
- [ ] 🔴 Age gate on signup (13+ US; consider 18+ for booking adult-adjacent services).
- [ ] 🔴 Acceptance checkboxes logged with timestamp + policy version for audit trail.

### 1.7 Trust & moderation (the "verify don't restrict" doctrine)

> **Guiding principle (founders, 2026-04-28):** Verify the **person** at the gate, gate **content** at submit-time via a queue (manual + agentic), and **monitor** content after publish. **Never** make the act of authoring slow. Open posting/listing for all verified users; trust comes from the layered safety net, not from gatekeeping who can write.

#### 1.7.a Identity gate (at signup / login, not at post/listing time)

- [ ] 🔴 **Phone OTP verification before first write.** Anyone can browse without a phone number, but writing a post or listing requires `phone_verified = true`. Cheap signal, deters spam, no UX hit on the act of posting itself. Use Twilio Verify or Supabase phone-auth.
- [ ] 🟠 **Stripe Identity** for higher-trust badge (D5). Voluntary for personal users, required for business profiles handling money. $1.50/check, instant.
- [ ] 🟠 **Email confirmation already enforced** (Supabase default) — keep as-is.
- [ ] 🟠 **Behavioural signals** at signup: device fingerprint, IP geolocation vs claimed neighborhood, signup velocity per IP. Used to flag suspect accounts to the moderation queue automatically rather than blocking.

#### 1.7.b Pre-publish moderation queue (initial launch phase)

> **Status today (2026-04-28):** posts and listings publish instantly. Acceptable for internal dev / smoke testing. **Must flip before public SoHo launch.**

- [ ] 🔴 **`moderation_status` column** on `public.posts` and `public.listings`: `pending_review` | `approved` | `rejected`. Default `pending_review` once the flip is made; default `approved` until then to keep dev velocity. New migration.
- [ ] 🔴 **RLS policy update** so non-owners only see `approved` rows; owners see all of their own (any status). Mirrors the existing `listings_select_active` shape.
- [ ] 🔴 **Agentic first-pass review** via an Edge Function: every new post / listing fires a webhook to an LLM that scores against rules (`policy.json`: prohibited categories, suspect keywords, IP/identity correlation, image content if images are in scope by then). Auto-approve `score >= 0.95`, auto-reject `score <= 0.10`, send the middle band to the human queue.
- [ ] 🔴 **Human queue** (V1 = co-founders + part-time SoHo person) in the Next.js admin panel (§3.10). Approve / reject with reason, with reject reasons fed back to the user via in-app inbox. Target SLA: 1 hour median during launch phase.
- [ ] 🔴 **Author-side UX copy** when a write goes to queue: *"Your post is in review and will go live shortly. We'll let you know if anything needs to change."* Critical that it doesn't feel like rejection or punishment.
- [ ] 🟠 **Trust ladder.** Author with N consecutive approved posts → `auto_approved = true`, future posts skip the queue (still subject to post-publish monitoring). Configurable threshold, default 5.

#### 1.7.c Submit-time hard blocks (no queue, instant feedback — already partial)

These are not "moderation" — they're fast-failing form validation that prevents queue spam from obvious abuse.

- [ ] 🟠 **Banned-hashtags client check.** `banned_hashtags` table exists + seeded. Wire a Riverpod provider that loads the list at app start; the post + listing forms reject submission if any hashtag matches. Server-side trigger as a backstop (already in schema for listings; add for posts).
- [ ] 🟠 **Hashtag auto-normalization** (lowercase, strip `#`, alphanumeric + underscore only). Already enforced server-side via the `normalize_hashtags` trigger; mirror client-side for snappier UX.
- [ ] 🟠 **Length & rate caps.** Post `content` 1–500 chars (schema enforces). Listings cap at 10 per business per 24h to prevent flooding the queue.
- [ ] 🟠 **Image safety scan** once image upload lands (FOLLOWUPS §2.6). Use Cloudflare Images / Sightengine for nudity + violence detection at upload time, before the row is even queued.

#### 1.7.d Post-publish ongoing monitoring

- [ ] 🟠 **Report button on every post / listing / profile** → writes to `public.reports` (table already in schema, no UI yet). Threshold-based escalation: 3 reports on the same row in <24h → auto-paused pending re-review.
- [ ] 🟠 **Repeat-offender heuristics.** Every rejected post increments an `offense_count` on the user; thresholds escalate to soft-warn → temporary write ban → permanent ban. Logged in `admin_audit_log`.
- [ ] 🟠 **Periodic LLM scan** of recently-published rows for drift (an approved post that becomes problematic in context). Cheap nightly Edge Function batch.
- [ ] 🟡 **Trust dashboard** for admins: queue length, median review SLA, false-positive / false-negative rates from the agentic scorer, top reporters and reportees. Without this we can't tune the auto-approve thresholds.
- [ ] 🟡 **User-facing trust signals.** Display verification badges (phone-verified, ID-verified, founding business) on cards so consumers can see the trust level at a glance. Schema (`verifications` table) is in place.

#### 1.7.e Open product questions to settle before flipping the queue on

- [ ] 🔴 **What's the median agentic confidence threshold?** Need real data from a 1-week shadow run (queue runs but everything still publishes) to calibrate before going hard.
- [ ] 🔴 **Who staffs the queue at launch?** Co-founder C primary, plus the SoHo door-to-door part-timer? Define on-call schedule.
- [ ] 🔴 **What's the appeal flow for a rejected post?** "Reply to the rejection notification" → admin inbox seems sufficient for V1. Defined when the inbox UI lands.
- [ ] 🔴 **Cost of agentic review at scale.** Estimate: $0.001/post × 200 posts/day × 30 days = $6/mo at SoHo POC scale. Negligible. Revisit at neighborhood-#5 scale.

### 1.8 Community + Agent + Browseable-tier blockers (added 2026-05-02)

> **Context:** the Community + Agent Architecture design was ratified on 2026-05-02 (see `MVP_SPEC.md` §3.12, §3.13, §5.5, §5.6 and the design doc in `.cursor/plans/community_agent_architecture_*.plan.md`). The items below are the things that have to happen before the agent can actually be enabled in front of real SoHo users. They block the agent flag, not the underlying SoHo POC — meaning the SoHo MVP can ship without them and the agent can flip on as a follow-on phase.

#### 1.8.a Agent infrastructure (🔴 before agent launches publicly)

- [ ] 🔴 **Anthropic API account + billing**, with separate keys per environment (dev/staging/prod). Confirmed model availability in our region: `claude-sonnet-4-5` (smart) and `claude-haiku-4-5` (router/cheap). Budget alert thresholds set in the Anthropic console at $100, $500, $2,000/mo so cost runaway is impossible to miss.
- [ ] 🔴 **Per-user daily token budget enforced server-side** in the agent Edge Function. Default: free tier ~30 messages/day or ~100k tokens/day (whichever first); Business Pro: unlimited with a hard ceiling of 1M tokens/day to catch abuse. Exceed → graceful fallback to traditional `discover_listings` search.
- [ ] 🔴 **Prompt cache hit-rate >70%** verified in observability dashboards before launch. System prompt + tool schemas are cache-eligible per Anthropic's caching docs; if hit rate is below this we are over-paying by 3–5x.
- [ ] 🔴 **Tool schema versioning + backward compatibility plan.** Each tool gets a semver tag in the system prompt; deprecated tool calls return a structured error the agent surfaces to the user as "I tried something that's no longer available." Avoids silent breakage on tool changes.
- [ ] 🔴 **`agent_traces` retention policy.** Decide between 30/60/90-day raw-conversation retention. Recommend 60 days to balance debugging needs with privacy minimization. Document in privacy policy.
- [ ] 🔴 **Hallucination guardrail tested.** Before launch, run an adversarial prompt set ("recommend a restaurant on Mars", "what's the address of [made-up business]?") and confirm the agent never invents entities. System prompt forbids returning entities not retrieved through a tool call.
- [ ] 🔴 **Latency budget defined.** Time-to-first-token target: <800 ms p50, <2 s p95. Total response p50 <4 s, p95 <10 s. Surface partial cards as the agent reasons; "I'm checking…" progress text every 1.5 s of silence.
- [ ] 🔴 **Per-user `discoverable: bool` setting** (default `true`) plus the corresponding RLS so agent overlap queries from another user only reach `discoverable=true` profiles. One-tap opt-out in profile settings.
- [ ] 🔴 **PII scrubber on agent input** — strip phone numbers, emails, full names of *third* parties from user messages before sending to LLM (only the asking user's PII can pass through, and only to the extent needed for tool calls). Layered defense against leaking another user's data.
- [ ] 🔴 **"Agent drafts, user sends" enforcement** — `propose_intro` returns a draft only; the actual `messages.insert` requires an explicit user click. Server-side rejection if an agent-tagged session tries to insert a message without the corresponding draft confirmation token.
- [ ] 🟠 **Voice / tone spec for the agent.** Warm, knowledgeable local friend. Not salesy. Willing to say "I don't know that yet." Co-founder writes the system prompt and reviews periodically. Ties to brand work in §2.2.

#### 1.8.b Browseable-tier neighborhood data (🔴 before browseable cards render in agent answers)

- [ ] 🔴 **Pick the 4–5 browseable neighborhoods** (D-NBHD-1) — recommended set: Williamsburg, West Village, Lower East Side, Nolita, NoHo. Founder confirmation needed before any importer work.
- [ ] 🔴 **Public-data ToS audit** (D-NBHD-2) — Google Places, Yelp Fusion, NYC OpenData. Each ToS reviewed by counsel for: derivative-work / display restrictions, attribution requirements, caching limits, prohibition on building competing directories. Output: a one-page memo per source listing what we may and may not display + a yes/no on inclusion.
- [ ] 🔴 **Per-neighborhood polygons** seeded for all 5 browseable neighborhoods (same OSM/Overpass workflow as SoHo).
- [ ] 🔴 **Importer Edge Function** (`refresh_browseable_businesses`) running nightly with rate-limit + cost guard. First run hand-audited row-by-row before going automatic.
- [ ] 🔴 **`business_profiles.source` column populated honestly** — `imported` rows visibly badged as "Unclaimed listing — public info" in every UI surface. Violating this is a trust-killer.
- [ ] 🔴 **Claim-this-business flow.** Owner enters their business email or phone (from the imported public record), receives a one-time code, claims the profile, gets routed into the standard business-onboarding flow.
- [ ] 🟠 **Waitlist conversion email cadence.** Triggered when a user hits "notify me when [browseable nbhd] goes live" and again when that neighborhood's Live conversion is announced.

#### 1.8.c B2B + B2C listings (🟠 alongside agent launch, not blocking SoHo POC)

- [ ] 🟠 **`listings.audience` + `listings.subtype` columns** added (see `MVP_SPEC.md` §5.5). Default `audience='consumer'` so existing listings are unaffected.
- [ ] 🟠 **B2B-only fields** (`min_order_quantity`, `unit`, `bulk_pricing JSONB`, `lead_time_days`, `business_only_visibility`) added as nullable; not required for V1 consumer listings.
- [ ] 🟠 **Listing form audience picker** with sensible defaults (personal profile asking → `consumer`; business profile asking → choose).
- [ ] 🟠 **Discovery filters add an `audience` toggle** (consumer / business / both). Default: matches the asker's profile type. The agent passes through whatever it inferred from the query.
- [ ] 🟡 **B2B payments path** (D-B2B-1) — V1 keeps Stripe regular charges. V2 introduces Stripe Invoices + net-terms. Trigger to revisit: ≥10 B2B contracts/month at average ticket >$200.

#### 1.8.d Implicit communities (V1) and named communities (V1.5)

- [ ] 🟠 **`get_overlap(serial_a, serial_b)` RPC** plus the bottom-sheet UI ("you and BP-XYZ share…"). Tap-the-chip portal lands here.
- [ ] 🟠 **`find_similar_people(my_serial, scope, limit)` RPC** with neighborhood + interest + hashtag scopes.
- [ ] 🟠 **`hashtag_pair` materialized view** refreshed nightly via pg_cron — feeds the "tags that travel together" intuition into both the agent and future community mining.
- [ ] 🟠 **`agent_conversations`, `agent_messages`, `agent_traces`, `user_preferences_cache`, `community_mining_candidates`, `neighborhood_waitlist`** tables provisioned (per `MVP_SPEC.md` §5.6) — even if some stay empty until V1.5, the schema lands together so we don't migrate twice.
- [ ] 🟡 **Community mining job** scoring `community_mining_candidates` by (distinct users, query density, hashtag co-occurrence). Threshold: ≥25 distinct users + ≥50 queries over 30 days (D-COMM-1) — tunable.
- [ ] 🟡 **Named-communities surface** (`communities`, `community_tags`, `community_members`) — schema ratified; admin UI to promote candidates ships when V1.5 starts.
- [ ] 🟡 **Community moderation tooling** — leave/mute, report a community, mod queue, abandoned-community garbage collection. Required for any user-proposed communities.

#### 1.8.e Chip behavior change (D-CHIP-1)

- [ ] 🟠 **Move `BP-XXXXXX` chip default tap from "Copy" to "Open overlap sheet."** Copy becomes a button at the top-right of the sheet. Touches every place a chip renders today (listing detail, business page, post card, profile). One PR, kept behind a feature flag (`chip.tap_opens_overlap`) so we can ship the sheet first and flip behavior atomically.

---

## 2. Needed during build (🟠 operational setup before launch)

### 2.1 SoHo-specific prep (Co-founder C)

- [ ] 🟠 **SoHo neighborhood polygon GeoJSON** sourced from OpenStreetMap (Overpass API query on Wikidata SoHo entity).
- [ ] 🟠 **Target business list** — 150 hand-picked SoHo businesses with contact info to approach. Categorize by: boutiques, galleries, cafés/restaurants, studios, wellness.
- [ ] 🟠 **Outreach script** for door-to-door onboarding. 2-minute pitch + the tablet demo flow.
- [ ] 🟠 **Founding Business badge** visual designed; messaging finalized.
- [ ] 🟠 **QR window stickers** designed + printed (~$200 for 100). Vendor: StickerMule or VistaPrint.
- [ ] 🟠 **Launch press list:** Time Out NY (SoHo vertical), Secret NYC, Curbed NY, SoHo Broadway Initiative, SoHo Partnership, Racked archives/followers, local IG accounts 10k–100k (@sohonyc, @nycfoodie, etc.). Goal: 3 committed press pieces on launch day.

### 2.2 Design & brand

- [ ] 🟠 **Logo + wordmark** final.
- [ ] 🟠 **App icon** — iOS & Android variants.
- [ ] 🟠 **Brand style guide** — colors, typography, voice.
- [ ] 🟠 **Core screen designs** (Figma) — onboarding, map home, search, listing detail, profile, book & pay, feedback. The mockup at `beepbip-mockup.html` is directional; final designs still needed from the hired freelancer ($3–5k, budget approved in original plan).
- [ ] 🟠 **Web marketing site** — simple 1-page site explaining the app, with App Store / Play Store links and email capture for the waitlist.
- [ ] 🟠 **Press kit** — PDF + .zip of logo variants, screenshots, founder bios, quotable positioning.

### 2.3 Financial / ops

- [ ] 🟠 **Referral credit budget** locked ($10k cap for 500 activations, as planned in §8.2.3). Separate line item in books.
- [ ] 🟠 **Founders agreement / cap table** finalized if not already done.
- [ ] 🟠 **Bookkeeping setup** — QuickBooks / Xero + separate "platform fees" revenue tracking from "subscription revenue".
- [ ] 🟠 **Dispute handling SLA internal policy** — target first response <24h, resolution <72h, escalation path to founder A.

### 2.4 Infrastructure hardening

- [ ] 🟠 **Secrets management** — confirm no secrets in git history; rotate anything exposed.
- [ ] 🟠 **Backup strategy** — Supabase daily backups verified; tested restore at least once.
- [ ] 🟠 **Monitoring alerts** — Crashlytics crash-free rate threshold; Stripe webhook failure alert; dispute rate alert.
- [ ] 🟠 **Rate limiting** on Edge Functions (signup, booking create) to prevent abuse.

### 2.5 Auth UX loose ends

- [ ] 🟠 **Password-reset completion screen.** Login screen's "Forgot password?" now triggers `AuthController.resetPassword(email)` which sends the Supabase recovery email. We still need a screen to handle the `type=recovery` callback: catch the recovery session, show a "set a new password" form, call `supabase.auth.updateUser(UserAttributes(password: ...))`, then redirect to `/home`. Needs route `/auth/recover` + deep-link scheme for mobile. (Without this, the email link just drops users onto the app's Site URL with a session but no UI to change the password.)
- [ ] 🟠 **Email-confirmation landing screen.** Same story: after tapping the confirmation link, the user lands on the Site URL with `type=signup`. Today the router just places them in the normal logged-in flow. A lightweight "Welcome, your email is confirmed" screen would be friendlier than silently teleporting them into `/profile-type`.
- [ ] 🟠 **Change-password screen** (from within Settings once authed). Calls `supabase.auth.updateUser` after re-prompting current password. Needed before production.

### 2.6 Listings vertical — deferred sub-features

The listings feature shipped a "broad and shallow" vertical (domain → data → application → presentation) covering create / browse / detail / edit. The following sub-features were intentionally cut from the first slice to keep scope contained and let us dogfood the architecture quickly. None of them blocks running the existing flow; each is a self-contained follow-up.

- [x] ~~🟠 **Image upload for listings.**~~ **Shipped 2026-05-01.** `ImagePicker` + `WatermarkService` + Supabase Storage `user-uploads` bucket (RLS keyed by `auth.uid()` first path segment, see `20260501120000_storage_user_uploads.sql`). Listing form uploads up to 10 images and persists URLs into `listings.images TEXT[]`. Reorder + primary-image picker still deferred — `ImageGridEditor` widget supports add/remove only.
- [ ] 🟠 **Map view of listings.** The `MapScreen` is currently a placeholder with hardcoded pins. Need: query `listings` joined with `locations` (or `business_profiles.address` until per-listing locations land), cluster pins, tap-to-preview card with deep link to `/listings/:id`. Blocks the spec's §3.3 "Discovery — Map view".
- [ ] 🟠 **Hashtag-filtered search UI.** Schema has GIN indexes on `hashtags` and a `tsvector` `search_vector`. The form already lets businesses author hashtags; consumers can't yet search/filter by them. Need: search input on `/listings` that combines full-text query (`tsvector`) and hashtag containment (`@>`), plus a tag-tap → filtered view affordance from listing cards.
- [ ] 🟠 **Pagination / infinite scroll on `/listings`.** Currently `LIMIT 50` with pull-to-refresh. SoHo POC volumes won't hit 50 active listings on day 1, but as inventory grows we'll need cursor-based pagination (`created_at` desc + tie-breaker on `id`) and a `loadMore` action on the AsyncNotifier.
- [ ] 🟠 **Realtime listing updates.** Supabase Realtime can stream `listings` insert/update/delete events scoped to a neighborhood. Per architecture doc §117, default to polling in V1 and only flip to Realtime per-surface once load justifies it. Worth measuring once we have ~50 active listings + 10 daily authors.
- [~] 🟠 **Booking flow from a listing.** _Foundation shipped 2026-05-01._ "Book / Reserve / Buy" CTA on `ListingDetailScreen` is wired to `create-booking-checkout` Edge Function (server-computed totals + 8 % platform fee, transfer to seller's connected Stripe account); `stripe-webhook` advances `bookings.pending → accepted → paid` and writes `payments` ledger rows idempotently on `stripe_event_id`. The CTA is hidden behind `feature_flags.bookings_enabled` (default OFF) until Stripe Connect is verified end-to-end. Still deferred: quantity / scheduled-time pickers, escrow auto-release at 72 h, refunds, disputes (those become `features/bookings/` proper).
- [x] ~~🟠 **Listing media bucket security.**~~ **Shipped 2026-05-01.** RLS in `20260501120000_storage_user_uploads.sql` enforces `auth.uid()::text = (storage.foldername(name))[1]` on insert/update/delete; bucket is public-read so the rendered URLs work everywhere.
- [x] ~~🟠 **Owner profile chip on `ListingDetailScreen`.**~~ **Shipped 2026-05-01.** Detail screen now shows a "Visit business page" link routing to `/business/:profileId`.
- [ ] 🟡 **Soft-delete instead of hard-delete.** Today `delete()` is a row-level DELETE. Once bookings/feedback reference listings as foreign keys, switch to `status = 'removed'` and filter it out of all read providers — preserves auditability.
- [ ] 🟡 **Personal users authoring listings.** Per MVP §3.4, V1 is business-only. The `canAuthorListingsProvider` and `currentBusinessProfileProvider` helpers gate UI on having a business profile; lift the gate (after KYC) when V1.5 ships personal-user services.

### 2.7 Posts vertical — visibility model & deferred sub-features

> **Visibility design (chosen 2026-04-29):** *discoverability*, not *audience scope*. A post is either:
> * **`public`** — surfaces in the SoHo neighborhood feed, on the map, in search.
> * **`unlisted`** — hidden from every discovery surface; the row is still reachable by direct id (e.g. for "share this link with the WhatsApp group" or pre-staging a post during QA).
>
> We deliberately did **not** add a "private to friends" mode because there's no friend graph in V1. If we later add followers / connections, the natural extension is a third value `'connections'`, not a re-naming of `unlisted`.
>
> Schema lives in `supabase/migrations/20260418000001_posts_visibility.sql`. RLS update: `posts_select_active` returns owner rows in any state, plus `public AND NOT is_removed AND expires_at > NOW()` for everyone else.

- [ ] 🟠 **Unlisted-post sharing flow.** UI for the author to copy a "direct link" (`/posts/:id`) once a post is created as unlisted. Until that route + screen exist, "unlisted" is mostly an internal-staging mode. Needs a `PostDetailScreen` and a deep-link URL contract.
- [ ] 🟠 **Post detail screen** (`/posts/:id`). Renders a single post with author chip, content, hashtags, linked listing card, expiry countdown. Author actions: edit (defer), delete (soft, sets `is_removed=true`). Reach gated by RLS.
- [ ] 🟠 **Post images.** Schema has `images TEXT[]` (cap 4). Same pattern as listings: ImagePicker → Supabase Storage bucket `posts/<profile_id>/...` → RLS keyed by author profile.
- [ ] 🟠 **Post detail link from map / feed.** Post rows currently end at the form; once `PostDetailScreen` lands, every feed card and map pin should deep-link to it.
- [ ] 🟠 **Author-profile location → post pin.** Schema deliberately has no `location` on posts. To render a post pin on the map, we look up the author's primary `locations` row (or `business_profiles.address`) and place the pin there. Until that join is wired, the map shows only people pins.
- [ ] 🟠 **Hashtag-filtered post feed.** Same machinery as listings (GIN on `hashtags`); needs a discoverability surface (Phase 3 Discover tab).
- [ ] 🟡 **Edit post.** Schema allows it (RLS owner-write). UI deferred — V1 prioritizes "delete and re-post" simplicity over in-place edits.
- [ ] 🟡 **Future visibility values.** Add `'connections'` once a follow/friend graph exists; possibly `'neighborhood_only'` if we ever expand beyond a single neighborhood per post.
- [ ] 🟡 **Per-business active-post cap.** Spec §3.7 reads "limited to 3 active posts per business (10 for Business Pro)." Not yet enforced in schema or app. Implementation: count `posts WHERE author_profile_id=? AND NOT is_removed AND expires_at > NOW()` before insert; reject with a soft "you have 3 active posts; remove one or wait for one to expire".

### 2.7a Business Page MVP — deferred sub-features

Shipped 2026-05-01: public viewer (`BusinessPageScreen`), owner editor (`BusinessPageEditScreen`), Stripe Connect onboarding + booking checkout Edge Functions wired behind a feature flag. The intentionally-deferred extensions:

- [ ] 🟠 **Smoke-test the page end-to-end on staging.** Editor: cover/logo upload, hashtags, hours, contact, social handles, save → public viewer reflects changes within one fetch. Photos strip aggregates from listing images correctly. Catalog tabs filter by Service/Item/Event.
- [ ] 🟠 **Stripe Connect — wire env + deploy functions.** `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_CONNECT_RETURN_URL`, `STRIPE_CONNECT_REFRESH_URL`, `STRIPE_CHECKOUT_SUCCESS_URL`, `STRIPE_CHECKOUT_CANCEL_URL`. Then `supabase functions deploy create-stripe-connect-account create-booking-checkout stripe-webhook` and register webhook in Stripe with `checkout.session.completed`, `payment_intent.succeeded`, `account.updated`, `charge.refunded`.
- [ ] 🟠 **Booking polish.** Quantity selector for items; scheduled-time picker for services / events. Buyer-facing booking history screen ("My orders").
- [ ] 🟠 **Curated `business_media` table** if we want photos that aren't tied to a listing. V1 reuses `listings.images[]` aggregated; once owners want a non-catalog gallery (interior shots, team photos), promote to a dedicated table with its own RLS.
- [ ] 🟠 **Hero parallax on `BusinessPageScreen`.** V1 uses a fixed-height hero. SliverAppBar with parallax cover is a small refactor inside `BusinessPageScreen.build` that doesn't change the data contract.
- [ ] 🟡 **Escrow auto-release.** Cron `bookings_auto_release` job that flips `paid → completed` once `auto_release_at` passes (72 h after `delivered_at`/event end). Posts a `payout` row in `payments` and triggers a Stripe Transfer.
- [ ] 🟡 **Refunds + disputes.** UI affordances on the buyer's "My orders" screen + admin tooling. The webhook already records `charge.refunded` ledger entries; the booking-state machine just needs a path through `paid → refunded` for clean cases.
- [ ] 🟡 **Repository tests.** `business_page_repository` is straightforward enough that a fake-Postgrest test would catch regressions in the bundle assembly. Defer until we add a proper testing kit (`supabase_flutter` doesn't ship one out of the box).

### 2.8 Information architecture reorganization (Compose / Discover / Cleanup)

> **Why this section exists (founder feedback, 2026-04-28):** the original UX had three independent friction points — the bare `+` FAB sent every user into the post composer, listings were only reachable via a hero card on the Search tab, and posts created through the in-memory mock vanished and never appeared as a "social feed". Reorg the IA so post and listing authoring/discovery are complementary and organic. Plan agreed: 4 phases, summarised below.

> **Status as of 2026-04-29:** Phase 1 + Phase 2 shipped in code in megachat `c0145b97`. Both are **awaiting smoke verification** because the running Flutter session was stale during the chat and the cloud migration for `posts.visibility` did not land. See `STATE.md`.

#### Phase 1 — Compose menu (DONE in code)

- [x] 🟠 **Replace the bare `+` FAB with a Compose bottom sheet** — `lib/features/home/screens/home_screen.dart`. Two cards: *Share an update* (always visible) and *Add a listing* (only when `canAuthorListingsProvider == true`). Listing entry hidden, not greyed-out, so personal-only users don't see UI they can't act on.

#### Phase 2 — Real Posts vertical (DONE in code, BLOCKED on cloud migration)

- [x] 🟠 **Domain + data + application + presentation** for posts (model, repository, providers, form). The legacy in-memory `postsProvider` has been deleted; map screen migrated to the new `neighborhoodPostsProvider`. Discoverability semantics chosen — see §2.7. **Server-side trigger `enforce_banned_hashtags` already exists for posts** (migration 09); we additionally cache the block-list client-side via `bannedHashtagsProvider` for instant feedback.
- [x] 🔴 **Push `supabase/migrations/20260418000001_posts_visibility.sql` to cloud staging.** Done 2026-04-29 after `SUPABASE_DB_PASSWORD` was filled into `.env.cli`. Migration history shows `20260418000001` in the Remote column; live `pg_dump` of the public schema confirms the column, check constraint, partial index `idx_posts_neighborhood_public`, and replaced `posts_select_active` policy. See `STATE.md` "Last verified working" 2026-04-29.
- [ ] 🔴 **End-to-end smoke** after the migration lands: (a) hot-restart Flutter; (b) Compose → Share an update; (c) confirm Posting-as switcher swaps Personal/Business; (d) confirm Public/Unlisted pill renders both taglines; (e) submit `#porn` → client snackbar reject; (f) submit a public post → row appears in `posts` with `visibility='public'`, `expires_at ≈ NOW + 72h`; (g) submit an unlisted post → row appears with `visibility='unlisted'`, hidden from a second account but visible to the author; (h) `select count(*) from posts where author_profile_id=? and visibility='public'` from a second account should NOT include the unlisted row. **Status 2026-04-29:** (h) is satisfied by policy form (the new `posts_select_active` only returns owner rows OR `visibility='public' AND NOT is_removed AND expires_at>now()`, so unlisted rows are unreachable to any non-owner by construction). (a)–(g) still need a human at the keyboard.

#### Phase 3 — Discover tab (PENDING, next session)

- [ ] 🟠 **Convert the Map tab into a Discover tab** with two segments at the top (`Map` | `Feed`) and a secondary `All / Listings / Posts` toggle when Feed is selected. The Feed view is a chronological merge of public posts + active listings, scoped to the SoHo neighborhood. Map remains the geographic projection of the same data set. Neighborhood chip in the header (read-only in V1; switcher deferred — see §2.8 cleanup).
- [ ] 🟠 **Feed item types.** Two card shapes: PostCard (avatar, content, hashtags, optional linked-listing chip, expiry pill) and ListingCard (image, title, price, hashtags, type icon). Tap → `/posts/:id` or `/listings/:id` (the post detail screen is itself queued — see §2.7).
- [ ] 🟠 **Empty / loading / error states** for each toggle. Treat error as "neighborhood activity is taking a moment" rather than a stack trace.

#### Phase 4 — Search & profile cleanup (PENDING, next session)

- [ ] 🟠 **Remove the "Browse listings in SoHo" hero card** from the Search tab — listings are now reachable via Compose (write) and Discover (read), so the Search tab can return to text/hashtag query as its single job.
- [ ] 🟠 **Add a "My listings" section to `/profile`** for business profile owners. Reuses `myListingsProvider`; cards link to `/listings/:id`; quick-edit / quick-delete actions.
- [ ] 🟠 **Neighborhood switcher** on the Discover header — defer in code, but stub the data path now: profile already has `neighborhoods` array, just need a sheet picker. Deferred until neighborhood #2 is real.

### 2.9 Agent surface integration prep (added 2026-05-02)

> **Why this section exists:** the agent isn't a chat tab — it's the search/command bar everywhere (`MVP_SPEC.md` §3.12). That means existing screens need surface-level edits before the agent can plug in. Doing this prep during the SoHo MVP build avoids a refactor when the agent ships.

- [ ] 🟠 **`AskBeepBipBar` widget contract** specified in `lib/core/widgets/ask_bar.dart`. V1 it's a styled `TextField` that routes to traditional search. The agent flag (`agent.enabled`) flips the same widget into chat-sheet expansion mode. Same widget on Map, Feed, Search.
- [ ] 🟠 **Map screen search input** swapped from `Search SoHo…` to `AskBeepBipBar` placeholder copy. Cosmetic V1; behavior V1.5 when the agent ships.
- [ ] 🟠 **Persistent `AskBeepBipBar` pill** at the top of the Feed (Discover tab Phase 3 — see §2.8). Doesn't gain agent behavior in V1.
- [ ] 🟠 **`Ask about this place…` FAB on `BusinessPageScreen`** primed with the business id. Same flag-gated pattern.
- [ ] 🟠 **Inline `RichCard` widget contracts** drafted in `lib/core/widgets/cards/` — `ListingCard`, `BusinessCard`, `PersonCard`, `NeighborhoodCard`. They have to render correctly inside a chat sheet AND inside the existing screens (single source of truth). This is a refactor of the current ad-hoc card widgets.
- [ ] 🟠 **`agent` feature folder** scaffolded with the layered architecture even before code lands: `lib/features/agent/{domain,data,application,presentation}`. Empty packages so the V1.5 build doesn't have to invent a place to put things mid-flight.
- [ ] 🟠 **Tool-layer RPCs for agent** (subset that the SoHo MVP can use even without LLM): `get_overlap`, `find_similar_people`, `discover_listings_v2` (with audience + B2B filters). Ship these RPCs and call them from the existing search UI; the agent later calls the same surface. Reduces the V1.5 surface area significantly.

---

## 3. External dependencies (who to contact)

- [ ] 🟠 **Marketplace-CPA consult** (1 hour) — NY sales tax + multi-state marketplace facilitator obligations. Budget ~$500. Action: D12.
- [ ] 🟠 **Startup lawyer** (2–4 hours) — ToS, privacy, seller agreement, refund policy drafting. Budget $1.5–3k. Action: D8.
- [ ] 🟠 **UI/UX designer** (freelance) — core screens in Figma. Budget $3–5k as originally planned.
- [ ] 🟠 **Accountant** (ongoing) — monthly bookkeeping, tax filing. ~$200–400/mo.
- [ ] 🟠 **Business liability insurance broker** — quote & bind policy. Budget $50–150/mo.
- [ ] 🟡 **iOS mobile contractor** (optional, on-call) — for native iOS specifics if the vibe-coder hits platform limits. Rate $75–150/hr for spot help.
- [ ] 🟢 **PR / comms contractor** — if launch exceeds in-house capacity, budget a 1-month PR push around launch. Budget $3–5k.
- [ ] 🟠 **Anthropic API account** — sign up + add a payment method + provision per-environment keys (dev / staging / prod). Set monthly cost-alert thresholds at $100, $500, $2,000.
- [ ] 🟠 **Counsel review of public-data ToS** for D-NBHD-2 (Google Places, Yelp Fusion, NYC OpenData). One-page memo per source. Budget ~$1k. Output drives whether each source is in or out of the importer.

---

## 4. V1.5 items (🟡 within first 3 months after SoHo launch)

- [ ] 🟡 **TikTok Login Kit integration** (D9) — custom OAuth provider via Supabase. Revisit if creator businesses are requesting it. ~3–5 dev days.
- [ ] 🟡 **Instagram Business Login + Graph API** (D10) — surfaces IG handle + follower count on business profiles. Requires Meta app review. ~1–2 dev weeks.
- [ ] 🟡 **Personal users listing services** after KYC (currently businesses-only in V1). Unlocks the "neighbor offering dog-walking / tutoring" use case from original vision.
- [ ] 🟡 **Image attachments in chat** (currently text-only).
- [ ] 🟡 **Hashtag canonical lookup table** (`hashtags_canonical`) — helps handle case/typo variants.
- [ ] 🟡 **Hashtag auto-suggest** on listing create based on popular tags in the neighborhood.
- [ ] 🟡 **Drift (SQLite) for offline outbox** — stronger retry/queue layer for write operations.
- [ ] 🟡 **Promoted listings / paid boost** — $1–5/day featured placement. Add to revenue streams.
- [ ] 🟡 **Stripe Identity** integration (D5) if manual verification doesn't scale past ~100 businesses.
- [ ] 🟡 **Self-service dispute refund UI** for sellers (currently admin-handled).
- [ ] 🟡 **Email receipts with branded template** (replace default Stripe template).
- [ ] 🟡 **Referral program v2** — structured tracking, cohort analysis, A/B test credit amount.
- [ ] 🟡 **Business analytics dashboard** for Business Pro — views, conversions, top hashtags, repeat customers.
- [ ] 🟡 **Customer list export** for Business Pro (CSV).

### 4.3 Agent + community V1.5 enhancements (added 2026-05-02)

- [ ] 🟡 **Stateful agent memory across sessions** — `user_preferences_cache` populated from past conversations + interest taxonomy. Enables proactive notifications ("3 new bakers this week match your taste").
- [ ] 🟡 **Proactive notifications** powered by saved searches (`agent_saved_searches` table — V1.5 add). Daily digest fan-out via existing Edge Function pattern. Gated to Business Pro for unlimited; free tier capped at 1 saved search.
- [ ] 🟡 **`compare_neighborhoods()` tool** for cross-neighborhood agent answers. Requires browseable-tier data live (§1.8.b).
- [ ] 🟡 **Named-communities V1 ship** — `communities`, `community_tags`, `community_members` tables active; admin promotion flow from `community_mining_candidates`; community detail screen + join/leave; "From your communities" feed slot above the SoHo digest. Builds on the implicit-clusters work that ships in V1.
- [ ] 🟡 **Agent inline rich cards — full set** (PersonCard with overlap badges, CommunityCard, NeighborhoodCard with waitlist CTA, IntroDraftCard). V1 ships ListingCard + BusinessCard; the rest land as their underlying surfaces do.
- [ ] 🟡 **Voice input on the agent bar** — iOS Speech framework + Android speech-to-text. Optional but disproportionately helpful for hands-busy use cases (driving past a SoHo storefront).
- [ ] 🟡 **Agent multilingual** (D-AGENT-5 follow-on) — Spanish + Simplified Chinese for NYC. Adds `language` to `agent_messages`; system prompt branches; tool result strings remain canonical English (cards localized in client).
- [ ] 🟡 **Conversation export / delete UI** in Settings — required for GDPR/CCPA compliance once we have EU/California users; nice-to-have for trust signaling at SoHo launch.

---

## 5. V2 items (🟢 after SoHo POC succeeds — neighborhood expansion phase)

- [ ] 🟢 **Neighborhood #2 launch.** Candidates: Williamsburg, West Village, Williamsburg, Tel Aviv (original plan). Criterion: 15%+ household penetration in SoHo first.
- [ ] 🟢 **Verified badge fee** — $99/yr for B2B trust layer.
- [ ] 🟢 **Event ticketing premium tier** — tiered fees based on event size.
- [ ] 🟢 **API access** for Business Pro partners — programmatic listing management.
- [ ] 🟢 **Follower system** (if retention data justifies it post-PMF).
- [ ] 🟢 **Stories / ephemeral content** (only if social layer retention data supports it).
- [ ] 🟢 **Multi-language support** — Hebrew first (for Tel Aviv expansion). Requires i18n refactor.
- [ ] 🟢 **Multi-currency support** — ILS, EUR for international neighborhoods.
- [ ] 🟢 **Recommendation algorithm** — only once you have 10k+ bookings of training data.
- [ ] 🟢 **Anonymized neighborhood insights** sold to local chambers of commerce / real estate. Check lawyer first.
- [ ] 🟢 **Web app parity** — currently marketing + share-link only. Only if data shows web-first user intent.
- [ ] 🟢 **Native Android design parity** — currently iOS-first in V1.
- [ ] 🟢 **Live video / stories** — defer indefinitely; re-evaluate only if engagement metrics lag.
- [ ] 🟢 **Agent matchmaker / intro tier.** Beyond the V1 "draft an intro" model, an opt-in matchmaker that proactively pairs people with strong overlap. Heavy trust/safety scaffolding (consent gating, abuse reporting, soft-block escalation). Only ship after named communities have proven the social signal is real.
- [ ] 🟢 **Stripe Invoices + B2B net-terms** (D-B2B-1 follow-on) — enables recurring B2B contracts (a SoHo cafe paying monthly for pastry supply). Revisit when ≥10 B2B contracts/month at average ticket >$200.
- [ ] 🟢 **Agent web parity** — chat works in the marketing/share-page web layer too. Currently mobile-first.

---

## 6. Watch items & things to revisit (⚪ ongoing)

- [ ] ⚪ **Google Maps temptation.** Every 6 months, re-check whether we need Google Maps features (Street View, indoor maps, Places API). If not, stay on `flutter_map` + MapTiler. Cost savings compound.
- [ ] ⚪ **Supabase vs. custom Node.js backend.** Re-evaluate at 50k MAU whether Supabase still fits. Indicators to migrate: complex Stripe webhook chains, high-volume cron jobs, non-Supabase data sources.
- [ ] ⚪ **Image storage cost.** Once >10k MAU, migrate image storage from Supabase Storage to Cloudflare R2 + CDN. Huge egress savings.
- [ ] ⚪ **Realtime cost.** Monitor Supabase Realtime concurrent connections. If it exceeds Pro tier limits, consider moving chat to a dedicated provider (Stream Chat, Ably) or stricter polling-based fallback.
- [ ] ⚪ **Platform fee ceiling test.** We're launching at 8%. Test whether 10% or 6% converts better once there are enough bookings for statistical significance.
- [ ] ⚪ **Business Pro pricing test.** A/B test $19 / $29 / $49 once there are 100+ paying businesses.
- [ ] ⚪ **Dispute rate.** Target <5%. If >10%, either category is too risky (ban it) or verification is too lax (tighten).
- [ ] ⚪ **Churn of Business Pro after trial.** Target <30%. If higher, audit which features aren't being used.
- [ ] ⚪ **Banned-hashtags list maintenance** — monthly review of abuse reports for new terms to add.
- [ ] ⚪ **App Store / Play Store policy changes.** Meta in particular changes Login rules yearly — keep an eye on Facebook Login / Instagram deprecations.
- [ ] ⚪ **Crashlytics crash-free rate.** Target >99.5% on both platforms. Spike = drop everything and fix.
- [ ] ⚪ **NPS + user interview cadence.** Monthly survey; quarterly 5-user interviews. Read the free-text responses.
- [ ] ⚪ **GMV + take-rate dashboard.** Weekly PostHog dashboard review.
- [ ] ⚪ **Agent token cost per session.** Target: <$0.05/session at p50, <$0.20/session at p95. Trigger to act: any week the average exceeds $0.10/session means routing or caching regressed.
- [ ] ⚪ **Agent prompt-cache hit rate.** Target >70%. Below this we're over-paying by 3–5x; investigate what changed in the system prompt or tool schema.
- [ ] ⚪ **Agent fallback rate.** % of agent invocations that fall back to traditional `discover_listings` due to budget exhaustion or tool failure. Target <2%; >5% means we need to raise free-tier budgets or fix tool reliability.
- [ ] ⚪ **Hallucination report rate.** Users have a "this answer was wrong" button on every agent response. >0.5% on factual claims about SoHo entities is a fire — usually means the system prompt regressed or tool retrievals are stale.
- [ ] ⚪ **Browseable → live conversion rate.** Of users who add a browseable neighborhood to their waitlist, what % subscribe to the launch announcement and convert to first booking when that neighborhood goes live? This is the metric that justifies neighborhood #2's GTM spend.
- [ ] ⚪ **Implicit-overlap density.** For the average SoHo account, how many other accounts share ≥3 tags with them? This is the V1 diagnostic from the prior `arch: unique id` chat. Target: ≥10. Below 5 means the interest taxonomy is too sparse and named communities (V1.5) won't have legs.

---

## 7. Resolved decisions (reference only)

| # | Decision | Resolution |
|---|---|---|
| D1 | Platform legal entity | ✅ Existing Florida LLC. US business bank account confirmed. Just register with Stripe Connect. |
| D6 | Keep or drop Facebook Login | ✅ Keep — Meta-sanctioned path that also covers Instagram identity since standalone IG Login was deprecated Dec 2024. |
| D9 | TikTok Login V1 vs V1.5 | ✅ V1.5 — deferred. Custom OAuth, ~3–5 dev days. |
| D10 | Instagram Business Login surfacing | ✅ V1.5 — deferred. Uses `social_handles` JSONB in V1 as a manual-link stopgap. |
| D2 | Business Pro pricing | ✅ $29/mo or $290/yr, 14-day trial. A/B revisit deferred to §6 once 100+ paying businesses. |
| D7 | Primary iOS vs Android split | ✅ iOS-first: ship V1 to both stores, design + QA prioritized on iOS. Android design parity is V2. |
| — | Launch neighborhood | ✅ SoHo, Manhattan, NYC. Polygon: Canal / Houston / Crosby-Lafayette / 6th Ave. |
| — | Stack | ✅ Flutter + Supabase (kept from repo). No React Native migration. |
| — | Map provider | ✅ `flutter_map` + MapTiler (NOT Google Maps). |
| — | Geo model | ✅ PostGIS, neighborhoods as polygons. |
| — | Payment model | ✅ Stripe Connect Standard, 8% platform fee, 72h auto-release escrow, 0% first 90 days per neighborhood. |
| — | Hashtags in V1 | ✅ Yes, scoped: taxonomy tool, not feed format. Up to 10 per listing, 5 per post, 5 per business profile. |
| — | Subscription model | ✅ Free tier + Business Pro ($29/mo target, pending D2). RevenueCat for IAP. |
| D-AGENT-1 | LLM provider for the discovery agent | ✅ Anthropic Claude — `claude-sonnet-4-5` for smart turns, `claude-haiku-4-5` for routing/cheap intents. Native tool-use, native prompt caching, predictable per-token pricing. Multi-provider via OpenRouter is a V2 hedge, not V1 work. |
| D-AGENT-2 | Streaming infra for the agent | ✅ Supabase Edge Function (Deno) streaming SSE. Co-locates with the rest of the data plane; one less vendor; sufficient for the latency budget. Cloudflare Workers stays as the V2 fallback if Supabase Edge cold starts become a problem. |
| D-AGENT-3 | Vector DB for agent memory | ✅ Supabase `pgvector` extension on `agent_messages` + `user_preferences_cache`. Stays inside the existing data plane; no new vendor; cost dominated by storage which is cheap. Pinecone/Weaviate revisited only if we hit pgvector's recall limits at >1M vectors. |
| D-AGENT-5 | Agent multilingual support | ✅ V1 English-only. Spanish + Simplified Chinese in V1.5 (NYC needs both). Tool-result strings stay canonical English; client localizes the rendered cards. |
| D-COMM-1 | Community mining promotion threshold | ✅ ≥25 distinct users + ≥50 queries over a rolling 30-day window scored against the same hashtag/interest cluster signature → eligible for promotion to a named community. Tunable; document the chosen threshold in the admin tool when it ships. |

---

## 8. How to evolve this document

- When a follow-up is done, move it to a "Done" section at the bottom (don't delete; keeps audit trail).
- When a new follow-up emerges in any meeting, PR or conversation, add it here immediately — don't trust memory.
- Every Monday standup: scan §1 (pre-launch blockers) to confirm nothing is silently drifting.
- Every quarter: scan §6 (watch items). Most architecture regrets come from ignoring these.
