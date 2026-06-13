# Agent Entry Point

This repository is guarded for AI-assisted development. Agents must follow
these files in order:

1. `PROJECT.md`
2. `AI_RULES.md`
3. `CONTEXT/agent-entry.md`
4. Relevant `CONTEXT/*.md`
5. Relevant module or boundary README
6. Existing tests and scripts

## Default Workflow

- Inspect current code and tests before editing.
- Keep changes scoped to the requested boundary.
- Prefer existing patterns over new abstractions.
- Update governance docs when changing architecture, dependencies, source
  policy, bridge interfaces, player behavior, or verification gates.
- Add or update tests when behavior changes.
- Run focused checks first, then `pwsh -File scripts/local-quality-gate.ps1`
  before broad handoff.

## High-Risk Areas

Read the matching context before touching these areas:

- First orientation: `CONTEXT/agent-entry.md`
- Architecture: `CONTEXT/architecture.md`
- Flutter UI/state: `CONTEXT/flutter-ui.md`
- Rust backend/bridge: `CONTEXT/rust-backend.md`
- Source rules: `CONTEXT/source-rules.md`
- Player: `CONTEXT/player.md`
- Storage: `CONTEXT/storage.md`
- Testing/release: `CONTEXT/testing.md`
- Licensing/dependencies: `CONTEXT/licensing.md`
- GitHub sync: `CONTEXT/github-sync.md`

## Do Not

- Do not call generated FRB bindings directly from widgets.
- Do not put business logic in presentation widgets.
- Do not add source-specific playback branches outside declarative rules.
- Do not add scripts, credentials, DRM/login/paywall bypass, or anti-scraping
  bypass behavior to source packages.
- Do not add GPL/AGPL/SSPL/unknown-license code.
- Do not lower verification gates without an approved architecture decision.
- Do not commit secrets, private source credentials, or local playback URLs.

