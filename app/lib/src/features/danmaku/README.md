# danmaku Feature

## Responsibilities

- V1 placeholder for future danmaku UI/application contracts.

## Public Contracts

- Public Dart exports are limited to index.dart through index.dart.

## Public Index Export List

- index.dart

## Forbidden

- Remote danmaku source implementation in V1.
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