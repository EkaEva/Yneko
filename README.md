# Yneko

Yneko is a Windows-first Flutter + Rust anime desktop application.

The new codebase is a clean restart from the earlier Tauri/React prototype. The
old project is reference material only; this repository keeps the product
principles that still matter and avoids carrying over WebView2, Tauri runtime,
DirectComposition, or native-player host experiments.

## V1 Goal

Yneko V1 proves one complete product loop:

```text
Bangumi search -> subject detail -> episode -> declarative source resolution -> playback
```

Bangumi remains canonical for subject and episode identity. Playback sources are
third-party compatible rule packages imported by the user; the app does not ship
public playback sources.

## Stack

- Flutter desktop UI, Windows first.
- Riverpod for application state and dependency wiring.
- `flutter_rust_bridge` for Flutter/Rust calls.
- Rust backend for metadata, declarative source rules, SQLite persistence, and
  playback contract resolution.
- `media_kit` behind a Flutter player adapter.
- SQLite for local favorites, history, progress, settings, and installed source
  package state.

## Repository Layout

```text
app/                  Flutter application
rust/                 Rust workspace
CONTEXT/              Focused architecture and development context
scripts/              Local quality gates and policy checks
third_party/          Dependency, runtime, asset, and license register
.github/workflows/    CI and scheduled health checks
```

## Development Status

Flutter is an explicit prerequisite. If `flutter` is not on PATH, install the
Flutter SDK first and run:

```powershell
flutter doctor
pwsh -File scripts/bootstrap.ps1
pwsh -File scripts/local-quality-gate.ps1
```

Rust is pinned through `rust-toolchain.toml`.

