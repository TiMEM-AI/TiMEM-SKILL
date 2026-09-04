function Invoke-InstallAllInSandbox {
  param(
    [string]$AgentName,
    [string]$TestRoot,
    [switch]$UseCli,
    [switch]$SkipAgentInstructions,
    [hashtable]$AdditionalEnvironment = @{}
  )

  $scriptPath = Join-Path (Join-Path $PSScriptRoot '..') 'install-all.ps1'
  $escapedPath = $scriptPath.Replace("'", "''")
  $command = "Get-Content -Raw -Encoding UTF8 -LiteralPath '$escapedPath' | Invoke-Expression"
  $environment = @{
    USERPROFILE = Join-Path $TestRoot 'profile'
    APPDATA = Join-Path $TestRoot 'appdata'
    TEMP = Join-Path $TestRoot 'temp'
    TIMEM_API_KEY = 'test-key-12345678'
    TIMEM_AGENT = if ($UseCli) { $null } else { $AgentName }
    CODEX_HOME = $null
    QODER_CONFIG_DIR = $null
    TRAE_MCP_CONFIG = $null
    OPENCLAW_WORKSPACE_DIR = $null
    OPENCLAW_PROFILE = $null
    HERMES_HOME = $null
  }
  foreach ($entry in $AdditionalEnvironment.GetEnumerator()) {
    $environment[$entry.Key] = $entry.Value
  }
  $previous = @{}

  try {
    foreach ($name in $environment.Keys) {
      $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
      [Environment]::SetEnvironmentVariable($name, $environment[$name], 'Process')
    }

    if ($UseCli) {
      $arguments = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $scriptPath,
        '-ApiKey', 'test-key-12345678',
        '-Agent', $AgentName
      )
      if ($SkipAgentInstructions) {
        $arguments += '-SkipAgentInstructions'
      }
      $output = "1`ny`n" | & powershell.exe @arguments 2>&1 | Out-String
    } else {
      $output = "3`n" | & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $command 2>&1 | Out-String
    }
    return [pscustomobject]@{
      ExitCode = $LASTEXITCODE
      Output = $output
    }
  } finally {
    foreach ($name in $environment.Keys) {
      [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process')
    }
  }
}

