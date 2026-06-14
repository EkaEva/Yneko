# sources Feature

## Responsibilities

- Source package management UI for user-imported declarative playback rules.
- Text and URL import flows for V1 YAML/JSON packages.
- Shared rule-source state consumed by settings and watch presentation.

## Public Contracts

- Public Dart exports are limited to source package application providers and
  presentation/sources_page.dart through index.dart.
- Widgets call `SourcePackagesController`; generated bridge calls stay behind
  the backend port.

## Public Index Export List

- application/source_packages_controller.dart
- presentation/sources_page.dart

## Forbidden

- Executing third-party source code.
- Generated bridge calls from widgets.
- Cross-feature deep imports; consume another feature through its index.dart.

## Allowed Dependencies

- Shared contracts.
- Documented infrastructure ports.
- Other feature public index.dart files when route composition requires them.

## Required Checks

- flutter analyze
- flutter test
- pwsh -File scripts/local-quality-gate.ps1
