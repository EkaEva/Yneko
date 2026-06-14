<p align="center">
  <img src="app/assets/icons/Yneko/app-icon.png" alt="Yneko" width="120" height="120">
</p>

<h1 align="center">Yneko</h1>

<p align="center">
  一只 Windows 优先的 Flutter + Rust 番剧桌面客户端。
  <br>
  A Windows-first Flutter + Rust desktop client for anime discovery, source rules, and playback.
</p>

<p align="center">
  <a href="https://github.com/EkaEva/Yneko/actions"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/EkaEva/Yneko/ci.yml?label=ci"></a>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white">
  <img alt="Rust" src="https://img.shields.io/badge/Rust-1.94.1-000000?logo=rust&logoColor=white">
  <img alt="Platform" src="https://img.shields.io/badge/Windows-first-0078D4?logo=windows&logoColor=white">
  <img alt="FRB" src="https://img.shields.io/badge/flutter__rust__bridge-2.11.1-ff6f91">
  <img alt="Status" src="https://img.shields.io/badge/status-preview-fb7299">
</p>

<p align="center">
  <a href="#中文">中文</a> | <a href="#english">English</a>
</p>

---

## 中文

Yneko 是一次面向桌面体验的 Flutter + Rust 重启项目。它不是旧 Tauri / React 项目的逐文件迁移，而是在保留原项目视觉语言和交互方向的基础上，重新设计应用边界、播放器边界、规则源边界和本地持久化模型。

当前版本以 Windows 桌面为第一目标，围绕一个清晰的主流程推进：

```text
Bangumi 元数据 -> 首页 / 搜索 -> Watch 播放页 -> 规则源解析 -> 播放器适配器
```

Yneko 使用 Bangumi 作为番剧元数据入口，使用用户导入的声明式规则源解析播放候选，并通过 Flutter 内的 `WatchRoute` 打开单窗口播放工作台。项目不会内置公开播放源，不保存私密凭据，也不会加入脚本执行、登录绕过、付费绕过、DRM 绕过或反爬绕过能力。

### 项目定位

- **桌面优先**：优先打磨 Windows 桌面端的标题栏、侧边栏、搜索、设置、规则管理和播放页体验。
- **视觉复刻**：参考旧项目 Yneko 的页面结构、按钮动效、加载动画、设置项卡片、播放控件和规则源面板。
- **安全规则源**：规则源采用声明式 YAML / JSON，不执行第三方脚本，不保存账号凭据。
- **清晰边界**：Flutter 负责界面和状态编排，Rust 负责元数据、规则解析、存储和桥接 facade。
- **可测试维护**：项目包含本地质量门、Flutter widget tests、Rust tests、policy check 和 CI。

### 当前状态

Yneko 仍处于预览开发阶段。界面和基础闭环已经可运行，部分业务能力仍在逐步接入真实数据。

| 模块 | 状态 | 说明 |
| --- | --- | --- |
| 桌面 Shell | 已实现 | 自定义标题栏、侧边栏、顶部搜索、主题切换、窗口按钮 |
| 首页 | 已实现 | 推荐、时间表、榜单入口，番剧卡片直接进入 Watch 页 |
| 搜索 | 已实现 | Bangumi 搜索结果页、横向卡片、加载 / 错误 / 空状态 |
| 我的 | UI 完善中 | 追番 / 历史 / 缓存壳，已移除假列表数据 |
| 设置 | UI 完善中 | 根页面、二级设置页、规则管理、配色方案弹窗等已复刻 |
| Watch 播放页 | 已实现基础壳 | 单窗口全屏工作台、左侧播放器、右侧剧集 / 系列 / 规则源 |
| 规则源 | V1 闭环 | 文本 / URL / 外部仓库导入，规则组，启停，解析候选 |
| 播放器 | 基础适配 | `media_kit` 通过 `PlayerAdapter` 隔离，播放控件使用项目 SVG |
| 弹幕 | 接口预留 | UI 与设置入口存在，远程弹幕源不在当前 V1 范围 |
| 下载 / 离线缓存 | 暂不启用 | 设置入口保留，真实下载不在当前 V1 范围 |

