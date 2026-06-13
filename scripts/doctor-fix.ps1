param(
  [switch]$AcceptAndroidLicenses,
  [switch]$InstallVisualStudioComponents
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$flutterBin = Join-Path $env:USERPROFILE 'dev/flutter/bin'
$vsInstallerRoot = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer'
$vswhere = Join-Path $vsInstallerRoot 'vswhere.exe'
$vsInstaller = Join-Path $vsInstallerRoot 'vs_installer.exe'

$requiredVsComponents = @(
  'Microsoft.VisualStudio.Workload.NativeDesktop',
  'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
  'Microsoft.VisualStudio.Component.VC.CMake.Project',
  'Microsoft.VisualStudio.Component.Windows11SDK.26100'
)

function Add-FlutterToPath {
  if ((Test-Path -LiteralPath $flutterBin) -and
      ($env:Path -split ';' | Where-Object { $_ -eq $flutterBin } | Measure-Object).Count -eq 0) {
    $env:Path = "$flutterBin;$env:Path"
  }
}

function Set-LocalProxyBypass {
  $localBypass = 'localhost,127.0.0.1,::1'
  $env:NO_PROXY = $localBypass
  $env:no_proxy = $localBypass
  Write-Host "NO_PROXY set for this shell: $localBypass"
}

function Test-WindowsDeveloperMode {
  if (-not $IsWindows) {
    return $true
  }

  $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
  $value = Get-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue
  return ($null -ne $value -and $value.AllowDevelopmentWithoutDevLicense -eq 1)
}

function Get-VisualStudioInstallationPath {
  if (-not (Test-Path -LiteralPath $vswhere)) {
    return $null
  }

  $path = & $vswhere -products * -latest -property installationPath
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($path)) {
    return $null
  }

  return $path.Trim()
}

function Test-VisualStudioComponent {
  param([Parameter(Mandatory = $true)][string]$Component)

  if (-not (Test-Path -LiteralPath $vswhere)) {
    return $false
  }

  $path = & $vswhere -products * -requires $Component -property installationPath
  return ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($path))
}

function Get-VisualStudioInstallCommand {
  param([Parameter(Mandatory = $true)][string]$InstallPath)

  $componentArgs = $requiredVsComponents | ForEach-Object { "--add $_" }
  $allArgs = @(
    'modify',
    "--installPath `"$InstallPath`"",
    '--passive',
    '--norestart'
  ) + $componentArgs

  return "`"$vsInstaller`" $($allArgs -join ' ')"
}

Add-FlutterToPath
Set-LocalProxyBypass

Write-Host '== Windows Developer Mode =='
if (Test-WindowsDeveloperMode) {
  Write-Host 'Developer Mode is enabled. Flutter desktop plugin symlinks are supported.'
} else {
  Write-Warning 'Developer Mode is disabled. Flutter desktop plugin builds may fail with "requires symlink support".'
  Write-Host 'Open Settings > System > For developers and enable Developer Mode, or run:'
  Write-Host 'start ms-settings:developers'
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter was not found. Expected SDK at $flutterBin or on PATH."
}

Write-Host '== Flutter doctor =='
flutter doctor -v

if ($AcceptAndroidLicenses) {
  Write-Host '== Android licenses =='
  $yes = 'y' + [Environment]::NewLine
  1..80 | ForEach-Object { $yes += 'y' + [Environment]::NewLine }
  $yes | flutter doctor --android-licenses
}

Write-Host '== Visual Studio components =='
$vsPath = Get-VisualStudioInstallationPath
if ($null -eq $vsPath) {
  Write-Warning 'Visual Studio installation was not found by vswhere.'
} else {
  Write-Host "Visual Studio installation: $vsPath"
}

$missing = @()
foreach ($component in $requiredVsComponents) {
  if (Test-VisualStudioComponent -Component $component) {
    Write-Host "present: $component"
  } else {
    Write-Warning "missing: $component"
    $missing += $component
  }
}

if ($missing.Count -gt 0) {
  if ($null -eq $vsPath -or -not (Test-Path -LiteralPath $vsInstaller)) {
    Write-Warning "Cannot build an installer command because Visual Studio Installer was not found at $vsInstaller."
  } else {
    $command = Get-VisualStudioInstallCommand -InstallPath $vsPath
    Write-Host ''
    Write-Host 'Run this from an elevated PowerShell if automatic install is blocked:'
    Write-Host $command

    if ($InstallVisualStudioComponents) {
      Write-Host ''
      Write-Host 'Starting Visual Studio Installer. UAC or installer UI may still require manual confirmation.'
      Start-Process -FilePath $vsInstaller -ArgumentList ($command -replace "^`"$([regex]::Escape($vsInstaller))`" ", '') -Wait -WindowStyle Hidden
    }
  }
} else {
  Write-Host 'Visual Studio has the Flutter-required Windows desktop components.'
}

Write-Host ''
Write-Host "Project root: $root"
