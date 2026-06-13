# subject_detail Feature

## Responsibilities

- Subject detail presentation and episode selection route intent.
- Subject-detail provider state for loading Bangumi subject and episode data.

## Public Contracts

- Public Dart exports are limited to presentation/subject_detail_page.dart through index.dart.
- Application providers call the documented `YnekoBackend` port; widgets consume
  providers only.

## Public Index Export List

- presentation/subject_detail_page.dart

## Forbidden

- Player runtime ownership or source parsing implementation.
- Generated bridge calls from widgets.
- Direct Bangumi HTTP calls from Dart.
- Cross-feature deep imports; consume another feature through its index.dart.

## Allowed Dependencies

- Shared contracts.
- Documented infrastructure ports.
- Other feature public index.dart files when route composition requires them.

## Required Checks

- flutter analyze
- flutter test
- pwsh -File scripts/local-quality-gate.ps1
