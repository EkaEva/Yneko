# home Feature

## Responsibilities

- Home layout and main navigation entry composition.

## Public Contracts

- Public Dart exports are limited to presentation/home_page.dart through index.dart.

## Public Index Export List

- presentation/home_page.dart

## Forbidden

- Owning search, detail, or player state.
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