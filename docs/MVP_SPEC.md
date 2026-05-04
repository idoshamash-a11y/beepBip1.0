# BEEPBIP — MVP Engineering Spec

> **Status:** Canonical source of truth for MVP build.
> **Owners:** 3 co-founders.
> **Last updated:** 2026-05-04 (co-founder review pass — added §3.1.a Google Business Profile connect for business onboarding, §3.1.b social-data-pull for personal onboarding, §3.3 Globe-first map + POI overlay, §3.14a Brand color system, §3.15 Favorites & wishlists, §4.7a Map/globe runtime, §5.7a Category taxonomy + GMB sync schema, §5.7b Favorites schema, §5.8 agent favorites tools. Build plan §10 Phase 0 gains MapLibre globe spike + brand color tokens + POI overlay, Phase 1 splits onboarding into GMB + social-pull tracks, Phase 2 adds favorites. §12 resolves D-NBHD-1 to the 5-neighborhood set (Williamsburg / West Village / LES / Nolita / NoHo); resolves D-APPLE-DEV (Shai owns Apple Developer enrollment); adds D-MAP-1 / D-GMB-1 / D-SOCIAL-1 / D-FAV-1.).
> **Launch target:** SoHo, Manhattan (New York, USA) — single-neighborhood POC, then a 4–5 neighborhood "browseable tier" via the agent + waitlist (see §3.14).
> **Scope horizon:** 6–8 weeks from foundation fixes to public SoHo launch (Phases 0–6). Agent + browseable tier ship as Phase 7–8 immediately after, behind feature flags.

---

## 0. Why this document exists

Three conversation threads have shaped this spec:

1. A product/business analysis that compared the original PRD (location-based social discovery) with the founding team's vision (neighborhood marketplace with transaction-based revenue). We agreed on a **merged MVP**: a marketplace backbone with a thin social layer, revenue from transaction fees + B2B subscriptions + promoted listings.
2. A parallel agent cloned the public repo (`github.com/Shaus12/beepBip1.0`) and did a deep technical audit + cost analysis. It identified 5 critical bugs, architectural gaps, and cost traps (notably Google Maps).
3. The **Community + Agent Architecture** thread (May 2026) — reframed the serial id `BP-XXXXXX` as a graph node, ratified an agent-native discovery surface, a two-tier neighborhood model (live + browseable), B2B + B2C in one listings graph, and implicit-then-explicit communities mined from agent conversation logs. This is what added §3.12, §3.13, §4.7, §5.5–§5.7, and Phases 7–8.

This spec merges all three. It is the **only** document the team should reference when in doubt. If code and spec disagree, spec wins until the spec is updated.

---

## 1. Product identity (non-negotiable)

**BEEPBIP is an agent-native neighborhood commerce platform.** Users discover, book, and pay verified local businesses and individuals within their neighborhood, with buyer protection via escrow and a community feedback layer. The discovery surface itself is conversational — every screen exposes an "Ask BeepBip…" bar that translates fuzzy intent into structured queries against verified inventory and a real people graph (§3.12). A lightweight social surface and emergent communities (§3.13) drive daily opens, but their only purpose is to feed users back into commerce.

### What BEEPBIP is
- A **map-first marketplace** for local services, goods, and events.
- A **trust layer** for neighborhoods: verified identity + escrow + feedback.
- An **agent-native discovery surface** — the search/command bar IS the agent (§3.12); chat is everywhere, never a separate tab.
- A **community graph** rooted in the serial id `BP-XXXXXX` as a node — implicit overlap clusters in V1, named communities mined from agent conversations in V1.5 (§3.13).
- A **two-tier neighborhood model** — SoHo "live" (full transactions); 4–5 surrounding NYC neighborhoods "browseable" via imported public data with claim-this-business CTAs (§3.14).
- A **single graph for B2C and B2B** — the same listings table powers a SoHo resident finding fresh bread and a SoHo cafe finding a wholesale pastry supplier, both via the same agent (§3.4, §5.5).
- A **micro-business incubator**: if it works in SoHo, expand to the next neighborhood — and the agent's browseable-tier waitlist tells us *which* neighborhood next.

### What BEEPBIP is NOT (V1)
- Not Instagram / TikTok. No infinite scroll feed. No follower counts as a core metric. No algorithmic discovery feed.
- Not Nextdoor. No free-form community posting, no political content, no moderation nightmare.
- Not Facebook Marketplace. No anonymous C2C selling of used couches.
- Not Thumbtack. We are neighborhood-bound and community-native, not a national contractor directory.
- Not ChatGPT. Our agent is *grounded* in real verified neighborhood inventory + a real people graph; it never invents entities.

### Primary user personas (V1 only)

| Persona | Example | Why they're here |
|---|---|---|
| **Indie business owner** | A SoHo jewelry maker, a café, a vintage clothing store, a massage therapist | Low-cost way to reach local customers + take payments with buyer protection. Often *both* a B2C seller and a B2B buyer (the cafe selling lattes also needs a coffee roaster). |
| **Local buyer** | A SoHo resident or commuter looking for a specific service/good nearby | Trusted, curated, frictionless booking from people they can verify. Agent makes "I love vinyl and Sunday brunch — who do I meet?" a one-shot query. |
| **Event organizer** | Gallery opening, pop-up dinner, studio sale | Fill seats in their neighborhood without Eventbrite fees |
| **Adjacent-neighborhood scout** | A would-be Williamsburg resident researching the move; a SoHo cafe owner sourcing supplies from LES | Browseable tier + agent answers cross-neighborhood questions; waitlist captures their demand signal so we know where to go live next. |

Defer: power-user personal profilers, influencers, content creators. They come in V2 when the social layer deepens.

---

## 2. Launch strategy: SoHo POC

**Target polygon:** Canal St (south) → Houston St (north) → Crosby/Lafayette (east) → 6th Ave (west). ~0.5 sq mi. ~5,000 residents + ~250,000 daily visitors + ~1,000 retail/service businesses.

**Operating entity:** Existing **Florida LLC** (confirmed by founders) is the Stripe Connect platform entity. Because we facilitate NY-state transactions, D12 flags the need to verify our marketplace-facilitator obligations under NY Tax Law §1101(e). Stripe Tax likely handles collection; verify with accountant before public launch.

### Why SoHo specifically
- High density of **independent, identity-driven businesses** (boutiques, galleries, studios, craft food) — exactly our ICP.
- English-first — no i18n work for MVP.
- iOS-heavy user base — simpler device testing.
- Smartphone + high-intent commerce habits already universal.
- Tight geographic footprint — **50 door-to-door visits covers a meaningful % of inventory**.
- Strong local press / blog ecosystem — cheap organic PR if we do something interesting.
- Tourist overlap creates a second user segment (visitors looking for non-Yelp, locals-know recommendations).

### Success criteria for POC (12-week mark)
- **≥ 50 verified businesses** with active listings.
- **≥ 500 consumers** who completed onboarding.
- **≥ 200 paid bookings** flowed through escrow.
- **≥ 70% of bookings** complete without dispute.
- **Gross take from platform fees ≥ $2,000** (not a business yet — just proof the flow works).
- **NPS ≥ 40** from surveyed active users.

If these are hit → raise seed, open neighborhood #2 (candidate: Williamsburg or West Village). If not → iterate before expanding.

### Competitive positioning in SoHo

| Competitor | Their weakness we exploit |
|---|---|
| **Yelp** | Reviews are pay-to-play; no booking/payment in-app for non-restaurants |
| **Google Maps reviews** | No transaction layer; just directory |
| **Instagram** | Great discovery, terrible commerce (DM-to-Venmo is the reality) |
| **OpenTable / Resy** | Restaurant-only |
| **Etsy** | Global, not local; no services |
| **Facebook Marketplace** | Zero trust; used-goods vibe |
| **TaskRabbit / Thumbtack** | National contractors, not neighborhood businesses |
| **Nextdoor** | Social-only, no commerce, dying engagement |

Our one sentence to the user: **"SoHo's best, booked and paid in one tap — with your money protected until you're happy."**

---

## 3. Scope — the MVP feature list (V1)

Everything below ships before public launch. Anything not listed ships later.

### 3.1 Identity & onboarding
- **Phone + OTP** signup (primary, lowest friction).
- **Email + password** (fallback, plus email is needed for receipts).
- **Social login:**
  - **Sign in with Apple** — required by App Store guidelines when any other social login is present.
  - **Sign in with Google** — covers Android + web share-page signups.
  - **Facebook Login** — kept in V1 because it's already wired in `pubspec.yaml` AND it is the current Meta-supported path for Instagram identity (Instagram Basic Display API was deprecated Dec 2024; standalone "Login with Instagram" no longer exists for consumer use).
  - **Instagram Business Login** — V1.5 for business onboarding only (requires a Facebook Page connected to an IG business/creator account; surfaces the IG handle + follower count on the business profile for social proof).
  - **TikTok Login Kit** — **V1.5**, not V1. Rationale: Supabase has no native TikTok OAuth provider, so it requires a custom OAuth integration (~3–5 dev days + ongoing maintenance). Defer until a demand signal justifies the cost. When added, it will primarily serve creators and businesses using TikTok for marketing (surfaces handle on profile, enables share-to-TikTok from listings).
- Profile type choice: **Personal** (free) or **Business** (required paid tier after 14-day trial).
- Serial ID `BP-XXXXXX` kept from current schema.
- Minimal onboarding: phone → interests (personal) or business category + address (business). **Full profile setup deferred until after first meaningful action** (booking as consumer, first listing as business).

#### 3.1.a Business onboarding — Google My Business connect (V1)

The business onboarding flow opens with a **"Connect your Google Business Profile"** step (formerly Google My Business). This is the fastest path from "I tap Sign Up" to "my page is live and credible."

- **OAuth scope:** `https://www.googleapis.com/auth/business.manage` via Google Identity. The user signs in with the Google account that owns their listing; we never ask for a password.
- **What we pull, with explicit on-screen consent (one toggle per field group, all default ON):**
  - Business name, primary category, address, phone, website
  - Business hours (7-day) → maps directly to `business_hours`
  - Up to 10 photos (cover + gallery) → uploaded to our Storage and copied, not hot-linked
  - Public review summary as **read-only social proof** (e.g. "4.6★ on Google · 312 reviews"). We do **not** import the reviews themselves; our 3-tier feedback (§3.6) is our trust system.
  - Verified-owner status → grants the user a stronger candidate profile in our verification queue (§3.6) but never auto-grants the BeepBip Verified Business badge.
