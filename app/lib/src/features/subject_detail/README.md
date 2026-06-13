# subject_detail Feature

## Responsibilities

- Subject detail presentation and episode selection route intent.

## Public Contracts

- Public Dart exports are limited to presentation/subject_detail_page.dart through index.dart.

## Public Index Export List

- presentation/subject_detail_page.dart

## Forbidden

- Player runtime ownership or source parsing implementation.
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