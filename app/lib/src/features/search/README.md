# search Feature

## Responsibilities

- Search query state, Bangumi-first result presentation, and direct watch-page
  entry from result cards.

## Public Contracts

- Public Dart exports are limited to application/search_providers.dart and presentation/search_page.dart through index.dart.

## Public Index Export List

- application/search_providers.dart and presentation/search_page.dart

## Forbidden

- Calling generated bridge from widgets or resolving playback.
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
