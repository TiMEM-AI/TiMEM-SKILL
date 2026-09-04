<#
.SYNOPSIS
  TiMEM Skill installer launcher for Windows PowerShell.
.DESCRIPTION
  Keeps the public install command stable while loading the UTF-8 installer core safely.
.USAGE
  $env:TIMEM_API_KEY = "tmk_xxx"; irm https://raw.githubusercontent.com/TiMEM-AI/TiMEM-SKILL/main/install-all.ps1 | iex
  .\install-all.ps1 -ApiKey "tmk_xxx" -Agent "codex"
  .\install-all.ps1 -ApiKey "tmk_xxx" -Agent "codex" -SkipAgentInstructions
#>

[CmdletBinding()]
param(
  [string]$ApiKey,
  [Alias('Agent')]
  [string]$AgentSelection,
  [switch]$SkipAgentInstructions
)

$ErrorActionPreference = "Stop"
$coreFileName = "install-all.core.ps1"
$launcherPath = [string]$MyInvocation.MyCommand.Path

if (-not [string]::IsNullOrWhiteSpace($launcherPath)) {
  $localCorePath = Join-Path (Split-Path -Parent $launcherPath) $coreFileName
  if (Test-Path -LiteralPath $localCorePath -PathType Leaf) {
    & $localCorePath @PSBoundParameters
    return
  }
}

$coreUrl = "https://raw.githubusercontent.com/TiMEM-AI/TiMEM-SKILL/main/$coreFileName"
$coreSource = [string](Invoke-RestMethod -Uri $coreUrl)
$coreSource = $coreSource.TrimStart([char]0xFEFF)

if ([string]::IsNullOrWhiteSpace($coreSource)) {
  throw "Downloaded installer core is empty: $coreUrl"
}

. ([scriptblock]::Create($coreSource)) @PSBoundParameters
