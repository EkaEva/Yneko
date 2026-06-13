# Source Rules Context

Playback sources are user-imported declarative packages. The app ships no
public source catalog.

## Package Shape

V1 source packages are manifest plus YAML/JSON rule definitions.

## Forbidden

- Scripts or executable code.
- Credentials or session secrets.
- DRM bypass, login bypass, paywall bypass, or anti-scraping bypass behavior.
- Source-specific player or UI branches.

## Required Behavior

Invalid packages fail closed with privacy-safe diagnostics. Rule capabilities
must be generic and documented before use.

