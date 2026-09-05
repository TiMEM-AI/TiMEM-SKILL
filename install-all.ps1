<#
.SYNOPSIS
  TiMEM Skill 一键安装 (Windows PowerShell 版)
.DESCRIPTION
  为所有已检测的 Agent 工具安装 TiMEM Skills + MCP 配置 + 全局指令
.USAGE
  $env:TIMEM_API_KEY = "tmk_xxx"; (irm https://careerfun-1257357192.cos.ap-beijing.myqcloud.com/installers/install-all.ps1).TrimStart([char]0xFEFF) | iex
  .\install-all.ps1 -ApiKey "tmk_xxx" -Agent "codex"
  .\install-all.ps1 -ApiKey "tmk_xxx" -Agent "codex" -SkipAgentInstructions
#>

param(
  [string]$ApiKey,
  [Alias('Agent')]
  [string]$AgentSelection,
  [switch]$SkipAgentInstructions
)

$ErrorActionPreference = "Stop"

# ============================================================================
# 常量
# ============================================================================
$TIMEM_COS_BASE_URL = "https://careerfun-1257357192.cos.ap-beijing.myqcloud.com"
$TIMEM_MCP_REPO = "https://github.com/TiMEM-AI/timem-mcp"
$TIMEM_CLOUD_URL = "https://api.space.timem.cloud/mcp/"
$TIMEM_API_HOST_DEFAULT = "https://api.space.timem.cloud"
$TIMEM_SERVER_NAME = "TiMEM-SPACE"
$TIMEM_AGENT_INSTRUCTION = "每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程"
$TIMEM_INSTRUCTION_MARKERS = @("TiMEM-SPACE", "太忆空间", "timem-memory")
$CODEX_CONFIG_PATH = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) { "$env:USERPROFILE\.codex" } else { $env:CODEX_HOME }
$QODER_CONFIG_PATH = if ([string]::IsNullOrWhiteSpace($env:QODER_CONFIG_DIR)) { "$env:USERPROFILE\.qoder" } else { $env:QODER_CONFIG_DIR }
$HERMES_CONFIG_PATH = if ([string]::IsNullOrWhiteSpace($env:HERMES_HOME)) { "$env:USERPROFILE\.hermes" } else { $env:HERMES_HOME }
$TRAE_MCP_CONFIG_PATH = [string]$env:TRAE_MCP_CONFIG
if ([string]::IsNullOrWhiteSpace($TRAE_MCP_CONFIG_PATH)) {
  $traeMcpCandidates = @()
  if (-not [string]::IsNullOrWhiteSpace($env:APPDATA)) {
    $traeMcpCandidates += (Join-Path $env:APPDATA 'Trae\User\mcp.json')
    $traeMcpCandidates += (Join-Path $env:APPDATA 'TRAE SOLO CN\User\mcp.json')
    $traeMcpCandidates += (Join-Path $env:APPDATA 'TRAE SOLO\User\mcp.json')
  }
  $traeMcpCandidates += (Join-Path $env:USERPROFILE '.trae\mcp.json')
  $TRAE_MCP_CONFIG_PATH = $traeMcpCandidates |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1
  if ([string]::IsNullOrWhiteSpace($TRAE_MCP_CONFIG_PATH)) {
    $TRAE_MCP_CONFIG_PATH = $traeMcpCandidates[0]
  }
}
$TRAE_CONFIG_PATH = Split-Path -Path $TRAE_MCP_CONFIG_PATH -Parent

$ALL_SKILLS = @(
  @{name="timem-coding-memory"; path="dist/standalone/timem-coding-memory"}
  @{name="timem-general-memory"; path="dist/standalone/timem-general-memory"}
  @{name="timem-writing-memory"; path="skills/timem-writing-memory"}
)

