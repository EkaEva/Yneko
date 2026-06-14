Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'README.md',
  '.github/workflows/ci.yml',
  'third_party/SOURCES.md',
  'scripts/doctor-fix.ps1',
  'scripts/local-quality-gate.ps1',
  'rust/Cargo.toml',
  'app/pubspec.yaml',
  'app/android/app/build.gradle.kts',
  'app/android/app/src/main/kotlin/com/yneko/anime/MainActivity.kt',
  'app/ios/Runner.xcodeproj/project.pbxproj',
  'app/windows/CMakeLists.txt'
)

foreach ($file in $requiredFiles) {
  $path = Join-Path $root $file
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Required file missing: $file"
  }
}

$forbiddenPatterns = @(
  'tauri',
  'webview2',
  'directcomposition',
  '@tauri-apps',
  'react-dom'
)

$scanFiles = Get-ChildItem -Path $root -Recurse -File |
  Where-Object {
    $_.FullName -notmatch '\\.git\\' -and
    $_.FullName -notmatch '\\target\\' -and
    $_.FullName -notlike (Join-Path $root 'scripts/policy-check.ps1') -and
    $_.Extension -in @('.yaml', '.yml', '.toml', '.dart', '.rs', '.ps1')
  }

foreach ($file in $scanFiles) {
  $relative = Resolve-Path -LiteralPath $file.FullName -Relative
  $text = Get-Content -Raw -LiteralPath $file.FullName
  foreach ($pattern in $forbiddenPatterns) {
    if ($text.ToLowerInvariant().Contains($pattern)) {
      throw "Forbidden legacy stack term '$pattern' found in $relative"
    }
  }
}

$sources = Get-Content -Raw -LiteralPath (Join-Path $root 'third_party/SOURCES.md')
foreach ($dependency in @('flutter_riverpod', 'flutter_rust_bridge', 'media_kit', 'serde', 'sqlx')) {
  if (-not $sources.Contains($dependency)) {
    throw "Dependency register missing $dependency"
  }
}

$forbiddenTopLevelFlutterDirs = @('application', 'presentation', 'domain')
foreach ($dir in $forbiddenTopLevelFlutterDirs) {
  $path = Join-Path $root "app/lib/src/$dir"
  if (Test-Path -LiteralPath $path) {
    throw "Forbidden top-level Flutter garbage-bin directory exists: app/lib/src/$dir"
  }
}

$requiredFeatures = @(
  'shell',
  'home',
  'search',
  'watch',
  'sources',
  'library',
  'history',
  'mine',
  'settings',
  'danmaku'
)

foreach ($feature in $requiredFeatures) {
  foreach ($file in @('README.md', 'index.dart')) {
    $path = Join-Path $root "app/lib/src/features/$feature/$file"
    if (-not (Test-Path -LiteralPath $path)) {
      throw "Feature boundary missing ${file}: $feature"
    }
  }
}

foreach ($plugin in @('source_rules', 'danmaku_sources', 'subtitle_sources', 'player_processors')) {
  $path = Join-Path $root "app/lib/src/plugins/$plugin/README.md"
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Plugin boundary missing README: $plugin"
  }
}

$generatedPlatformDirs = Get-ChildItem -Directory -LiteralPath (Join-Path $root 'app') |
  Where-Object { $_.Name -in @('android', 'ios', 'windows', 'linux', 'macos', 'web') } |
  Select-Object -ExpandProperty Name

$expectedPlatformDirs = @('android', 'ios', 'windows')
foreach ($platform in $expectedPlatformDirs) {
  if ($generatedPlatformDirs -notcontains $platform) {
    throw "Expected Flutter platform runner missing: $platform"
  }
}
foreach ($platform in $generatedPlatformDirs) {
  if ($expectedPlatformDirs -notcontains $platform) {
    throw "Unapproved Flutter platform runner exists: $platform"
  }
}

$androidGradle = Get-Content -Raw -LiteralPath (Join-Path $root 'app/android/app/build.gradle.kts')
if (-not $androidGradle.Contains('namespace = "com.yneko.anime"')) {
  throw 'Android namespace must be com.yneko.anime'
}
if (-not $androidGradle.Contains('applicationId = "com.yneko.anime"')) {
  throw 'Android applicationId must be com.yneko.anime'
}

$androidActivity = Get-Content -Raw -LiteralPath (Join-Path $root 'app/android/app/src/main/kotlin/com/yneko/anime/MainActivity.kt')
if (-not $androidActivity.Contains('package com.yneko.anime')) {
  throw 'Android MainActivity package must be com.yneko.anime'
}

$iosProject = Get-Content -Raw -LiteralPath (Join-Path $root 'app/ios/Runner.xcodeproj/project.pbxproj')
if ($iosProject.Contains('PRODUCT_BUNDLE_IDENTIFIER = com.yneko.yneko')) {
  throw 'iOS project still contains old com.yneko.yneko bundle identifier'
}
if (-not $iosProject.Contains('PRODUCT_BUNDLE_IDENTIFIER = com.yneko.anime;')) {
  throw 'iOS Runner bundle identifier must be com.yneko.anime'
}

Write-Host 'Policy check passed.'
