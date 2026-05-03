# BEEPBIP — Investor One-Pager

**Round:** SAFE · **Ask:** $600,000 · **Use of funds:** 18-month runway to product-market fit
**Stage:** MVP in build · public launch SoHo (Manhattan) Q3 2026, agent + 5-neighborhood browseable tier 4 weeks after
**Entity:** Florida LLC (Stripe Connect platform) · **Team:** 3 co-founders

---

## Vision

**Make every neighborhood transactable — through a grounded conversation, not a filter form.**

Local commerce in dense urban neighborhoods is broken: discovery happens on Instagram, payments happen on Venmo, trust happens on a friend's group chat, and reviews happen on Yelp where the highest bidder wins. Indie businesses lose the customer between platforms; residents lose 30 minutes of friction per booking.

We unify discovery, booking, payment, and trust into one neighborhood-scoped app — and we make the discovery surface itself **conversational and grounded**: every screen exposes an "Ask BeepBip…" bar that translates fuzzy intent into structured queries against verified inventory and a real people graph. Communities emerge from the questions real users repeatedly ask. The same graph powers B2C ("where's the best fresh bread?") and B2B ("who wholesales organic flour with 3-day lead time?"). We start Live in SoHo and Browseable in five surrounding NYC neighborhoods, expanding one polygon at a time — with the next polygon picked from waitlist data, not founder guesswork.

**One sentence to the user:** *"SoHo's best, booked and paid in one tap — with your money protected until you're happy. Just ask."*

**See `docs/AGENT_NARRATIVE.md` for the full differentiation story.**

---

## The MVP (V1, shipping in 12–13 weeks across two halves)

A map-first marketplace for **services, items, and events** in SoHo (Live tier) plus 5 NYC neighborhoods (Browseable tier), with an agent-native discovery surface and a community graph rooted in the serial id `BP-XXXXXX`. Built on Flutter + Supabase + Stripe Connect + Anthropic Claude.

**Half 1 — SoHo POC (8 weeks, Phases 0–6):**

| Layer | What ships |
|---|---|
| **Identity** | Phone OTP, Apple/Google/Facebook login, verified-business badge, serial id `BP-XXXXXX` as graph node |
| **Discovery** | Map (flutter_map + MapTiler), full-text + hashtag search, curated weekly digest |
| **Listings** | Service / Item / Event types, **B2C and B2B in one graph** (audience flag, optional B2B fields like MOQ + bulk pricing), hashtag taxonomy, photo gallery |
| **Transactions** | Stripe Connect Standard, **escrow** with 72h auto-release, refunds, disputes |
| **Trust** | 3-tier emoji feedback tied 1:1 to bookings, anonymous complaint flow, ID/license verification |
| **Light social** | Business channel posts, "What's new in SoHo" digest, hashtag filtering |
| **Monetization** | **8% transaction fee** + **Business Pro $29/mo** (14-day trial) |

**Half 2 — Agent + browseable tier (5 weeks, Phases 7–8, behind feature flags):**

| Layer | What ships |
|---|---|
| **Discovery agent** | "Ask BeepBip…" bar on every screen (not a chat tab). Anthropic Claude with tiered routing (Haiku → Sonnet), pgvector memory, 11 typed tools backing real RPCs. Cost target <$0.10/MAU at 100k MAU. |
| **Community graph** | Implicit clusters via overlap RPCs in V1; serial-id chip becomes a "shared connections" portal; named communities mined from agent conversation logs in V1.5 |
| **Browseable tier** | Williamsburg, West Village, Lower East Side, Nolita, NoHo — imported public-data businesses with "Unclaimed listing" badges, claim-this-business flow, neighborhood waitlist as expansion signal |

**Explicitly not built:** infinite feed, follower graph, algorithmic ranking, multi-language (V1.5), multi-currency, autonomous agent actions, chat tab, named communities (V1.5), Stripe Invoices for B2B (V2). We are not Instagram, not Nextdoor, and not ChatGPT.

