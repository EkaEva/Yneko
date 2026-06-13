# Yneko

Yneko is a Flutter + Rust anime library and playback application. It is designed
as a Bangumi-first client with a native Flutter interface, a Rust backend, local
SQLite storage, and user-imported declarative playback source packages.

The project is in early development. The current focus is building a polished
desktop UI shell, clean module boundaries, and the first end-to-end product
loop.

## Product Goal

Yneko V1 focuses on one complete flow:

```text
Bangumi search -> subject detail -> episode selection -> source resolution -> playback -> progress history
```

Bangumi is the canonical metadata source for subjects and episodes. Playback
source packages are imported by the user and must be declarative rule packages.
Yneko does not ship public playback sources, account credentials, DRM bypasses,
paywall bypasses, login bypasses, or anti-scraping bypass logic.

## Current Status

Implemented foundations:

- Flutter app scaffold for Windows, Android, and iOS.
- Windows-first desktop shell with custom title bar, side rail, theme toggle,
  home tabs, and mock UI pages.
- Feature-based Flutter module layout.
- Rust workspace with initial crates for API, core types, metadata, source
  rules, and storage.
- Local quality gate scripts and GitHub Actions for policy, Rust, and Flutter
  checks.
- Application identifier locked to `com.yneko.anime`.

Still in progress:

- Real Bangumi integration in the Flutter UI.
- Flutter/Rust bridge code generation for the final public API surface.
- Source repository import and package installation UI.
- Real playback session orchestration through the player adapter.
- Persistent favorites, history, progress, and settings screens.

## Tech Stack

- **Flutter** for the app UI.
- **Riverpod** for application state and dependency wiring.
- **Rust** for metadata, source rules, storage, and API facade logic.
- **flutter_rust_bridge** for Flutter/Rust interop.
- **SQLite** for local app state.
- **media_kit** behind a player adapter for playback.
- **GitHub Actions** for push, pull request, and scheduled health checks.

## Typography

Yneko uses `MiSansYneko`, a project subset of MiSans Regular, Semibold, and
Bold, as the default UI font. The subset is generated from app UI text plus a
small common character set to keep package size low. System fallback fonts are
used for characters outside the subset.

Regenerate the subset after adding significant UI copy:

```powershell
pwsh -File scripts/font-subset.ps1
```

## Repository Layout

```text
app/                         Flutter application
app/lib/src/features/         Feature modules and route-level UI
app/lib/src/shared/           Shared theme, UI, mock data, and value objects
app/lib/src/infrastructure/   Bridge, player, platform, and adapter code
app/lib/src/plugins/          Plugin boundary documentation and contracts
rust/                         Rust workspace
scripts/                      Local quality, doctor, and policy scripts
third_party/                  Dependency, asset, and license register
.github/workflows/            CI workflows
```

Feature modules currently include:

```text
shell, home, search, subject_detail, episode_playback, player,
sources, library, history, settings, danmaku
```

The `danmaku` feature is interface-only for now.

## Architecture Rules

- Flutter widgets render UI and emit user intent.
- Business state should live in Riverpod providers and application/use-case
  code, not directly inside leaf widgets.
- Widgets must not call Rust or bridge APIs directly.
- Rust bridge exports should be facade-level APIs only.
- Lower Rust crates must not depend on Flutter, Dart, or app shell code.
- Source packages must remain declarative manifest and YAML/JSON rules.
- `media_kit` stays behind the Flutter player adapter.
- New dependencies, runtime assets, and substantial copied assets must be
  recorded in `third_party/SOURCES.md`.

## Source Package Policy

Yneko source packages are intended to describe compatible public page matching
and extraction rules. They must not contain executable scripts or secret fields.

Forbidden package behavior includes:

- Credentials, cookies, tokens, or private account material.
- DRM bypass, login bypass, paywall bypass, or anti-scraping bypass fields.
- Embedded executable code.
- Rules whose purpose is to evade access controls.

## Development Setup

Install the following tools:

- Flutter stable SDK.
- Rust toolchain, pinned by `rust-toolchain.toml`.
- Visual Studio with the Desktop development with C++ workload for Windows
  desktop builds.
- Android SDK if building or checking Android targets.

If Flutter is installed at the default local path used by the project scripts,
new PowerShell sessions can add it with:

```powershell
$env:Path = "$env:USERPROFILE\dev\flutter\bin;$env:Path"
```

Bootstrap dependencies:

```powershell
pwsh -File scripts/bootstrap.ps1
```

Check the local development environment:

```powershell
pwsh -File scripts/doctor-fix.ps1
```

Accept Android SDK licenses when needed:

```powershell
pwsh -File scripts/doctor-fix.ps1 -AcceptAndroidLicenses
```

## Run The App

Windows desktop:

```powershell
pwsh -File scripts/run-windows.ps1
```

If Flutter reports that desktop plugins require symlink support, enable Windows
Developer Mode:

```powershell
start ms-settings:developers
```

The run script also bypasses local proxy handling for `localhost`, `127.0.0.1`,
and `::1`. This keeps Flutter's debug service connection stable on Windows.

## Quality Gates

Run all local checks:

```powershell
pwsh -File scripts/local-quality-gate.ps1
```

Run Flutter checks directly:

```powershell
cd app
flutter analyze
flutter test
```

Run Rust checks directly:

```powershell
cargo fmt --manifest-path rust/Cargo.toml --all --check
cargo test --manifest-path rust/Cargo.toml --workspace
cargo clippy --manifest-path rust/Cargo.toml --workspace --all-targets -- -D warnings
```

## CI

GitHub Actions runs:

- Policy checks.
- Rust format, tests, and clippy.
- Flutter dependency install, analyze, and tests.
- Scheduled non-secret health checks.

CI does not require private source credentials and should not store them.

## Third-Party Register

All direct dependencies, runtime assets, and project assets used by the app are
tracked in:

```text
third_party/SOURCES.md
```

Update the register whenever adding a dependency, runtime asset, platform asset,
or substantial implementation reference.
