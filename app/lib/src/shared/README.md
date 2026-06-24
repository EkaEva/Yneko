# Shared Boundary

## Responsibilities

- Reusable domain-neutral Dart types, UI primitives, and utilities.
- Small helpers that are not owned by a feature.

## Public Contracts

- `domain/index.dart` exports shared UI/domain value objects.
- Shared interactive controls keep hover, pressed, and selected visual states on
  the theme-token path. They must not flash through a neutral gray pressed state
  or tween selection backgrounds through transparent/neutral midpoint colors
  before showing the selected theme color.

## Public Index Export List

- `domain/index.dart`

## Forbidden

- Feature-specific state, routing, source parsing, playback orchestration, or generated bridge access.

## Allowed Dependencies

- Dart SDK and Flutter foundation/UI packages when needed.

## Required Checks

- `flutter analyze`
- `flutter test`
