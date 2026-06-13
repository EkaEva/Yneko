# Third-Party Source Register

Record every third-party runtime asset, copied asset, substantial implementation
reference, generated source, and new dependency decision here.

## Policy

- Allowed by default: MIT, Apache-2.0, BSD, ISC, and equivalent permissive
  licenses.
- Forbidden by default: GPL, AGPL, SSPL, unknown license, no-license code, and
  copied snippets without provenance.
- LGPL requires dynamic linking/loading and a local note describing how
  replacement is possible.
- Never copy implementation code from anime source, parser, player, danmaku, or
  scraping projects unless provenance and license are compatible.

## Direct Dart And Flutter Dependencies

| Name | Version / Range | Source | License | Use | Integration |
|---|---|---|---|---|---|
| flutter | SDK | https://flutter.dev | BSD-3-Clause | App UI runtime | Pinned by local Flutter SDK once installed. |
| flutter_riverpod | `^3.0.3` | https://pub.dev/packages/flutter_riverpod | MIT | Application state and dependency wiring | Presentation consumes providers; widgets do not own business logic. |
| media_kit | `^1.2.6` | https://pub.dev/packages/media_kit | MIT | Cross-platform media playback core | Used only behind `infrastructure/player`. |
| media_kit_video | `^1.3.1` | https://pub.dev/packages/media_kit_video | MIT | Flutter video widget for media_kit | Used only behind `infrastructure/player`. |
| media_kit_libs_windows_video | `^1.0.11` | https://pub.dev/packages/media_kit_libs_windows_video | MIT | Windows media_kit runtime libraries | Runtime dependency for Windows desktop playback. |
| flutter_rust_bridge | `^2.11.1` | https://pub.dev/packages/flutter_rust_bridge | MIT | Flutter/Rust bridge runtime and codegen integration | Generated bindings stay under infrastructure. |
| flutter_svg | `^2.3.0` | https://pub.dev/packages/flutter_svg | MIT | Render project SVG logo and player icons in Flutter | Presentation uses paths from `YnekoAssets`; assets remain declarative image files. |
| window_manager | `^0.5.1` | https://pub.dev/packages/window_manager | MIT | Hide native desktop title bar and expose desktop window controls | Wrapped by `infrastructure/platform/window_chrome`; widgets call the adapter only. |

## Project-Owned Runtime Assets

| Name | Source | License / Provenance | Use | Integration |
|---|---|---|---|---|
| Yneko logo and platform icons | `app/assets/icons/Yneko`, generated runner icon locations | Project-owned Yneko assets | App branding, Windows icon, Android launcher icon, iOS icon, Flutter UI logo | Exposed through `YnekoAssets` and platform runner resources. |
| Yneko player SVG icons | `app/assets/player-icons` | Project-owned Yneko assets | Player control visuals | Exposed via `YnekoAssets`. |
| Yneko empty/back-to-top illustrations | `app/assets/illustrations` | Project-owned Yneko assets | Empty states and back-to-top affordance | Exposed via `YnekoAssets`. |

## Fonts

| Name | Source | License / Provenance | Use | Integration |
|---|---|---|---|---|
| MiSansYneko subset fonts | Generated from MiSans Regular, Semibold, and Bold source fonts using `scripts/font-subset.ps1` | MiSans free commercial-use font; source package mirror `boyan01/mi_sans_font` is MIT | Default Flutter UI font | Generated files live in `app/assets/fonts/misans`; full source fonts stay local under ignored `tools/fonts/source/misans`. |

## Direct Rust Dependencies

| Name | Version / Range | Source | License | Use | Integration |
|---|---|---|---|---|---|
| serde | `1` | https://github.com/serde-rs/serde | MIT OR Apache-2.0 | Serialization contracts | Workspace dependency. |
| serde_json | `1` | https://github.com/serde-rs/json | MIT OR Apache-2.0 | JSON contracts | Workspace dependency. |
| thiserror | `2` | https://github.com/dtolnay/thiserror | MIT OR Apache-2.0 | Error types | Workspace dependency. |
| reqwest | `0.12` | https://github.com/seanmonstar/reqwest | MIT OR Apache-2.0 | Bangumi and source repository HTTP client | Restricted to backend crates. |
| tokio | `1` | https://github.com/tokio-rs/tokio | MIT | Async runtime | Used by backend async APIs. |
| sqlx | `0.8` | https://github.com/launchbadge/sqlx | MIT OR Apache-2.0 | SQLite persistence | Restricted to `yneko-storage`. |
| url | `2` | https://github.com/servo/rust-url | MIT OR Apache-2.0 | URL validation | Source repository and playback contracts. |
| regex | `1` | https://github.com/rust-lang/regex | MIT OR Apache-2.0 | Declarative matching support | Source-rule crate only unless approved. |
| scraper | `0.24` | https://github.com/causal-agent/scraper | ISC | Declarative HTML extraction support | Source-rule crate only. |
| yaml_serde | `0.10` | https://github.com/yaml/yaml-serde | MIT OR Apache-2.0 | YAML source packages | Source-rule crate only. |
| flutter_rust_bridge | `2.11.1` | https://github.com/fzyzcjy/flutter_rust_bridge | MIT | Rust bridge macros/runtime | Restricted to `yneko-api`. |
