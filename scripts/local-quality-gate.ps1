param(
  [switch]$PolicyOnly,
  [switch]$SkipFlutter
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$failed = $false

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$Script
  )

  Write-Host "== $Name =="
  try {
    & $Script
    if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
      throw "Command exited with code $LASTEXITCODE"
    }
  } catch {
    Write-Error "$Name failed: $_"
    $script:failed = $true
  }
}

Invoke-Step 'Policy check' {
  pwsh -File (Join-Path $root 'scripts/policy-check.ps1')
}

if (-not $PolicyOnly) {
  Invoke-Step 'Rust format' {
    cargo fmt --manifest-path (Join-Path $root 'rust/Cargo.toml') --all --check
  }

  Invoke-Step 'Rust test' {
    cargo test --manifest-path (Join-Path $root 'rust/Cargo.toml') --workspace
  }

  Invoke-Step 'Rust clippy' {
    cargo clippy --manifest-path (Join-Path $root 'rust/Cargo.toml') --workspace --all-targets -- -D warnings
  }

  if (-not $SkipFlutter) {
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
      Invoke-Step 'Flutter analyze' {
        $env:NO_PROXY = 'localhost,127.0.0.1,::1'
        $env:no_proxy = $env:NO_PROXY
        Push-Location (Join-Path $root 'app')
        try {
          flutter pub get
          flutter analyze
        } finally {
          Pop-Location
        }
      }

      Invoke-Step 'Flutter test' {
        $env:NO_PROXY = 'localhost,127.0.0.1,::1'
        $env:no_proxy = $env:NO_PROXY
        Push-Location (Join-Path $root 'app')
        try {
          flutter test
        } finally {
          Pop-Location
        }
      }
    } else {
      Write-Warning 'Flutter is not available on PATH; skipping Flutter checks locally.'
    }
  }
}

if ($failed) {
  exit 1
}

Write-Host 'Local quality gate completed.'
