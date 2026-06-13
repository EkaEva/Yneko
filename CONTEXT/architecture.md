# Architecture Context

Yneko uses a clear boundary between Flutter presentation/application code and
Rust backend services.

## Data Flow

```text
Flutter widget -> Riverpod provider/use case -> infrastructure port -> FRB facade -> Rust backend crate
```

Rust returns typed DTOs and privacy-safe errors. Flutter maps them into view
models and player contracts.

## Forbidden Direction

- Widgets -> generated FRB binding.
- Rust lower crate -> `yneko-api`.
- Rust crate -> Dart or Flutter code.
- Source rule parser -> player adapter.
- Player adapter -> source rule internals.

## Boundary Rule

If a change needs a new top-level module, a new runtime, a different bridge, or
a different player engine, record the architecture decision before coding.

## Flutter Module Rule

Feature code lives under `app/lib/src/features/<feature>/`. The approved feature
set is shell, home, search, subject_detail, episode_playback, player, sources,
library, history, settings, and danmaku placeholder. Top-level application,
presentation, and domain folders are forbidden.

The locked application identifier is `com.yneko.anime`.
