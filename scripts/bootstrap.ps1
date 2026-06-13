Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

Write-Host '== Rust versions =='
rustc --version
cargo --version

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Warning 'Flutter is not available on PATH. Install Flutter before running Flutter bootstrap.'
  exit 0
}

Write-Host '== Flutter doctor =='
flutter doctor

Write-Host '== Flutter pub get =='
Push-Location (Join-Path $root 'app')
try {
  flutter pub get
} finally {
  Pop-Location
}

