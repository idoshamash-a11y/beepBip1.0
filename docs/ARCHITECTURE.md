# BEEPBIP — App Architecture

> Status: living document. Updated as layers land. Last substantive edit: 2026‑04‑29 (posts vertical end-to-end: domain → data → application → presentation; visibility model `public | unlisted` and Compose-menu IA shipped in code, awaits cloud migration push + smoke).

This document describes how code in `lib/` is organized and the rules we hold each layer to. It is the engineering complement to `docs/MVP_SPEC.md` (which covers product and data model).

## Goals

1. **Testability** — every non‑trivial piece of logic is reachable without a running Flutter engine, Supabase, or network.
2. **Blast radius control** — a change to "which maps SDK we use" or "which auth provider we enable" should touch one file, not twelve.
3. **Readable error paths** — failures are named, typed, and part of method signatures. No mystery exceptions leaking out of the infrastructure layer.
4. **No hidden globals** — all dependencies flow through Riverpod providers, never through `Supabase.instance` calls sprinkled in UI code.

## Layers

From the outside in:

```
┌──────────────────────────────────────────────────────────────┐
│  Presentation  (lib/features/<x>/screens, widgets)           │
│  Widgets + Riverpod ConsumerWidgets.                         │
│  Depends on → Application                                    │
├──────────────────────────────────────────────────────────────┤
│  Application   (lib/features/<x>/providers, controllers)     │
│  StateNotifier / Notifier controllers, AsyncValue selectors. │
│  Depends on → Domain (repository interfaces), Core           │
├──────────────────────────────────────────────────────────────┤
│  Domain        (lib/features/<x>/models, repository IFaces)  │
│  Plain Dart. No Flutter, no Supabase. Immutable data and     │
│  repository INTERFACES (abstract classes).                   │
├──────────────────────────────────────────────────────────────┤
│  Data          (lib/features/<x>/repositories, services)     │
│  Concrete repository implementations. Talk to Supabase,      │
│  Stripe, Storage, etc. Map exceptions → Failures.            │
│  Depends on → Domain, Core                                   │
├──────────────────────────────────────────────────────────────┤
│  Core          (lib/core/**)                                 │
│  Env config, Failure hierarchy, Result<T>, logger, theming,  │
│  routing. Zero feature knowledge.                            │
└──────────────────────────────────────────────────────────────┘
```

### Rules of the road

- **Dependencies point inward only.** `data` depends on `domain`; `domain` never imports anything from `data` or `presentation`.
- **Domain is pure Dart.** No `import 'package:flutter/...'`, no `supabase_flutter`. If you need `DateTime`, `dart:convert`, or `intl`, those are fine.
- **Repositories return `Result<T>`** (see `lib/core/result/result.dart`). Never throw a raw Supabase exception out of the data layer — always map through `SupabaseFailureMapper` first.
- **Controllers talk to repositories via their domain interface**, not the concrete class. This is what lets tests substitute a fake.
- **UI reads Riverpod providers, never `Supabase.instance` directly.** The only file allowed to reference `Supabase.initialize` is `main.dart`.

## Current state (what's landed)

