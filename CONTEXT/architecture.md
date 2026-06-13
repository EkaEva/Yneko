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

