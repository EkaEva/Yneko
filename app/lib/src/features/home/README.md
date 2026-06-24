# home Feature

## Responsibilities

- Home layout and main navigation entry composition.
- Direct watch-page entry from anime cards.
- Home-only Bangumi recommendation, calendar, ranking, ranking pagination,
  ranking filter, schedule day, and schedule archive provider state.
- Mapping Bangumi subject summaries into home poster view models.
- Schedule archive browsing for non-current quarters through the documented
  backend browse port.

## Public Contracts

- Public Dart exports are limited to presentation/home_page.dart through index.dart.
- Application providers call the documented `YnekoBackend` port; widgets consume
  providers only.
- Ranking and schedule request planning stays inside the home application layer;
  presentation widgets forward filter and load-more intent only.

## Public Index Export List

- presentation/home_page.dart

## Forbidden

- Owning search or player state.
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
