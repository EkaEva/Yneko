# mine Feature

## Responsibilities

- Mine/profile UI shell for favorites, watch history, and cache placeholders.
- Visual-only local interactions while V1 persistence is wired elsewhere.

## Public Contracts

- Public Dart exports are limited to presentation/mine_page.dart through index.dart.

## Public Index Export List

- presentation/mine_page.dart

## Forbidden

- Generated bridge calls from widgets.
- Direct storage or playback runtime access.
- Cross-feature deep imports; consume another feature through its index.dart.

## Allowed Dependencies

- Shared contracts and mock UI preview data.
- Other feature public index.dart files when route composition requires them.

## Required Checks

- flutter analyze
- flutter test
- pwsh -File scripts/local-quality-gate.ps1
