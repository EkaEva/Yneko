# AI Rules For Yneko

These are hard constraints for AI agents and human contributors using AI
assistance. Read this file before changing the repository.

## Required Reading

Before editing:

1. Read `PROJECT.md`.
2. Read the relevant `CONTEXT/*.md`.
3. Read the module or boundary README for every area touched.
4. Search for existing components, providers, services, contracts, and tests
   before adding new ones.

## Locked Decisions

- Keep the stack: Flutter, Riverpod, `flutter_rust_bridge`, Rust, SQLite, and
  `media_kit`.
- Keep Bangumi as canonical metadata identity.
- Keep source packages declarative and user-imported.
- Keep Rust backend calls behind the `yneko-api` bridge facade.
- Keep `media_kit` behind a Flutter player adapter.
- Keep `com.yneko.anime` as the Android application ID and iOS bundle
  identifier.
- Keep generated platform runners limited to Windows, Android, and iOS until
  another platform is approved.
- Do not lower test, format, analysis, clippy, policy, or CI gates.

## Forbidden Changes

- No direct FRB calls from widgets.
- No business logic in widgets.
- No top-level Flutter `application/`, `presentation/`, or `domain/` folders
  under `app/lib/src`; use feature modules, `shared`, and `infrastructure`.
- No Rust lower crate may depend on Flutter, Dart, `yneko-api`, or app shell
  code.
- No source-specific hardcoded scraping branches in UI, player, storage, or API
  facade code.
- No rule source scripts, credentials, DRM bypass, login bypass, paywall bypass,
  or anti-scraping bypass behavior.
- No GPL, AGPL, SSPL, unknown-license, no-license, or copied third-party code
  without compatible provenance.
- No broad refactor while fixing a narrow issue.
- No blind automated commit/push of local work.
- No secrets, private source credentials, or raw playback URLs in tests,
  fixtures, logs, CI, or documentation.

## Flutter Rules

- Presentation code renders UI and forwards user intent only.
- Feature application code owns Riverpod providers, use cases, async state, and
  navigation coordination.
- Infrastructure code owns generated FRB bindings, `media_kit`, and platform
  integration.
- Domain code is pure Dart model and rule code; it does not import Flutter
  widgets, generated bindings, player runtimes, storage, or network clients.
- Public cross-layer interfaces must be documented in the owning README.
- Cross-feature imports must use the target feature public `index.dart`.
- Every feature must keep a README and public `index.dart`.

## Rust Rules

- `yneko-core` has no internal dependencies.
- `yneko-metadata`, `yneko-source-rules`, and `yneko-storage` may depend on
  `yneko-core` only.
- `yneko-api` may aggregate the lower Rust crates and is the only FRB export
  boundary.
- SQLite access belongs in `yneko-storage`.
- Bangumi HTTP behavior belongs in `yneko-metadata`.
- Declarative source package validation belongs in `yneko-source-rules`.

## Player Rules

- Keep `Source -> Parser -> Matcher -> Player`.
- Player UI must not parse sources.
- Source parsing must not inspect player internals.
- Danmaku must remain independent of player state internals.
- V1 uses `media_kit` through an adapter; replacing it requires an architecture
  decision.

## Dependency And License Rules

- Add every new direct Dart, Flutter, Rust, runtime, copied asset, generated
  source, or substantial reference to `third_party/SOURCES.md`.
- Prefer permissive licenses: MIT, Apache-2.0, BSD, ISC.
- LGPL is allowed only for dynamic runtime integration with replacement notes.
- Run dependency and policy gates after manifest or license-register changes.

## Verification Rules

Use the smallest useful check while iterating, then run the local gate before a
broad handoff:

```powershell
pwsh -File scripts/local-quality-gate.ps1
```

High-risk source/player/bridge/storage changes require focused tests plus the
local gate. When a check fails, fix the cause. Do not delete tests, weaken
assertions, or mark failures acceptable without a documented decision.
