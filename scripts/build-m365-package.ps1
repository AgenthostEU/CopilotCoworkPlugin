#Requires -Version 5.1
<#
.SYNOPSIS
  Assemble the Microsoft 365 Copilot Cowork app package (.zip).

.DESCRIPTION
  The package must have manifest.json, the two icons, the tools/ folder, and the
  skills/ folder all at the ZIP root. Skills are the cross-platform source of
  truth at the repo root (they also serve Claude Code / Cursor), so we copy them
  in at build time rather than duplicating them under m365/.

  PowerShell equivalent of scripts/build-m365-package.sh. Runs on Windows
  PowerShell 5.1+ and PowerShell 7+ (Windows, macOS, Linux).

.EXAMPLE
  pwsh ./scripts/build-m365-package.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$root  = Split-Path -Parent $PSScriptRoot
$out   = Join-Path $root 'm365/build'
$stage = Join-Path $out 'pkg'
$zip   = Join-Path $out 'agenthost-cowork.zip'

if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
if (Test-Path $zip)   { Remove-Item -Force $zip }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

# Regenerate icons if missing.
$color   = Join-Path $root 'm365/color.png'
$outline = Join-Path $root 'm365/outline.png'
if (-not (Test-Path $color) -or -not (Test-Path $outline)) {
  node (Join-Path $root 'scripts/gen-icons.mjs')
}

Copy-Item (Join-Path $root 'm365/manifest.json') $stage
Copy-Item $color   $stage
Copy-Item $outline $stage
Copy-Item (Join-Path $root 'm365/tools')  (Join-Path $stage 'tools')  -Recurse
Copy-Item (Join-Path $root 'skills')      (Join-Path $stage 'skills') -Recurse

# Compress the staged contents so the archive entries sit at the ZIP root.
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force

Write-Host "Built $zip"
Get-ChildItem -Recurse -File $stage |
  ForEach-Object { $_.FullName.Substring($stage.Length + 1) -replace '\\', '/' } |
  Sort-Object
