Describe 'install-all.ps1' {
  It 'has no PowerShell parser errors' {
    $scriptPath = Join-Path $PSScriptRoot '..' 'install-all.ps1'
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

    $scriptPath = Join-Path $PSScriptRoot '..' 'install-all.ps1'
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
}
