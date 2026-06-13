# settings Feature

## Responsibilities

- Settings UI placeholder.

## Public Contracts

- Public Dart exports are limited to presentation/settings_page.dart through index.dart.

## Public Index Export List

- presentation/settings_page.dart

## Forbidden

- Direct platform mutation without infrastructure ports.
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