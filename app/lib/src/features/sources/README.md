# sources Feature

## Responsibilities

- Source repository and package management UI placeholder.

## Public Contracts

- Public Dart exports are limited to presentation/sources_page.dart through index.dart.

## Public Index Export List

- presentation/sources_page.dart

## Forbidden

- Executing third-party source code.
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