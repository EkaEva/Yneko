# shell Feature

## Responsibilities

- App route state, top-level navigation, watch route composition, and app theme
  composition.
- Topbar composition for shell tabs, global search input, and the floating
  search-history popover anchored under the search field.

## Public Contracts

- Public Dart exports are limited to presentation/yneko_app.dart through index.dart.

## Public Index Export List

- presentation/yneko_app.dart

## Forbidden

- Feature algorithms, source parsing, and playback runtime control.
- Wrapping WatchRoute in the normal shell chrome.
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
