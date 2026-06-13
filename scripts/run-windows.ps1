Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$flutterBin = Join-Path $env:USERPROFILE 'dev/flutter/bin'

if ((Test-Path -LiteralPath $flutterBin) -and
    ($env:Path -split ';' | Where-Object { $_ -eq $flutterBin } | Measure-Object).Count -eq 0) {
  $env:Path = "$flutterBin;$env:Path"
}

$env:NO_PROXY = 'localhost,127.0.0.1,::1'
$env:no_proxy = $env:NO_PROXY

Push-Location (Join-Path $root 'app')
try {
  flutter run -d windows
} finally {
  Pop-Location
}
