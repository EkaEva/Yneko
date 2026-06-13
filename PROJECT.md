# Yneko Project Architecture

This repository is the Flutter + Rust clean restart of Yneko. It is a new
project, not a file-by-file migration from the earlier Tauri/React codebase.

## Locked Product Decisions

- Windows desktop is the first target.
- V1 scope is Bangumi-first search, detail, episode selection, source package
  import, playback resolution, playback, favorites, history, progress, and
  settings.
- Bangumi subject and episode IDs are canonical for local identity.
- Playback source packages are user-imported and declarative.
- The app does not ship public playback sources.
- Danmaku is interface-only in V1: models, settings, player slot, and future
  contract are allowed; remote danmaku source integration is not in V1.
- Downloads and offline cache are not in V1.

## Locked Stack

- Flutter for UI.
- Riverpod for Flutter application state and dependency injection.
- `flutter_rust_bridge` for Flutter/Rust calls.
- Rust 1.94.1, edition 2024, for backend business logic.
- SQLite for local persistence.
- `media_kit` behind a player adapter for V1 playback.

Do not introduce another app framework, state framework, bridge mechanism,
player engine, database, or build system without an approved architecture
decision recorded in this file and `AI_RULES.md`.

## Flutter Architecture

Flutter code is split into:

```text
app/lib/src/
  presentation/     pages, widgets, routes, and view composition
  application/      Riverpod providers, use cases, async UI state
  domain/           Dart-side UI/domain value objects
  infrastructure/   FRB bindings, media_kit adapter, platform helpers
```

Rules:

- Widgets must not call FRB directly.
- Widgets must not own business logic.
- Presentation code consumes Riverpod providers and view models.
- Application code owns user flows and calls infrastructure interfaces.
- Infrastructure code owns generated bindings and player/platform adapters.
- Shared helpers must stay small and domain-neutral.

## Rust Architecture

Rust code is split into:

```text
rust/crates/
  yneko-core/          models, shared errors, pure domain helpers
  yneko-metadata/      Bangumi client and response mapping
  yneko-source-rules/  declarative source package schema and matching
  yneko-storage/       SQLite migrations and repositories
  yneko-api/           flutter_rust_bridge facade
```

Dependency direction:

```text
yneko-core          -> no internal dependencies
yneko-metadata      -> yneko-core
yneko-source-rules  -> yneko-core
yneko-storage       -> yneko-core
yneko-api           -> yneko-core, yneko-metadata, yneko-source-rules, yneko-storage
```

Lower crates must not depend on `yneko-api`, Flutter, Dart, or app shell code.
The `yneko-api` crate is the only exported bridge surface.

## Source Rules

Source packages are manifest plus YAML/JSON rules. They must not contain:

- Scripts or executable code.
- Credentials or session secrets.
- DRM bypass, login bypass, paywall bypass, or anti-scraping bypass behavior.
- Source-specific branches in UI, player, or storage code.

Source behavior must be represented as generic schema, parser, matcher, or
playback-contract capability.

## Player Boundary

V1 playback uses `media_kit` through a Flutter infrastructure adapter.

Rust resolves playback candidates and returns privacy-safe contracts. Rust does
not control mpv directly in V1. Player UI renders controls and forwards user
intent through application providers.

The player remains separate from source parsing, danmaku, downloads, settings,
and history persistence.

## Change Control

Changing locked stack, target platform, V1 scope, module layout, source policy,
license policy, verification gates, or public bridge shape requires explicit
approval and a documentation update in the same change.

Approved architecture changes must update `PROJECT.md`, `AI_RULES.md`, relevant
`CONTEXT/*.md`, affected module READMEs, policy scripts, and focused tests.