- **No GMB account?** The user falls through to the existing manual flow (category + address + hours). GMB connect is recommended, never required.
- **Category → curated hashtag + services menu.** Once we know the GMB primary category (e.g. `Bakery`, `Massage Therapist`, `Art Gallery`), the next step in onboarding **only surfaces hashtags and services relevant to that category** — not the entire universe. The mapping lives in `category_taxonomy` (see §5.7a) and is curated, not learned. A bakery sees `#sourdough`, `#gluten_free`, `#wholesale_pastry`, `#wedding_cakes`; not `#tattoo_artist`. The user can still reach the "Show all" view if they want to add an off-category tag, but the default is the curated set. This is what keeps a business's hashtags coherent and what makes the agent's `find_provider`/`find_materials` answers actually trustworthy.
- **Hash + service drift control.** Owners can mark a category as a secondary category (e.g. a café that also runs pastry classes); each secondary category contributes its hashtag/service pool. Cap of 2 secondary categories to keep the surface honest.
- **Re-sync hooks.** A `business_profiles.gmb_resource_name` and `gmb_last_synced_at` let us refresh hours / photos on a nightly job. The owner can disconnect at any time → we keep what we already imported (it's their data) but stop refreshing.
- **Why this matters strategically.** GMB connect is also our cleanest way to *match* a SoHo business to a row in the browseable tier (§3.14). If the business already exists as `imported` from Google Places, GMB connect is the canonical way to claim it without an out-of-band one-time code: same Google entity ⇒ instant claim.

#### 3.1.b Personal onboarding — social media data pull (V1, opt-in)

Personal onboarding offers (does not require) **"Connect your social accounts to skip the empty-profile feeling."** Each provider is a separate consent step with a clear, plain-language list of what we'll pull.

- **Providers in V1:** Apple, Google, Facebook (already wired). Instagram via the Facebook Business Login path is V1.5; TikTok is V1.5 (D9). Apple's "hide my email" → no social data, just identity.
- **Two distinct user actions, separately consented:**
  1. **Sign in with X** — identity only (auth + serial ID assignment). No data pulled beyond name + email.
  2. **Connect X to your BeepBip profile** — opt-in, data-pull step that runs *after* identity is established. Each field shown as a toggle that the user can leave off.
- **What we pull, per provider (consent-toggled, none default ON for V1; we err strict):**
  - **Profile photo + display name** (one-tap copy into BeepBip).
  - **Public bio / description** (suggested as the BeepBip bio; user can edit).
  - **Self-declared interests / followed pages / liked categories** → mapped to our `interests` taxonomy via the same `category_taxonomy` table (§5.7a). User reviews the suggested interests before they save. Nothing is stored without an explicit "Save" tap.
  - **Public handle** (e.g. `@dana.in.soho`) → stored in `personal_profiles.social_handles` JSONB and surfaced as a clickable chip on the profile (already in spec).
  - **Recent public posts (last ~30 days, max 9)** → suggested as starter items for the BeepBip *feed*: each one shown as a card the user **explicitly checks** to import as a `posts` row. Anything they don't check is dropped. We never auto-publish.
  - **No friend graph, no contact list, no DMs, no location history.** Hard rule. These are off-limits in V1 regardless of what the provider offers.
- **Permission UI rules (non-negotiable):**
  - Plain-language list of fields *before* the OAuth redirect ("BeepBip will see your name, photo, public posts, and follows. We will not see your DMs, friends, or location history.").
  - Every field has its own toggle on the post-OAuth review screen.
  - Disconnect at any time → revokes the token; previously-imported data stays unless the user taps "Erase imported data" (one-button nuke).
  - Privacy policy section dedicated to social import describing exactly what we touch and what we don't.
- **Why this matters strategically.** A pre-populated profile + a feed that already has 3-5 cards in it is the difference between an empty-shell first session and a "this app already knows me" first session. It also gives the agent (§3.12) something to ground `find_similar_people` on from minute one, instead of waiting for the user to author content.

> **Privacy posture for §3.1.a + §3.1.b:** every connector is opt-in. Default-on toggles only exist where a reasonable user would feel surprise if the data *weren't* used (e.g. importing your own GMB hours into your own business hours). User-private fields (DMs, contacts, location history) are out of scope, period. See `FOLLOWUPS.md` §1.6 for the privacy-policy work this implies.

### 3.2 Profiles
- **Personal profile:** display name, photo, bio, interests (tags), optional neighborhoods, visibility toggle (open/closed), location-sharing tri-state.
- **Business profile:** business name, logo, cover image, category, description, SoHo address (must fall inside SoHo polygon for V1), hours (7-day), services, photo gallery, founding-business badge (first 100).

### 3.3 Discovery
- **Map view (Globe-first projection).** The map opens as a **3D globe** (Mercator falls back automatically below zoom ~3 if device GPU/perf can't sustain globe). The globe is the brand-defining "you live in a city in a world" framing — when you spin out, you see Earth; when you fly in, you land in your neighborhood polygon with our pins on top of it. Implementation: **MapLibre GL Native** (via `maplibre_gl` Flutter plugin) using **MapTiler** vector tiles in globe projection; `flutter_map` is retained as the fallback raster path for older devices. (See §4.7a for the cost & device-support matrix and the rationale for not switching to Mapbox or Google Maps.)
- **What sits on the globe / map:**
  - **Active neighborhood polygon** outlined and softly tinted (live = brand color; browseable = muted border).
  - **BeepBip pins** — clustered by category, colored by listing type (service / item / event), tap → preview card.
  - **Points of interest in the neighborhood** — parks, transit, landmarks, cultural venues, public toilets etc. Sourced from MapTiler's base style + an OpenStreetMap (Overpass) overlay for the neighborhood polygon. POIs render in a desaturated style so BeepBip pins always read as primary. Filter chips along the bottom (`Coffee · Parks · Transit · Galleries · Public bathrooms · …`) toggle which POI categories show. Tapping a POI shows a lightweight info card with the public name + category + a "Get directions" link; no commerce surface (POIs are context, not inventory).
  - **Browseable-tier neighborhoods** show their polygons + a stylized "Browseable — tap to preview" affordance when the camera flies over them.
  - **Favorites overlay** (see §3.15) — toggleable; renders the user's favorited businesses, listings, and saved places as a distinct pin style.
- **List view** of businesses with filters: category, distance, rating, open-now, price range, **hashtag**.
- **Search** with typo tolerance (Postgres `pg_trgm`), scoped to SoHo by default. Supports plain text, `#hashtag`, and `@business` syntaxes.
- **Hashtag search & filter** — tapping `#handmade` on any listing opens a filtered results view of all listings with that tag in the current neighborhood. See §3.11.
- **"What's new in SoHo" weekly digest** (push + in-app card) — curated, not algorithmic. Includes one "Hashtag of the week" section (editor-picked, not trending-based).

### 3.4 Listings
- Types: **Service** (bookable slot, price), **Item** (limited stock, price), **Event** (date, capacity, price per ticket).
- **Audience:** every listing carries an `audience` flag — `consumer`, `business`, or `both`. Defaults to `consumer` for personal-profile authors and prompts the choice for business-profile authors. Powers the B2C + B2B single-graph model (see §5.5 for the schema delta and §3.12 for how the agent surfaces audience filters).
- **B2B fields** (optional, populated only when `audience ∈ {business, both}`): `min_order_quantity`, `unit` (lb / kg / case / sheet / etc.), `bulk_pricing` (tiered JSONB: `[{qty: 25, price_cents: 8000}, {qty: 100, price_cents: 28000}]`), `lead_time_days`, `business_only_visibility` (hides from the consumer feed entirely).
- Fields: title, description, photos (1–10), price in USD, duration (for services), stock/capacity, **hashtags (up to 10, see §3.8)**, status (draft / active / paused / sold out).
- Businesses only in V1. Personal users can list services in V1.5 after KYC check. B2B-audience listings stay business-only (a personal profile can never post a wholesale listing).

### 3.5 Booking & payment (the spine)
- **Stripe Connect (Standard accounts)** as primary provider. Businesses onboard through Stripe's hosted flow.
- **8% platform fee** on all transactions (adjustable via feature flag). First 90 days per neighborhood: 0% promotional.
- **Escrow semantics:** funds captured at booking, held until buyer confirms completion OR 72 hours after `scheduled_at` auto-releases to seller. Disputes pause release.
- **Refund flow:** seller-initiated or dispute-driven. Platform fee refunded on full refund.
- **Payment methods:** card (via Stripe), Apple Pay, Google Pay. No bank transfers, no cash, no crypto in V1.
- **Receipts** via email + in-app.

### 3.6 Feedback & trust
- **3-tier emoji feedback** (positive / neutral / negative) tied 1:1 to completed bookings.
- **7-day edit window**, then locked.
- **Anonymous complaint flow** for negative feedback, with a structured dispute response from the business before the feedback is published publicly.
- **Aggregate display:** "32 positive · 3 neutral · 1 negative" with expandable breakdown (no 1–5 stars).
- **Verification badges:** ID-verified person, verified business, founding business.

### 3.7 Light social surface
- **Business channel posts** (text + up to 3 images + up to 5 hashtags + optional linked listing): promotions, news, new listings. Limited to 3 active posts per business (10 for Business Pro).
- **Nearby activity card** on home screen: "Dana's Kitchen added a weekend brunch special", "New vintage shop opened on Spring St". Curated manually by admin in first 6 weeks.
- **No follower system** in V1. Users subscribe to notifications from businesses they've bought from.
- **Hashtags are filtering + search aids, not a feed format.** There is explicitly no "top posts" / "trending hashtag" tab or algorithmic discovery in V1. See §3.11 for the exact hashtag model.

### 3.8 Hashtags (scoped, V1)

Hashtags are in V1, but tightly constrained to avoid the "become Instagram" drift. Everything below is enforced by schema, UX, and moderation rules.

**Where hashtags live:**
- On **listings** (up to 10 per listing, self-tagged by the business).
- On **posts** (up to 5 per post).
- On **business profiles** (up to 5 "signature" tags — surface as chips on the profile).

**Hashtag format & storage:**
- Stored as lowercase, alphanumeric + underscores, no `#` prefix in the DB.
- Rendered with `#` in the UI.
- Max length 40 chars per tag.
- Stored as `TEXT[]` columns on each host table, with a GIN index for fast containment queries.
- Canonical display (case/spelling) resolved via a `hashtags_canonical` lookup table (V1.5, nice-to-have).

**Discovery surfaces:**
- Tapping any hashtag chip opens a **filtered search view** scoped to the current neighborhood.
- Hashtag queries integrate with the existing search: `#handmade` returns listings + posts tagged that way.
- **"Hashtag of the week"** in the curated SoHo digest — editor-picked by admin, not algorithmic.

**Explicitly NOT built in V1:**
- ❌ No trending / top / popular hashtags leaderboard
- ❌ No hashtag follow / subscribe mechanism
- ❌ No hashtag-organized feed tab
- ❌ No auto-suggest based on popularity (V1.5)
- ❌ No cross-neighborhood hashtag browsing in the consumer UI (admin tools only)

**Moderation:**
- A `banned_hashtags` table blocks abuse terms (profanity, hate, drug-related, scam signals). Client + server both enforce.
- Report button on any hashtag-filtered view sends the specific hashtag + target to the admin reports queue.
- Admin can mark a hashtag `shadow_muted` (remains visible on the owner's listing, does not appear in search results) as a soft-moderation tool.

**Why this scoping matters:**
Hashtags in our context are a **taxonomy tool** (a SoHo gallery tags `#opening_reception #paintings #friday_night`) — they help the right buyer find the right listing. Without the scope limits, a hashtag system becomes a trending engine, a trending engine becomes a social feed, a social feed becomes Instagram, and Instagram is what V1 is explicitly not. Revisit expansion post-PMF.

### 3.9 Messaging
- **1:1 chat** between buyer and seller, **only** after a booking is initiated. No cold DMs.
- Supabase Realtime, text-only V1. Image attachments V1.5.

### 3.10 Admin / moderation
- Small internal **Next.js admin panel** on Vercel. Not shipped in the mobile app.
- Features: pending business approvals, verification requests, dispute queue, reports queue, feature flags, neighborhood manager, hashtag moderation (block-list + shadow-mute).

### 3.11 Infrastructure commitments
- PostGIS-based geo.
- Environment separation: `dev` / `staging` / `prod` Supabase projects + Flutter flavors.
- Secrets via `flutter_dotenv` + `--dart-define` at build time; never in git.
- Crash reporting (Firebase Crashlytics), product analytics (PostHog self-hosted).
- Typed error hierarchy and retry/offline layer in the Flutter client.

### 3.12 Discovery agent — "Ask BeepBip…" (Phase 7, V1)

The agent is the conversational discovery surface. **It is the search/command bar everywhere, not a chat tab.**

**Where it lives in the UI**
- **Map screen**: the search input is `Ask BeepBip…`. Tap → expands into a chat sheet anchored to the current map context (auto-includes "in SoHo, near you").
- **Discover Feed (§2.8 Phase 3)**: persistent `Ask…` pill at the top.
- **Business profile**: `Ask about this place…` FAB → chat with that business pre-loaded.
- **Listing detail**: `Find similar` button → agent suggests adjacent listings + people who'd care.
- **Explicitly no bottom-tab "Chat".** A chat tab tells users "go talk to a robot for everything." The bar-everywhere model says "type what you want; if it needs intelligence, you'll get it transparently." Same widget (`AskBeepBipBar`) used everywhere; flipping `feature_flags.agent.enabled` swaps its behavior from traditional `discover_listings` calls into chat-sheet expansion.

**LLM stack** (resolved in D-AGENT-1/2/3, see `FOLLOWUPS.md` §7):
- Provider: **Anthropic Claude** (`claude-sonnet-4-5` smart, `claude-haiku-4-5` router).
- Streaming: **Supabase Edge Function** (Deno) with SSE.
- Memory: **Supabase `pgvector`** on `agent_messages` + `user_preferences_cache`.
- Tool-use schema validation through Anthropic's native tool API.

**Tool layer (the agent's hands)** — V1 set, all backed by Postgres RPCs / Edge Functions; agent can only act through these:
- `search_listings(neighborhood, type, audience, hashtags, query, price_range, time_window)`
- `find_provider(category, neighborhood, criteria)` — service-specific search with rating filters
- `find_materials(category, audience, neighborhood, moq)` — the B2B + B2C bridge
- `find_similar_people(my_serial, scope, limit)` — implicit-overlap RPC
- `get_overlap(serial_a, serial_b)` — the chip-portal RPC
- `describe_neighborhood(slug)` — reads from `neighborhoods`; serves browseable tier with cited public data
- `compare_neighborhoods(slugs[], on_dimensions[])` — cross-neighborhood Q&A (V1.5 once 3+ neighborhoods seeded)
- `propose_intro(my_serial, target_serial, context)` — returns a *draft*; never sends
- `save_search(query, notify_frequency)` — opt-in proactive notifications (V1.5)
- `add_to_waitlist(neighborhood, intent)` — browseable → live signal
- `suggest_communities(my_serial)` — V1.5; returns named CommunityCards once §3.13 communities exist

**Inline rich cards** — the agent doesn't reply with paragraphs; it replies with typed cards that drop the user back into native UI: `ListingCard`, `BusinessCard` (with verified/imported badge), `PersonCard` (serial id + shared overlap badges + "draft intro" CTA), `CommunityCard` (V1.5), `NeighborhoodCard` (live or browseable + waitlist CTA), `IntroDraftCard` (proposed first message, editable, explicit Send), `WaitlistCard`. These are the same components used everywhere in the app (`lib/core/widgets/cards/`) — single source of truth.

**Safety / consent rules (non-negotiable)**:
- The agent **drafts**, the user **sends.** No autonomous DMs, no autonomous bookings.
- Agent never reveals about user X anything that user X hasn't made publicly visible. Overlap responses say "you and `BP-XYZ` share photography, vinyl, coffee" — never "user X is currently looking at vintage cameras."
- Cross-user mentions are gated by per-user `discoverable: bool` (default `true`; one-tap opt-out in profile settings).
- Conversations are user-owned: full export, full delete, retention timer (60 days unless saved).
- PII scrubber on outbound LLM input: phone numbers, emails, full names of *third* parties stripped before send.
- Hallucination guardrail: system prompt forbids returning entities not retrieved through a tool call. Adversarial prompt set ("recommend a restaurant on Mars") run before launch; pass = no inventions.

**Cost discipline** (target: <$0.10/MAU at 100k MAU):
- Tiered routing (Haiku for ~70% of intents, Sonnet only when needed): ~5x reduction.
- Anthropic prompt caching on system prompt + tool schemas: target ≥70% hit rate.
- Per-user daily token budget enforced server-side (D-AGENT-4: rec. 30 messages / 100k tokens free tier, unlimited Business Pro with 1M-token abuse ceiling). Exceed → graceful fallback to traditional `discover_listings` search.
- Result caching for 5 min on identical structured queries.
- Streaming SSE so UX feels snappy even when reasoning is slow (target TTFT <800 ms p50).

**Latency budget**: TTFT <800 ms p50 / <2 s p95; total response <4 s p50 / <10 s p95. Skeleton states + "I'm checking…" progress every 1.5 s of silence.

### 3.13 Communities — implicit (V1) → named (V1.5)

The serial id `BP-XXXXXX` is a **graph node**, not a watermark. Edges (interests, services, hashtags, locations, transactions) connect nodes; communities are clusters in that graph.

**V1: implicit clusters (no new visible community surface)**
- `find_similar_people` and `get_overlap` RPCs land. Implicit clusters live in queries, not in tables.
- **Tap-the-chip portal** (D-CHIP-1, founder OK pending): every `BP-XXXXXX` chip in the app changes default tap from "Copy" to "Open overlap sheet" with Copy as a button inside. Sheet shows: shared interests, shared hashtags, shared neighborhood, "Find similar people" CTA → opens agent with primed query, "Draft intro" CTA → IntroDraftCard. Ship behind feature flag `chip.tap_opens_overlap`.
- **Hashtag co-occurrence** tracked in a lightweight `hashtag_pair` materialized view refreshed nightly via pg_cron — feeds the agent's "tags that travel together" intuition and seeds the V1.5 community-mining job.
- **No visible "communities" UI in V1.** The implicit graph powers agent answers and the chip portal.

**V1.5: named communities mined from agent conversation logs**
- Once the agent's `agent_messages` history shows clear repeating patterns ("anyone else into reclaimed-wood furniture in SoHo?" asked ≥50 times by ≥25 distinct users — D-COMM-1 threshold), promote that cluster to a named, joinable community.
- New tables (schema in §5.6): `communities`, `community_tags`, `community_members`, `community_mining_candidates`.
- Communities have pages (members, pinned posts, tag-defined feed), join/leave, mod tooling.
- "From your communities" feed slot above the SoHo digest.
- The agent's mining pipeline output (`community_mining_candidates`) is human-reviewed before promotion. Names default to the dominant hashtag set; humans refine.

### 3.14a Brand color system (V1 source of truth)

The brand is built around a **warm-amber-on-vantablack** identity. Three colors do all the heavy lifting; everything else is a tint or shade of these. The values below are normative — `lib/core/theme/app_theme.dart` is the implementation.

| Role | Hex | Where it shows |
|---|---|---|
| **Primary — Amber** | `#FF9800` | Buttons, CTAs, active map pins, agent send button, "Ask BeepBip…" cursor, hashtag chips on hover |
| **Accent — Light Amber** | `#FFB74D` | Hovers, secondary chips, gradient highlights |
| **Secondary — Near Black** | `#1A1A1A` | Headlines on light surfaces, dark icon strokes |
| **Surface (dark, default) — Vantablack Base** | `#050505` | Main scaffold bg in dark mode (default theme) |
| **Surface (dark, raised) — Deep Core** | `#0F0F11` | Cards, sheets, dialogs in dark mode |
| **Surface (light) — Off White** | `#F8F9FA` | Light-mode scaffold bg |
| **Text on dark** | `#FFFFFF` (primary), `#A0A0A0` (secondary) | All dark-mode body copy |
| **Text on light** | `#1A1A1A` (primary), `#6B6B6B` (secondary) | All light-mode body copy |
| **Success** | `#34C759` | Booking confirmed, payment succeeded |
| **Warning** | `#FFCC00` | Pending review, soft moderation states |
| **Error** | `#FF3B30` | Card declines, validation errors, dispute opened |

**Typography:** `Plus Jakarta Sans` via `google_fonts` (Display/Headline/Body all use the same family with weight differences).

**Theming rules:**
- Dark mode is the **default**. Light mode is supported but not the brand-forward state.
- Brand color is **never** used as a flat background — only as ink/CTA/accent. Backgrounds are vantablack, near-black, or off-white.
- Map pins and chip backgrounds are the only places where amber gets a fill; elsewhere it's a stroke or a glow.
- Founders' iconography & app icon will be commissioned (designer brief — see `FOLLOWUPS.md` §2.2) but must remain compatible with this palette; no reroll.

### 3.15 Favorites & wishlists (V1)

> **Why this matters.** Users want to save things — "I want to come back to this gallery", "I'm thinking about booking that massage next month", "this person looks interesting." Without a save action, every session restarts from zero. With it, the app accumulates *value over time per user*, which is the only way to beat Yelp's "I bookmark on Google Maps anyway" inertia.

The model is **one favorite primitive, four target types, two views**:

- **Target types:** `business_profile`, `listing`, `post`, `place` (a POI from the map overlay — §3.3 — that the user wants to remember). A future `person` target is gated behind privacy work and is V2.
- **Two views the user sees:**
  1. **Saved places** — a layer on the **map / globe**. Toggleable like any other map filter. Renders pins for favorited businesses, listings (where a location can be derived), and POIs.
  2. **Wishlists** — a tab on the **profile screen**, grouped by target type ("Businesses", "Listings", "Posts", "Places"). Sort by date saved or last visited.
- **One-tap heart on every relevant card** — `BusinessCard`, `ListingCard`, `PostCard`, `PlaceCard`. The same heart appears in the agent's RichCards (§3.12), so if the agent surfaces a good answer the user can keep it without leaving the chat sheet.
- **Public vs private:**
  - All favorites are **private by default**.
  - V1 ships private only.
  - V1.5 adds an opt-in "Public wishlist" mode (e.g. "Things I love in SoHo") that becomes part of the social surface — useful for tastemaker accounts and for the agent's `find_similar_people` overlap signal.
- **Agent integration:** `propose_card_for_save` is not a tool the agent calls; saving stays a user action. But the agent reads the user's favorites (with consent) as a strong signal in `find_similar_people` and `suggest_communities` once V1.5 communities ship. The "you and `BP-XYZ` share…" overlap sheet (§7) gains a "shared favorites" row when both users have favorited the same thing.
- **Cold-start tie-in:** the social-data-pull step (§3.1.b) can pre-seed `favorites` with up to 5 places the user explicitly checks (e.g. places they tagged in their last 30 days of public posts). Strict opt-in. This is what turns "empty wishlist tab" into "5 places I already love" on day one.

Schema lives in §5.7b. UI surfaces touched: every card site, profile screen, map screen.

### 3.14 Browseable-tier neighborhoods (Phase 8, V1)

The agent is only as useful as its range. Restricting it to SoHo would limit it to "what's in 0.5 sq mi"; a multi-neighborhood agent answers "compare SoHo and Williamsburg for indie coffee" or "I want to move for the food scene — where?". But going *live* in 5 neighborhoods at once breaks the depth-before-breadth GTM rule.

The compromise: **two tiers of neighborhood**. **MVP locks to exactly 5 browseable neighborhoods + 1 Live neighborhood (SoHo).**

| Tier | What exists | What works | Why |
|---|---|---|---|
| **Live** (SoHo) | Real verified businesses, real users, real listings | Transactions, escrow, feedback, full agent capability | The depth play; existing §2 |
| **Browseable — exactly 5** (Williamsburg, West Village, Lower East Side, Nolita, NoHo) | Imported businesses from public data (Google Places + Yelp Fusion + NYC OpenData — D-NBHD-2 pending counsel review) | Read-only descriptions, "Claim this business" CTA, neighborhood-level waitlist | Gives the agent real range without 5x door-to-door cost; generates demand signal for next launch |

**D-NBHD-1 resolved** (founder decision, 2026-05-04): the 5 browseable neighborhoods at MVP launch are **Williamsburg, West Village, Lower East Side, Nolita, NoHo**. Polygon work and importer scope are bound to this set; any change requires explicit re-ratification.

**Rules:**
- Every imported business is **visibly badged** in every UI surface as "Unclaimed listing — public info." Violating this is a trust-killer.
- A browseable business owner who claims their profile (one-time code via the public-record email/phone) is routed into the standard SoHo onboarding flow.
- Booking attempts on browseable tier route to a `WaitlistCard` instead of Stripe: "We're not live in [nbhd] yet — be the first to know when we are." Each waitlist click is a demand signal in `neighborhood_waitlist`.
- Live conversion of a browseable neighborhood is a co-founder-C decision and triggers a launch-announcement email to everyone on its waitlist.
- Importer (`refresh_browseable_businesses` Edge Function) runs nightly with rate limits + cost guard. First run hand-audited row by row.

### Explicitly NOT in V1
- ❌ Infinite-scroll social feed
- ❌ Following / followers
- ❌ **Hashtag trending / top-tab / algorithmic hashtag discovery** (hashtags themselves are in V1 — see §3.8 — but as a taxonomy tool, not a feed format)
- ❌ Stories / ephemeral content
- ❌ Group chat
- ❌ Live video
- ❌ Multi-language support — English only V1, Spanish + Simplified Chinese in V1.5 (NYC actually needs both — see D-AGENT-5)
- ❌ Multiple currencies (USD only)
- ❌ Subscription tiers beyond Free / Business Pro
- ❌ Promoted listings / paid boost
- ❌ Full referral program (just a simple invite-for-$X code)
- ❌ Native Android app parity — ships to Android but primary testing & design on iOS
- ❌ Standalone TikTok login (V1.5 — see §3.1)
- ❌ Instagram Business Login surfacing (V1.5 — see §3.1)
- ❌ Bottom-tab dedicated to the agent (the agent IS the search/command bar — see §3.12)
- ❌ Named communities surface (V1.5 — implicit clusters + chip portal in V1; named communities in V1.5 once agent conversation logs prove which clusters are real — see §3.13)
- ❌ Autonomous agent actions (no auto-DMs, no auto-bookings — agent drafts, user sends — see §3.12 safety rules)
- ❌ Stripe Invoices / B2B net-terms (V2 — V1 B2B uses standard Stripe charges — see D-B2B-1)
- ❌ Agent matchmaker tier (V2 — opt-in proactive intros once named communities have proven the social signal)

---

## 4. Architecture

### 4.1 High-level diagram

```
┌──────────────────────────────────────────────────────────────┐
│                     Flutter app (iOS / Android)               │
│  Presentation ─▶ Controllers ─▶ Repositories ─▶ Data sources │
│                           │                                   │
└───────────────────────────┼───────────────────────────────────┘
                            ▼
         ┌──────────────────────────────────────┐
         │             Supabase                 │
         │  Auth · Postgres (PostGIS) · RLS ·   │
         │  Storage · Realtime · Edge Functions │
         └──────────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                  ▼
    ┌─────────┐      ┌────────────┐      ┌──────────┐
    │ Stripe  │      │ MapTiler / │      │ RevenueCat│
    │ Connect │      │ Mapbox     │      │  (IAP)    │
    └─────────┘      └────────────┘      └──────────┘

         ┌──────────────────────────────────────┐
         │  Next.js Admin (Vercel)              │
         │  Moderation · Verifications · Flags  │
         └──────────────────────────────────────┘
```

### 4.2 Client architecture (Flutter) — Clean-ish layers

The current repo has screens calling services directly; for scale we introduce two layers. The migration is incremental — `auth` first as the template, then feature-by-feature.

```
lib/
├── core/                        # shared primitives
│   ├── config/                  # env-driven config
│   ├── errors/                  # typed Failure hierarchy
│   ├── network/                 # retry, connectivity, interceptors
│   ├── router/                  # GoRouter setup
│   └── theme/
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/     # Supabase / REST adapters
│       │   └── repositories/    # impl of domain repository
│       ├── domain/
│       │   ├── entities/        # pure Dart, no Flutter imports
│       │   ├── repositories/    # interfaces
│       │   └── usecases/        # pure business logic (optional, only for complex flows)
│       ├── presentation/
│       │   ├── controllers/     # Riverpod Notifier / AsyncNotifier
│       │   ├── screens/
│       │   └── widgets/
│       └── <feature>_providers.dart
└── main.dart
```

**Rationale** (lifted from the technical deep-dive):
- `domain/` lets us unit-test business logic without Supabase, and swap data sources later (e.g., if we add a Node.js service for payment webhook handling).
- `data/repositories/` centralize retry, caching, and error mapping so controllers stay dumb.
- `presentation/controllers/` use **modern Riverpod** (`AsyncNotifier` with `@riverpod` code generation), not the legacy `StateNotifier` currently in the repo.

### 4.3 State management rules (enforced in code review)

| State kind | Example | Where it lives |
|---|---|---|
| Ephemeral UI | Form text, dropdown open/closed | Local controller or `setState` |
| App-wide | Current user, theme, selected neighborhood | Riverpod `Provider` / `NotifierProvider` |
| Server cache | Listings list, profile | `AsyncNotifierProvider.autoDispose.family` |
| Persisted | User prefs, offline drafts | `shared_preferences` wrapped in a repo |
| Routing | Current route, params | GoRouter |

**Rules:**
1. 80%+ of widgets must be `StatelessWidget` / `ConsumerWidget`. `StatefulWidget` only for controllers, animations, lifecycle hooks.
2. Always `const` constructors where possible.
3. Every screen-scoped provider is `.autoDispose`. Every provider that takes a key uses `.family`.
4. `ref.watch` should live in the smallest widget that consumes the value. Use `provider.select(...)` to avoid over-rebuild.
5. No `catch (e) { rethrow; }` in application code. Map to a typed `Failure` at the repository boundary.

### 4.4 Error model

```dart
sealed class Failure {
  final String code;
  final String messageKey; // i18n key
  const Failure(this.code, this.messageKey);
}

final class NetworkFailure extends Failure { ... }
final class AuthFailure extends Failure { ... }
final class ValidationFailure extends Failure { ... }
final class NotFoundFailure extends Failure { ... }
final class PaymentFailure extends Failure { ... }   // e.g. card_declined, stripe_down
final class ServerFailure extends Failure { ... }
final class UnknownFailure extends Failure { ... }
```

All repositories return `Future<Result<T, Failure>>` (via `fpdart` or an in-house `Result`). Controllers map failures to snackbar/banner UI. This is how we stop swallowing errors and get observable, user-friendly messages.

### 4.5 Offline / retry strategy

- `connectivity_plus` (already in `pubspec.yaml`) feeds a `ConnectivityProvider`.
- Read repositories use **stale-while-revalidate**: return cached data immediately, refetch in background, emit updated state. Implemented via a small wrapper around Riverpod's `AsyncNotifier`.
- Write operations queue in a lightweight outbox (SQLite via `drift` or simple `shared_preferences` list for MVP) and retry with exponential backoff when connectivity returns.
- Idempotency keys on every write that hits Stripe or mutates bookings.

### 4.6 Backend architecture

**Supabase-first.** No custom Node.js service in V1. Rationale: lower ops cost, faster iteration, team already using Supabase.

**Edge Functions** are used ONLY for logic that must be server-authoritative:
- Stripe webhooks (`payment.created`, `charge.succeeded`, `charge.refunded`, `charge.dispute.created`).
- Booking state machine transitions that touch payments.
- Push notification fan-out (when a booking is accepted / reminder / review request).
- Nightly cleanup (auto-release escrow after 72h, expire stale drafts).
- Admin actions (approve business, verify ID).

**All other CRUD** goes through RLS-protected direct Postgres queries. No compute cost, faster latency.

**Why not Node.js yet:** Every service we skip is a cost line we don't pay and a failure mode we don't own. Revisit only when one of (a) Stripe webhooks get hairy, (b) we need a cron system more complex than pg_cron, or (c) we add non-Supabase data sources.

### 4.7 Agent runtime architecture

```
┌──────────────────────────────────────────────────────────────┐
│  Flutter app — AskBeepBipBar (Map / Feed / Business / etc.) │
│  Renders chat sheet + RichCards (Listing/Business/Person…)  │
└─────────────────┬────────────────────────────────────────────┘
                  │  user message (SSE bidirectional)
                  ▼
        ┌──────────────────────────────┐
        │ Supabase Edge Function       │
        │ `agent-chat` (Deno, SSE)     │
        │  · auth check (RLS context)  │
        │  · per-user budget gate      │
        │  · PII scrubber              │
        │  · prompt cache lookup       │
        └────────┬───────────┬─────────┘
                 │           │
        ┌────────▼─┐   ┌─────▼──────────────────┐
        │ Anthropic│   │ Tool dispatcher        │
        │ Claude   │◀──│ search_listings        │
        │ (Haiku → │   │ find_provider          │
        │  Sonnet) │   │ find_materials         │
        └────────┬─┘   │ find_similar_people    │
                 │     │ get_overlap            │
                 │     │ describe_neighborhood  │
                 │     │ propose_intro          │
                 │     │ save_search            │
                 │     │ add_to_waitlist        │
                 │     └────────┬───────────────┘
                 │              │  (typed RPCs / Edge fns)
                 ▼              ▼
        ┌────────────────────────────────────┐
        │ Postgres (Supabase) + pgvector     │
        │ · agent_conversations / messages   │
        │ · agent_traces (intent, tool, ms)  │
        │ · user_preferences_cache (vectors) │
        │ · listings / business_profiles /   │
        │   neighborhoods / hashtag_pair /   │
        │   neighborhood_waitlist            │
        └────────────────────────────────────┘
```

**Component contracts:**

- **`agent-chat` Edge Function**: receives `{conversation_id, message, attached_context}`; streams SSE chunks of either text or `tool_call` or `card`. Auth uses the user's access token (RLS context). Per-request enforcement: token budget, PII scrub, prompt cache check.
- **Tool dispatcher**: a typed registry that maps Claude tool-call payloads to Postgres RPCs / Edge Function invocations. Every tool call writes a row to `agent_traces` with `(intent, tool, args_hash, latency_ms, tokens_in, tokens_out, cost_cents)`. Schema validation on both inputs (against Anthropic's tool schema) and outputs (against the card schema rendered to the client).
- **System prompt**: versioned, cached by Anthropic. Forbids inventing entities, sets voice (warm, knowledgeable local friend; not salesy), sets safety rules ("never reveal third-party PII", "never claim to have sent a message").
- **Memory**: short-term context = the most recent N messages of the conversation. Long-term context = `user_preferences_cache` (a vector representation of stable preferences derived from the user's profile + behavior, refreshed nightly). Long-term context is *retrieved*, not auto-injected; the agent decides whether to pull it via the `recall_preferences()` tool.
- **Observability**: `agent_traces` is the single source of truth for cost, latency, fallback rate, and (with sampling) conversation quality. Dashboards in PostHog.

**Failure modes the architecture explicitly handles:**

- **Anthropic outage**: tool dispatcher detects upstream 5xx → returns a structured "agent unavailable, here are the top results from traditional search" answer with fallback `discover_listings` results.
- **Budget exhaustion**: same fallback path; user sees a friendly notice "You're at your daily message limit — Business Pro removes this."
- **Tool timeout (>3 s for any single tool)**: returns a partial card list; agent informs the user. Logged in `agent_traces.timeouts`.
- **Tool error**: structured error returned to the agent; agent must surface it user-friendly (system-prompt rule), never invent.

### 4.7a Map / globe runtime architecture

The map is the most interactive surface in the app. We've moved it from a flat 2D Mercator (per the original `flutter_map` plan) to a **3D globe with a Mercator fallback** (§3.3) for brand and storytelling reasons. That decision has cost and engineering implications, captured here so it isn't forgotten when implementation starts.

**Stack:**

| Layer | Choice | Why |
|---|---|---|
| Tile source | **MapTiler** vector tiles (`streets-v2`, `dataviz-dark`) | Free up to 100k loads/mo; a globe-compatible style; we already chose them for cost reasons |
| Renderer (primary, V1) | **`maplibre_gl` Flutter plugin** with globe projection enabled | Open-source MapLibre Native; supports globe; works with any vendor's vector tiles |
| Renderer (fallback, V1) | **`flutter_map`** raster (existing path) | Older devices / web preview / extreme low-power mode |
| Geocoding | **Nominatim** (self-hostable) for reverse geocoding; MapTiler geocoding API for forward | Avoid Google Geocoding ($5/1k) entirely |
| POI overlay | OpenStreetMap (Overpass API) for the neighborhood polygon, cached nightly into a `pois` table | Free, accurate enough for "where's the nearest park" framing |
| User location | `geolocator` (already in pubspec) | No change |

**Why not Mapbox / Google Maps for the globe:** Mapbox supports globe natively and looks great, but the SDK price ramps after 25k MAU and the Flutter SDK is officially maintained but lower-velocity than MapLibre. Google Maps remains rejected on cost (§6). MapLibre + MapTiler keeps us inside our cost ceiling and ships a globe.

**Device support floor:** globe projection requires WebGL2-equivalent on the device GPU. iPhone 8+ and Android devices on Vulkan/OpenGL ES 3.0+ are fine (~98% of the iOS install base, ~85% Android). Below that we silently downgrade to flat MapLibre, then to `flutter_map` raster.

**Performance budget:** first paint of the globe < 1.5 s on iPhone 12; 60 fps on idle pan/zoom; battery target < 5%/min in active use. Telemetry tracks fps via `AutomatedPerfTracker` (existing PostHog hook).

**POI overlay rules:**
- Up to ~100 POI rendered at a time, clustered above 1km zoom-out radius.
- Distinct visual language from BeepBip pins: smaller, desaturated, no border, opens a lightweight InfoCard (not a `BusinessCard`).
- Source attribution: "Map data © OpenStreetMap contributors, © MapTiler" on the legal page and in a tiny ⓘ corner of the map.

**Open questions captured for `FOLLOWUPS.md`:** MapTiler globe-style billing model, MapLibre Flutter plugin maturity for our supported iOS/Android matrix, whether the POI nightly job lives next to `refresh_browseable_businesses` or as its own Edge Function.

---

## 5. Data model

### 5.1 Keep (from current schema, with tweaks)

- `users`, `profiles`, `personal_profiles`, `business_profiles`, `business_hours`, `locations`, `interests` — keep.
- **Replace** `earthdistance` extension (`schema.sql:149 ll_to_earth`) with **PostGIS**. `locations` gets a `geog GEOGRAPHY(POINT, 4326)` column with a GIST index.
- Add `locations.neighborhood_id FK → neighborhoods(id)`.
- `profiles.subscription_tier` gets a third value: `business_pro` (distinct from legacy `premium`).
- Add `business_profiles.hashtags TEXT[] NOT NULL DEFAULT '{}' CHECK (cardinality(hashtags) <= 5)` — "signature tags" shown on profile. GIN indexed.
- Add `personal_profiles.social_handles JSONB NOT NULL DEFAULT '{}'` — opt-in `{instagram, tiktok, x, website}` surfaced on profile.
- Add `business_profiles.social_handles JSONB NOT NULL DEFAULT '{}'` — same, for businesses.

### 5.2 Add (new tables)

```sql
-- Geographic scoping unit
CREATE TABLE public.neighborhoods (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug         TEXT UNIQUE NOT NULL,           -- 'soho-nyc'
  display_name TEXT NOT NULL,                  -- 'SoHo'
  city         TEXT NOT NULL,                  -- 'New York'
  region       TEXT NOT NULL,                  -- 'NY'
  country      TEXT NOT NULL DEFAULT 'US',
  polygon      GEOGRAPHY(POLYGON, 4326) NOT NULL,
  status       TEXT NOT NULL DEFAULT 'active', -- active | coming_soon | paused
  launched_at  TIMESTAMPTZ,
  timezone     TEXT NOT NULL DEFAULT 'America/New_York',
  currency     TEXT NOT NULL DEFAULT 'USD',
  platform_fee_bps INT NOT NULL DEFAULT 800,   -- basis points; 800 = 8%
  created_at   TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_neighborhoods_polygon ON public.neighborhoods USING GIST(polygon);

-- Marketplace supply
CREATE TYPE listing_type   AS ENUM ('service','item','event');
CREATE TYPE listing_status AS ENUM ('draft','active','paused','sold_out','removed');

CREATE TABLE public.listings (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  neighborhood_id   UUID NOT NULL REFERENCES public.neighborhoods(id),
  type              listing_type NOT NULL,
  title             TEXT NOT NULL,
  description       TEXT,
  price_cents       INTEGER NOT NULL CHECK (price_cents >= 0),
  currency          TEXT NOT NULL DEFAULT 'USD',
  duration_minutes  INTEGER,              -- services
  capacity          INTEGER,              -- events
  stock             INTEGER,              -- items
  images            TEXT[] DEFAULT '{}',
  hashtags          TEXT[] NOT NULL DEFAULT '{}'
                    CHECK (cardinality(hashtags) <= 10),
  status            listing_status NOT NULL DEFAULT 'draft',
  starts_at         TIMESTAMPTZ,          -- events
  ends_at           TIMESTAMPTZ,
  search_vector     tsvector GENERATED ALWAYS AS
                    (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(description,''))) STORED,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_listings_search   ON public.listings USING GIN(search_vector);
CREATE INDEX idx_listings_hashtags ON public.listings USING GIN(hashtags);
CREATE INDEX idx_listings_neighborhood_status ON public.listings(neighborhood_id, status);

-- Transactions
CREATE TYPE booking_status AS ENUM (
  'pending',       -- created, awaiting seller accept (for services)
  'accepted',      -- seller accepted, awaiting buyer pay
  'paid',          -- escrow funded
  'in_progress',   -- service in progress / item shipped
  'completed',     -- buyer confirmed OR 72h auto-release
  'disputed',      -- buyer raised dispute, escrow locked
  'cancelled',     -- cancelled pre-payment
  'refunded'       -- money returned to buyer
);

CREATE TABLE public.bookings (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  listing_id           UUID NOT NULL REFERENCES public.listings(id),
  buyer_user_id        UUID NOT NULL REFERENCES public.users(id),
  seller_profile_id    UUID NOT NULL REFERENCES public.profiles(id),
  status               booking_status NOT NULL DEFAULT 'pending',
  scheduled_at         TIMESTAMPTZ,
  amount_cents         INTEGER NOT NULL,
  platform_fee_cents   INTEGER NOT NULL,
  currency             TEXT NOT NULL DEFAULT 'USD',
  stripe_payment_intent TEXT UNIQUE,
  auto_release_at      TIMESTAMPTZ,       -- set when status -> 'paid'
  idempotency_key      TEXT UNIQUE NOT NULL,
  metadata             JSONB NOT NULL DEFAULT '{}',
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_bookings_buyer  ON public.bookings(buyer_user_id, created_at DESC);
CREATE INDEX idx_bookings_seller ON public.bookings(seller_profile_id, created_at DESC);
CREATE INDEX idx_bookings_status ON public.bookings(status);

-- Financial audit trail (one row per money movement)
CREATE TYPE payment_movement AS ENUM ('charge','refund','payout','fee','adjustment');

CREATE TABLE public.payments (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id     UUID REFERENCES public.bookings(id),
  type           payment_movement NOT NULL,
  amount_cents   INTEGER NOT NULL,
  currency       TEXT NOT NULL DEFAULT 'USD',
  provider       TEXT NOT NULL DEFAULT 'stripe',
  provider_ref   TEXT,                   -- charge_xxx / re_xxx / tr_xxx
  status         TEXT NOT NULL,          -- pending|succeeded|failed
  metadata       JSONB NOT NULL DEFAULT '{}',
  created_at     TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_payments_booking ON public.payments(booking_id);

-- Seller payout accounts (Stripe Connect)
CREATE TABLE public.stripe_accounts (
  profile_id            UUID PRIMARY KEY REFERENCES public.profiles(id),
  stripe_account_id     TEXT UNIQUE NOT NULL,
  charges_enabled       BOOLEAN NOT NULL DEFAULT FALSE,
  payouts_enabled       BOOLEAN NOT NULL DEFAULT FALSE,
  details_submitted     BOOLEAN NOT NULL DEFAULT FALSE,
  requirements          JSONB NOT NULL DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- Trust
CREATE TYPE feedback_tone AS ENUM ('positive','neutral','negative');

CREATE TABLE public.feedback (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id           UUID UNIQUE NOT NULL REFERENCES public.bookings(id),
  reviewer_user_id     UUID NOT NULL REFERENCES public.users(id),
  reviewee_profile_id  UUID NOT NULL REFERENCES public.profiles(id),
  tone                 feedback_tone NOT NULL,
  comment              TEXT,
  is_anonymous_complaint BOOLEAN NOT NULL DEFAULT FALSE,
  business_response    TEXT,
  published_at         TIMESTAMPTZ,      -- NULL until negotiation period ends
  editable_until       TIMESTAMPTZ NOT NULL,
  created_at           TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.disputes (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id    UUID NOT NULL REFERENCES public.bookings(id),
  raised_by     UUID NOT NULL REFERENCES public.users(id),
  reason_code   TEXT NOT NULL,
  description   TEXT,
  status        TEXT NOT NULL DEFAULT 'open',  -- open | resolved_buyer | resolved_seller | resolved_split
  resolution    TEXT,
  resolved_by   UUID REFERENCES public.users(id),
  resolved_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Light social
CREATE TABLE public.posts (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id         UUID NOT NULL REFERENCES public.profiles(id),
  neighborhood_id    UUID NOT NULL REFERENCES public.neighborhoods(id),
  body               TEXT NOT NULL,
  media_urls         TEXT[] DEFAULT '{}',
  hashtags           TEXT[] NOT NULL DEFAULT '{}'
                     CHECK (cardinality(hashtags) <= 5),
  linked_listing_id  UUID REFERENCES public.listings(id),
  expires_at         TIMESTAMPTZ,
  created_at         TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_posts_neighborhood ON public.posts(neighborhood_id, created_at DESC);
CREATE INDEX idx_posts_hashtags     ON public.posts USING GIN(hashtags);

-- Hashtag moderation
CREATE TABLE public.banned_hashtags (
  tag         TEXT PRIMARY KEY,           -- normalized (lowercase, no #)
  reason      TEXT NOT NULL,
  created_by  UUID REFERENCES public.users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.muted_hashtags (
  tag         TEXT PRIMARY KEY,
  reason      TEXT,
  created_by  UUID REFERENCES public.users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Messaging
CREATE TABLE public.conversations (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id      UUID UNIQUE REFERENCES public.bookings(id),
  buyer_user_id   UUID NOT NULL REFERENCES public.users(id),
  seller_profile_id UUID NOT NULL REFERENCES public.profiles(id),
  last_message_at TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_user_id  UUID NOT NULL REFERENCES public.users(id),
  body            TEXT NOT NULL,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_messages_conv ON public.messages(conversation_id, created_at);

-- Moderation
CREATE TYPE verification_type AS ENUM ('id','business_license','address');

CREATE TABLE public.verifications (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id    UUID NOT NULL REFERENCES public.profiles(id),
  type          verification_type NOT NULL,
  status        TEXT NOT NULL DEFAULT 'pending',  -- pending|approved|rejected
  evidence_url  TEXT,
  reviewed_by   UUID REFERENCES public.users(id),
  reviewed_at   TIMESTAMPTZ,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.reports (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_user_id UUID NOT NULL REFERENCES public.users(id),
  target_type    TEXT NOT NULL,    -- profile | listing | post | message
  target_id      UUID NOT NULL,
  reason         TEXT NOT NULL,
  status         TEXT NOT NULL DEFAULT 'open',
  resolution     TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Feature flags & config (runtime toggles without redeploy)
CREATE TABLE public.feature_flags (
  key          TEXT PRIMARY KEY,
  enabled      BOOLEAN NOT NULL DEFAULT FALSE,
  rollout_pct  INTEGER NOT NULL DEFAULT 0,
  payload      JSONB DEFAULT '{}',
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.3 RLS policy principles

- **Owner read/write:** users/profiles/listings/bookings can only be modified by their owning user.
- **Public read gated by visibility + neighborhood + subscription tier:** e.g. `free` tier sees 5 km radius and 10 nearby profiles per query; `business_pro` sees more, enforced in a Postgres function, not the client.
- **Payment tables are server-write only.** Client can read their own; only Edge Functions (service role) insert.
- **Dispute escalation:** only raised_by user and admin role can read private dispute text.

### 5.4 Critical RPC functions

```sql
-- PostGIS-based nearby discovery, cursor-paginated, hashtag-aware
CREATE FUNCTION public.discover_listings(
  p_neighborhood_slug TEXT,
  p_type              listing_type DEFAULT NULL,
  p_query             TEXT DEFAULT NULL,
  p_hashtags          TEXT[] DEFAULT NULL,        -- array-contains OR match
  p_user_lat          DOUBLE PRECISION DEFAULT NULL,
  p_user_lng          DOUBLE PRECISION DEFAULT NULL,
  p_cursor            TIMESTAMPTZ DEFAULT NULL,
  p_limit             INT DEFAULT 20
) RETURNS TABLE (...) ...;

-- Hashtag lookup — resolves a raw user query into a usable normalized tag
CREATE FUNCTION public.normalize_hashtag(raw TEXT) RETURNS TEXT
  LANGUAGE sql IMMUTABLE AS
$$
  SELECT lower(regexp_replace(trim(leading '#' from coalesce($1,'')), '[^a-z0-9_]', '', 'g'))
$$;

-- Escrow auto-release (pg_cron)
CREATE FUNCTION public.release_expired_escrows() RETURNS INT ...;

-- Feedback publishing after negotiation window
CREATE FUNCTION public.publish_ripe_feedback() RETURNS INT ...;
```

### 5.5 B2C + B2B audience layer (additive, non-breaking)

The single-graph B2C + B2B model from §3.4 lands as additive columns on `listings`. Existing rows default to `audience='consumer'` so nothing breaks.

```sql
CREATE TYPE listing_audience AS ENUM ('consumer','business','both');

ALTER TABLE public.listings
  ADD COLUMN audience listing_audience NOT NULL DEFAULT 'consumer',
  ADD COLUMN subtype TEXT,                         -- e.g. 'wholesale', 'materials', 'supply', 'retail'
  ADD COLUMN min_order_quantity INTEGER,
  ADD COLUMN unit TEXT,                            -- 'lb','kg','case','sheet',...
  ADD COLUMN bulk_pricing JSONB,                   -- [{qty:25, price_cents:8000},{qty:100, price_cents:28000}]
  ADD COLUMN lead_time_days INTEGER,
  ADD COLUMN business_only_visibility BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX idx_listings_audience ON public.listings(neighborhood_id, audience, status);

-- Discovery RPC update: filter by audience
DROP FUNCTION IF EXISTS public.discover_listings(...);
CREATE FUNCTION public.discover_listings(
  p_neighborhood_slug TEXT,
  p_type              listing_type DEFAULT NULL,
  p_audience          listing_audience DEFAULT 'consumer',
  p_query             TEXT DEFAULT NULL,
  p_hashtags          TEXT[] DEFAULT NULL,
  p_user_lat          DOUBLE PRECISION DEFAULT NULL,
  p_user_lng          DOUBLE PRECISION DEFAULT NULL,
  p_cursor            TIMESTAMPTZ DEFAULT NULL,
  p_limit             INT DEFAULT 20
) RETURNS TABLE (...) ...;
```

**RLS:** `business_only_visibility=true` rows are visible only when the requesting user has a business profile (or is the listing owner). Enforced via the `auth.jwt()` claims on `profile_type`.

### 5.6 Agent + community schema

```sql
-- Agent conversations (long-lived per-user)
CREATE TABLE public.agent_conversations (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES public.users(id),
  title         TEXT,
  started_at    TIMESTAMPTZ DEFAULT NOW(),
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  is_saved      BOOLEAN NOT NULL DEFAULT FALSE,    -- user pinned; survives retention
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_agent_conv_user ON public.agent_conversations(user_id, last_active_at DESC);

-- Agent messages (turn-by-turn)
CREATE TYPE agent_role AS ENUM ('user','assistant','tool','system');
CREATE TABLE public.agent_messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.agent_conversations(id) ON DELETE CASCADE,
  role            agent_role NOT NULL,
  content         JSONB NOT NULL,                  -- text + cards + tool_calls
  tool_call_id    TEXT,
  cards           JSONB,                           -- rendered card payloads, for replay
  tokens_in       INT,
  tokens_out      INT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_agent_msg_conv ON public.agent_messages(conversation_id, created_at);

-- Per-call observability (one row per tool invocation)
CREATE TABLE public.agent_traces (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.agent_conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES public.users(id),
  intent          TEXT,
  tool            TEXT,
  args_hash       TEXT,                            -- SHA-256 of args for cache key
  latency_ms      INT,
  tokens_in       INT,
  tokens_out      INT,
  cost_cents      NUMERIC(10,4),
  status          TEXT NOT NULL DEFAULT 'ok',      -- ok | timeout | error | budget_exceeded
  error_msg       TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_agent_traces_user_day ON public.agent_traces(user_id, created_at);

-- Vector cache of stable user preferences (refreshed nightly via job)
CREATE EXTENSION IF NOT EXISTS vector;
CREATE TABLE public.user_preferences_cache (
  user_id          UUID PRIMARY KEY REFERENCES public.users(id),
  preferences_text TEXT NOT NULL,                  -- human-readable summary
  embedding        vector(1536),                   -- OpenAI / Voyage / Cohere; pick in §10
  refreshed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Saved searches (drives proactive notifications, V1.5)
CREATE TABLE public.agent_saved_searches (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.users(id),
  query       TEXT NOT NULL,
  filters     JSONB NOT NULL DEFAULT '{}',
  notify      TEXT NOT NULL DEFAULT 'weekly',      -- daily | weekly | off
  last_notified TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Hashtag co-occurrence (materialized; refreshed nightly)
CREATE MATERIALIZED VIEW public.hashtag_pair AS
SELECT a, b, COUNT(*)::INT AS weight, neighborhood_id
FROM (
  SELECT UNNEST(hashtags) AS a, UNNEST(hashtags) AS b, neighborhood_id
  FROM public.listings WHERE status = 'active'
  UNION ALL
  SELECT UNNEST(hashtags) AS a, UNNEST(hashtags) AS b, neighborhood_id
  FROM public.posts WHERE NOT is_removed
) p
WHERE a < b
GROUP BY a, b, neighborhood_id;
CREATE INDEX idx_hashtag_pair ON public.hashtag_pair(neighborhood_id, weight DESC);

-- Discoverability flag on profiles (default ON, one-tap opt-out)
ALTER TABLE public.profiles
  ADD COLUMN discoverable BOOLEAN NOT NULL DEFAULT TRUE;

-- Community mining candidates (output of agent log mining job)
CREATE TABLE public.community_mining_candidates (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cluster_signature  TEXT UNIQUE NOT NULL,         -- normalized hashtag/interest fingerprint
  sample_questions   TEXT[],
  distinct_users     INT NOT NULL DEFAULT 0,
  query_count        INT NOT NULL DEFAULT 0,
  hashtag_set        TEXT[],
  neighborhood_id    UUID REFERENCES public.neighborhoods(id),
  first_seen         TIMESTAMPTZ DEFAULT NOW(),
  last_seen          TIMESTAMPTZ DEFAULT NOW(),
  promoted_to        UUID REFERENCES public.communities(id), -- NULL until human promotes
  created_at         TIMESTAMPTZ DEFAULT NOW()
);

-- Named communities (V1.5; schema lands now to avoid double-migration)
CREATE TYPE community_kind AS ENUM ('interest','service','business','geo');
CREATE TYPE community_source AS ENUM ('user_proposed','agent_mined','admin_curated');
CREATE TYPE community_role AS ENUM ('member','mod','owner');

CREATE TABLE public.communities (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug            TEXT UNIQUE NOT NULL,
  name            TEXT NOT NULL,
  description     TEXT,
  kind            community_kind NOT NULL DEFAULT 'interest',
  source          community_source NOT NULL DEFAULT 'admin_curated',
  neighborhood_id UUID REFERENCES public.neighborhoods(id),
  created_by      UUID REFERENCES public.users(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.community_tags (
  community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  tag          TEXT NOT NULL,
  weight       NUMERIC(4,2) NOT NULL DEFAULT 1.00,
  PRIMARY KEY (community_id, tag)
);

CREATE TABLE public.community_members (
  community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role         community_role NOT NULL DEFAULT 'member',
  joined_at    TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (community_id, user_id)
);
```

### 5.7 Browseable-tier neighborhood schema

```sql
CREATE TYPE neighborhood_tier AS ENUM ('live','browseable','dark');

ALTER TABLE public.neighborhoods
  ADD COLUMN tier neighborhood_tier NOT NULL DEFAULT 'live';

CREATE TYPE business_source AS ENUM ('claimed','imported','seeded');

ALTER TABLE public.business_profiles
  ADD COLUMN source business_source NOT NULL DEFAULT 'claimed',
  ADD COLUMN imported_from TEXT,                    -- 'google_places' | 'yelp_fusion' | 'nyc_open_data'
  ADD COLUMN claim_token TEXT,
  ADD COLUMN claim_token_expires_at TIMESTAMPTZ;

-- Demand signal for next-launch decisions
CREATE TABLE public.neighborhood_waitlist (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.users(id),
  neighborhood_id UUID NOT NULL REFERENCES public.neighborhoods(id),
  intent          TEXT,                             -- free-text: "I want vintage shops here"
  source_card_id  UUID,                             -- which agent answer prompted this
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, neighborhood_id)
);
CREATE INDEX idx_waitlist_neighborhood ON public.neighborhood_waitlist(neighborhood_id, created_at);
```

**RLS:** every UI surface that renders an `imported` business badge it visibly as "Unclaimed listing — public info." Enforced in render code (no DB-level enforcement of UI badging — but `business_profiles.source` is exposed in every read so the client can't claim ignorance).

### 5.7a Category taxonomy + GMB sync schema

```sql
-- Curated mapping from a category (GMB or our own taxonomy) to the hashtags / services
-- the onboarding flow should surface for that business. Editable via the admin panel.
CREATE TABLE public.category_taxonomy (
  category_key   TEXT PRIMARY KEY,             -- e.g. 'bakery', 'massage_therapist'
  display_name   TEXT NOT NULL,
  parent_key     TEXT REFERENCES public.category_taxonomy(category_key),
  audience       listing_audience NOT NULL DEFAULT 'consumer',
  hashtags       TEXT[] NOT NULL DEFAULT '{}', -- recommended starter hashtags
  services       TEXT[] NOT NULL DEFAULT '{}', -- recommended service names
  interests      TEXT[] NOT NULL DEFAULT '{}', -- mapped personal-side interests
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_category_taxonomy_parent ON public.category_taxonomy(parent_key);

-- Crosswalk from external provider categories (Google, Yelp, Instagram) to our keys.
CREATE TABLE public.category_aliases (
  provider       TEXT NOT NULL,                -- 'google_places' | 'yelp' | 'instagram'
  external_key   TEXT NOT NULL,                -- e.g. 'gcid:bakery'
  category_key   TEXT NOT NULL REFERENCES public.category_taxonomy(category_key),
  PRIMARY KEY (provider, external_key)
);

-- GMB connection per business profile.
ALTER TABLE public.business_profiles
  ADD COLUMN gmb_resource_name        TEXT,        -- e.g. 'accounts/123/locations/456'
  ADD COLUMN gmb_place_id             TEXT,        -- the Google Places id (used to match imported rows)
  ADD COLUMN gmb_primary_category_key TEXT REFERENCES public.category_taxonomy(category_key),
  ADD COLUMN gmb_secondary_categories TEXT[] NOT NULL DEFAULT '{}', -- max 2 enforced in app
  ADD COLUMN gmb_last_synced_at       TIMESTAMPTZ,
  ADD COLUMN gmb_sync_error           TEXT;        -- last error message, NULL on healthy

-- When a `business_profiles.source='imported'` row is later claimed via GMB,
-- the row is updated in place: source -> 'claimed', gmb_* fields populated, claim_token cleared.

-- Personal-profile social-data-pull state (V1, opt-in per provider per field).
CREATE TABLE public.social_connections (
  user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  provider     TEXT NOT NULL,                  -- 'apple' | 'google' | 'facebook' | 'instagram' | 'tiktok'
  external_id  TEXT NOT NULL,                  -- the provider's stable user id
  scopes       TEXT[] NOT NULL DEFAULT '{}',   -- granted scopes, mirror what we asked for
  consent      JSONB NOT NULL DEFAULT '{}',    -- { profile_photo:true, bio:false, interests:true, ... }
  last_pulled_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, provider)
);

-- A staging table the user reviews before import; rows survive only until accepted/rejected.
CREATE TABLE public.social_import_candidates (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  provider      TEXT NOT NULL,
  kind          TEXT NOT NULL,                 -- 'interest' | 'post' | 'photo' | 'handle'
  payload       JSONB NOT NULL,                -- the raw candidate (e.g. text, image url, tag)
  decision      TEXT,                          -- NULL | 'accepted' | 'rejected'
  decided_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_social_import_pending ON public.social_import_candidates(user_id) WHERE decision IS NULL;
```

**RLS for §5.7a:**
- `category_taxonomy`, `category_aliases` — public read; admin-only write.
- `social_connections`, `social_import_candidates` — owner-only read/write. Service role inserts during the OAuth callback Edge Function. Rows older than 30 days with `decision IS NULL` are reaped nightly (the user lost interest; safer to forget than to keep stale candidates around).

### 5.7b Favorites & wishlists schema

```sql
CREATE TYPE favorite_target_type AS ENUM (
  'business_profile', 'listing', 'post', 'place'
);

CREATE TABLE public.favorites (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_type     favorite_target_type NOT NULL,
  target_id       UUID,                              -- for business_profile / listing / post
  place_payload   JSONB,                             -- for 'place' targets (POI from map): {name, lat, lng, source, source_id}
  list_name       TEXT NOT NULL DEFAULT 'default',   -- user-named wishlists (e.g. "Date night", "SoHo coffee")
  is_public       BOOLEAN NOT NULL DEFAULT FALSE,    -- V1 ships private only; V1.5 enables this toggle
  note            TEXT,                              -- private note from the user
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  CHECK (
    (target_type IN ('business_profile','listing','post') AND target_id IS NOT NULL AND place_payload IS NULL)
    OR
    (target_type = 'place' AND target_id IS NULL AND place_payload IS NOT NULL)
  )
);

CREATE UNIQUE INDEX uniq_favorite_per_target
  ON public.favorites(user_id, target_type, COALESCE(target_id::TEXT, place_payload->>'source_id'), list_name);
CREATE INDEX idx_favorites_user_recent ON public.favorites(user_id, created_at DESC);
CREATE INDEX idx_favorites_target ON public.favorites(target_type, target_id) WHERE target_id IS NOT NULL;

-- Aggregate count for cards (eventually replace with a counter cache if write traffic warrants).
CREATE VIEW public.favorite_counts AS
SELECT target_type, target_id, COUNT(*)::INT AS n_favorites
FROM public.favorites
WHERE target_id IS NOT NULL
GROUP BY target_type, target_id;
```

**RLS for §5.7b:**
- `favorites` — owner-only read/write **except** for rows where `is_public = TRUE`, which any authenticated user can read. (V1 keeps `is_public` permanently FALSE via a CHECK at the app layer; V1.5 lifts the lock and adds the public-list UI.)
- `favorite_counts` — public read, intentionally unauthenticated-friendly (used to render "12 saves" on a listing card without leaking *who* saved it).

### 5.8 Discovery agent — favorites tool extension

The agent's tool layer (§3.12) gains a read-only signal:

- `read_user_favorites(my_serial, target_type?, list_name?)` — returns the user's own favorites for the agent to ground answers ("you usually save bakeries — here's a new one").
- `get_overlap(serial_a, serial_b)` is extended to include `shared_favorites` in its return shape. RLS still applies: only `is_public = TRUE` favorites are visible cross-user.

The agent never *writes* a favorite. Saving stays a deliberate user action with a heart tap.

---

## 6. Cost-aware stack decisions

All cost figures are order-of-magnitude at MVP scale. The principle: **every $/MAU line item above $0.10 must be architected around before it hits.**

| Layer | Choice | MVP cost | 100k MAU cost | Alternative (rejected) |
|---|---|---|---|---|
| Mobile | Flutter + Riverpod | $0 | $0 | React Native — rejected b/c code already in Flutter |
| Backend | Supabase Free → Pro | $0 → $25/mo | ~$100–300/mo | Self-hosted Postgres, Firebase |
| Maps | **MapLibre GL Native + MapTiler vector tiles** (globe primary, `flutter_map` raster fallback) | $0 | $25–50/mo | **Google Maps — rejected**, $10k+/mo at 100k MAU; **Mapbox SDK — rejected** at this stage on per-MAU SDK pricing |
| POI overlay | **OpenStreetMap (Overpass)** cached nightly into `pois` | $0 | $0 (self-cached) | Google Places (used for browseable-tier import only — not the POI overlay) |
| Geocoding | Nominatim (OSS) | $0 | $0 (self-hosted) | Google Geocoding $5/1k |
| Images | Supabase Storage → **Cloudflare R2 + CDN** at 10k+ | $0 | $30–100/mo | Cloudinary (expensive at scale) |
| Realtime | **Polling 30–60s** default; Supabase Realtime only for active chats | $0 | ~$50/mo | Always-on WebSockets ($500+/mo idle) |
| Payments | **Stripe Connect Standard** | 2.9% + 30¢ | same | PayPal, Square — rejected on marketplace features |
| IAP | **RevenueCat** (free ≤ $2.5k MTR) | $0 | 1% of IAP rev | DIY IAP — rejected, 2–4 weeks of work |
| Push | FCM / APNs | $0 | $0 | OneSignal $99/mo |
| Analytics | **PostHog self-hosted on Hetzner** (~$20/mo VPS) | $20/mo | $20/mo | Mixpanel, Amplitude $$$ |
| Crashes | **Firebase Crashlytics** | $0 | $0 | Sentry $26/mo |
| CI | GitHub Actions on public fork | $0 | $0 | Codemagic 500 min free |
| Admin | Next.js on Vercel Hobby | $0 | $20/mo | Retool $10/user |
| **Discovery agent** | Anthropic Claude (Sonnet smart + Haiku router), prompt caching, per-user budget, fallback to traditional search | $0 (V1 SoHo POC) → ~$50/mo when agent ships at low volume | $300–800/mo at 100k MAU | OpenAI GPT-4o (parity, slightly higher cost), self-hosted Llama (rejected: ops cost > savings until 1M+ MAU) |
| **Browseable-tier data** | Google Places (cached) + Yelp Fusion free tier + NYC OpenData | $0 (5 nbhds × monthly refresh, fits free tier) | ~$50/mo if cache hit-rate stays >90% | Scraping (rejected: ToS risk) |

**Total MVP infra: $20/mo. With agent + browseable tier at 100k MAU: $400–900/mo. Target: gross margin > 85% at scale.**

### The traps we're consciously avoiding

1. **Google Maps.** Already in `pubspec.yaml` as `google_maps_flutter: ^2.6.1`. This dep gets removed on Day 1. `flutter_map: ^8.3.0` stays as the raster-fallback path. **Globe rendering** ships via `maplibre_gl` (added as a new dep) using the same MapTiler tile source — see §4.7a for the full rationale.
2. **Always-on Realtime.** Supabase Realtime bills per concurrent connection. For map discovery we poll; Realtime is only on open chat screens and for booking state transitions where the user is actively waiting.
3. **Untiered LLM routing.** A naive "Sonnet for everything" deployment at 10k MAU averaging 3 chats/day at ~6k tokens each would burn ~$3–8k/mo. Tiered routing (Haiku for ~70% of intents, Sonnet only when needed) + Anthropic prompt caching (≥70% hit rate target) cuts this 5–10x. Per-user daily token budget is the hard backstop.
4. **Naive vector storage.** Pinecone-style hosted vector DBs add a new vendor and a per-record fee. `pgvector` on the existing Supabase Postgres handles ≥1M vectors comfortably. Revisit only if recall regresses.

---

## 7. Revenue model & feature gating

### 7.1 Streams (ranked by when they contribute)

| Stream | When it starts | MVP target | Notes |
|---|---|---|---|
| **Transaction fees (8%)** | V1 day 1 (0% first 90 days in new neighborhoods) | $2k GMV take by week 12 | Main engine |
| **Business Pro subscription** | V1 day 1 (14-day trial) | 20 paying businesses by week 12 | $29/mo or $290/yr |
| **Promoted listings** | V1.5 | — | $1–5 per featured slot-day |
| **Verified badge fee** | V2 | — | $99/yr for B2B |
| **Event ticketing premium** | V2 | — | Tiered per event size |
| **Display ads** | Never in foreseeable future | — | Kills trust |

### 7.2 Feature gating

| Feature | Free (personal / business trial) | **Business Pro** ($29/mo) |
|---|---|---|
| Profile | ✓ | ✓ + Verified badge + cover video |
| Listings active | 3 | Unlimited |
| Images per listing | 3 | 10 |
| Chat with buyers | ✓ | ✓ + saved replies |
| Analytics | 7-day basic | 90-day full + export |
| Search ranking | Normal | +10% boost baseline |
| Customer list export | ✗ | CSV |
| Posts (channel updates) | 1 active | 3 active |
| Priority support | ✗ | <24h email |
| **Discovery agent (§3.12)** | 30 messages / 100k tokens per day, no proactive notifications | Unlimited messages (1M-token/day abuse cap), proactive notifications, multiple saved searches |
| **B2B-audience listings (§3.4, §5.5)** | Up to 1 active B2B listing | Unlimited B2B listings + bulk-pricing tiers + business-only-visibility |
| **Browseable-tier waitlist visibility (§3.14)** | See aggregate waitlist count for own neighborhood | See per-listing waitlist demand for adjacent browseable neighborhoods (where to expand) |

**Enforcement**: RLS + Postgres functions gate on `profiles.subscription_tier`. Per-user daily agent token budget enforced in the `agent-chat` Edge Function (server-authoritative). Client-side feature checks are UI sugar only; server is the source of truth.

**Why the agent justifies Business Pro better than featured placement alone:** "Unlimited concierge that knows your business and proactively brings you customers" is a much stronger pitch to a SoHo cafe owner than "+10% search boost." The agent's marginal cost to us is bounded by token caching + tiered routing; the perceived value to the business is unbounded.

---

## 8. Acquisition & cold-start playbook (SoHo-specific)

The single biggest risk is the cold-start problem. **Architecture is the easy part; getting 50 real businesses and 500 real consumers in SoHo is the hard part.** Co-founder C's entire job for 8–10 weeks.

### 8.1 Supply side (businesses) — weeks 1–6

1. **Walk SoHo with a laptop.** 4 hours/day, 5 days/week. Physical visits to boutiques, cafés, studios, galleries, massage/wellness. Onboard on the spot (we have a tablet → Stripe Connect → first listing live in 15 min).
2. **Founding Business program.** First 100 = permanent badge, waived first 90 days of fees, first-to-be-featured in launch PR. Make this visibly scarce.
3. **SoHo-focused channels:** cold outreach to newsletter editors (Time Out NY SoHo, Secret NYC, SoHo Broadway Initiative), local blogs, SoHo Partnership. Offer them an exclusive "best of SoHo" list pulled from our early businesses.
4. **Window stickers + QR codes** for every partner business. Physical presence = digital signal. Cost: ~$200 printing for 100 stickers.

### 8.2 Demand side (consumers) — weeks 6–12

1. **Public soft launch** only after 50 businesses are live with at least 1 active listing each.
2. **Press push:** Time Out NY, Secret NYC, Curbed NY, local Instagram accounts with 10k–100k followers. Pitch: "SoHo has a new local app — and it pays your neighbors directly."
3. **Referral credit**: both sides get $10 off after invitee's first booking. Fund from own cash, cap at 500 activations ($10k max spend).
4. **Physical presence**: pop-up table 2 weekends in SoHo. Live onboarding, free tote bag, $5 credit for first booking on the spot.
5. **Instagram + TikTok Reels** of real transactions: "I booked a massage from a SoHo studio in 3 taps." Organic, zero ad spend for first 60 days.
6. **iMessage / WhatsApp share pages**: every listing and every business has a stunning public web page optimized for iMessage link previews. Existing customer DM groups become your distribution channel.
7. **Cross-promotion via existing social reach**: every business profile lets the owner link their Instagram and TikTok handles (stored in `social_handles` JSONB). On public web share pages, those handles render as clickable chips — turning their existing followers into BEEPBIP discovery traffic. Businesses with large IG/TikTok followings become our acquisition engine at zero CAC.
8. **Hashtag SEO**: the hashtag-filtered view for each neighborhood (`/n/soho-nyc/tag/handmade`) renders as a public, crawlable web page. Over time this builds a long-tail SEO presence for "SoHo + [category]" queries that Yelp currently owns.

### 8.3 Retention loop

- Weekly "What's new in SoHo" push notification (curated by C in week 1–6, then semi-automated via a `digests` Edge Function).
- Post-booking: 24h follow-up push asking for 3-tier feedback. One-tap completion.
- Save payment method + 1-tap rebooking from previous bookings.
- "You rated Dana positively — here are 3 more kitchens you might like in SoHo".

### 8.4 What success looks like at week 12

- 50+ verified businesses, 200+ active listings
- 500+ consumer signups with ≥1 booking
- $25k–50k GMV → ~$2–4k platform take (excluding 0% promo fee offset)
- Dispute rate < 5%, avg resolution time < 48h
- Churn (business dropping Business Pro after trial) < 30%
- 20+ inbound requests from businesses in adjacent neighborhoods ("Can I list? I'm in NoHo.")

That last metric is what tells us to open neighborhood #2.

### 8.5 Browseable-tier mechanics — turning user behavior into the next launch decision

Once Phase 8 ships, the browseable tier (§3.14) becomes a continuous demand-discovery instrument. It changes how we pick neighborhood #2:

1. **Imported businesses are visible immediately in the agent's answers.** When a SoHo user asks "compare SoHo and Williamsburg coffee," the agent returns Williamsburg cards with the "Unclaimed listing — public info" badge.
2. **Every booking attempt on a browseable tier card surfaces a `WaitlistCard`** ("We're not live in Williamsburg yet — be the first to know.") instead of Stripe checkout. Tap = row in `neighborhood_waitlist` with the originating intent string.
3. **Every claim of an imported business** is a free seller acquisition: an owner self-identifies, takes a one-time code, and converts into a normal Live-tier business with no door-to-door cost.
4. **The launch-#2 trigger** is now data-driven, not founder-guess: pick the browseable neighborhood with the highest combined `(waitlist_users, claimed_business_owners, agent_question_count)` score.
5. **Claimed-but-not-Live conversion email**: when an owner claims a profile in a browseable neighborhood, they're added to a "founding businesses" list. When that neighborhood goes Live, they get founding-100 status by default — they did the work of self-onboarding before we asked.

**Cost discipline:** the importer (`refresh_browseable_businesses`) is rate-limited and cache-heavy. Target: <$50/mo Google Places + Yelp Fusion costs at 5 browseable neighborhoods. Counsel reviews each source's ToS before inclusion (D-NBHD-2).

---

## 9. Current repo audit & remediation

### 9.1 Critical bugs (block V1 from functioning at all)

| # | File | Problem | Fix |
|---|---|---|---|
| A1 | `lib/features/auth/providers/auth_provider.dart:10-20` | Returns mocked hardcoded user; never calls Supabase | Wire to `Supabase.instance.client.auth.onAuthStateChange` stream |
| A2 | `lib/main.dart` | Missing `await Supabase.initialize(...)` before `runApp` | Add init with env-driven URL + anon key |
| A3 | `lib/core/config/supabase_config.dart` | Secrets in source (committed) | Move to `.env` via `flutter_dotenv` + `--dart-define`; gitignore |
| A4 | project-wide | One flat config, no dev/staging/prod | Add flavors: `dev`, `staging`, `prod`; separate Supabase projects + Stripe keys |
| A5 | `lib/features/posts/providers/posts_provider.dart:11-12` | In-memory only, posts lost on restart | Wire to new `posts` table via repository |

### 9.2 Architectural debt to fix during MVP

| # | Area | Fix |
|---|---|---|
| B1 | Services hit Supabase directly from screens | Introduce `domain/repositories/` interfaces + `data/repositories/` implementations. Migrate `auth` first as template |
| B2 | Errors are `catch (e) { rethrow; }` | Typed `Failure` hierarchy; `Result<T, Failure>`; centralized error → UI mapping |
| B3 | No retry / offline / cache | Connectivity-aware repositories; stale-while-revalidate on reads; outbox for writes; idempotency keys on Stripe calls |
| B4 | Legacy `StateNotifier` | Migrate to modern `AsyncNotifier` with `riverpod_generator`. Start with new features; migrate old ones incrementally |
| B5 | No codegen / no lints enforcement | Add `build_runner`, `riverpod_lint`, `custom_lint`; enforce in CI |
| B6 | `google_maps_flutter` + `flutter_map` both present | Remove `google_maps_flutter`; standardize on `flutter_map` + MapTiler; swap MapView component |
| B7 | `earthdistance` spatial indexing | Replace with PostGIS; migrate `locations` to `geog GEOGRAPHY(POINT, 4326)` |
| B8 | No analytics / crash reporting | Add Firebase Crashlytics; PostHog self-hosted instance + client SDK |
| B9 | No CI | GitHub Actions: `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed`, web build for PR preview |
| B10 | No admin tooling | Bootstrap Next.js admin in `admin/` subdirectory or separate repo |

### 9.3 Deps to add / remove

**Remove:**
- `google_maps_flutter`

**Add (client):**
- `flutter_dotenv` — env files
- `maplibre_gl` — globe-projection map renderer (MapTiler vector tiles, see §4.7a)
- `riverpod_generator`, `riverpod_annotation`, `build_runner`, `custom_lint`, `riverpod_lint` — modern Riverpod
- `freezed`, `freezed_annotation`, `json_serializable`, `json_annotation` — immutable models
- `fpdart` (or a small in-house `Result` type) — functional error handling
- `drift` (later, for offline outbox + local cache) — deferred to V1.5
- `purchases_flutter` (RevenueCat) — IAP
- `firebase_core`, `firebase_crashlytics`, `firebase_messaging` — crashes + push
- `posthog_flutter` — analytics
- `flutter_stripe` — card + Apple Pay + Google Pay
- `url_launcher` — Stripe Connect onboarding redirect

**Keep:**
- `flutter_facebook_auth` — **keep for V1** (resolved in D6). Provides Meta-sanctioned Instagram identity coverage for consumer accounts since standalone Instagram Login was deprecated Dec 2024.
- `google_sign_in` — keep for V1.
- **Add** `sign_in_with_apple` — required by App Store guidelines whenever any third-party social login is present.

**Deferred to V1.5:**
- Custom TikTok Login Kit integration (see D9) — needs Supabase custom OAuth provider, ~3–5 dev days.
- Instagram Business Login via Graph API (see D10) — for surfacing IG handle / follower count on business profiles; requires Meta app review.

---

## 10. Build plan — 6-to-8 week MVP

Ordered list. Every item has a **Definition of Done (DoD)** to prevent half-shipped work. Effort in calendar days assuming one primary vibe-coder on it full time.

### Phase 0 — Foundation (week 1)

| # | Task | DoD | Days |
|---|---|---|---|
| 1 | Fix A1–A5 critical bugs | App starts, real Supabase auth works, secrets not committed, `dev` flavor builds | 2 |
| 2 | Add PostGIS to Supabase; migrate `locations.geog` | Nearby query using `ST_DWithin` returns real results in < 100ms | 0.5 |
| 3 | Seed `neighborhoods` with SoHo polygon (GeoJSON from OpenStreetMap) | Map renders the polygon overlay on device | 0.5 |
| 4 | Swap `google_maps_flutter` → MapLibre GL (`maplibre_gl`) + MapTiler vector tiles, **globe projection enabled** + `flutter_map` raster fallback | Globe loads in <1.5s on iPhone 12; pins cluster; tap opens preview card; raster fallback verified on iPhone 8 | 3 |
| 4b | Brand color system enforced via `app_theme.dart` exports + `BrandColors` constants | Every screen imports brand colors from one place; design tokens shipped (D-COLOR-1) | 0.5 |
| 5 | CI (GitHub Actions) on public fork | PRs run analyze + test + build automatically | 0.5 |
| 6 | Crashlytics + PostHog wired (dev keys) | Crash in debug build surfaces in dashboards | 0.5 |
| 6b | Spike: D-MAP-1 (`maplibre_gl` plugin maturity) — confirm globe projection works on our supported iOS/Android matrix | 1-page memo with go/no-go + fallback decision | 1 |

### Phase 1 — Identity & profiles (week 2)

| # | Task | DoD | Days |
|---|---|---|---|
| 7 | Migrate `auth` feature to clean architecture (template) | `auth/domain`, `auth/data`, `auth/presentation` with repos, typed failures, `AsyncNotifier` | 1.5 |
| 8 | Phone + OTP onboarding (via Supabase phone auth) | New user can sign up with phone number end-to-end | 1 |
| 9 | Sign in with Apple + Google | Both working on iOS sim + real device | 1 |
| 10 | Business onboarding — **Google Business Profile (GMB) connect path** + manual fallback + SoHo polygon address validation (§3.1.a) | Owner who connects GMB lands on a pre-filled review screen; manual fallback still works; address geocodes inside SoHo polygon or flow blocks | 2 |
| 10b | Category taxonomy seed + curated hashtag/services menu (§3.1.a, §5.7a) | `category_taxonomy` + `category_aliases` seeded with our top 20 SoHo categories; onboarding shows category-filtered hashtag/service chips | 1.5 |
| 10c | Personal onboarding — **social-data-pull review screen** with per-field consent toggles (§3.1.b) | User can connect Apple/Google/Facebook → review pulled photo, bio, interests, public posts → tap-to-import; nothing imported without explicit consent | 2 |
| 11 | Profile edit screens (personal + business) | All fields editable, photos upload, saved to Supabase Storage | 1.5 |

### Phase 2 — Listings & discovery (week 3)

| # | Task | DoD | Days |
|---|---|---|---|
| 12 | `listings` table + migration | Business can create service/item/event listings via admin-only tool | 0.5 |
| 13 | Listing create/edit UI for businesses | Full CRUD with photo upload, preview | 2 |
| 14 | `discover_listings` RPC + map pins | Map in SoHo shows real listings by category | 1 |
| 14b | **POI overlay** on the map (§3.3) — Overpass importer + `pois` table + filter chips (Coffee / Parks / Transit / Galleries / Public bathrooms) | SoHo POIs render with desaturated styling; chips toggle layers; BeepBip pins visually dominant | 2 |
| 15 | Search (full-text + filters + **hashtags**) | Typing "coffee" returns <200ms; `#handmade` returns only tagged listings; typo tolerance via `pg_trgm` | 2 |
| 16 | Listing detail screen | Photos, description, price, **hashtag chips (tappable)**, book CTA, seller info, feedback summary | 1 |
| 16b | Hashtag moderation infra | `banned_hashtags` + `muted_hashtags` tables seeded; admin UI to manage; client-side validation on listing create | 1 |
| 16c | **Favorites/wishlist** (§3.15, §5.7b) — schema, heart on every card, profile "Wishlists" tab, "Saved places" map layer | Tap heart on listing/business/post/POI → row in `favorites`; profile tab shows grouped wishlists; map toggle shows saved-places overlay | 2 |

### Phase 3 — Transactions (weeks 4–5)

| # | Task | DoD | Days |
|---|---|---|---|
| 17 | Stripe Connect Standard onboarding flow | Business connects Stripe account; `charges_enabled=true` | 1.5 |
| 18 | Booking create → payment intent → capture | Buyer books, pays via Stripe sheet, funds reach platform | 2 |
| 19 | Booking state machine + Edge Function webhooks | `pending→accepted→paid→completed` all transition correctly | 2 |
| 20 | Escrow release (confirm + 72h auto) | Funds route to seller Stripe account after completion | 1.5 |
| 21 | Refund + cancel flows | Full & partial refunds work; platform fee refunded on full | 1 |
| 22 | Receipts (email + in-app) | Email delivered; in-app history shows all bookings | 1 |

### Phase 4 — Trust & light social (week 6)

| # | Task | DoD | Days |
|---|---|---|---|
| 23 | Feedback (3-tier emoji, 7-day edit) | Prompted post-booking; aggregate shown on profile | 1.5 |
| 24 | Dispute intake + admin queue | Buyer can raise dispute; admin sees queue | 1 |
| 25 | Business posts (channel) | 3 active post limit; shows on business profile + neighborhood digest | 1 |
| 26 | "What's new in SoHo" digest screen | Admin-curated in V1; visible on home | 1 |
| 27 | Booking chat (1:1) | Text-only, Realtime, opens after booking created | 1.5 |

### Phase 5 — Monetization & polish (week 7)

| # | Task | DoD | Days |
|---|---|---|---|
| 28 | RevenueCat + Business Pro subscription | 14-day trial, $29/mo or $290/yr, entitlement gates features | 1.5 |
| 29 | Verification flow (ID for individuals, license for businesses) | Admin queue processes submissions; badge granted | 1.5 |
| 30 | Reports & block | User can report; admin resolves | 1 |
| 31 | Push notifications (FCM/APNs) | Booking updates, new feedback, digest | 1 |
| 32 | Typed errors everywhere; user-friendly messages | No `rethrow` anywhere outside repositories | 1 |

### Phase 6 — Launch prep (week 8)

| # | Task | DoD | Days |
|---|---|---|---|
| 33 | Admin panel (Next.js) MVP | Approvals, verifications, disputes, flags, neighborhood manager | 2 |
| 34 | Analytics dashboards in PostHog | North-star funnel, booking conversion, retention cohorts | 0.5 |
| 35 | Public web share pages | Listing URL + business URL render beautifully; open in app if installed | 1.5 |
| 36 | Beta test with 10 SoHo businesses | All can onboard, list, receive bookings, receive payout | 2 |
| 37 | App Store + Play Store submission | Live in both stores under TestFlight / internal track initially | 1 |

Total planned for Phases 0–6: ~38 working days of primary dev = **6–8 calendar weeks** with one full-time coder + support. Anything slipping from these phases goes to a V1.5 list, not into the MVP.

### Phase 7 — Discovery agent (weeks 9–11; ships behind `agent.enabled` flag)

The SoHo POC launches before the agent. Phase 7 adds the agent as a feature-flagged surface that turns on once the underlying infrastructure (browseable data, RPCs, observability) is verified. Treat this phase as immediately follow-on, not "later."

| # | Task | DoD | Days |
|---|---|---|---|
| 38 | Schema deltas (§5.5–§5.7): `listings.audience`, `listings` B2B columns, `agent_*` tables, `user_preferences_cache` (pgvector), `hashtag_pair` materialized view, `neighborhood_waitlist`, `community_mining_candidates`, `communities` family, `profiles.discoverable`, `business_profiles.source`, `neighborhoods.tier` | All migrations applied to staging; existing rows back-filled with defaults; no read regression on existing surfaces | 2 |
| 39 | Tool-layer RPCs (`get_overlap`, `find_similar_people`, `find_provider`, `find_materials`, `describe_neighborhood`, `discover_listings_v2` with audience/B2B filters) | Each RPC unit-tested; called from existing search UI to reduce V1.5 surface area | 3 |
| 40 | `agent-chat` Edge Function with Anthropic client + tool dispatcher + per-user budget gate + PII scrubber + prompt cache | End-to-end smoke test: user asks "find me a vegan baker" → agent returns ListingCard from real SoHo inventory; all writes to `agent_traces` correct | 4 |
| 41 | `AskBeepBipBar` widget + chat sheet + RichCard renderer (`ListingCard`, `BusinessCard`, `PersonCard`, `NeighborhoodCard`, `IntroDraftCard`, `WaitlistCard`) | Map / Feed / Business profile use the same widget; cards render correctly inside chat AND inside existing screens | 4 |
| 42 | Chip-portal flip (D-CHIP-1): `BP-XXXXXX` chip default tap = open overlap sheet; Copy as button-in-sheet | Behind `chip.tap_opens_overlap` flag; touches every chip render site; reverts cleanly if flagged off | 1 |
| 43 | Safety scaffolding: `discoverable` setting in profile, agent system-prompt finalized, hallucination adversarial prompt set, `propose_intro` draft-then-send flow with confirmation token | Adversarial prompt set passes 100%; PII scrub verified with red-team test cases | 2 |
| 44 | Agent observability dashboards (PostHog): cost per session, prompt-cache hit rate, fallback rate, latency p50/p95, hallucination report rate | Dashboards render real data from staging | 1 |
| 45 | Per-user budget gate + graceful fallback to traditional `discover_listings` when exceeded | Free-tier user hits cap → agent shows friendly notice, traditional results still appear | 1 |

Phase 7 total: ~18 working days = **~3 calendar weeks**. Agent stays flag-off in production until the dashboards prove cost discipline AND the hallucination test passes.

### Phase 8 — Browseable-tier neighborhoods (weeks 11–13; can overlap Phase 7)

| # | Task | DoD | Days |
|---|---|---|---|
| 46 | Counsel review of public-data ToS (D-NBHD-2) | One-page memo per source (Google Places / Yelp Fusion / NYC OpenData); go/no-go on each | (external) |
| 47 | Polygon seed for the 5 browseable neighborhoods (D-NBHD-1) | Polygons in `neighborhoods` with `tier='browseable'`; render correctly on map | 1 |
| 48 | `refresh_browseable_businesses` Edge Function (importer) | Nightly job; cost-guarded; first run hand-audited row-by-row | 3 |
| 49 | "Unclaimed listing — public info" badge wired into every business render site | Every UI surface that shows a business reads `business_profiles.source` and badges accordingly | 1 |
| 50 | Claim-this-business flow | Owner enters public-record email/phone → one-time code → claim → routed to standard onboarding | 2 |
| 51 | `WaitlistCard` rendering when a booking is attempted on a browseable-tier listing | Tap → `neighborhood_waitlist` insert; user sees confirmation; admin dashboard shows demand-by-neighborhood | 1 |
| 52 | Browseable-neighborhood description content (curated) for each of the 5 nbhds | `neighborhoods.description` populated; agent's `describe_neighborhood` tool returns useful answers | 1 |

Phase 8 total: ~9 working days = **~2 calendar weeks** (parallelizable with Phase 7).

**Cumulative timeline:** SoHo public launch by week 8 (Phases 0–6); agent + browseable tier publicly enabled by week 11–13 (Phases 7–8). The two halves are decoupled by feature flags; either can slip without blocking the other.

---

## 11. Quality gates (CI enforcement)

PR can't merge unless:
- `flutter analyze` → 0 issues
- `flutter test` → all pass, coverage ≥ 60% on domain + data layers
- `dart format` clean
- `custom_lint` + `riverpod_lint` clean
- At least one reviewer approval
- DB migrations forward-tested on staging
- No secrets in diff (gitleaks in CI)

---

## 12. Open decisions (need to be made within week 1)

| # | Decision | Status / Options | Owner | Deadline |
|---|---|---|---|---|
| ~~D1~~ | Business legal entity for Stripe Connect platform | **RESOLVED — existing Florida LLC.** Action item: register the LLC as the Stripe Connect platform entity; confirm EIN, bank account, and authorized rep for Connect onboarding. | Founder A | Week 1 |
| ~~D2~~ | Pricing of Business Pro | **RESOLVED — $29/mo, $290/yr, 14-day free trial.** Feature gating (§7.2) and revenue model (§7.1) already designed around this number. Action items: create RevenueCat products `business_pro_monthly` + `business_pro_annual`; mirror in App Store Connect + Play Console. | Founder A | Week 2 |
| D3 | Who handles SoHo door-to-door | C full time, or C + part-time local? | Founders | Week 1 |
| D4 | Launch date target | "Before summer" vs. "Tech-ready only" | Founders | Week 2 |
| D5 | Verification rigor V1 | Manual review by C vs. Stripe Identity ($1.50/verify) | A | Week 3 |
| ~~D6~~ | Keep or drop Facebook Login | **RESOLVED — keep.** Facebook Login is the current Meta-sanctioned path that also covers Instagram identity (standalone IG Login deprecated Dec 2024). Already wired in repo. | B | Week 2 |
| ~~D7~~ | Primary iOS vs. Android split | **RESOLVED — iOS-first.** Ship V1 to both iOS and Android via Flutter; design + QA bandwidth prioritized on iOS (§3.11 line 208). Native Android design parity is V2. No code changes — codebase already reflects this asymmetry (Sign in with Apple wired iOS-native, Android web-fallback deferred per FOLLOWUPS §1.4). | Founders | Week 1 |
| D8 | When to set up legal: terms of service, privacy policy, dispute resolution | Which lawyer, what budget | A | Week 4 |
| D9 | TikTok Login Kit in V1 vs. V1.5 | **Leaning V1.5.** Requires custom Supabase OAuth provider (~3–5 dev days + maintenance). Defer unless a specific creator/business demand signal emerges during SoHo seeding. | A | Week 3 |
| D10 | Whether to surface Instagram handle / follower count on business profile | Requires Instagram Business Login + Graph API + Meta app review. Adds social proof for businesses. V1.5 candidate. | B | Week 4 |
| D11 | Initial banned-hashtags seed list | Need a ~100-term seed (profanity, hate, drugs, scam keywords). Use open-source `naughty-words` list + SoHo-context additions. | C | Week 3 |
| D12 | Sales-tax nexus with New York as Florida LLC running a marketplace | Consult accountant re: NY marketplace facilitator laws, §1101 marketplace provider rules. Stripe Tax may handle this. | A | Week 4 |
| ~~D-AGENT-1~~ | LLM provider for the discovery agent | **RESOLVED — Anthropic Claude** (`claude-sonnet-4-5` smart, `claude-haiku-4-5` router). Native tool use + native prompt caching + predictable per-token cost. | A | (resolved) |
| ~~D-AGENT-2~~ | Streaming infra for the agent | **RESOLVED — Supabase Edge Function** (Deno, SSE). Co-locates with the rest of the data plane; one less vendor. | A | (resolved) |
| ~~D-AGENT-3~~ | Vector DB for agent memory | **RESOLVED — Supabase `pgvector`**. No new vendor; storage-dominated cost; pgvector handles ≥1M vectors comfortably. | A | (resolved) |
| D-AGENT-4 | Free-tier daily message budget for the agent | Recommendation: 30 messages / 100k tokens per day (whichever first). Business Pro: unlimited with 1M-token/day abuse ceiling. Founder sign-off needed before agent enable. | Founders | Before Phase 7 ship |
| ~~D-AGENT-5~~ | Agent multilingual support | **RESOLVED — V1 English-only**, Spanish + Simplified Chinese in V1.5. NYC needs both eventually but not at SoHo POC. | A | (resolved) |
| ~~D-NBHD-1~~ | Browseable-tier neighborhood set | **RESOLVED 2026-05-04 — Williamsburg, West Village, Lower East Side, Nolita, NoHo.** MVP locks to exactly 5 browseable + 1 Live. Polygon and importer work bound to this set. | Founders | (resolved) |
| D-NBHD-2 | Public-data sources for browseable tier | Mix to validate with counsel: Google Places (paid, cached) + Yelp Fusion (free tier, attribution required) + NYC OpenData (free, official). Each needs a one-page ToS memo before import code ships. Budget: ~$1k legal. | A + counsel | Before Phase 8 ship |
| D-B2B-1 | B2B payment path in V1 | Recommendation: V1 uses standard Stripe charges (same path as B2C); Stripe Invoices + net-terms is V2 (trigger: ≥10 B2B contracts/month at avg ticket >$200). Need CPA confirmation that "instant-pay" B2B contracts don't trip 1099/marketplace-facilitator quirks distinct from B2C. | A + CPA | Phase 7 schema work |
| ~~D-COMM-1~~ | Community mining promotion threshold | **RESOLVED — ≥25 distinct users + ≥50 queries** over a rolling 30-day window scored against the same hashtag/interest cluster signature. Tunable; document in admin tool when V1.5 ships. | A | (resolved) |
| D-CHIP-1 | Serial-ID chip default tap behavior | Recommendation: change default tap from "Copy" to "Open overlap sheet"; expose Copy as a button inside the sheet. Touches every chip render site (1 PR). Ship behind feature flag `chip.tap_opens_overlap`. Founder OK needed before flip. | Founders | Phase 7 ship |
| D-MAP-1 | Globe map plugin selection | Recommendation: `maplibre_gl` Flutter plugin against MapTiler vector tiles (§4.7a). Spike on plugin maturity (active iOS+Android support, globe projection stability) before locking. If maturity is shaky, fallback path is `flutter_map` raster as primary with a "later" globe upgrade. | A | Phase 0 spike (1 day) |
| D-GMB-1 | Google Business Profile API access | Requires a Google Cloud project + OAuth verification + restricted-scope review for `business.manage` (~2-4 weeks). Founder A applies; engineering can stub the integration in dev with a mock until verified. | A | Before Phase 1 ship |
| D-SOCIAL-1 | Social-data-pull scope (Facebook + IG) | Confirm with Meta App Review which scopes (`user_posts`, `user_likes`, `instagram_basic`) we'll actually be granted at non-business consumer tier. Likely V1 ships with Apple/Google/Facebook profile-only fields and IG comes V1.5 with Business Login. | B | Phase 1 |
| D-FAV-1 | Public wishlists timing | V1 ships private only. V1.5 lifts the lock and adds the public-list UI + agent surfacing. Confirm during V1 → V1.5 planning. | Founders | V1.5 planning |
| D-APPLE-DEV | Apple Developer account ownership | **RESOLVED — Shai owns Apple Developer enrollment** ($99/yr) and is the named "account holder" on App Store Connect. D-U-N-S verification for the Florida LLC to be filed in Shai's name with the LLC as the legal entity. | Shai | Week 1 |

---

## 13. Non-goals and things we are consciously not doing

- Not building a web app. Web is read-only marketing & link-preview layer only. Agent web parity is V2 if at all.
- Not supporting multiple **Live** neighborhoods in V1. One Live neighborhood (SoHo) at a time; the **browseable** tier (§3.14) is read-only public-data and is *not* a live neighborhood. Live expansion is data-driven, not founder-guess (see §8.5).
- Not supporting multiple currencies. USD only until we cross a border.
- Not supporting multiple languages in V1. English only. Spanish + Simplified Chinese for the agent in V1.5 (NYC needs both). Hebrew comes with Tel Aviv (V2+).
- Not building our own payment infra. Stripe does what Stripe does; we're a thin layer on top. B2B uses standard Stripe charges in V1; Stripe Invoices + net-terms is V2 (D-B2B-1).
- Not building our own map tiles. MapTiler → Protomaps migration deferred to 100k+ MAU.
- Not building a generic recommendation algorithm. The agent (§3.12) is a grounded conversational *retrieval* layer over typed tools — it never invents entities and never makes black-box ML rankings the primary surface. Implicit-overlap clusters (§3.13) are deterministic SQL, not learned models.
- Not building our own LLM or fine-tuning one. We use frontier models via Anthropic with prompt caching + tiered routing.
- Not building a chat tab. The agent IS the search/command bar (§3.12).
- Not autonomously messaging users on each other's behalf. The agent drafts; the user sends.
- Not hiring full-time engineers. 3 founders + 1 designer + 1 mobile contractor (optional) until product-market fit.

---

## 14. How to use this document

- **Product decisions** → update this file and PR it. If it's not here, it's not the plan.
- **Engineering decisions** that are durable → add to Section 4 or 5. Throwaway decisions → doc-comments in code.
- **Scope creep** → if a feature isn't in Section 3, it goes to the V1.5 backlog (to be created in `docs/BACKLOG.md`).
- **Launch readiness** → we launch SoHo publicly only when all items in Section 10 Phases 0–6 are DoD.

---

## 15. References

- Public repo: [github.com/Shaus12/beepBip1.0](https://github.com/Shaus12/beepBip1.0)
- Original PRD (Hebrew): BEEPBIP.pdf (co-founder document)
- Interactive mockup: `../beepbip-mockup.html` (5 screens: onboarding, map, search, profile, book & pay)
- Prior product discussion: agent transcript `8cb75f18-5414-4451-a024-b6bf0092c6e5`
- Prior technical deep-dive: agent transcript `0d8389cb-095c-41fe-8329-5a963c09ba09`
- Serial-id-as-graph-node framing: agent transcript `609b9da7-fd3f-490a-b5ec-95097ab16899` ("arch: unique id")
- Community + Agent Architecture design exploration: `.cursor/plans/community_agent_architecture_*.plan.md`
- Founder-facing differentiation narrative: `docs/AGENT_NARRATIVE.md`
