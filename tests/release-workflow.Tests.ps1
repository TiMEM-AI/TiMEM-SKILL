Describe 'COS release workflow' {
  $workflowPath = Join-Path $PSScriptRoot '..' '.github' 'workflows' 'ci.yml'
  $workflow = Get-Content -Raw -Encoding UTF8 -LiteralPath $workflowPath

  It 'runs Windows installer tests before the COS publishing job' {
    $workflow | Should Match 'test-installer:'
    $workflow | Should Match 'runs-on: windows-latest'
    $workflow | Should Match 'needs: test-installer'
    $workflow | Should Match 'Invoke-Pester.*tests'
  }

  It 'is triggered when a release artifact or installer changes' {
    $workflow | Should Match 'install-all\.ps1'
    $workflow | Should Match 'install-all\.sh'
    $workflow | Should Match 'README(_zh)?\.md'
    $workflow | Should Match 'scripts/\*\*'
  }

  It 'builds and publishes both the versioned release and latest alias' {
    $workflow | Should Match 'scripts/build-release\.sh'
    $workflow | Should Match 'timem-skill-latest\.zip'
    $workflow | Should Match 'releases/'
    $workflow | Should Match 'EnableMD5=True'
  }
}
