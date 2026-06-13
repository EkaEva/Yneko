# Flutter UI Context

Flutter UI is quiet, dense, and desktop-first. It should feel like a real
desktop application, not a marketing page.

## Responsibilities

- `features/<feature>/presentation` owns pages, widgets, routing composition,
  and view layout for one feature.
- `features/<feature>/application` owns Riverpod providers, use cases, async
  state, and command orchestration for one feature.
- `features/<feature>/domain` may own feature-local pure types.
- `shared/domain` owns app-wide pure types used by UI and providers.
- `infrastructure` owns generated bridge access, media player integration, and
  platform helpers.

## Rules

- No business logic in widgets.
- No direct generated FRB calls in widgets.
- Use stable, testable provider boundaries for every user flow.
- Keep `media_kit` behind a player adapter.
- Use feature public `index.dart` files for cross-feature imports.
- Do not create top-level `application`, `presentation`, or `domain` folders.
