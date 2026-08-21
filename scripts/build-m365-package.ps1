#Requires -Version 5.1
<#
.SYNOPSIS
  Assemble the Microsoft 365 Copilot Cowork app package (.zip).

.DESCRIPTION
  The package must have manifest.json, the two icons, the tools/ folder, and the
  skills/ folder all at the ZIP root. Skills are the cross-platform source of
  truth at the repo root (they also serve Claude Code / Cursor), so we copy them
  in at build time rather than duplicating them under m365/.

  Entries are written with forward-slash names via the .NET ZipFile API. We do
  NOT use Compress-Archive: on Windows PowerShell 5.1 it records ZIP entries with
  backslash separators (e.g. "skills\deploy-on-agenthost\SKILL.md"), which the
  ZIP spec forbids and Copilot Cowork rejects with "This plugin package contains
  an unsafe file path."

  Runs on Windows PowerShell 5.1+ and PowerShell 7+ (Windows, macOS, Linux).

.EXAMPLE
  pwsh ./scripts/build-m365-package.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$out  = Join-Path $root 'm365/build'
$zip  = Join-Path $out 'agenthost-cowork.zip'

New-Item -ItemType Directory -Force -Path $out | Out-Null
if (Test-Path $zip) { Remove-Item -Force $zip }

# Icons are committed. Regenerate them with `node scripts/gen-icons.mjs` (needs
# sharp) if they are ever missing — we do not auto-generate here so a release
# never ships without the real brand icons.
$color   = Join-Path $root 'm365/color.png'
$outline = Join-Path $root 'm365/outline.png'
if (-not (Test-Path $color) -or -not (Test-Path $outline)) {
  Write-Error "m365/color.png or m365/outline.png missing. Run: npm install && node scripts/gen-icons.mjs"
}

# Build the list of (source file, ZIP entry name) pairs. Entry names always use
# forward slashes and are relative to the ZIP root — no drive letters, no
# backslashes, no parent-directory (..) segments.
$entries = [System.Collections.Generic.List[object]]::new()

function Add-File($source, $entryName) {
  if (-not (Test-Path -LiteralPath $source)) { throw "Missing file: $source" }
  $entries.Add([pscustomobject]@{ Source = (Resolve-Path -LiteralPath $source).Path; Name = $entryName })
}

function Add-Tree($sourceDir, $entryPrefix) {
  $base = (Resolve-Path -LiteralPath $sourceDir).Path
  Get-ChildItem -LiteralPath $base -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($base.Length).TrimStart('\', '/') -replace '\\', '/'
    Add-File $_.FullName "$entryPrefix/$rel"
  }
}

Add-File (Join-Path $root 'm365/manifest.json') 'manifest.json'
Add-File $color   'color.png'
Add-File $outline 'outline.png'
Add-Tree (Join-Path $root 'm365/tools') 'tools'
Add-Tree (Join-Path $root 'skills')     'skills'

Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

$archive = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  foreach ($e in $entries) {
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
      $archive, $e.Source, $e.Name,
      [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
  }
}
finally {
  $archive.Dispose()
}

Write-Host "Built $zip"
$entries | ForEach-Object { $_.Name } | Sort-Object