---

## Why now & why us

- **Distribution gap:** Yelp's review economy is collapsing; Instagram has discovery but no commerce; Resy/OpenTable are restaurant-only; ChatGPT has conversation but no inventory. No one owns *grounded conversational neighborhood commerce*.
- **Tech tailwinds:** Stripe Connect Standard + Supabase + flutter_map + frontier LLMs (Anthropic Claude with prompt caching + tiered routing) make a defensible agent-native marketplace cost-buildable for <$60K of infra in year one.
- **Tight wedge:** SoHo = 0.5 sq mi, ~1,000 indie businesses, ~250K daily visitors, English-first, iOS-heavy, smartphone-native commerce already a habit. **50 door-to-door visits cover meaningful inventory.** Plus 5 surrounding neighborhoods seeded with public-data inventory so the agent feels powerful from day one.
- **Five-leg differentiation bundle that nobody else ships together:** agent-native discovery + emergent communities + B2B+B2C single graph + browseable-tier neighborhoods + chip-as-portal identity. Each leg is individually copyable; the bundle takes years.
- **Team:** 3 co-founders covering product/engineering, design, and SoHo street-level GTM. Florida LLC already in place; Stripe Connect platform onboarding underway.

---

## What $600K buys (use of funds, 18 months)

Allocations are tied to specific line items in the MVP spec and the SoHo + neighborhood-#2 playbook.

| Bucket | Amount | What it pays for |
|---|---:|---|
| **Founder stipends** (3 × $5K/mo × 18 mo) | $270,000 | Below-market salaries; no executive comp until Series Seed |
| **Engineering contractors** (mobile + backend, post-MVP V1.5) | $50,000 | ~600 hrs at $80/hr for offline/outbox, drift cache, V1.5 features (TikTok login, IG handle surfacing, image chat, named communities, agent multilingual) |
| **Product design** ($5K/mo × 6 mo, then retainer) | $35,000 | Brand system, map/listing/booking UX, agent chat-sheet UX, RichCard family, public web share pages, App Store assets |
| **Infrastructure & SaaS** | $22,000 | Supabase Pro, MapTiler, PostHog VPS (Hetzner), Crashlytics, RevenueCat (free until $2.5K MTR), Vercel admin, domains, push (FCM/APNs free) |
| **Discovery agent (Anthropic API + browseable-tier data)** | $14,000 | ~$300–800/mo agent API at scaling MAU, plus Google Places + Yelp Fusion calls for the browseable-tier importer. Tiered routing + prompt caching keep it bounded. |
| **Legal & compliance** | $35,000 | ToS / privacy policy, marketplace-facilitator analysis (NY §1101), Stripe Tax setup, App Store / Play Store legal, IP protection, browseable-tier public-data ToS memos |
| **Insurance** (general liability + E&O for marketplace) | $9,000 | Required for partner businesses & Stripe Connect compliance |
| **SoHo go-to-market (weeks 1–12 post-launch)** | $55,000 | Founding-100 onboarding kits, window stickers + QR (~$200/100), pop-up tables (2 weekends), micro-influencer/press push (Time Out NY, Secret NYC, Curbed), referral credits ($10×500 activations capped at $10K), content production |
| **Neighborhood #2 GTM** (picked from waitlist data, month 9+) | $55,000 | Same playbook + part-time local ops contractor 6 mo. Waitlist signal lowers the risk of choosing the wrong second market. |
| **Stripe Identity & KYC** | $5,000 | $1.50 × verifications + Stripe Connect onboarding fees |
| **Accounting, bookkeeping, state registrations** | $14,000 | Marketplace-facilitator filings, NY foreign-entity, R&D tax credit prep |
| **Contingency / buffer (~6%)** | $36,000 | Hiring acceleration, faster neighborhood expansion if metrics hit |
| **Total** | **$600,000** | **18 months runway** |

