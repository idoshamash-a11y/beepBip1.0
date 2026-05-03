# BEEPBIP — What's New

> Companion to `docs/INVESTOR_ONE_PAGER.md` and `docs/MVP_SPEC.md`. One page distilling the differentiated bet. Use in decks, press conversations, and partner intros.
> **Last updated:** 2026-05-02 (post Community + Agent Architecture ratification).

---

## The thesis in one sentence

**Local discovery should be a conversation, and communities should be the residue of those conversations** — grounded in a real neighborhood graph of verified people, businesses, and inventory.

## The five things that, together, make this new

Most local apps treat discovery as filter + browse. Yelp, Nextdoor, Thumbtack, Facebook Marketplace all assume you already know what you want; you just need to narrow it down. That's why their UX has felt the same since 2010.

We bundle five things that no competitor ships together:

1. **Agent as the discovery primitive for hyper-local.** ChatGPT can't book a SoHo baker. Yelp can't answer "I just moved to NYC, I love vinyl and Sunday brunch — who do I meet and where do I go?" Our agent can do both because its tools are backed by real verified inventory and a real people graph.
2. **Implicit-then-explicit communities mined from agent conversation logs.** Most apps either ship predefined communities (Reddit, Facebook Groups) or none. We propose: communities *emerge* from the questions real users repeatedly ask, then get promoted to named, joinable surfaces. The agent both finds them and names them.
3. **B2B + B2C in one local graph.** Faire is B2B-only. Etsy is B2C-only. None mix them at a hyper-local level. A SoHo baker looking for organic flour and a SoHo resident looking for sourdough live in the same neighborhood graph — and the same agent serves both.
4. **Two-tier neighborhood model with the waitlist as our expansion signal.** SoHo launches Live (full transactions). Five surrounding NYC neighborhoods launch Browseable (public-data businesses with claim-this CTAs). Every "be the first to know when this neighborhood goes live" tap is a demand signal that tells us where to launch next — paid for by user behavior, not founder guesswork.
5. **The serial id `BP-XXXXXX` as a graph portal.** Every chip is a doorway. Tap it → see your overlap, shared communities, shared interests with that node. The id stops being a label and becomes navigation.

If we land all five, we have something that can't be cloned by feature-copying. The agent is only as good as its tool layer, its community graph, and its verified data — and those take years to build.

## Why "agent" doesn't mean "ChatGPT for local"

We've seen the pattern: a startup wraps GPT in a search box, calls it a copilot, and ships in a weekend. That's not what this is.

- **The agent is grounded.** It can only describe entities returned by tools. Adversarial prompts ("recommend a restaurant on Mars") get a graceful "I don't know that yet," not an invention. Our system prompt forbids it; our test suite proves it.
- **The agent is constrained.** It cannot send messages, make bookings, or share another user's data without explicit user confirmation. It drafts; the user sends. This is a trust ceiling, not a capability one — it's what makes the surface usable in a neighborhood where people actually have to live with each other after the transaction.
- **The agent is everywhere — but not as a chat tab.** It's the search/command bar on every screen. Map, Feed, Business profile, Listing detail. Same widget. Tap → expand. The home screen never demands a conversation; it offers one.
- **The agent is cheap to operate.** Tiered model routing (Haiku for ~70% of intents, Sonnet only when reasoning is needed) + Anthropic prompt caching gets us to <$0.10/MAU at 100k MAU scale. Per-user budgets and graceful fallbacks stop runaway cost.

## Why "communities" doesn't mean "subreddits"

- **V1 has no community pages.** The graph is implicit: a serial id, its interests, its hashtags, its services. Tap a `BP-XXXXXX` chip → see your overlap. Ask the agent "people like me in SoHo" → it returns the cluster. No moderation, no naming, no ghost towns.
- **V1.5 promotes the densest clusters to named communities.** The agent's conversation logs are the dataset that tells us which communities deserve to exist. When 25+ users repeatedly ask the same kind of question, we name it, seed it with the people who asked, and ship it. The cold-start problem solves itself.
- **Communities never become a social-media feed.** They have member lists, pinned content, hashtag-defined surfaces. They never have follower counts, algorithmic ranking, or stories. We're not Instagram and we're not trying to be.

## Why "B2B + B2C in one app" is a moat, not scope creep

