# settings Feature

## Responsibilities

- Settings UI placeholder.

## Public Contracts

- Settings panel navigation state is exposed through the feature application
  controller so the shell back button can return from a settings detail panel
  to the settings root page.
- Settings UI is exported through presentation/settings_page.dart.

## Public Index Export List

- application/settings_navigation_controller.dart
- presentation/settings_page.dart

## Forbidden

- Direct platform mutation without infrastructure ports.
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
