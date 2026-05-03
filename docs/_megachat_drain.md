# Megachat drain — `c0145b97` cross-check

> **Purpose:** Independent audit of megachat `c0145b97-42cb-48bf-92ef-b3ae178eb440` (48 turns, ~80K tokens of assistant output) to confirm nothing of substance was lost when the chat self-drained into the docs.
> **Method:** Pattern-hunt the full transcript for decisions / bugs / deferrals / infra facts / commitments, then cross-reference against `MVP_SPEC.md`, `FOLLOWUPS.md`, `STATE.md`, and `ARCHITECTURE.md`.
> **Verdict:** **The closing turn was thorough.** All major content is captured. A handful of small items below are either nice-to-have additions or housekeeping.
> **Author:** workflow agent `7ba9c5da`, 2026-04-29.
> **Disposition:** Once you (or a future agent) merge the items below into the right docs, **delete this file**.

---

## ✅ Confirmed-captured (sample of cross-checks)

| Topic from megachat | Now lives in |
|---|---|
| Phone+OTP gate before first write (Twilio Verify or Supabase phone-auth) | `FOLLOWUPS.md` §1.7.a |
| Image safety scan (Cloudflare Images / Sightengine) at upload | `FOLLOWUPS.md` §1.7.c |
| Resend SMTP wired + own-domain verification needed for prod | `FOLLOWUPS.md` §1.5 |
| 5 foundation bugs A1–A5 + 10 architectural debt items B1–B10 | `MVP_SPEC.md` §9 |
| Apple Service ID + iOS capability + OAuth callback config | `FOLLOWUPS.md` §1.4 |
| Stripe Connect Standard / 8% / 72h escrow / 0% first 90 days | `MVP_SPEC.md` §7 + `FOLLOWUPS.md` §7 |
| Public/Unlisted visibility = *discoverability not audience scope*; future `connections` value | `FOLLOWUPS.md` §2.7 |
| Compose menu (Phase 1) replacing the bare `+` FAB | `FOLLOWUPS.md` §2.8 + `STATE.md` |
| Posts vertical shipped in code, awaits cloud-migration push | `FOLLOWUPS.md` §2.8 + `STATE.md` |
| `posts.visibility` migration blocker: empty `SUPABASE_DB_PASSWORD` in `.env.cli` | `FOLLOWUPS.md` §2.8 + `STATE.md` |
| Forgot-password / email-confirm landing screens / change-password screen | `FOLLOWUPS.md` §2.5 |
| Cross-project `localhost:3000` redirect on email confirm | `STATE.md` (Known broken) |
| Tel Aviv → SoHo pivot; English-only; America/New_York timezone | `MVP_SPEC.md` §7 + `FOLLOWUPS.md` §7 |
| Florida LLC + US bank for Stripe Connect | `FOLLOWUPS.md` §7 D1 + §1.1 |
| NY sales tax + multi-state marketplace facilitator question | `FOLLOWUPS.md` §1.1 D12 + §3 |
| Drop Google Maps in favor of `flutter_map` + MapTiler | `FOLLOWUPS.md` §6 + §1.5 + §7 |
| Cloudflare R2 image storage migration at 10k+ MAU | `FOLLOWUPS.md` §6 |
| PostHog cloud free → self-host on Hetzner $20/mo trigger | `FOLLOWUPS.md` §1.5 |
| Next.js admin panel on Vercel | `FOLLOWUPS.md` §1.5 + §1.7.b |
| Banned-hashtags seed list (D11) | `FOLLOWUPS.md` §1.3 D11 |
| 3-tier feedback system (positive / neutral / negative + 7-day edit window + anonymous complaints) | `MVP_SPEC.md` (verify §3.x) |
| TikTok Login deferred to V1.5; Instagram Business Login deferred (D9, D10) | `FOLLOWUPS.md` §4 + §7 |
| Verified-badge fee $99/yr (V2) | `FOLLOWUPS.md` §5 |

