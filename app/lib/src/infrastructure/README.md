# Infrastructure Boundary

## Responsibilities

- Generated Flutter/Rust bridge access.
- Player runtime adapters such as `media_kit`.
- Platform helpers and storage/network ports used by application layers.

## Public Contracts

- `bridge/yneko_backend.dart` exposes the backend port.
- `player/player_adapter.dart` exposes the media player adapter port.

## Public Index Export List

- No root `index.dart` yet; consumers import documented sub-boundary contracts.

## Forbidden

- UI composition, feature routing, business policy, or source-specific branches.

## Allowed Dependencies

- `shared/domain`, generated bridge code, `media_kit`, Flutter platform packages.

## Required Checks

- `flutter analyze`
- `flutter test`

