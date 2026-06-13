Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$rustRoot = Join-Path $root 'rust'
$dllPath = Join-Path $rustRoot 'target/debug/yneko_api.dll'

Push-Location $rustRoot
try {
  cargo build -p yneko-api
} finally {
  Pop-Location
}

if (-not (Test-Path -LiteralPath $dllPath)) {
  throw "Rust bridge DLL was not produced at $dllPath"
}

Write-Host "Built Rust bridge DLL: $dllPath"