(Sampled, not exhaustive — but these were the highest-value items in the chat and they all landed.)

---

## 🟡 Small items to consider adding

These are minor — if you want a clean audit, fold them in. Otherwise they're cheap to skip.

### 1. Operational footnote: Supabase Free-tier email rate limit
The chat documented a real failure mode: Supabase's built-in email sender on Free tier is capped at **~3–4 emails per hour, project-wide**, which silently breaks signup smoke tests once the limit is hit. This is *why* we wired Resend SMTP, but the specific cap isn't recorded.

**Suggestion:** add a one-liner under `FOLLOWUPS.md` §1.5 (Transactional email row) or `STATE.md` Known broken:

> *Supabase built-in SMTP is rate-limited to ~3–4 emails/hour project-wide on Free tier. Resend custom SMTP is now the path; do not regress to the built-in for any user-facing flow.*

### 2. Test-account nuance: a single user with both personal AND business profiles
The chat explicitly handled the case where the test account has both profile types attached. The "Posting-as" pill swaps which profile authors the post. This nuance is implicit in the Phase-1/Phase-2 implementation but isn't called out as a behavior the smoke test should cover.

**Suggestion:** in `FOLLOWUPS.md` §2.8 Phase-2 smoke list (item *(c)*), expand:

> *(c) confirm the Posting-as switcher swaps Personal/Business **for an account that has both profile types attached**, and that the resulting `posts.author_profile_id` matches the selected profile.*

### 3. The orphan `paste` file at the repo root
There's a 0-byte file `beepBip1.0/paste` (created 2026-04-18). It's not gitignored, not documented, and probably an accidental shell paste. Harmless but ugly.

**Action:** delete it. One-liner: `rm "beepBip1.0/paste"`. Also worth adding `paste` (or a broader `*.tmp`) to `.gitignore` if these slip in often.

### 4. Git-remote safety fact (informational, low value)
The chat established that:
- `origin` = user's fork `idoshamash-a11y/beepBip1.0`
- `upstream` = `Shaus12/beepBip1.0` with **push explicitly disabled**

This lives in `.git/config` so it's already truth-of-record. Mentioning it again in docs is redundant unless you want a one-liner in the README's "Working with this repo" section for future contributors.

### 5. Build-plan source of truth
The chat referenced `MVP_SPEC.md` §10 ("6 phases over ~38 dev days") and §12 ("8 named decisions") as authoritative. These exist in the spec and are not at risk — but neither `STATE.md` nor `FOLLOWUPS.md` cross-links to them. Optional: add a "Build plan: see `MVP_SPEC.md` §10" line to the *Current sprint focus* section of `STATE.md` so it's one click away.

---

## 🟢 No action needed

Items I checked that are already correctly captured or intentionally not tracked:

- `policy.json` for the agentic moderation scorer — covered conceptually in `FOLLOWUPS.md` §1.7.b (the schema/file format itself is implementation detail to be defined when the Edge Function is built).
- `admin_audit_log` table — the chat referenced this as future schema; the moderation queue work in §1.7.b is sufficient placeholder until that lands.
- Easycount (Israeli payment gateway) — was discussed as the IL-fallback adapter pre-pivot; correctly dropped after Tel Aviv → SoHo pivot. Not a follow-up.
- Specific `.env.cli` re-link command — already in `FOLLOWUPS.md` §2.8 as a literal one-liner.
- Hot-restart-Flutter-after-migration — already in `FOLLOWUPS.md` §2.8 smoke list step (a).

---

## How to act on this file

1. Read the §🟡 items above.
2. Decide which (if any) you want folded in. The first two are worth the 30 seconds; the rest are taste.
3. Either edit the target docs yourself, or open a fresh `infra:` chat with this prompt:
   > *"Read `docs/_megachat_drain.md`. Apply the §🟡 items I marked as agreed (list them) to the appropriate doc files. Then delete `docs/_megachat_drain.md`."*
4. Once merged or dismissed, delete this file.