### 功能概览

#### 桌面界面

- 自定义 Windows 标题栏，最小化、最大化 / 还原、关闭按钮复刻旧项目交互。
- 左侧三入口侧边栏：首页、我的、设置。
- 顶部全局搜索框、品牌标题和日夜主题切换。
- 全局按钮、图标按钮、hover 菜单、分段控件和设置项 hover 状态统一去除 Flutter Material 默认深灰闪烁。
- MiSansYneko 字体子集，配合 Microsoft YaHei UI / Segoe UI 等系统 fallback。

#### 首页与搜索

- 首页包含推荐、时间表和榜单等桌面布局。
- 番剧卡片点击后直接进入主窗口内的 `WatchRoute`，不再经过旧式番剧详情页。
- 搜索页保留全局搜索入口，并渲染旧项目风格的横向结果卡片、返回按钮、结果数量、加载、错误和空状态。

#### Watch 播放页

- 单窗口内播放，不再创建第二系统窗口。
- 隐藏普通 Shell chrome，让播放页独占主窗口工作区。
- 左侧为黑色视频区域和播放器控制条。
- 右侧包含剧集、系列、规则源等 tab。
- 支持剧集列表 / 网格切换、倒序、规则组选择、源候选展示和基础播放控制。
- 播放按钮、上一集 / 下一集、弹幕、音量、设置等主控图标使用项目内 `assets/player-icons/*.svg`。

#### 规则源与规则管理

Yneko 的规则源是用户导入的声明式包，当前支持：

- 粘贴文本导入 YAML / JSON 规则。
- URL 导入规则文本。
- 外部仓库订阅导入，内置默认 KazumiRules 订阅入口。
- 规则组管理、规则源启停、删除、编辑入口。
- 仓库索引刷新、搜索、全选 / 取消全选、批量导入。
- Watch 页规则源面板按当前番剧和剧集解析播放候选。

默认 KazumiRules 仅作为外部订阅入口保存，项目不捆绑公开规则源内容。用户需要主动刷新、选择并导入规则。

#### 安全规则源策略

规则包必须是声明式 manifest + YAML / JSON。禁止内容包括：

- 脚本、可执行代码或动态执行字段。
- Cookie、Token、账号、密码或其它凭据。
- DRM 绕过、登录绕过、付费绕过或反爬绕过字段。
- UI、播放器或存储层中的源站特例硬编码。

Rust 规则引擎采用 fail closed 策略：发现危险字段或无法验证的结构时拒绝导入，并返回安全诊断。

### 技术栈

| 层 | 技术 |
| --- | --- |
| UI | Flutter |
| 状态管理 | Riverpod |
| 后端逻辑 | Rust 1.94.1 / edition 2024 |
| Flutter / Rust 桥接 | flutter_rust_bridge 2.11.1 |
| 本地存储 | SQLite / sqlx |
| 播放 | media_kit，经 `PlayerAdapter` 隔离 |
| 元数据 | Bangumi API |
| CI / 本地质量门 | GitHub Actions + PowerShell scripts |

### 架构概览

```text
Yneko
├─ app/                         Flutter application
│  ├─ lib/src/features/          Feature modules
│  │  ├─ shell/                  App shell, topbar, side rail, route state
│  │  ├─ home/                   Home tabs and anime cards
│  │  ├─ search/                 Search result page
│  │  ├─ mine/                   Mine page shell
│  │  ├─ settings/               Settings root and detail pages
│  │  ├─ sources/                Source package UI and providers
│  │  └─ watch/                  Main-window playback route
│  ├─ lib/src/shared/            Theme, UI components, assets, domain models
│  ├─ lib/src/infrastructure/    FRB bindings, backend port, player adapter
│  └─ lib/src/plugins/           Source-rule extension boundary docs
├─ rust/
│  └─ crates/
│     ├─ yneko-core              Pure models and shared errors
│     ├─ yneko-metadata          Bangumi client and mapping
│     ├─ yneko-source-rules      Declarative source-rule schema and parsing
│     ├─ yneko-storage           SQLite migrations and repositories
│     └─ yneko-api               flutter_rust_bridge facade
├─ scripts/                      Bootstrap, doctor, run, policy, quality gate
├─ third_party/                  Dependency and asset register
└─ .github/workflows/            CI
```