# Agent 矩阵
$AGENTS = @(
  @{name="claude-code"; detect="claude"; configDir="$env:USERPROFILE\.claude"; skillsDir="$env:USERPROFILE\.claude\skills"; configFile="$env:USERPROFILE\.claude.json"; format="json"; rootKey="mcpServers"; hasSkills=$true; instructionFile="CLAUDE.md"}
  @{name="codex"; detect="codex"; configDir=$CODEX_CONFIG_PATH; skillsDir=(Join-Path $CODEX_CONFIG_PATH 'skills'); configFile=(Join-Path $CODEX_CONFIG_PATH 'config.toml'); format="toml"; rootKey="mcp_servers"; hasSkills=$true; instructionFile="AGENTS.md"}
  @{name="cursor"; detect="cursor"; configDir="$env:USERPROFILE\.cursor"; skillsDir="$env:USERPROFILE\.cursor\skills"; configFile="$env:USERPROFILE\.cursor\mcp.json"; format="json"; rootKey="mcpServers"; hasSkills=$true; instructionFile="timem-memory.mdc"; instructionScope="cursor-user-rules"}
  @{name="openclaw"; detect="openclaw"; configDir="$env:USERPROFILE\.openclaw"; skillsDir="$env:USERPROFILE\.openclaw\skills"; configFile="$env:USERPROFILE\.openclaw\openclaw.json"; format="json"; rootKey="mcp.servers"; hasSkills=$true; instructionFile="AGENTS.md"; instructionScope="openclaw-workspaces"}
  @{name="hermes"; detect="hermes"; configDir=$HERMES_CONFIG_PATH; skillsDir=(Join-Path $HERMES_CONFIG_PATH 'skills'); configFile=(Join-Path $HERMES_CONFIG_PATH 'config.yaml'); format="yaml"; rootKey="mcp_servers"; hasSkills=$true; instructionFile="SOUL.md"; instructionCreateIfMissing=$false}
  @{name="trae"; detect="trae"; configDir=$TRAE_CONFIG_PATH; detectDirs=@($TRAE_CONFIG_PATH, "$env:USERPROFILE\.trae"); skillsDir="$env:USERPROFILE\.trae\skills"; configFile=$TRAE_MCP_CONFIG_PATH; format="json"; rootKey="mcpServers"; hasSkills=$true; instructionFile="timem-memory.md"; instructionScope="trae-user-rules"}
  @{name="workbuddy"; detect="workbuddy"; configDir="$env:USERPROFILE\.workbuddy"; skillsDir="$env:USERPROFILE\.workbuddy\skills"; configFile="$env:USERPROFILE\.workbuddy\.mcp.json"; format="json"; rootKey="mcpServers"; hasSkills=$true; instructionFile="SOUL.md"; instructionCreateIfMissing=$false}
  @{name="qoder"; detect="qoder"; configDir=$QODER_CONFIG_PATH; skillsDir=(Join-Path $QODER_CONFIG_PATH 'skills'); configFile=(Join-Path $QODER_CONFIG_PATH 'settings.json'); format="json"; rootKey="mcpServers"; hasSkills=$true; instructionFile="AGENTS.md"}
)

# Claude Desktop
$CLAUDE_DESKTOP_CONFIG = "$env:APPDATA\Claude\claude_desktop_config.json"

$API_KEY = if ($ApiKey) { $ApiKey } else { $env:TIMEM_API_KEY }
$SILENT_MODE = $false
$AGENT_FILTER = if ($AgentSelection) { $AgentSelection } else { $env:TIMEM_AGENT }
$AGENT_FILTER_VALUES = @()
$SKILLS_FILTER = ""
$SKIP_AGENT_INSTRUCTIONS = $SkipAgentInstructions.IsPresent