| Module | File(s) | Status |
|---|---|---|
| Env + flavors | `lib/core/config/env.dart`, `.env.example`, `.env.dev` | Done |
| Logger facade | `lib/core/logging/app_logger.dart` | Done |
| Failure hierarchy | `lib/core/errors/failure.dart` | Done |
| Supabase → Failure mapper | `lib/core/errors/supabase_failure_mapper.dart` | Done |
| Result<T, Failure> | `lib/core/result/result.dart` | Done |
| Real Supabase init | `lib/main.dart` | Done |
| Real auth stream + onboarding state | `lib/features/auth/providers/auth_provider.dart` | Done |
| Router reads onboarding from DB | `lib/core/router/app_router.dart` | Done |
| Auth repository (interface + Supabase impl) | `lib/features/auth/domain/`, `lib/features/auth/data/` | Done |
| Apple / Google / Facebook social login (Dart) | `lib/features/auth/data/supabase_auth_repository.dart` | Done (native iOS capability for Apple still pending — see FOLLOWUPS §1.4) |
| Profile repository (interface + Supabase impl) | `lib/features/profile/domain/`, `lib/features/profile/data/` | Done |
| Profile setup controller (composes multi-step flow) | `lib/features/profile/providers/profile_provider.dart` | Done |
| Listings vertical — domain + data + application + presentation | `lib/features/listings/**` | Done (V1 scope; image upload, map view, search UI, booking flow deferred — see FOLLOWUPS §2.6) |
| Posts vertical — domain + data + application + presentation | `lib/features/posts/**` | Done in code (PostRepository / SupabasePostRepository / posts_providers / PostFormController / PostCreationScreen with Posting-as switcher + Public/Unlisted pill + 72h auto-expiry copy + banned-hashtags client check). **Awaits**: push of `supabase/migrations/20260418000001_posts_visibility.sql` to cloud staging; full smoke test. Sub-features deferred — see FOLLOWUPS §2.7 |
| Compose menu (home `+` FAB) | `lib/features/home/screens/home_screen.dart` | Done — bottom sheet routes to Share-an-update or Add-a-listing (the latter only visible when `canAuthorListingsProvider == true`). |
| Repository layer for the rest (bookings, messaging) | – | **Next** |
| Freezed / json_serializable models | – | Later |
| Riverpod v3 codegen | – | Later |

## Folder convention (per-feature)

The aspirational layout is `domain/` → `data/` → `application/` → `presentation/`. The repo grew up with `models/`, `services/`, `providers/`, `screens/`, `widgets/` instead. To avoid a churn-heavy rename we use this mapping:

| Architectural layer | Folder name in this repo | Notes |
|---|---|---|
| Domain (models + repo *interfaces*) | `models/` + `domain/` | Plain Dart. `domain/` holds the abstract repository classes; `models/` holds the value objects. |
| Data (concrete repository implementations) | `data/` | Talks to Supabase / Stripe / Storage. Maps exceptions through `SupabaseFailureMapper`. The legacy `services/` folder is being retired — new code lives in `data/`. |
| Application (controllers + providers) | `providers/` | StateNotifier / Notifier controllers, Riverpod selectors. |
| Presentation (UI) | `screens/` + `widgets/` | Render `AsyncValue` + controller state. |

When in doubt, follow the auth feature as the reference layout (`lib/features/auth/{domain,data,providers,screens,widgets,models}`).

## How to write a new feature

Using "listings" as a hypothetical example:

```
lib/features/listings/
├── domain/
│   └── listing_repository.dart      # abstract interface
├── data/
│   └── supabase_listing_repository.dart   # concrete, implements the interface
├── models/
│   └── listing.dart                 # immutable value object
├── providers/
│   └── listings_providers.dart      # providers + controllers
├── screens/
└── widgets/
```

1. **Start in `domain/`**: define the data shape and the repository interface. The interface should express *what* you need (`Future<Result<List<Listing>>> search(...)`), not *how* (no mention of tables or RPCs).
2. **Move to `data/`**: implement the interface against Supabase. Every method wraps its body in `Result.guardAsync(..., onError: SupabaseFailureMapper.map)`.
3. **In `application/`**: expose one Riverpod provider for the concrete repository (returning the interface type), plus controllers / FutureProviders that call into it. Nothing here knows about tables.
4. **In `presentation/`**: render `AsyncValue<Result<...>>` from the application layer. Use `switch` over the `Failure` type to produce localized error messages.

## Testing plan (to be wired up)

- **Unit tests** for domain + application logic. Provide fake repository implementations; never instantiate real Supabase in a unit test.
- **Widget tests** for screens. Override the Riverpod providers with `ProviderContainer` + fake repositories.
- **Integration tests** (thin) driving the real Supabase local stack end‑to‑end for the critical flows: signup → profile setup → create listing → book → pay.

## Open architectural questions

- **Code generation**: are we adopting `freezed` + `json_serializable` + `riverpod_generator`? Worth it once there are >10 models. Until then, hand‑written.
- **Offline cache**: `drift` (sqlite) or `hive` for the read‑side offline cache? Leaning toward `drift` because the schema discipline aligns with our Postgres side.
- **Realtime vs polling**: feature flags (`messaging.realtime`, `discovery.*`) control which surfaces use Supabase Realtime vs a 30s polling loop. Default to polling in V1 to keep connection counts low; flip per‑surface once load shows it's worth the sockets.
