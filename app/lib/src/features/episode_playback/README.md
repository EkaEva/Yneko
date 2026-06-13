# episode_playback Feature

## Responsibilities

- Episode playback detail route with left player and right episode/source/progress panel.

## Public Contracts

- Public Dart exports are limited to presentation/episode_playback_page.dart through index.dart.

## Public Index Export List

- presentation/episode_playback_page.dart

## Forbidden

- Media runtime implementation or source-rule parsing internals.
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