Describe 'COS release workflow' {
  $root = Join-Path $PSScriptRoot '..'
  $workflow = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path (Join-Path (Join-Path $root '.github') 'workflows') 'ci.yml')
  $uploadScript = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path (Join-Path $root 'scripts') 'upload_cos.py')

  It 'gates publishing on the Windows and Bash installer jobs' {
    $workflow | Should Match '(?m)^\s{2}test-installer:'
    $workflow | Should Match "runs-on:.*RUNNER_LABEL_WINDOWS.*windows-latest"
    $workflow | Should Match 'Invoke-Pester.*tests'
    $workflow | Should Match 'needs:\s*\[test-installer,\s*test-shell-installer\]'
    $workflow | Should Match "cancel-in-progress:.*github\.event_name.*pull_request"
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
    $workflow | Should Match 'timem-skill/dist/full/timem-memory-skill/SKILL\.md'
    $workflow | Should Match 'timem-skill/dist/standalone/timem-coding-memory/SKILL\.md'
    $workflow | Should Match 'timem-skill/dist/standalone/timem-general-memory/SKILL\.md'
    $workflow | Should Match 'timem-skill/skills/timem-writing-memory/SKILL\.md'
    $uploadScript | Should Match 'RELEASE_COS_PREFIX'
    $uploadScript | Should Match 'timem-skill-latest\.zip'
    $uploadScript | Should Match 'EnableMD5=True'
    $uploadScript | Should Match 'head_object'
    $uploadScript | Should Match 'latest\.json'
    $buildJob = $workflow.Substring($workflow.IndexOf('build-packages:'))
    $buildJob | Should Match 'name:\s*Build, verify and publish release artifacts'
    $buildJob | Should Match 'name:\s*Upload verified COS release snapshot'
    $buildJob | Should Match 'python scripts/build_cos_artifacts\.py'
    $workflow | Should Match 'python -m unittest tests\.test_cos_artifacts tests\.test_cos_upload_plan'
    $buildJob | Should Match 'COS_FULL_PREFIX:'
    $buildJob | Should Match 'INSTALLER_COS_PREFIX:'
    $buildJob | Should Match 'actions/checkout@v4'
  }
}
