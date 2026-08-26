Describe 'COS release workflow' {
  $root = Join-Path $PSScriptRoot '..'
  $workflow = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path (Join-Path (Join-Path $root '.github') 'workflows') 'ci.yml')
  $uploadScript = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path (Join-Path $root 'scripts') 'upload_cos.py')

  It 'runs Windows installer tests before the COS publishing job' {
    $workflow | Should Match 'test-installer:'
    $workflow | Should Match 'runs-on: windows-latest'
    $workflow | Should Match 'needs:\s*\[test-installer,\s*test-shell-installer\]'
    $workflow | Should Match 'Invoke-Pester.*tests'
  }

  It 'runs Bash installer tests before building release packages' {
    $workflow | Should Match 'test-shell-installer:'
    $workflow | Should Match 'bash tests/install-all\.sh\.Tests\.sh'
    $buildJob = $workflow.Substring($workflow.IndexOf('build-packages:'))
    $buildJob | Should Match 'needs:\s*\[test-installer,\s*test-shell-installer\]'
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
    $workflow | Should Match 'timem-skill/install-all\.sh.*cmp -s install-all\.sh'
    $uploadScript | Should Match 'RELEASE_COS_PREFIX'
    $uploadScript | Should Match 'timem-skill-latest\.zip'
    $uploadScript | Should Match 'EnableMD5=True'
    $publishJob = $workflow.Substring($workflow.IndexOf('publish-to-cos:'))
    $publishJob | Should Match 'actions/checkout@v4'
  }
}
