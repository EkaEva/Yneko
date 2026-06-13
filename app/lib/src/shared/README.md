# Shared Boundary

## Responsibilities

- Reusable domain-neutral Dart types, UI primitives, and utilities.
- Small helpers that are not owned by a feature.

## Public Contracts

- `domain/index.dart` exports shared UI/domain value objects.

## Public Index Export List

- `domain/index.dart`

## Forbidden

- Feature-specific state, routing, source parsing, playback orchestration, or generated bridge access.

## Allowed Dependencies

- Dart SDK and Flutter foundation/UI packages when needed.

## Required Checks

- `flutter analyze`
- `flutter test`

