# player Feature

## Responsibilities

- Player visual surface and future control presentation contracts.

## Public Contracts

- Public Dart exports are limited to presentation/player_page.dart through index.dart.

## Public Index Export List

- presentation/player_page.dart

## Forbidden

- Source parsing, episode list ownership, and storage orchestration.
- Generated bridge calls from widgets.
- Cross-feature deep imports; consume another feature through its index.dart.

## Allowed Dependencies

- Shared contracts.
- Documented infrastructure ports.
- Other feature public index.dart files when route composition requires them.

## Required Checks

- flutter analyze
- flutter test
- pwsh -File scripts/local-quality-gate.ps1