# ============================================================================
# 日志函数
# ============================================================================
function Info($msg) { Write-Host "  [INFO] $msg" }
function Success($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Err($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red }

function Set-AgentFilter([string]$value) {
  $script:AGENT_FILTER_VALUES = @()
  if ([string]::IsNullOrWhiteSpace($value)) { return }

  foreach ($item in ($value -split ',')) {
    $normalized = $item.Trim().ToLowerInvariant()
    if ($normalized -and ($script:AGENT_FILTER_VALUES -notcontains $normalized)) {
      $script:AGENT_FILTER_VALUES += $normalized
    }
  }
}

function Test-AgentSelected($agentName) {
  if ($script:AGENT_FILTER_VALUES.Count -eq 0) { return $true }
  $normalized = ([string]$agentName).Trim().ToLowerInvariant()
  return $script:AGENT_FILTER_VALUES -contains $normalized
}

Set-AgentFilter $AGENT_FILTER

function Write-Utf8NoBom($path, [string]$content) {
  New-Item -ItemType Directory -Path (Split-Path $path) -Force | Out-Null
  $encoding = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($path, $content, $encoding)
}

function Remove-TomlTables($content, $tableName) {
  if ([string]::IsNullOrEmpty($content)) { return "" }

  $keptLines = New-Object System.Collections.Generic.List[string]
  $skipping = $false
  foreach ($line in ($content -split "`r?`n")) {
    if ($line -match '^\s*\[([^\]]+)\]\s*(?:#.*)?$') {
      $header = $Matches[1].Trim()
      $skipping = $header -eq $tableName -or $header.StartsWith("$tableName.")
    }
    if (-not $skipping) { [void]$keptLines.Add($line) }
  }

  return ($keptLines -join [Environment]::NewLine).TrimEnd()
}

function Read-JsonObject([string]$rawConfig) {
  if ($PSVersionTable.PSVersion.Major -ge 6) {
    return ConvertFrom-Json -InputObject $rawConfig -AsHashtable
  }

  # Windows PowerShell 5.1 的 PSCustomObject 不能读取仅大小写不同的 JSON 键。
  # Claude Code 的 ~/.claude.json 可能含这类项目路径键，改用大小写敏感的字典。
  Add-Type -AssemblyName System.Web.Extensions
  $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  return $serializer.DeserializeObject($rawConfig)
}

function Get-YamlTopLevelBlockEnd($lines, $startIndex) {
  for ($index = $startIndex + 1; $index -lt $lines.Count; $index++) {
    $line = $lines[$index]
    if ($line -match '^\S' -and $line -notmatch '^#') { return $index }
  }
  return $lines.Count
}

function Remove-DuplicateYamlMcpRoots($lines) {
  $keptLines = New-Object System.Collections.Generic.List[string]
  $seenRoot = $false
  $skippingRoot = $false

  foreach ($line in $lines) {
    if ($skippingRoot -and $line -match '^\S' -and $line -notmatch '^#') {
      $skippingRoot = $false
    }

    if (-not $skippingRoot -and $line -match '^mcp_servers:\s*(?:#.*)?$') {
      if ($seenRoot) {
        $skippingRoot = $true
        continue
      }
      $seenRoot = $true
    }

    if (-not $skippingRoot) { [void]$keptLines.Add($line) }
  }

  return @($keptLines)
}

# ============================================================================
# Agent 检测
# ============================================================================
function Detect-Agent($agent) {
  $cmd = Get-Command $agent.detect -ErrorAction SilentlyContinue
  if ($cmd) { return $true }
  if (Test-Path $agent.configDir) { return $true }
  if ($agent -is [System.Collections.IDictionary] -and $agent.ContainsKey("detectDirs")) {
    foreach ($directory in @($agent["detectDirs"])) {
      if (-not [string]::IsNullOrWhiteSpace([string]$directory) -and (Test-Path -LiteralPath $directory)) {
        return $true
      }
    }
  }
  return $false
}

# ============================================================================
# 下载 TiMEM-SKILL
# ============================================================================
function Download-Skills {
  if ($env:TIMEM_SKILL_SOURCE_DIR) {
    foreach ($skill in $ALL_SKILLS) {
      if (-not (Test-Path -LiteralPath (Join-Path $env:TIMEM_SKILL_SOURCE_DIR "$($skill.path)/SKILL.md"))) {
        Err "Local release missing skill: $($skill.name)"
        return $null
      }
    }
    return $env:TIMEM_SKILL_SOURCE_DIR
  }
  $tmpDir = Join-Path $env:TEMP "timem-skill-$(Get-Random)"
  Info "从 COS 下载 TiMEM-SKILL 发行包..."
  try {
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    $latest = Invoke-RestMethod -Uri "$TIMEM_COS_BASE_URL/releases/latest.json" -ErrorAction Stop
    $version = [string]$latest.version
    if ($version -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { throw "Invalid release version" }
    $releaseKey = "releases/timem-skill-$version.zip"
    $manifestKey = "releases/release-manifest-$version.json"
    if ($latest.artifacts.release -ne $releaseKey -or $latest.artifacts.manifest -ne $manifestKey) {
      throw "Invalid release snapshot paths"
    }
    $manifest = Invoke-RestMethod -Uri "$TIMEM_COS_BASE_URL/$manifestKey" -ErrorAction Stop
    if ($manifest.version -ne $version) { throw "Release manifest version mismatch" }
    $archive = Join-Path $tmpDir 'release.zip'
    Invoke-WebRequest -Uri "$TIMEM_COS_BASE_URL/$releaseKey" -OutFile $archive -UseBasicParsing -ErrorAction Stop
    $record = $manifest.artifacts.release
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
      $digest = [BitConverter]::ToString($sha256.ComputeHash([IO.File]::ReadAllBytes($archive))).Replace('-', '')
    } finally { $sha256.Dispose() }
    if ((Get-Item -LiteralPath $archive).Length -ne $record.size -or
        $digest -ne $record.sha256) {
      throw "Release ZIP checksum mismatch"
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($archive, $tmpDir)
    $package = Join-Path $tmpDir 'timem-skill'
    foreach ($skill in $ALL_SKILLS) {
      if (-not (Test-Path -LiteralPath (Join-Path $package "$($skill.path)/SKILL.md"))) {
        throw "Release missing skill: $($skill.name)"
      }
    }
    Success "TiMEM-SKILL $version 已下载并校验"
    return $package
  } catch {
    Err "下载 TiMEM-SKILL 失败: $_"
    return $null
  }
}

# ============================================================================
# Skill 安装
# ============================================================================
function Install-Skills($agent, $skillDir) {
  $installed = 0; $failed = 0
  foreach ($skill in $ALL_SKILLS) {
    if ($SKILLS_FILTER -and ($SKILLS_FILTER -notcontains $skill.name)) { continue }
    $src = Join-Path $skillDir $skill.path
    $dst = Join-Path $agent.skillsDir $skill.name

    if (-not (Test-Path "$src\SKILL.md")) {
      Warn "skill 源不存在: $($skill.path)"
      $failed++; continue
    }

    New-Item -ItemType Directory -Path $agent.skillsDir -Force | Out-Null
    if (Test-Path $dst) {
      # 备份
      if (Test-Path "$dst.bak") { Remove-Item "$dst.bak" -Recurse -Force }
      Copy-Item $dst "$dst.bak" -Recurse -Force
      Remove-Item $dst -Recurse -Force
      Warn "skill '$($skill.name)' 已存在，已备份 .bak"
    }
    Copy-Item $src $dst -Recurse -Force
    Success "skill '$($skill.name)' 已安装"
    $installed++
  }
  return @{installed=$installed; failed=$failed}
}

# ============================================================================
# 全局 / 工作区 Agent 指令注入
# ============================================================================
function ConvertFrom-OpenClawWorkspacePath([string]$workspacePath, [string]$configDir) {
  $candidate = $workspacePath.Trim()
  if ($candidate -eq "~" -or $candidate.StartsWith("~/") -or $candidate.StartsWith("~\")) {
    $relativePath = $candidate.Substring(1).TrimStart([char[]]@('\', '/'))
    if ([string]::IsNullOrWhiteSpace($relativePath)) {
      return $env:USERPROFILE
    }
    return Join-Path $env:USERPROFILE $relativePath
  }
  if ([IO.Path]::IsPathRooted($candidate)) {
    return $candidate
  }
  return Join-Path $configDir $candidate
}

function Get-OpenClawInstructionDirectories($agent) {
  $configDir = [string]$agent.configDir
  $openClawConfig = $null
  if (Test-Path -LiteralPath $agent.configFile) {
    try {
      $rawConfig = [IO.File]::ReadAllText($agent.configFile)
      if (-not [string]::IsNullOrWhiteSpace($rawConfig)) {
        $openClawConfig = ConvertFrom-Json -InputObject $rawConfig
      }
    } catch {
      Warn "OpenClaw workspace 配置解析失败，将使用默认路径: $_"
    }
  }

  $agentsConfig = if ($null -ne $openClawConfig) { $openClawConfig.agents } else { $null }
  $workspaceSetting = [string]$env:OPENCLAW_WORKSPACE_DIR
  if ([string]::IsNullOrWhiteSpace($workspaceSetting) -and $null -ne $agentsConfig -and $null -ne $agentsConfig.defaults) {
    $workspaceSetting = [string]$agentsConfig.defaults.workspace
  }

  if ([string]::IsNullOrWhiteSpace($workspaceSetting)) {
    $profileName = [string]$env:OPENCLAW_PROFILE
    $workspaceName = if ([string]::IsNullOrWhiteSpace($profileName) -or $profileName -ieq "default") { "workspace" } else { "workspace-" + $profileName }
    $defaultWorkspace = Join-Path $configDir $workspaceName
  } else {
    $defaultWorkspace = ConvertFrom-OpenClawWorkspacePath $workspaceSetting $configDir
  }

  $directories = New-Object System.Collections.Generic.List[string]
  [void]$directories.Add($defaultWorkspace)
  $agentEntries = @()
  if ($null -ne $agentsConfig) {
    if ($null -ne $agentsConfig.list) {
      $agentEntries += @($agentsConfig.list)
    }
    if ($null -ne $agentsConfig.entries) {
      foreach ($property in $agentsConfig.entries.PSObject.Properties) {
        $agentEntries += [pscustomobject]@{
          id = $property.Name
          workspace = [string]$property.Value.workspace
        }
      }
    }
  }

  foreach ($entry in $agentEntries) {
    if ($null -eq $entry) { continue }
    $agentId = [string]$entry.id
    if ([string]::IsNullOrWhiteSpace($agentId)) {
      $agentId = [string]$entry.name
    }
    $entryWorkspace = [string]$entry.workspace
    if ([string]::IsNullOrWhiteSpace($entryWorkspace)) {
      if ([string]::IsNullOrWhiteSpace($agentId) -or $agentId -ieq "main" -or $agentId -ieq "default") {
        continue
      }
      $resolvedWorkspace = Join-Path $configDir ("workspace-" + $agentId)
    } else {
      $resolvedWorkspace = ConvertFrom-OpenClawWorkspacePath $entryWorkspace $configDir
    }
    if ($directories -notcontains $resolvedWorkspace) {
      [void]$directories.Add($resolvedWorkspace)
    }
  }

  return $directories.ToArray()
}

function Get-AgentInstructionDirectories($agent) {
  if ([string]$agent.instructionScope -eq "openclaw-workspaces") {
    return @(Get-OpenClawInstructionDirectories $agent)
  }
  return @([string]$agent.configDir)
}

function New-CursorUserRuleContent {
  return (@(
    "---"
    'description: "TiMEM memory workflow"'
    "alwaysApply: true"
    "---"
    ""
    $TIMEM_AGENT_INSTRUCTION
    ""
  ) -join "`n")
}

function Ensure-CursorUserRule($agent) {
  $rulesDirectory = Join-Path ([string]$agent.configDir) "rules"
  $instructionPath = Join-Path $rulesDirectory "timem-memory.mdc"

  try {
    if (Test-Path -LiteralPath $instructionPath -PathType Container) {
      throw "Cursor User Rule 路径不是文件: $instructionPath"
    }

    $existingContent = if (Test-Path -LiteralPath $instructionPath) { [IO.File]::ReadAllText($instructionPath) } else { "" }
    foreach ($marker in $TIMEM_INSTRUCTION_MARKERS) {
      if ($existingContent.IndexOf($marker, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Info "Cursor User Rule 已包含 TiMEM 标记: $instructionPath"
        return $true
      }
    }

    if ([string]::IsNullOrEmpty($existingContent)) {
      $updatedContent = New-CursorUserRuleContent
    } else {
      $newLine = if ($existingContent.Contains("`r`n")) { "`r`n" } else { "`n" }
      $updatedContent = if ($existingContent.EndsWith("`n")) {
        $existingContent + $TIMEM_AGENT_INSTRUCTION + $newLine
      } else {
        $existingContent + $newLine + $TIMEM_AGENT_INSTRUCTION + $newLine
      }
    }

    Write-Utf8NoBom $instructionPath $updatedContent
    Success "Cursor User Rule 已注入: $instructionPath"
    return $true
  } catch {
    Err "Cursor User Rule 注入失败 ($($agent.name)): $_"
    return $false
  }
}

function Ensure-TraeUserRule($agent) {
  $rulesDirectory = Join-Path (Join-Path $env:USERPROFILE ".trae") "user_rules"
  $instructionPath = Join-Path $rulesDirectory "timem-memory.md"

  try {
    if (Test-Path -LiteralPath $instructionPath -PathType Container) {
      throw "TRAE Global Rule 路径不是文件: $instructionPath"
    }

    $existingContent = if (Test-Path -LiteralPath $instructionPath) { [IO.File]::ReadAllText($instructionPath) } else { "" }
    foreach ($marker in $TIMEM_INSTRUCTION_MARKERS) {
      if ($existingContent.IndexOf($marker, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Info "TRAE Global Rule 已包含 TiMEM 标记: $instructionPath"
        return $true
      }
    }

    $newLine = if ($existingContent.Contains("`r`n")) { "`r`n" } else { "`n" }
    $updatedContent = if ([string]::IsNullOrEmpty($existingContent)) {
      (@(
        "---"
        "alwaysApply: true"
        "---"
        ""
        $TIMEM_AGENT_INSTRUCTION
        ""
      ) -join "`n")
    } elseif ($existingContent.EndsWith("`n")) {
      $existingContent + $TIMEM_AGENT_INSTRUCTION + $newLine
    } else {
      $existingContent + $newLine + $TIMEM_AGENT_INSTRUCTION + $newLine
    }

    Write-Utf8NoBom $instructionPath $updatedContent
    Success "TRAE Global Rule 已注入: $instructionPath"
    return $true
  } catch {
    Err "TRAE Global Rule 注入失败 ($($agent.name)): $_"
    return $false
  }
}

function Ensure-AgentInstruction($agent) {
  if ($SKIP_AGENT_INSTRUCTIONS) {
    Info "已跳过 Agent 指令注入"
    return $true
  }

  if ([string]$agent.instructionScope -eq "cursor-user-rules") {
    return Ensure-CursorUserRule $agent
  }
  if ([string]$agent.instructionScope -eq "trae-user-rules") {
    return Ensure-TraeUserRule $agent
  }

  $instructionFileName = [string]$agent.instructionFile
  if ([string]::IsNullOrWhiteSpace($instructionFileName)) {
    Info "未配置 Agent 指令文件 (跳过)"
    return $true
  }

  try {
    $instructionDirectories = @(Get-AgentInstructionDirectories $agent)
    if ($instructionDirectories.Count -eq 0) {
      Info "未解析到 Agent 指令目录 (跳过)"
      return $true
    }
    foreach ($instructionDirectory in $instructionDirectories) {
    $candidateNames = switch ($instructionFileName.ToUpperInvariant()) {
      "AGENTS.MD" { @("AGENTS.md", "AGENT.md") }
      "CLAUDE.MD" { @("CLAUDE.md") }
      default { @($instructionFileName) }
    }
    $availableFiles = @(Get-ChildItem -LiteralPath $instructionDirectory -File -ErrorAction SilentlyContinue)
    $existingFile = $null
    foreach ($candidateName in $candidateNames) {
      $existingFile = $availableFiles |
        Where-Object { $_.Name -ieq $candidateName } |
        Select-Object -First 1
      if ($existingFile) { break }
    }
    $instructionPath = if ($existingFile) { $existingFile.FullName } else { Join-Path $instructionDirectory $instructionFileName }
    $createInstructionFile = -not (
      $agent -is [System.Collections.IDictionary] -and
      $agent.ContainsKey("instructionCreateIfMissing") -and
      -not [bool]$agent["instructionCreateIfMissing"]
    )
    if (-not $createInstructionFile -and -not (Test-Path -LiteralPath $instructionPath -PathType Leaf)) {
      Info "Agent 指令文件不存在，保留默认行为 (跳过): $instructionPath"
      continue
    }
    New-Item -ItemType Directory -Path $instructionDirectory -Force | Out-Null
    $existingContent = if (Test-Path -LiteralPath $instructionPath) { [IO.File]::ReadAllText($instructionPath) } else { "" }

    $hasTiMEMMarker = $false
    foreach ($marker in $TIMEM_INSTRUCTION_MARKERS) {
      if ($existingContent.IndexOf($marker, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Info "Agent 指令已包含 TiMEM 标记: $instructionPath"
        $hasTiMEMMarker = $true
        break
      }
    }
    if ($hasTiMEMMarker) { continue }

    $newLine = if ($existingContent.Contains("`r`n")) { "`r`n" } else { "`n" }
    $updatedContent = if ([string]::IsNullOrEmpty($existingContent)) {
      $TIMEM_AGENT_INSTRUCTION + $newLine
    } elseif ($existingContent.EndsWith("`n")) {
      $existingContent + $TIMEM_AGENT_INSTRUCTION + $newLine
    } else {
      $existingContent + $newLine + $TIMEM_AGENT_INSTRUCTION + $newLine
    }

    Write-Utf8NoBom $instructionPath $updatedContent
    Success "Agent 指令已注入: $instructionPath"
    }
    return $true
  } catch {
    Err "Agent 指令注入失败 ($($agent.name)): $_"
    return $false
  }
}

# ============================================================================
# MCP 配置 (JSON)
# ============================================================================
function Merge-McpJson($configFile, $agentName, $rootKey) {
  $serverName = $TIMEM_SERVER_NAME
  $serverConfig = @{
    url = $TIMEM_CLOUD_URL
    headers = @{
      "X-API-Key" = $API_KEY
    }
  }

  $config = @{}
  if (Test-Path $configFile) {
    $rawConfig = [IO.File]::ReadAllText($configFile)
    if (-not [string]::IsNullOrWhiteSpace($rawConfig)) {
      $config = Read-JsonObject $rawConfig
    }
  }
  if (-not ($config -is [System.Collections.IDictionary])) {
    throw "MCP JSON 根节点必须是对象: $configFile"
  }

  # 确保 rootKey 路径存在
  $keys = @($rootKey -split '\.')
  $d = $config
  if ($keys.Length -gt 1) {
    foreach ($k in $keys[0..($keys.Length-2)]) {
      if (-not $d.ContainsKey($k)) { $d[$k] = @{} }
      elseif (-not ($d[$k] -is [System.Collections.IDictionary])) {
        throw "MCP JSON 路径 '$k' 不是对象: $configFile"
      }
      $d = $d[$k]
    }
  }
  $lastKey = $keys[-1]
  if (-not $d.ContainsKey($lastKey)) { $d[$lastKey] = @{} }
  elseif (-not ($d[$lastKey] -is [System.Collections.IDictionary])) {
    throw "MCP JSON 路径 '$lastKey' 不是对象: $configFile"
  }
  $servers = $d[$lastKey]

  # 修复旧版本在单层 rootKey 下错误嵌套出的 mcpServers.mcpServers.<server>。
  if ($keys.Length -eq 1 -and $servers.ContainsKey($lastKey) -and
      ($servers[$lastKey] -is [System.Collections.IDictionary]) -and
      $servers[$lastKey].ContainsKey($serverName)) {
    $servers.Remove($lastKey)
  }
  $servers[$serverName] = $serverConfig

  $jsonContent = $config | ConvertTo-Json -Depth 100
  Write-Utf8NoBom $configFile $jsonContent
  Success "MCP 配置已写入: $configFile"
}

# ============================================================================
# MCP 配置 (TOML - Codex)
# ============================================================================
function Merge-McpToml($configFile, $agentName) {
  $serverName = $TIMEM_SERVER_NAME
  $tomlContent = @"

[mcp_servers.$serverName]
command = "uvx"
args = ["--from", "git+$TIMEM_MCP_REPO.git@main", "timem-mcp"]

[mcp_servers.$serverName.env]
TIMEM_API_KEY = "$API_KEY"
TIMEM_API_HOST = "$TIMEM_API_HOST_DEFAULT"
TIMEM_AGENT_ID = "$agentName"
"@
  $existingContent = if (Test-Path $configFile) { [IO.File]::ReadAllText($configFile) } else { "" }
  $existingContent = Remove-TomlTables $existingContent "mcp_servers.$serverName"
  $separator = if ($existingContent -and -not $existingContent.EndsWith("`n")) { [Environment]::NewLine } else { "" }
  Write-Utf8NoBom $configFile ($existingContent + $separator + $tomlContent)
  Success "MCP 配置已写入: $configFile"
}

# ============================================================================
# MCP 配置 (YAML - Hermes)
# ============================================================================
function Merge-McpYaml($configFile, $agentName) {
  $serverName = $TIMEM_SERVER_NAME
  $serverLines = @(
    "  ${serverName}:",
    "    url: `"$TIMEM_CLOUD_URL`"",
    "    headers:",
    "      X-API-Key: `"$API_KEY`""
  )
  $existingContent = if (Test-Path $configFile) { [IO.File]::ReadAllText($configFile) } else { "" }
  $lines = Remove-DuplicateYamlMcpRoots @($existingContent -split "`r?`n")
  $mcpRootIndex = -1
  for ($index = 0; $index -lt $lines.Count; $index++) {
    if ($lines[$index] -match '^mcp_servers:\s*(?:#.*)?$') {
      $mcpRootIndex = $index
      break
    }
  }

  if ($mcpRootIndex -lt 0) {
    $prefix = $existingContent.TrimEnd()
    if ($prefix) { $prefix += [Environment]::NewLine + [Environment]::NewLine }
    $yamlContent = $prefix + "mcp_servers:" + [Environment]::NewLine + ($serverLines -join [Environment]::NewLine) + [Environment]::NewLine
    Write-Utf8NoBom $configFile $yamlContent
    Success "MCP 配置已写入: $configFile"
    return
  }

  $mcpBlockEnd = Get-YamlTopLevelBlockEnd $lines $mcpRootIndex
  $serverPattern = '^(?<indent> +)' + [regex]::Escape($serverName) + ':\s*(?:#.*)?$'
  $serverStart = -1
  $serverIndent = 0
  for ($index = $mcpRootIndex + 1; $index -lt $mcpBlockEnd; $index++) {
    $match = [regex]::Match($lines[$index], $serverPattern)
    if ($match.Success) {
      $serverStart = $index
      $serverIndent = $match.Groups['indent'].Value.Length
      break
    }
  }

  if ($serverStart -ge 0) {
    $serverEnd = $mcpBlockEnd
    for ($index = $serverStart + 1; $index -lt $mcpBlockEnd; $index++) {
      $line = $lines[$index]
      if ($line -match '^\s*#') { continue }
      $indentMatch = [regex]::Match($line, '^(?<indent> *)\S')
      if ($indentMatch.Success -and $indentMatch.Groups['indent'].Value.Length -le $serverIndent) {
        $serverEnd = $index
        break
      }
    }

    $withoutServer = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $lines.Count; $index++) {
      if ($index -lt $serverStart -or $index -ge $serverEnd) {
        [void]$withoutServer.Add($lines[$index])
      }
    }
    $lines = @($withoutServer)
    $mcpRootIndex = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
      if ($lines[$index] -match '^mcp_servers:\s*(?:#.*)?$') {
        $mcpRootIndex = $index
        break
      }
    }
    $mcpBlockEnd = Get-YamlTopLevelBlockEnd $lines $mcpRootIndex
  }

  $mergedLines = New-Object System.Collections.Generic.List[string]
  for ($index = 0; $index -lt $mcpBlockEnd; $index++) {
    [void]$mergedLines.Add($lines[$index])
  }
  foreach ($line in $serverLines) { [void]$mergedLines.Add($line) }
  for ($index = $mcpBlockEnd; $index -lt $lines.Count; $index++) {
    [void]$mergedLines.Add($lines[$index])
  }

  Write-Utf8NoBom $configFile (($mergedLines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine)
  Success "MCP 配置已写入: $configFile"
}

# ============================================================================
# 交互式引导
# ============================================================================
function Select-Language {
  Write-Host ""
  Write-Host "请选择语言 / Select language:"
  Write-Host "  1) 中文"
  Write-Host "  2) English"
  Write-Host "  3) 静默安装（一键全装）"
  $choice = Read-Host "> "
  switch ($choice) {
    "1" { $script:LANG_SEL = "zh" }
    "2" { $script:LANG_SEL = "en" }
    "3" { $script:LANG_SEL = "zh"; $script:SILENT_MODE = $true }
    default { $script:LANG_SEL = "zh" }
  }
}

function Input-ApiKey {
  if ($API_KEY) { return }
  Write-Host ""
  Write-Host "请输入 TiMEM API Key (可在 space.timem.cloud 获取):"
  $key = Read-Host "> " -AsSecureString
  $plainKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($key))
  if ($plainKey) { $script:API_KEY = $plainKey }
  else { Warn "未输入 API Key，MCP 配置将使用占位符" }
}

function Select-Agents {
  if ($AGENT_FILTER) { return }
  Write-Host ""
  Write-Host "检测到以下已安装的 Agent 工具:"
  Write-Host ""

  $detected = @()
  $idx = 1
  foreach ($agent in $AGENTS) {
    if (Detect-Agent $agent) {
      $detected += $agent
      Write-Host "  [$idx] $($agent.name) ($($agent.configDir))"
      $idx++
    }
  }

  # Claude Desktop
  if (Test-Path $CLAUDE_DESKTOP_CONFIG) {
    $detected += @{name="claude-desktop"; configFile=$CLAUDE_DESKTOP_CONFIG; format="json"; rootKey="mcpServers"; hasSkills=$false}
    Write-Host "  [$idx] claude-desktop ($CLAUDE_DESKTOP_CONFIG)"
    $idx++
  }

  if ($detected.Count -eq 0) {
    Write-Host "  未检测到任何已安装的 Agent 工具"
    return
  }

  Write-Host ""
  Write-Host "选择安装目标:"
  Write-Host "  a) 全部安装"
  Write-Host "  s) 选择部分安装"
  $choice = Read-Host "> "

  switch ($choice) {
    "a" { }
    "s" {
      Write-Host "请输入要安装的编号，用空格分隔 (如: 1 3 5):"
      $nums = Read-Host "> "
      $selected = @()
      foreach ($num in $nums -split '\s+') {
        $n = [int]$num - 1
        if ($n -ge 0 -and $n -lt $detected.Count) {
          $selected += $detected[$n].name
        }
      }
      if ($selected) {
        $script:AGENT_FILTER = $selected -join ","
        Set-AgentFilter $script:AGENT_FILTER
      }
    }
    default { }
  }
}

function Confirm-Install {
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  Write-Host "安装摘要:"
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  Write-Host "  Agent:  $(if ($AGENT_FILTER) {$AGENT_FILTER} else {'全部 (已检测的)'})"
  $skillSummary = if ($SKILLS_FILTER) { $SKILLS_FILTER } else { "全部 ($($ALL_SKILLS.Count)个)" }
  Write-Host "  Skills: $skillSummary"
  Write-Host "  MCP:    Cloud HTTP"
  Write-Host "  Agent 指令: $(if ($SKIP_AGENT_INSTRUCTIONS) {'跳过'} else {'注入已支持的 agent'})"
  $keyDisplay = if ($API_KEY) { "$($API_KEY.Substring(0,4))...$($API_KEY.Substring($API_KEY.Length-4))" } else { "未设置" }
  Write-Host "  API Key: $keyDisplay"
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  Write-Host ""
  $confirm = Read-Host "确认安装? (y/n)"
  if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "已取消安装。"
    exit 0
  }
}

# ============================================================================
# 主流程
# ============================================================================
Write-Host "╔══════════════════════════════════════════════════════════════╗"
Write-Host "║  TiMEM Skill 一键安装 (install-all.ps1)                      ║"
Write-Host "║  为所有已检测的 Agent 工具安装 TiMEM Skills + MCP 配置         ║"
Write-Host "╚══════════════════════════════════════════════════════════════╝"
Write-Host ""

# 交互式引导
Select-Language

if ($SILENT_MODE) {
  Input-ApiKey
  Write-Host "静默安装：将为所有已检测的 Agent 工具安装全部 Skills + MCP"
} else {
  Input-ApiKey
  Select-Agents
  Confirm-Install
}

# 下载 skills
$skillDir = Download-Skills
if (-not $skillDir) {
  throw "TiMEM-SKILL 下载或校验失败，安装已停止"
}

# 遍历所有 agent
$results = @()
foreach ($agent in $AGENTS) {
  Write-Host ""
  Write-Host "━━━ $($agent.name) ━━━"

  if (-not (Test-AgentSelected $agent.name)) {
    Info "被过滤跳过"
    $results += @{name=$agent.name; status="SKIP"}
    continue
  }

  if (-not (Detect-Agent $agent)) {
    Info "未检测到 $($agent.name) (跳过)"
    $results += @{name=$agent.name; status="SKIP"}
    continue
  }

  Success "检测到 $($agent.name)"

  # 安装 skills
  if ($skillDir -and $agent.hasSkills) {
    $r = Install-Skills $agent $skillDir
    if ($r.failed -gt 0) { Warn "skills: $($r.installed) 成功, $($r.failed) 失败" }
    else { Success "skills: $($r.installed) 个已安装" }
  }

  # 合并 MCP
  switch ($agent.format) {
    "json" { Merge-McpJson $agent.configFile $agent.name $agent.rootKey }
    "toml" { Merge-McpToml $agent.configFile $agent.name }
    "yaml" { Merge-McpYaml $agent.configFile $agent.name }
  }

  $instructionDetail = if ([string]::IsNullOrWhiteSpace([string]$agent.instructionFile)) {
    "skills+MCP"
  } elseif ($SKIP_AGENT_INSTRUCTIONS) {
    "skills+MCP (agent instructions skipped)"
  } else {
    "skills+MCP+instructions"
  }
  if (Ensure-AgentInstruction $agent) {
    $results += @{name=$agent.name; status="OK"; detail=$instructionDetail}
  } else {
    $results += @{name=$agent.name; status="FAIL"; detail="Agent instruction update failed"}
  }
}

# Claude Desktop
Write-Host ""
Write-Host "━━━ claude-desktop ━━━"
if (-not (Test-AgentSelected "claude-desktop")) {
  Info "被过滤跳过"
  $results += @{name="claude-desktop"; status="SKIP"}
} elseif (Test-Path $CLAUDE_DESKTOP_CONFIG) {
  Success "检测到 Claude Desktop"
  Merge-McpJson $CLAUDE_DESKTOP_CONFIG "claude-desktop" "mcpServers"
  $results += @{name="claude-desktop"; status="OK"}
} else {
  Info "未检测到 Claude Desktop (跳过)"
  $results += @{name="claude-desktop"; status="SKIP"}
}

# 摘要
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗"
Write-Host "║  安装摘要                                                     ║"
Write-Host "╚══════════════════════════════════════════════════════════════╝"
Write-Host ""
foreach ($r in $results) {
  $detailSuffix = if ($r.detail) { "  ($($r.detail))" } else { "" }
  switch ($r.status) {
    "OK" { Write-Host "  [OK]   $($r.name)$detailSuffix" -ForegroundColor Green }
    "FAIL" { Write-Host "  [FAIL] $($r.name)$detailSuffix" -ForegroundColor Red }
    "SKIP" { Write-Host "  [SKIP] $($r.name)$detailSuffix" -ForegroundColor Yellow }
  }
}

$okCount = @($results | Where-Object { $_.status -eq "OK" }).Count
$failCount = @($results | Where-Object { $_.status -eq "FAIL" }).Count
$skipCount = @($results | Where-Object { $_.status -eq "SKIP" }).Count

Write-Host ""
Write-Host "  总计: $($results.Count) 个 agent"
Write-Host "  成功: $okCount | 失败: $failCount | 跳过: $skipCount"
Write-Host ""

if ($okCount -gt 0) {
  Write-Host "  ✅ 所有检测到的 agent 均已安装完成" -ForegroundColor Green
  Write-Host ""
  Write-Host "  下一步:"
  Write-Host "    1. 配置环境变量 TIMEM_API_KEY (如尚未配置)"
  Write-Host "    2. 重启对应的 Agent 工具"
  Write-Host ""
}
