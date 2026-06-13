# Plugins Boundary

## Responsibilities

- Stable extension contracts for source rules and future extension families.
- Keep plugin capability boundaries explicit before implementation code appears.

## Public Contracts

- `source_rules` is the V1 declarative playback source adapter boundary.
- `danmaku_sources`, `subtitle_sources`, and `player_processors` are future placeholders.

## Public Index Export List

- No root `index.dart` yet.

## Forbidden

- Executable third-party plugin code in V1.
- Credentials, DRM/login/paywall bypass, or anti-scraping bypass behavior.
- Direct player or UI state mutation.

## Allowed Dependencies

- Shared contracts and feature-neutral plugin descriptors.

## Required Checks

- `pwsh -File scripts/local-quality-gate.ps1`

