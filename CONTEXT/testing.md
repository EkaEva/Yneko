# Testing Context

The local gate is:

```powershell
pwsh -File scripts/local-quality-gate.ps1
```

## Required Checks

- Rust: `cargo fmt --check`, `cargo test --workspace`, `cargo clippy`.
- Flutter: `flutter analyze`, `flutter test`.
- Policy: dependency register and required governance files.
- Policy: feature README/index presence, plugin boundaries, generated platform
  runner set, and `com.yneko.anime` identifiers.
- Bridge: refresh generated bindings with `flutter_rust_bridge_codegen generate
  --config-file flutter_rust_bridge.yaml --no-dart-fix --no-dart-format
  --no-rust-format --no-deps-check` after changing `yneko-api::api`.
- Bridge: build the Windows DLL with `pwsh -File scripts/build-rust-bridge.ps1`
  before local Windows smoke runs.

Windows smoke for V1 must cover source import, search, detail, playback
resolution, playback, progress save, and restart progress restore.
