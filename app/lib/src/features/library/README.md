# library Feature

## Responsibilities

- Favorite and library UI placeholder.

## Public Contracts

- Public Dart exports are limited to presentation/library_page.dart through index.dart.

## Public Index Export List

- presentation/library_page.dart

## Forbidden

- Metadata fetching or storage implementation.
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