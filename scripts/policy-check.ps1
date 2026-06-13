Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'PROJECT.md',
  'AGENTS.md',
  'AI_RULES.md',
  'CONTEXT/agent-entry.md',
  'CONTEXT/architecture.md',
  'CONTEXT/flutter-ui.md',
  'CONTEXT/rust-backend.md',
  'CONTEXT/source-rules.md',
  'CONTEXT/player.md',
  'CONTEXT/storage.md',
  'CONTEXT/testing.md',
  'CONTEXT/licensing.md',
  'CONTEXT/github-sync.md',
  'third_party/SOURCES.md',
  'rust/Cargo.toml',
  'app/pubspec.yaml'
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

Write-Host 'Policy check passed.'
