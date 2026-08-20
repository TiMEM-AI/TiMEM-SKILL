Describe 'COS release workflow' {
  $root = Join-Path $PSScriptRoot '..'
  $workflow = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root '.github' 'workflows' 'ci.yml')
  $uploadScript = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'scripts' 'upload_cos.py')

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

  It 'builds the full release and publishes a latest alias through the upload script' {
    $workflow | Should Match 'scripts/build-release\.sh'
    $workflow | Should Match 'timem-skill-latest\.zip'
    $workflow | Should Match 'scripts/upload_cos\.py'
    $uploadScript | Should Match 'RELEASE_COS_PREFIX'
    $uploadScript | Should Match 'timem-skill-latest\.zip'
    $uploadScript | Should Match 'EnableMD5=True'
  }
}
