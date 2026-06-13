# Testing Context

The local gate is:

```powershell
pwsh -File scripts/local-quality-gate.ps1
```

## Required Checks

- Rust: `cargo fmt --check`, `cargo test --workspace`, `cargo clippy`.
- Flutter: `flutter analyze`, `flutter test`.
- Policy: dependency register and required governance files.
- Bridge: generated bindings must be refreshed once Flutter and FRB tooling are
  installed.

Windows smoke for V1 must cover source import, search, detail, playback
resolution, playback, progress save, and restart progress restore.

