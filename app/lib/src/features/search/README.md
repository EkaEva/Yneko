# search Feature

## Responsibilities

- Search query state, Bangumi-first result presentation, and direct watch-page
  entry from result cards.
- The shell top search field is the only search input. It preserves typed text
  while routes change and submits into this feature's controller.
- Search supports keyword mode and tag mode. Tag mode is selected by the search
  top tab or by clicking a subject tag on the watch page; it calls
  `YnekoBackend.searchTagSubjects(tag, page)` so tag searches use Bangumi tag
  pages instead of keyword search fallback.
- Search history is feature-local UI state backed by backend storage: entries
  are de-duplicated, moved to the front on submit, shown in the floating panel
  under the shell search field, clearable, and restored across restarts.
- Keyword results paginate through `YnekoBackend.searchSubjects(query, page)`;
  tag results paginate through `YnekoBackend.searchTagSubjects(tag, page)`.
  Scroll-near-bottom loads more, appends by subject id, and keeps already loaded
  cards stable.

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
