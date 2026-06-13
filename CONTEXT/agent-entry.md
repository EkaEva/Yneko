# Agent Entry Context

Use this file as the short orientation after `PROJECT.md` and `AI_RULES.md`.

## Non-Negotiable Boundaries

- This is a clean Flutter + Rust restart.
- The old Tauri/React project is reference material only.
- Widgets do not call FRB directly.
- Rust lower crates do not depend on Flutter, Dart, or `yneko-api`.
- Source packages are declarative and user-imported.
- No secrets, credentials, private source URLs, or raw playback URLs in repo or
  CI logs.

## Default Checks

```powershell
pwsh -File scripts/local-quality-gate.ps1
```

If Flutter is unavailable, Rust and policy checks should still run and the
Flutter check should report the missing prerequisite clearly.

