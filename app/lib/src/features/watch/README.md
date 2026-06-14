# watch Feature

## Responsibilities

- Main-window playback route opened directly from anime cards.
- Full-window watch layout with left player surface and right episode, series,
  and source panels.
- Watch-local episode selection and player control shell.

## Public Contracts

- Public Dart exports are limited to presentation/watch_page.dart through
  index.dart.
- Widgets consume watch providers; generated bridge calls stay behind the
  documented backend port.

## Public Index Export List

- presentation/watch_page.dart

## Forbidden

- Source parsing, storage orchestration, or generated bridge calls from widgets.
- Public playback source URLs in tests, fixtures, logs, or documentation.
- Direct media runtime replacement; `media_kit` remains behind the app player
  boundary.

## Allowed Dependencies

- Shared UI/domain/mock preview contracts.
- Documented infrastructure backend port through watch application providers.
- Other feature public index.dart files when route composition requires them.

## Required Checks

- flutter analyze
- flutter test
- pwsh -File scripts/local-quality-gate.ps1