---

## Where this takes us

### Milestone 1 — SoHo POC (months 1–5)
- Public launch in SoHo
- **50 verified businesses · 500 onboarded consumers · 200+ paid bookings**
- $25K–$50K GMV → $2K–$4K platform take (0% promo first 90 days, then 8%)
- Dispute rate < 5%, NPS ≥ 40
- 20+ inbound business requests from adjacent neighborhoods → trigger to expand

### Milestone 2 — Neighborhood #2 (months 6–9)
- Williamsburg or West Village launch using the SoHo template
- **150 businesses · 2,500 users · 1,000+ bookings/mo**
- ~$120K monthly GMV · ~$10K monthly platform take + ~$3K MRR from Business Pro

### Milestone 3 — 5 NYC neighborhoods (months 10–18)
- SoHo, Williamsburg, West Village, NoHo, LES
- **600+ businesses · ~25K MAU · 4,000+ bookings/mo**
- ~$1M monthly GMV · **~$80K–$100K MRR** (transaction take + Business Pro subscriptions)
- Public web share pages + hashtag SEO compounding organic CAC near $0
- Position to raise **Series Seed ($3–5M)** on a $15–25M post by month 15–18

### Beyond month 18 (the seed round funds this, not this SAFE)
- 2 additional metros (Tel Aviv, Miami) using the same neighborhood-polygon playbook
- Promoted listings (V1.5), event ticketing premium (V2), creator/IG follower-count surfacing
- Path to **$10M+ ARR** at 25 neighborhoods, 80%+ gross margin

---

## Timeline

| Month | Milestone |
|---|---|
| **0–2** | SoHo MVP build complete (Phases 0–6 of `docs/MVP_SPEC.md` §10); beta with 10 SoHo businesses |
| **3** | Public SoHo launch; founding-100 program live; press push |
| **3–4** | Phase 7 (discovery agent) + Phase 8 (5-neighborhood browseable tier) ship behind feature flags; cost discipline + hallucination test verified before public enable |
| **4–5** | SoHo Live success criteria hit (50 biz / 500 users / 200 bookings); waitlist data identifies the strongest browseable neighborhood |
| **6–9** | Live conversion of the data-chosen neighborhood #2 |
| **10–15** | Scale to 5 Live NYC neighborhoods; named communities (V1.5) ship; build seed-round metrics |
| **16–18** | Close Series Seed; this SAFE converts |

---

## Unit economics at scale (illustrative)

- **Take rate:** 8% on every transaction + $29/mo Business Pro on ~30% of active businesses
- **Variable cost per booking:** Stripe ~3% + $0.05 infra ≈ **net contribution per booking ~$3–5 on $50 AOV**
- **CAC (consumer):** target < $5 via referral + organic web share pages
- **CAC (business):** target < $50 via founder-led door-to-door in dense polygons
- **Gross margin at 100K MAU:** **>85%** (infra at $300–$600/mo, see spec §6)

---

## Why a SAFE, why now

- We are pre-revenue but post-architecture. The technical plan is committed (`docs/MVP_SPEC.md`), the GTM polygon is chosen, the entity and Stripe platform are in motion.
- A SAFE keeps us moving without a priced round before we have SoHo data to price on. We will price the next round on **dollars in escrow per neighborhood**, not on slideware.
- This $600K bridges us from "MVP shipping" to "5-neighborhood traction" — the dataset that justifies a seed round at a real valuation.

---

## Contact

**Founders:** [Founder A] · [Founder B] · [Founder C]
**Repo & docs:** github.com/Shaus12/beepBip1.0 · canonical spec: `docs/MVP_SPEC.md` · differentiation narrative: `docs/AGENT_NARRATIVE.md`
**Mockup:** `beepbip-mockup.html` (5 screens)

---

*Confidential. This document is provided to prospective investors under NDA. All projections are illustrative and not guaranteed.*