### Flutter 边界

- Widgets 只负责渲染 UI 和发送用户意图。
- Widgets 不直接调用 generated FRB bindings。
- Feature application providers 负责业务流和状态。
- Infrastructure 负责桥接、播放器和平台适配。
- Cross-feature 引用应通过目标 feature 的 `index.dart`。

### Rust 边界

```text
yneko-core          -> no internal dependencies
yneko-metadata      -> yneko-core
yneko-source-rules  -> yneko-core
yneko-storage       -> yneko-core
yneko-api           -> yneko-core + metadata + source-rules + storage
```

`yneko-api` 是唯一对 Flutter 暴露的 Rust facade。低层 crate 不依赖 Flutter、Dart 或 app shell。

### 开发环境

推荐环境：

- Windows 10 / 11
- Flutter stable SDK
- Rust toolchain，由 `rust-toolchain.toml` 固定
- Visual Studio，安装 Desktop development with C++ workload
- PowerShell 7 (`pwsh`)
- Android SDK，仅在需要 Android 检查或构建时安装

如果 Flutter 安装在常见本地路径，可在新 PowerShell 会话中加入 PATH：

```powershell
$env:Path = "$env:USERPROFILE\dev\flutter\bin;$env:Path"
```

初始化依赖：

```powershell
pwsh -File scripts/bootstrap.ps1
```

检查开发环境：

```powershell
pwsh -File scripts/doctor-fix.ps1
```

需要接受 Android SDK licenses 时：

```powershell
pwsh -File scripts/doctor-fix.ps1 -AcceptAndroidLicenses
```

### 运行

Windows 桌面：

```powershell
pwsh -File scripts/run-windows.ps1
```

该脚本会先构建 Rust bridge DLL，再启动 Flutter Windows 应用。若 Flutter 提示桌面插件需要 symlink support，请启用 Windows Developer Mode：

```powershell
start ms-settings:developers
```

### 常用开发命令

Flutter：

```powershell
cd app
flutter analyze
flutter test
```

Rust：

```powershell
cargo fmt --manifest-path rust/Cargo.toml --all --check
cargo test --manifest-path rust/Cargo.toml --workspace
cargo clippy --manifest-path rust/Cargo.toml --workspace --all-targets -- -D warnings
```

完整本地质量门：

```powershell
pwsh -File scripts/local-quality-gate.ps1
```

质量门会运行 policy check、Rust format / test / clippy、Flutter analyze / test。

### 字体子集

Yneko 默认使用 `MiSansYneko`，这是面向当前 UI 文案裁剪的 MiSans 子集。添加大量新 UI 文案后可重新生成：

```powershell
pwsh -File scripts/font-subset.ps1
```

### CI

GitHub Actions 会在 push、pull request 和定时任务中运行：

- Policy check
- Rust format / tests / clippy
- Flutter dependency install / analyze / tests

CI 不需要私密规则源凭据，也不应保存私密播放 URL。

### 第三方与资产登记

所有直接依赖、运行时资产、项目资产和重要参考来源都记录在：

```text
third_party/SOURCES.md
```

新增依赖、字体、图标、图片、复制资产或重要实现参考时，请同步更新该文件。

### 个人数据与安全

请不要提交以下内容：

- 私密规则源、私密仓库地址或私密播放 URL
- Cookie、Token、账号、密码或其它凭据
- 本地数据库、日志、缓存或构建产物
- 私人下载内容、封面缓存或媒体文件
- `.env` 或本地环境文件

