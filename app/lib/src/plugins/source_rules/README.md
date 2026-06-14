# Source Rules Plugin Boundary

## Responsibilities

- Declarative source package descriptors consumed by Rust source-rule validation.

## Public Contracts

- V1 supports manifest plus YAML/JSON rules only.
- Required manifest fields are `id`, `name`, and `version`.
- Playback supports `staticCandidates` and `urlTemplate`.
- URL templates may only reference local fields: `subjectId`, `episodeId`,
  `episodeOrder`, `title`, and `episodeTitle`.

## Public Index Export List

- No public Dart exports yet.

## Forbidden

- Executable scripts, credentials, DRM/login/paywall bypass, anti-scraping bypass behavior, and source-site UI branches.

## Allowed Dependencies

- Shared plugin descriptors only.

## Required Checks

- Source-rule policy tests and local quality gate.
