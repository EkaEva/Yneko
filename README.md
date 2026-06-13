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

The repository is public at https://github.com/EkaEva/Yneko.

The locked app identifier is:

```text
com.yneko.anime
```

Generated Flutter runners are intentionally limited to:

```text
windows, android, ios
```

Flutter is installed locally at:

```text
C:\Users\86135\dev\flutter
```

New shells should pick it up from the user `PATH`. In the current shell, add it
manually if needed:

```powershell
$env:Path = "$env:USERPROFILE\dev\flutter\bin;$env:Path"
```

Then run:

```powershell
flutter doctor
pwsh -File scripts/bootstrap.ps1
pwsh -File scripts/local-quality-gate.ps1
```

Rust is pinned through `rust-toolchain.toml`.

## Environment Doctor

Android SDK licenses have been accepted on the current machine. To recheck the
local setup and set proxy bypass variables for the current shell, run:

```powershell
pwsh -File scripts/doctor-fix.ps1
```

If Android licenses ever reappear after an SDK reinstall, run:

```powershell
pwsh -File scripts/doctor-fix.ps1 -AcceptAndroidLicenses
```

Flutter still reports missing Visual Studio C++ desktop components until they
are installed. The required component IDs are:

```text
Microsoft.VisualStudio.Workload.NativeDesktop
Microsoft.VisualStudio.Component.VC.v142.x86.x64
Microsoft.VisualStudio.Component.VC.CMake.Project
Microsoft.VisualStudio.Component.Windows10SDK.26100
```

`scripts/doctor-fix.ps1` prints the exact Visual Studio Installer command for
the detected installation. To let the script start the installer, run an
elevated PowerShell:

```powershell
pwsh -File scripts/doctor-fix.ps1 -InstallVisualStudioComponents
```

The local environment uses a proxy; the quality gate and doctor script set
`NO_PROXY=localhost,127.0.0.1,::1` for local Flutter test traffic.