- **Local B2B supply is massively underserved.** Faire is national wholesale, not hyper-local. A SoHo cafe owner sourcing pastry suppliers, a Brooklyn maker sourcing fabric, a Bushwick bar sourcing local mezcal — they all do this on Instagram DMs and friend referrals today.
- **A small business is both buyer and seller in our graph.** A SoHo cafe sells lattes (B2C) and buys coffee beans (B2B). One signup, one platform, two sides of the wallet. That doubles wallet share per business onboarded.
- **The agent is the obvious UX for it.** "I'm opening a coffee shop in SoHo, who supplies what nearby?" is a question Yelp / Faire / Nextdoor literally cannot answer. Ours can.
- **One listings table, one schema delta.** B2B isn't a separate app or a separate database. It's a single `audience` column on `listings` plus optional B2B fields. Cheap to build, hard to copy after we have density.

## Why two tiers of neighborhood instead of "launch in 5 cities"

- **Depth-before-breadth wins local.** Network effects in a neighborhood compound when ≥15% of households are users. Spreading thin across 5 neighborhoods at once means hitting that threshold in zero of them.
- **But an agent that knows only SoHo is a weak demo.** "Compare SoHo and Williamsburg coffee" is a killer agent use case; "I can't help with Williamsburg" makes the agent feel small.
- **The browseable tier solves both.** SoHo gets the depth play. Williamsburg / West Village / LES / Nolita / NoHo get imported public-data businesses, badged honestly as "Unclaimed listing — public info." The agent has real range from day one. Booking attempts on browseable listings show "be the first to know when we go live here," generating the demand signal that picks neighborhood #2.
- **Imported businesses are zero-CAC seller acquisition.** When an owner discovers their business listed on us and clicks "claim this business," we get a verified seller without ever knocking on a door.

## What this means for the metrics

| Metric | Why it changes |
|---|---|
| **CAC for businesses** | Drops further as browseable-tier claims convert imported listings to real sellers free-of-charge |
| **CAC for consumers** | Drops as the agent's range (5 browseable neighborhoods + SoHo) gives the app a "useful from day one" feel without 5x the seeding cost |
| **Average wallet share per business** | Roughly doubles when B2B + B2C live in one app and one onboarding |
| **Choice of neighborhood #2** | Picked from waitlist data, not founder guess. Probability of choosing a wrong second market drops from "high" to "low" |
| **Differentiation defensibility** | Each leg of the bet (agent, communities, B2B+B2C, browseable, chip portal) is individually copyable; the bundle takes years to build with our quality of grounding + safety scaffolding |
| **Gross margin** | Held at >85% at 100k MAU even with the agent online, because of tiered routing + prompt caching + per-user budgets |

## What we're not claiming

- **Not the first app to do local discovery.** We're the first to make the discovery surface conversational *and* grounded in real neighborhood inventory + a real people graph.
- **Not the first app to use LLMs.** We're the first to make an LLM the search bar of a transactional local marketplace, with safety scaffolding designed for the "you have to live next to this person" failure mode.
- **Not the first app to ship neighborhoods.** Nextdoor and Patch tried. They built social products. We're building commerce, with neighborhoods as the unit of trust.
- **Not the first app with hashtags or interests.** We're the first to treat the serial id as a graph node and let communities emerge from the agent's conversation logs.

## What we are claiming

The combination — agent-native, grounded, multi-tier-geo, B2B+B2C, community-emergent, chip-as-portal — is **a new shape of local app.** None of the incumbents can copy it without rebuilding from data-model up. By the time they try, we have a year of conversation logs nobody else has, a verified-business density they can't seed past, and a community graph nobody else can compute.

## The ask

We are raising a SAFE to ship the SoHo POC (Phases 0–6 of the spec, ~8 weeks) and immediately follow with the agent + browseable-tier (Phases 7–8, ~5 weeks behind feature flags). Twelve to thirteen weeks from foundation fixes to a publicly-launched, agent-native, multi-neighborhood local platform — in NYC, the most contested local market in the world.

If it works in SoHo it works in any dense indie-merchant urban core. The same playbook ships Williamsburg next, Tel Aviv after, then Miami, then anywhere a polygon and a population have outgrown what Yelp can do.

---

**See also:** `docs/MVP_SPEC.md` (canonical engineering spec) · `docs/INVESTOR_ONE_PAGER.md` (financial summary) · `docs/FOLLOWUPS.md` (operational checklist) · `docs/ARCHITECTURE.md` (engineering rules).
