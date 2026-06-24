# Infrastructure Boundary

## Responsibilities

- Generated Flutter/Rust bridge access.
- Player runtime adapters such as `media_kit`.
- Platform helpers and storage/network ports used by application layers.

## Public Contracts

- `bridge/yneko_backend.dart` exposes the backend port for Bangumi keyword/tag
  search, search history storage, detail, calendar, browse, ranking, and
  playback resolution calls.
- `bridge/frb_mappers.dart` maps generated FRB DTOs into `shared/domain`
  models; feature code must continue to depend on `YnekoBackend`.
- `platform/directory_picker` exposes a small directory picker port backed by
  the Windows runner platform channel.
- `player/player_adapter.dart` exposes the media player adapter port.

## Public Index Export List

- No root `index.dart` yet; consumers import documented sub-boundary contracts.

## Forbidden

- UI composition, feature routing, business policy, or source-specific branches.

## Allowed Dependencies

- `shared/domain`, generated bridge code, `media_kit`, Flutter platform packages.

## Bridge Generation

- FRB config lives at the repository root in `flutter_rust_bridge.yaml`.
- Generated Dart files live under `bridge/generated/` and are owned by
  infrastructure only.
- Windows local runs use `scripts/build-rust-bridge.ps1` through
  `scripts/run-windows.ps1` to build and load `yneko_api.dll`.

## Required Checks

- `flutter analyze`
- `flutter test`
