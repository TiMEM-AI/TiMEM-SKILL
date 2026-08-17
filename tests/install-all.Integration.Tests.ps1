function Invoke-InstallAllInSandbox {
  param(
    [string]$AgentName,
    [string]$TestRoot
  )

  $scriptPath = Join-Path $PSScriptRoot '..' 'install-all.ps1'
  $escapedPath = $scriptPath.Replace("'", "''")
  $command = "Get-Content -Raw -Encoding UTF8 -LiteralPath '$escapedPath' | Invoke-Expression"
  $environment = @{
    USERPROFILE = Join-Path $TestRoot 'profile'
    APPDATA = Join-Path $TestRoot 'appdata'
    TEMP = Join-Path $TestRoot 'temp'
    TIMEM_API_KEY = 'test-key-12345678'
    TIMEM_AGENT = $AgentName
  }
  $previous = @{}

  try {
    foreach ($name in $environment.Keys) {
      $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
      [Environment]::SetEnvironmentVariable($name, $environment[$name], 'Process')
    }

    $output = "3`n" | & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $command 2>&1 | Out-String
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
        & $python.Source -c 'import sys,tomllib; tomllib.load(open(sys.argv[1], "rb"))' $configFile
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
}