Yneko 的规则源能力只用于声明式匹配和解析。请遵守相关网站、API、内容平台和规则源仓库的使用条款。

### 与旧项目的关系

当前仓库是 Yneko 的 Flutter + Rust clean restart。旧 Tauri / React 项目仅作为视觉、交互和产品方向参考，不作为运行时依赖，也不是逐文件迁移。

### 许可

Rust workspace metadata 当前声明为：

```text
MIT OR Apache-2.0
```

项目依赖、字体、图标、播放器运行时和其它第三方来源请以 `third_party/SOURCES.md` 为准。发布或二次分发时，请同时遵守 Flutter、Rust crate、Dart package、media runtime、字体和图标资产的许可要求。

### 致谢

- [Bangumi](https://bangumi.tv/)，提供番剧元数据生态。
- [Flutter](https://flutter.dev/) 与 [Rust](https://www.rust-lang.org/)，支撑当前跨端 UI 与本地后端架构。
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge)，连接 Flutter 与 Rust。
- [media_kit](https://github.com/media-kit/media-kit)，提供播放器基础能力。
- KazumiRules 相关生态，为外部规则仓库订阅入口提供参考方向。

---

## English

Yneko is a Flutter + Rust clean restart of a desktop anime client. It keeps the visual direction and interaction language of the earlier Yneko project, while rebuilding the application around explicit UI, player, source-rule, storage, and bridge boundaries.

The current target is Windows desktop. The core flow is:

```text
Bangumi metadata -> Home / Search -> Watch page -> Source-rule resolution -> Player adapter
```

Yneko uses Bangumi as the metadata source, user-imported declarative source packages for playback candidates, and a single-window Flutter `WatchRoute` for the playback workspace. The project does not bundle public playback sources, does not store private credentials, and does not add script execution, login bypass, paywall bypass, DRM bypass, or anti-scraping bypass behavior.

### Project Goals

- **Desktop first**: polish the Windows title bar, side rail, search, settings, source management, and watch-page workflows.
- **Faithful UI direction**: replicate the former Yneko visual language, button states, loading motion, settings cards, player controls, and source panels.
- **Safe source rules**: source packages are declarative YAML / JSON and cannot execute third-party scripts.
- **Clear boundaries**: Flutter owns UI and orchestration; Rust owns metadata, source rules, storage, and bridge facade logic.
- **Testable maintenance**: local quality gates, Flutter widget tests, Rust tests, policy checks, and CI are part of the workflow.

### Current Status

Yneko is still in preview development. The UI shell and the first source-to-playback loop are in place; some product data remains mocked or interface-only.

| Area | Status | Notes |
| --- | --- | --- |
| Desktop shell | Implemented | Custom title bar, side rail, top search, theme toggle, window buttons |
| Home | Implemented | Recommendation, calendar, ranking surfaces; cards open Watch directly |
| Search | Implemented | Bangumi results, horizontal cards, loading / error / empty states |
| Mine | UI in progress | Follow / history / cache shell, fake list data removed |
| Settings | UI in progress | Root page, detail pages, source management, color-scheme dialog |
| Watch page | Base implemented | Single-window playback workspace with player and right-side panels |
| Source rules | V1 loop | Text / URL / repository import, groups, enable / disable, candidate resolution |
| Player | Base adapter | `media_kit` is isolated behind `PlayerAdapter`; controls use project SVG assets |
| Danmaku | Interface-only | UI and settings placeholders exist; remote danmaku integration is outside current V1 |
| Downloads / offline cache | Disabled for V1 | Settings entries are visible, real downloads are not part of current V1 |

### Feature Overview

#### Desktop UI

- Custom Windows title bar with Yneko-style minimize, maximize / restore, and close buttons.
- Three-entry side rail: Home, Mine, Settings.
- Top search, brand title, and day / night theme toggle.
- Shared buttons, icon buttons, hover menus, segmented controls, and setting rows avoid Flutter Material's default dark overlay flashes.
- `MiSansYneko` font subset with system fallback fonts.

#### Home And Search

- Home tabs for recommendations, calendar, and rankings.
- Anime cards navigate directly to the main-window Watch page.
- Search results use the old-project horizontal-card layout with back button, count text, loading, error, and empty states.

#### Watch Page

- Playback happens inside the main app window, not in a second native window.
- The normal shell rail and topbar are hidden while Watch owns the workspace.
- Left side: black video surface and player controls.
- Right side: episode, series, and source-rule tabs.
- Episode list / grid modes, reverse order, rule-group selection, source candidates, and base player controls are available.
- Player controls use project-owned SVG assets from `assets/player-icons/*.svg`.

#### Source Rules And Management

Yneko source packages are user-imported declarative packages. Current support includes:

- Paste YAML / JSON source text.
- Import source text from URL.
- Import from external repository subscriptions, with a default KazumiRules subscription entry.
- Rule groups, source enable / disable, delete, and edit entry points.
- Repository index refresh, search, select all / clear, and batch import.
- Watch-page source panel resolves playback candidates for the selected subject and episode.

The default KazumiRules entry is only an external subscription entry. Yneko does not bundle public source package content. Users must explicitly refresh, select, and import rules.

#### Safe Source-Rule Policy

Source packages must be declarative manifest + YAML / JSON. They must not contain:

- Scripts, executable code, or dynamic execution fields.
- Cookies, tokens, accounts, passwords, or credentials.
- DRM bypass, login bypass, paywall bypass, or anti-scraping bypass fields.
- Source-specific branches in UI, player, or storage code.

The Rust rule engine fails closed: dangerous fields or unverifiable structures are rejected with privacy-safe diagnostics.

### Tech Stack

| Layer | Technology |
| --- | --- |
| UI | Flutter |
| State | Riverpod |
| Backend logic | Rust 1.94.1 / edition 2024 |
| Flutter / Rust bridge | flutter_rust_bridge 2.11.1 |
| Local storage | SQLite / sqlx |
| Playback | media_kit behind `PlayerAdapter` |
| Metadata | Bangumi API |
| Checks | GitHub Actions + PowerShell scripts |

### Architecture

```text
Yneko
├─ app/                         Flutter application
│  ├─ lib/src/features/          Feature modules
│  │  ├─ shell/                  App shell, topbar, side rail, route state
│  │  ├─ home/                   Home tabs and anime cards
│  │  ├─ search/                 Search result page
│  │  ├─ mine/                   Mine page shell
│  │  ├─ settings/               Settings root and detail pages
│  │  ├─ sources/                Source package UI and providers
│  │  └─ watch/                  Main-window playback route
│  ├─ lib/src/shared/            Theme, UI components, assets, domain models
│  ├─ lib/src/infrastructure/    FRB bindings, backend port, player adapter
│  └─ lib/src/plugins/           Source-rule extension boundary docs
├─ rust/
│  └─ crates/
│     ├─ yneko-core              Pure models and shared errors
│     ├─ yneko-metadata          Bangumi client and mapping
│     ├─ yneko-source-rules      Declarative source-rule schema and parsing
│     ├─ yneko-storage           SQLite migrations and repositories
│     └─ yneko-api               flutter_rust_bridge facade
├─ scripts/                      Bootstrap, doctor, run, policy, quality gate
├─ third_party/                  Dependency and asset register
└─ .github/workflows/            CI
```

### Flutter Boundaries

- Widgets render UI and emit user intent only.
- Widgets do not call generated FRB bindings directly.
- Feature application providers own business flow and state.
- Infrastructure owns bridge, player, and platform adapters.
- Cross-feature imports should go through the target feature's `index.dart`.

### Rust Boundaries

```text
yneko-core          -> no internal dependencies
yneko-metadata      -> yneko-core
yneko-source-rules  -> yneko-core
yneko-storage       -> yneko-core
yneko-api           -> yneko-core + metadata + source-rules + storage
```

`yneko-api` is the only Rust facade exported to Flutter. Lower crates do not depend on Flutter, Dart, or app shell code.

### Development Environment

Recommended tools:

- Windows 10 / 11
- Flutter stable SDK
- Rust toolchain pinned by `rust-toolchain.toml`
- Visual Studio with Desktop development with C++ workload
- PowerShell 7 (`pwsh`)
- Android SDK only when Android checks or builds are needed

If Flutter is installed at the common local path, add it to PATH in a new PowerShell session:

```powershell
$env:Path = "$env:USERPROFILE\dev\flutter\bin;$env:Path"
```

Bootstrap dependencies:

```powershell
pwsh -File scripts/bootstrap.ps1
```

Check the development environment:

```powershell
pwsh -File scripts/doctor-fix.ps1
```

Accept Android SDK licenses if needed:

```powershell
pwsh -File scripts/doctor-fix.ps1 -AcceptAndroidLicenses
```

### Running

Windows desktop:

```powershell
pwsh -File scripts/run-windows.ps1
```

The script builds the Rust bridge DLL first and then starts the Flutter Windows app. If Flutter reports that desktop plugins require symlink support, enable Windows Developer Mode:

```powershell
start ms-settings:developers
```

### Common Development Commands

Flutter:

```powershell
cd app
flutter analyze
flutter test
```

Rust:

```powershell
cargo fmt --manifest-path rust/Cargo.toml --all --check
cargo test --manifest-path rust/Cargo.toml --workspace
cargo clippy --manifest-path rust/Cargo.toml --workspace --all-targets -- -D warnings
```

Full local quality gate:

```powershell
pwsh -File scripts/local-quality-gate.ps1
```

The gate runs policy checks, Rust format / test / clippy, and Flutter analyze / tests.

### Font Subset

Yneko uses `MiSansYneko`, a subset generated for current UI copy. Regenerate it after adding significant UI text:

```powershell
pwsh -File scripts/font-subset.ps1
```

### CI

GitHub Actions runs on push, pull request, and scheduled health checks:

- Policy check
- Rust format / tests / clippy
- Flutter dependency install / analyze / tests

CI does not require private source credentials and must not store private playback URLs.

### Third-Party Register

Direct dependencies, runtime assets, project assets, and substantial references are tracked in:

```text
third_party/SOURCES.md
```

Update it whenever adding dependencies, fonts, icons, images, copied assets, or major references.

### Personal Data And Security

Do not commit:

- Private source rules, private repository URLs, or private playback URLs
- Cookies, tokens, accounts, passwords, or credentials
- Local databases, logs, caches, or build outputs
- Private downloads, cover caches, or media files
- `.env` or local environment files

Yneko source-rule capability is for declarative matching and extraction only. Please follow the terms of relevant websites, APIs, content platforms, and source-rule repositories.

### Relationship To The Earlier Project

This repository is the Flutter + Rust clean restart of Yneko. The earlier Tauri / React project is reference material for visuals, interaction, and product direction only. It is not a runtime dependency and this is not a file-by-file migration.

### License

The Rust workspace metadata currently declares:

```text
MIT OR Apache-2.0
```

Dependencies, fonts, icons, media runtime assets, and other third-party sources are documented in `third_party/SOURCES.md`. Redistribution should follow the licenses of Flutter, Rust crates, Dart packages, media runtimes, fonts, and icon assets.

### Thanks

- [Bangumi](https://bangumi.tv/), for the anime metadata ecosystem.
- [Flutter](https://flutter.dev/) and [Rust](https://www.rust-lang.org/), for the current UI and local backend architecture.
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge), for Flutter / Rust interop.
- [media_kit](https://github.com/media-kit/media-kit), for playback foundations.
- The KazumiRules ecosystem, for informing the external rule-repository subscription workflow.
