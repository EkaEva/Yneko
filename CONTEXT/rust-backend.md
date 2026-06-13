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

## Bridge Notes

- `yneko-api` is built as both `rlib` and `cdylib`; Windows local runs load
  `rust/target/debug/yneko_api.dll`.
- FRB generated Rust glue lives in `yneko-api/src/frb_generated.rs`.
- `yneko-api` may allow `unsafe_code` and generated glue `unwrap` only for FRB
  FFI code. Lower crates keep the workspace strict lint policy.
- Bridge-facing DTOs live in `yneko-api::api` and convert to/from `yneko-core`
  models so lower crates stay independent of Flutter/FRB constraints.
