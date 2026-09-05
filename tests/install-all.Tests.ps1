Describe 'install-all.ps1' {
  It 'can be evaluated with the advertised downloaded-source bootstrap' {
    $scriptPath = Join-Path (Join-Path $PSScriptRoot '..') 'install-all.ps1'
    $downloadedSource = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($scriptPath))
    $source = $downloadedSource.TrimStart([char]0xFEFF)
    $firstLine = ($source -split "`r?`n", 2)[0]
    $probe = $firstLine + "`n#>`n'DOWNLOADED_SOURCE_OK'"
    $advertisedBootstrap = [regex]::Escape('(irm https://careerfun-1257357192.cos.ap-beijing.myqcloud.com/installers/install-all.ps1).TrimStart([char]0xFEFF) | iex')

    $source[0] | Should Be '<'
    (Invoke-Expression $probe -ErrorAction Stop) | Should Be 'DOWNLOADED_SOURCE_OK'
    $source | Should Match $advertisedBootstrap
  }

  It 'has no PowerShell parser errors' {
    $scriptPath = Join-Path (Join-Path $PSScriptRoot '..') 'install-all.ps1'
    $tokens = $null
    $errors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
      $scriptPath,
      [ref]$tokens,
      [ref]$errors
    ) | Out-Null

    $errors.Count | Should Be 0
  }

  It 'has no Windows PowerShell 5.1 parser errors' {
    $windowsPowerShell = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if (-not $windowsPowerShell) { return }

    $scriptPath = Join-Path (Join-Path $PSScriptRoot '..') 'install-all.ps1'
    $escapedPath = $scriptPath.Replace("'", "''")
    $command = @"
`$source = Get-Content -Raw -Encoding UTF8 -LiteralPath '$escapedPath'
`$tokens = `$null
`$errors = `$null
[System.Management.Automation.Language.Parser]::ParseInput(`$source, [ref]`$tokens, [ref]`$errors) | Out-Null
if (`$errors.Count -gt 0) {
  `$errors | ForEach-Object { Write-Error (\"{0}:{1}:{2}:{3}\" -f `$_.ErrorId, `$_.Extent.StartLineNumber, `$_.Extent.StartColumnNumber, `$_.Message) }
  exit 1
}
"@
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    & $windowsPowerShell.Source -NoProfile -NonInteractive -EncodedCommand $encodedCommand 2>&1 | Out-Null
    $LASTEXITCODE | Should Be 0
  }

  It 'has no parser errors when invoked directly by Windows PowerShell 5.1' {
    $windowsPowerShell = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if (-not $windowsPowerShell) { return }

    $scriptPath = Join-Path (Join-Path $PSScriptRoot '..') 'install-all.ps1'
    $previousSource = $env:TIMEM_SKILL_SOURCE_DIR
    try {
      $env:TIMEM_SKILL_SOURCE_DIR = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
      $output = & $windowsPowerShell.Source -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $scriptPath -ApiKey 'test-parser-only' -Agent '__parser_probe__' 2>&1 | Out-String
      $LASTEXITCODE | Should Be 0
    } finally {
      $env:TIMEM_SKILL_SOURCE_DIR = $previousSource
    }

    ($output -match 'ParserError|Try statement is missing|Missing closing|Unexpected token') | Should Be $false
  }
}
