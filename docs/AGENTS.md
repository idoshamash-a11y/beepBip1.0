# BEEPBIP — Multi-agent playbook

> **Purpose:** Keep each Cursor chat focused on one lane so context stays small and the agent stays sharp.
> **Rule of thumb:** **One topic = one chat.** When the conversation drifts, open a new chat.
> **Last updated:** 2026-04-29.

---

## The four lanes

| Lane | Chat name prefix | Mode | Typical length | Items per chat |
|---|---|---|---|---|
| **Architect** — product, schema, trade-offs, pricing, legal, scope decisions | `arch: <topic>` | Plan | 5–15 turns | up to 3 *related* decisions |
| **Infra/Ops** — Supabase, Docker, env, SMTP, Stripe keys, deploys, CI | `infra: <task>` | Agent | 3–8 turns | exactly 1 task |
| **Feature build** — implement a feature end-to-end | `feat: <feature>` | Agent | 5–20 turns | exactly 1 feature |
| **Bug-hunt** — fix one reproducible bug | `bug: <symptom>` | Agent | 2–6 turns | exactly 1 bug |

**When grouping multiple `arch:` decisions in one chat:** they must be coupled (deciding A changes the answer for B, or they share the same input data). Independent decisions go in separate chats so you can do them on different days. State the coupling in the chat's first message — that's the signal the agent needs.

If a chat goes beyond ~20 turns or 50K tokens, **stop, drain state into the docs, and open a fresh chat.** Long chats degrade.

---

## Opening prompts (copy-paste these)

When you start a new chat, paste the matching block as your **first message**. The agent will already know the lane, what to read, and how to behave.

### `arch:` Architect chat

```
Lane: architect (Plan mode).

Read these first:
- docs/MVP_SPEC.md
- docs/FOLLOWUPS.md (open decisions)
- docs/STATE.md (where we are now)

Topic for this chat: <ONE sentence — e.g. "Decide D2 (Business Pro pricing) and D7 (iOS-first vs Android-first).">

Rules:
- Critique my assumptions. No BS, no flattery.
- When we agree on a decision, write it into MVP_SPEC.md or FOLLOWUPS.md in the same turn — do not let it live only in chat.
- Do not write code in this chat.
```

### `infra:` Infra/Ops chat

```
Lane: infra/ops (Agent mode).

Read these first:
- docs/STATE.md
- docs/FOLLOWUPS.md §1.2 (payments) and §1.5 (third-party accounts) if relevant
- .env.example for the keys we already have

Task for this chat: <ONE sentence — e.g. "Wire Resend SMTP into the staging Supabase project and verify a real password-reset email arrives.">

Rules:
- Never print full secret values. Never commit .env* files.
- Update .env.example if you introduce new keys.
- When done, append to docs/STATE.md "Last verified working" with today's date.
```

### `feat:` Feature build chat

```
Lane: feature build (Agent mode).

Read these first:
- docs/MVP_SPEC.md (the relevant section for this feature)
- docs/ARCHITECTURE.md (layer rules)
- docs/STATE.md

Feature for this chat: <ONE sentence — e.g. "Implement listings end-to-end so creating a post and creating a listing share a single flow surfaced from the + button and the social feed.">

Rules:
- Follow the layer order: Domain → Data → Application → Presentation.
- Do not fix unrelated bugs. Append to FOLLOWUPS.md instead.
- End with a "How to verify" checklist I can run in the app.
- Do not declare the feature done until I confirm verification.
```

### `bug:` Bug-hunt chat

```
Lane: bug-hunt (Agent mode).

Read these first:
- docs/STATE.md
- docs/ARCHITECTURE.md (to identify the right layer)

Bug for this chat: <ONE bug — e.g. "Forgot-password email is not arriving on the staging Supabase project.">

Steps I took:
1. ...
2. ...
Expected: ...
Actual: ...

Rules per .cursor/rules/one-bug-per-chat.mdc:
- Reproduce → identify layer → smallest fix → verification steps → wait for my confirmation.
- Do not work on any other bug or feature in this chat.
```

---

## How to close a chat properly

Before abandoning a chat, run this in it:

> *"Closing this chat. Summarize: (1) what we decided / built / fixed, (2) what remains, (3) any deferred items that should be appended to `docs/FOLLOWUPS.md` and `docs/STATE.md`. Write the file changes now. Then list them so I can verify."*

Then move on. The next chat starts fresh from the docs.

---

## Anti-patterns (don't do these)

- ❌ Mixing infra setup, product strategy, and feature build in one chat.
- ❌ Saying "keep this in our future to-do list" without writing it to `FOLLOWUPS.md`.
- ❌ Continuing a chat past ~20 turns "just to finish one more thing."
- ❌ Starting a new chat without reading `docs/STATE.md` first.
- ❌ Declaring something fixed/done before manually verifying in the app.
