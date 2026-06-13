# Rust Backend Context

Rust is the business backend for metadata, source rules, storage, and playback
contract resolution.

## Crates

- `yneko-core`: pure models and shared errors.
- `yneko-metadata`: Bangumi client and mapping.
- `yneko-source-rules`: source package schema, validation, parsing, matching.
- `yneko-storage`: SQLite schema and repositories.
- `yneko-api`: exported FRB facade.

## Rules

- `yneko-api` is the only bridge surface.
- Lower crates expose typed Rust APIs upward.
- SQLite stays in `yneko-storage`.
- HTTP metadata behavior stays in `yneko-metadata`.
- Source validation and matching stay in `yneko-source-rules`.