Describe 'install-all.ps1 Windows functional behavior' {
  It 'keeps Codex TOML valid across repeated installs' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.codex'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'codex' -TestRoot $testRoot
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'codex' -TestRoot $testRoot
      $configFile = Join-Path $configDir 'config.toml'

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0
      (Test-Path -LiteralPath $configFile) | Should Be $true
      (Test-Path -LiteralPath (Join-Path $configDir 'skills\timem-coding-memory\SKILL.md')) | Should Be $true

      $bytes = [IO.File]::ReadAllBytes($configFile)
      $hasUtf8Bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
      $hasUtf8Bom | Should Be $false

      $content = [IO.File]::ReadAllText($configFile)
      ([regex]::Matches($content, '(?m)^\[mcp_servers\.TiMEM-SPACE\]\s*$').Count) | Should Be 1
      ([regex]::Matches($content, '(?m)^\[mcp_servers\.TiMEM-SPACE\.env\]\s*$').Count) | Should Be 1

      $python = Get-Command python -ErrorAction SilentlyContinue
      if ($python) {
        & $python.Source -c "import sys,tomllib; tomllib.load(open(sys.argv[1], 'rb'))" $configFile
        $LASTEXITCODE | Should Be 0
      }
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'merges Cursor JSON in Windows PowerShell 5.1 across repeated installs' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.cursor'
    $configFile = Join-Path $configDir 'mcp.json'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      $seedConfig = '{"mcpServers":{"existing":{"url":"https://existing.example/mcp"}}}'
      [IO.File]::WriteAllText($configFile, $seedConfig, (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'cursor' -TestRoot $testRoot
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'cursor' -TestRoot $testRoot

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0

      $bytes = [IO.File]::ReadAllBytes($configFile)
      $hasUtf8Bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
      $hasUtf8Bom | Should Be $false

      $config = Get-Content -Raw -Encoding UTF8 -LiteralPath $configFile | ConvertFrom-Json
      ($config.mcpServers.PSObject.Properties.Name -contains 'existing') | Should Be $true
      ($config.mcpServers.PSObject.Properties.Name -contains 'TiMEM-SPACE') | Should Be $true
      ($null -eq $config.mcpServers.mcpServers) | Should Be $true
      ($config.mcpServers.'TiMEM-SPACE'.PSObject.Properties.Name -contains 'type') | Should Be $false
      (Test-Path -LiteralPath (Join-Path $configDir 'AGENTS.md')) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'writes Claude Code user MCP into .claude.json without collapsing case-distinct keys' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $claudeDir = Join-Path $profileDir '.claude'
    $configFile = Join-Path $profileDir '.claude.json'
    $legacySettingsFile = Join-Path $claudeDir 'settings.json'
    $seedConfig = @'
{
  "projects": {
    "Workspace": {"enabled": true},
    "workspace": {"enabled": false}
  },
  "mcpServers": {
    "existing": {"url": "https://existing.example/mcp"}
  }
}
'@

    try {
      New-Item -ItemType Directory -Force -Path $claudeDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText($configFile, $seedConfig, (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'claude-code' -TestRoot $testRoot
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'claude-code' -TestRoot $testRoot
      $content = [IO.File]::ReadAllText($configFile)

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0
      ([regex]::Matches($content, '"Workspace"\s*:').Count) | Should Be 1
      ([regex]::Matches($content, '"workspace"\s*:').Count) | Should Be 1
      ([regex]::Matches($content, '"existing"\s*:').Count) | Should Be 1
      ([regex]::Matches($content, '"TiMEM-SPACE"\s*:').Count) | Should Be 1
      (Test-Path -LiteralPath $legacySettingsFile) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'uses the current TRAE Windows user MCP path across repeated installs' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path (Join-Path (Join-Path $testRoot 'appdata') 'Trae') 'User'
    $configFile = Join-Path $configDir 'mcp.json'
    $legacyConfigFile = Join-Path (Join-Path $profileDir '.trae') 'mcp.json'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText($configFile, '{"mcpServers":{"existing":{"url":"https://existing.example/mcp"}}}', (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'trae' -TestRoot $testRoot
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'trae' -TestRoot $testRoot
      $config = Get-Content -Raw -Encoding UTF8 -LiteralPath $configFile | ConvertFrom-Json

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0
      ($config.mcpServers.PSObject.Properties.Name -contains 'existing') | Should Be $true
      ($config.mcpServers.PSObject.Properties.Name -contains 'TiMEM-SPACE') | Should Be $true
      ([regex]::Matches([IO.File]::ReadAllText($configFile), '"TiMEM-SPACE"\s*:').Count) | Should Be 1
      (Test-Path -LiteralPath $legacyConfigFile) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'detects legacy TRAE state before creating the current user MCP config' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $legacyStateDir = Join-Path $profileDir '.trae'
    $configFile = Join-Path (Join-Path (Join-Path (Join-Path $testRoot 'appdata') 'Trae') 'User') 'mcp.json'

    try {
      New-Item -ItemType Directory -Force -Path $legacyStateDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null

      $run = Invoke-InstallAllInSandbox -AgentName 'trae' -TestRoot $testRoot
      $config = Get-Content -Raw -Encoding UTF8 -LiteralPath $configFile | ConvertFrom-Json

      $run.ExitCode | Should Be 0
      ($config.mcpServers.PSObject.Properties.Name -contains 'TiMEM-SPACE') | Should Be $true
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'creates one TRAE global user rule in the documented directory' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path (Join-Path (Join-Path $testRoot 'appdata') 'Trae') 'User'
    $configFile = Join-Path $configDir 'mcp.json'
    $ruleFile = Join-Path (Join-Path (Join-Path $profileDir '.trae') 'user_rules') 'timem-memory.md'
    $instruction = '每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程'
    $expectedContent = (@(
      '---',
      'alwaysApply: true',
      '---',
      '',
      $instruction,
      ''
    ) -join [char]10)

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText($configFile, '{"mcpServers":{}}', (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'trae' -TestRoot $testRoot
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'trae' -TestRoot $testRoot

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0
      [IO.File]::ReadAllText($ruleFile) | Should Be $expectedContent
      (Test-Path -LiteralPath (Join-Path $profileDir '.trae\rules\timem-memory.md')) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'creates an always-applied Cursor user rule once' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.cursor'
    $configFile = Join-Path $configDir 'mcp.json'
    $ruleFile = Join-Path $configDir 'rules\timem-memory.mdc'
    $instruction = '每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程'
    $expectedContent = (@(
      '---',
      'description: "TiMEM memory workflow"',
      'alwaysApply: true',
      '---',
      '',
      $instruction,
      ''
    ) -join [char]10)

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText($configFile, '{"mcpServers":{}}', (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'cursor' -TestRoot $testRoot -UseCli
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'cursor' -TestRoot $testRoot -UseCli

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0
      (Test-Path -LiteralPath $ruleFile) | Should Be $true
      [IO.File]::ReadAllText($ruleFile) | Should Be $expectedContent
      (Test-Path -LiteralPath (Join-Path $configDir 'AGENTS.md')) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'honors a single CLI agent and leaves Claude Desktop unchanged' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.codex'
    $desktopDir = Join-Path (Join-Path $testRoot 'appdata') 'Claude'
    $desktopConfig = Join-Path $desktopDir 'claude_desktop_config.json'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,$desktopDir,(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText(
        (Join-Path $configDir 'config.toml'),
        '# existing codex config' + [Environment]::NewLine,
        (New-Object System.Text.UTF8Encoding($false))
      )
      $seedDesktopConfig = '{"mcpServers":{"existing":{"url":"https://existing.example/mcp"}}}'
      [IO.File]::WriteAllText($desktopConfig, $seedDesktopConfig, (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'codex' -TestRoot $testRoot -UseCli
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'codex' -TestRoot $testRoot -UseCli
      $codexConfig = [IO.File]::ReadAllText((Join-Path $configDir 'config.toml'))
      $desktopAfter = [IO.File]::ReadAllText($desktopConfig)

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0
      ($codexConfig -match 'TiMEM-SPACE') | Should Be $true
      $desktopAfter | Should Be $seedDesktopConfig
      ($firstRun.Output -match 'claude-desktop') | Should Be $true
      ($firstRun.Output -match '成功:\s+1\s+\|\s+失败:\s+0\s+\|\s+跳过:\s+8') | Should Be $true
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'treats comma-separated agent filters as a set' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $codexDir = Join-Path $profileDir '.codex'
    $cursorDir = Join-Path $profileDir '.cursor'
    $desktopDir = Join-Path (Join-Path $testRoot 'appdata') 'Claude'
    $desktopConfig = Join-Path $desktopDir 'claude_desktop_config.json'

    try {
      New-Item -ItemType Directory -Force -Path $codexDir,$cursorDir,$desktopDir,(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText((Join-Path $codexDir 'config.toml'), '# codex' + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
      [IO.File]::WriteAllText((Join-Path $cursorDir 'mcp.json'), '{"mcpServers":{}}', (New-Object System.Text.UTF8Encoding($false)))
      $seedDesktopConfig = '{"mcpServers":{"existing":{"url":"https://existing.example/mcp"}}}'
      [IO.File]::WriteAllText($desktopConfig, $seedDesktopConfig, (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'codex,cursor' -TestRoot $testRoot
      $codexConfig = [IO.File]::ReadAllText((Join-Path $codexDir 'config.toml'))
      $cursorConfig = [IO.File]::ReadAllText((Join-Path $cursorDir 'mcp.json'))
      $desktopAfter = [IO.File]::ReadAllText($desktopConfig)

      $firstRun.ExitCode | Should Be 0
      ($codexConfig -match 'TiMEM-SPACE') | Should Be $true
      ($cursorConfig -match 'TiMEM-SPACE') | Should Be $true
      $desktopAfter | Should Be $seedDesktopConfig
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'merges Hermes YAML without duplicate mcp_servers keys across repeated installs' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.hermes'
    $configFile = Join-Path $configDir 'config.yaml'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      $seedConfig = @"
mcp_servers:
  existing:
    url: "https://existing.example/mcp"
other_setting: true
"@
      [IO.File]::WriteAllText($configFile, $seedConfig, (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'hermes' -TestRoot $testRoot
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'hermes' -TestRoot $testRoot

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0

      $bytes = [IO.File]::ReadAllBytes($configFile)
      $hasUtf8Bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
      $hasUtf8Bom | Should Be $false

      $content = [IO.File]::ReadAllText($configFile)
      ([regex]::Matches($content, '(?m)^mcp_servers:\s*$').Count) | Should Be 1
      ([regex]::Matches($content, '(?m)^  existing:\s*$').Count) | Should Be 1
      ([regex]::Matches($content, '(?m)^  TiMEM-SPACE:\s*$').Count) | Should Be 1
      ($content -match '(?m)^other_setting: true\s*$') | Should Be $true
      ($content -match '(?m)^    type: http\s*$') | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'injects one TiMEM instruction into Codex AGENTS.md across repeated installs' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.codex'
    $instructionFile = Join-Path $configDir 'AGENTS.md'
    $instruction = '每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText(
        (Join-Path $configDir 'config.toml'),
        '# existing codex config' + [Environment]::NewLine,
        (New-Object System.Text.UTF8Encoding($false))
      )
      [IO.File]::WriteAllText(
        $instructionFile,
        '# Existing global instructions' + [Environment]::NewLine,
        (New-Object System.Text.UTF8Encoding($false))
      )

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'codex' -TestRoot $testRoot
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'codex' -TestRoot $testRoot
      $content = [IO.File]::ReadAllText($instructionFile)
      $expectedContent = '# Existing global instructions' + [Environment]::NewLine + $instruction + [Environment]::NewLine

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0
      $content | Should Be $expectedContent
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'honors CODEX_HOME for Codex config and AGENTS.md' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $testRoot 'custom-codex'
    $instructionFile = Join-Path $configDir 'AGENTS.md'
    $defaultInstructionFile = Join-Path (Join-Path $profileDir '.codex') 'AGENTS.md'
    $instruction = '每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText((Join-Path $configDir 'config.toml'), '# existing codex config' + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))

      $run = Invoke-InstallAllInSandbox -AgentName 'codex' -TestRoot $testRoot -AdditionalEnvironment @{ CODEX_HOME = $configDir }

      $run.ExitCode | Should Be 0
      [IO.File]::ReadAllText($instructionFile) | Should Be ($instruction + [char]10)
      ([IO.File]::ReadAllText((Join-Path $configDir 'config.toml')) -match 'TiMEM-SPACE') | Should Be $true
      (Test-Path -LiteralPath $defaultInstructionFile) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'preserves Claude Code instructions that already mention 太忆空间' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.claude'
    $instructionFile = Join-Path $configDir 'CLAUDE.md'
    $seedInstruction = '# Team guidance' + [Environment]::NewLine + '本项目已接入太忆空间。' + [Environment]::NewLine

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText($instructionFile, $seedInstruction, (New-Object System.Text.UTF8Encoding($false)))

      $run = Invoke-InstallAllInSandbox -AgentName 'claude-code' -TestRoot $testRoot

      $run.ExitCode | Should Be 0
      [IO.File]::ReadAllText($instructionFile) | Should Be $seedInstruction
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'injects one TiMEM instruction into Qoder user AGENTS.md across repeated installs' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.qoder'
    $instructionFile = Join-Path $configDir 'AGENTS.md'
    $instruction = '每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText((Join-Path $configDir 'mcp.json'), '{"mcpServers":{}}', (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'qoder' -TestRoot $testRoot
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'qoder' -TestRoot $testRoot

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0
      [IO.File]::ReadAllText($instructionFile) | Should Be ($instruction + [char]10)
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'honors QODER_CONFIG_DIR for Qoder user instructions' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $testRoot 'custom-qoder'
    $instructionFile = Join-Path $configDir 'AGENTS.md'
    $defaultInstructionFile = Join-Path (Join-Path $profileDir '.qoder') 'AGENTS.md'
    $instruction = '每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText((Join-Path $configDir 'settings.json'), '{"mcpServers":{}}', (New-Object System.Text.UTF8Encoding($false)))

      $run = Invoke-InstallAllInSandbox -AgentName 'qoder' -TestRoot $testRoot -AdditionalEnvironment @{ QODER_CONFIG_DIR = $configDir }

      $run.ExitCode | Should Be 0
      [IO.File]::ReadAllText($instructionFile) | Should Be ($instruction + [char]10)
      (Test-Path -LiteralPath $defaultInstructionFile) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'injects OpenClaw instructions into resolved agent workspaces' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.openclaw'
    $defaultWorkspace = Join-Path $testRoot 'openclaw-default-workspace'
    $workWorkspace = Join-Path $profileDir '.openclaw-work'
    $opsWorkspace = Join-Path $configDir 'workspace-ops'
    $researchWorkspace = Join-Path $profileDir '.openclaw-research'
    $configuredDefaultWorkspace = Join-Path $profileDir '.configured-openclaw'
    $instruction = '每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程'
    $config = @'
{"agents":{"defaults":{"workspace":"~/.configured-openclaw"},"list":[{"id":"work","workspace":"~/.openclaw-work"},{"id":"ops"}],"entries":{"research":{"workspace":"~/.openclaw-research"}}},"mcp":{"servers":{}}}
'@

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText((Join-Path $configDir 'openclaw.json'), $config, (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'openclaw' -TestRoot $testRoot -AdditionalEnvironment @{ OPENCLAW_WORKSPACE_DIR = $defaultWorkspace }
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'openclaw' -TestRoot $testRoot -AdditionalEnvironment @{ OPENCLAW_WORKSPACE_DIR = $defaultWorkspace }

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0
      foreach ($instructionFile in @(
        (Join-Path $defaultWorkspace 'AGENTS.md'),
        (Join-Path $workWorkspace 'AGENTS.md'),
        (Join-Path $opsWorkspace 'AGENTS.md'),
        (Join-Path $researchWorkspace 'AGENTS.md')
      )) {
        [IO.File]::ReadAllText($instructionFile) | Should Be ($instruction + [char]10)
      }
      (Test-Path -LiteralPath (Join-Path $configuredDefaultWorkspace 'AGENTS.md')) | Should Be $false
      (Test-Path -LiteralPath (Join-Path $configDir 'AGENTS.md')) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'appends TiMEM instruction to an existing Hermes SOUL.md at HERMES_HOME' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $testRoot 'custom-hermes'
    $instructionFile = Join-Path $configDir 'SOUL.md'
    $defaultInstructionFile = Join-Path (Join-Path $profileDir '.hermes') 'SOUL.md'
    $instruction = '每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText((Join-Path $configDir 'config.yaml'), 'model: test' + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
      [IO.File]::WriteAllText($instructionFile, '# Existing Hermes soul' + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))

      $run = Invoke-InstallAllInSandbox -AgentName 'hermes' -TestRoot $testRoot -AdditionalEnvironment @{ HERMES_HOME = $configDir }

      $run.ExitCode | Should Be 0
      [IO.File]::ReadAllText($instructionFile) | Should Be ('# Existing Hermes soul' + [Environment]::NewLine + $instruction + [Environment]::NewLine)
      (Test-Path -LiteralPath $defaultInstructionFile) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'does not create a missing Hermes SOUL.md' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $configDir = Join-Path $testRoot 'custom-hermes'
    $instructionFile = Join-Path $configDir 'SOUL.md'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText((Join-Path $configDir 'config.yaml'), 'model: test' + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))

      $run = Invoke-InstallAllInSandbox -AgentName 'hermes' -TestRoot $testRoot -AdditionalEnvironment @{ HERMES_HOME = $configDir }

      $run.ExitCode | Should Be 0
      (Test-Path -LiteralPath $instructionFile) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'appends TiMEM instruction to an existing WorkBuddy SOUL.md' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.workbuddy'
    $instructionFile = Join-Path $configDir 'SOUL.md'
    $instruction = '每次对话都要查看timem-memory的skill，并调用TiMEM-SPACE中合适的接口进行正确的记忆传输流程'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null
      [IO.File]::WriteAllText($instructionFile, '# Existing WorkBuddy soul' + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))

      $firstRun = Invoke-InstallAllInSandbox -AgentName 'workbuddy' -TestRoot $testRoot
      $secondRun = Invoke-InstallAllInSandbox -AgentName 'workbuddy' -TestRoot $testRoot

      $firstRun.ExitCode | Should Be 0
      $secondRun.ExitCode | Should Be 0
      [IO.File]::ReadAllText($instructionFile) | Should Be ('# Existing WorkBuddy soul' + [Environment]::NewLine + $instruction + [Environment]::NewLine)
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'does not create a missing WorkBuddy SOUL.md' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.workbuddy'
    $instructionFile = Join-Path $configDir 'SOUL.md'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null

      $run = Invoke-InstallAllInSandbox -AgentName 'workbuddy' -TestRoot $testRoot

      $run.ExitCode | Should Be 0
      (Test-Path -LiteralPath $instructionFile) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }

  It 'does not create Codex AGENTS.md when agent instruction injection is skipped' {
    if (-not (Get-Command powershell.exe -ErrorAction SilentlyContinue)) { return }

    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('timem-install-test-' + [guid]::NewGuid().ToString('N'))
    $profileDir = Join-Path $testRoot 'profile'
    $configDir = Join-Path $profileDir '.codex'
    $instructionFile = Join-Path $configDir 'AGENTS.md'

    try {
      New-Item -ItemType Directory -Force -Path $configDir,(Join-Path $testRoot 'appdata'),(Join-Path $testRoot 'temp') | Out-Null

      $run = Invoke-InstallAllInSandbox -AgentName 'codex' -TestRoot $testRoot -UseCli -SkipAgentInstructions

      $run.ExitCode | Should Be 0
      (Test-Path -LiteralPath $instructionFile) | Should Be $false
    } finally {
      if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
      }
    }
  }
}
