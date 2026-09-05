"""Exercise the actual downloader functions against a local COS fixture."""
import functools
import hashlib
import http.server
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass


class CosInstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        release_dir = self.root / 'releases'
        release_dir.mkdir()
        self.archive = release_dir / 'timem-skill-test1.zip'
        with zipfile.ZipFile(self.archive, 'w') as archive:
            for path in ('dist/standalone/timem-coding-memory',
                         'dist/standalone/timem-general-memory',
                         'skills/timem-writing-memory'):
                archive.writestr('timem-skill/' + path + '/SKILL.md', 'test skill')
            archive.writestr('timem-skill/dist/full/timem-memory-skill/references/new/nested.txt', 'future')
        manifest = {'version': 'test1', 'artifacts': {'release': {
            'size': self.archive.stat().st_size,
            'sha256': hashlib.sha256(self.archive.read_bytes()).hexdigest()}}}
        (release_dir / 'release-manifest-test1.json').write_text(json.dumps(manifest))
        (release_dir / 'latest.json').write_text(json.dumps({
            'version': 'test1', 'artifacts': {
                'release': 'releases/timem-skill-test1.zip',
                'manifest': 'releases/release-manifest-test1.json'}}))
        self.server = http.server.ThreadingHTTPServer(
            ('127.0.0.1', 0), functools.partial(QuietHandler, directory=str(self.root)))
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.base = 'http://127.0.0.1:' + str(self.server.server_port)

    def run_downloader(self):
        work = self.root / 'work'
        work.mkdir(exist_ok=True)
        if os.name == 'nt':
            shell = shutil.which('powershell.exe')
            if not shell:
                self.skipTest('Windows PowerShell is unavailable')
            source = (ROOT / 'install-all.ps1').read_text(encoding='utf-8-sig')
            body = source.split('function Download-Skills {', 1)[1].split('# Skill 安装', 1)[0]
            body = 'function Download-Skills {' + body
            # No agent configuration or installation is executed by this harness.
            probe = "function Info($x) {}\nfunction Success($x) {}\nfunction Err($x) { Write-Host $x }\n"
            probe += "$TIMEM_COS_BASE_URL='" + self.base + "'\n$ALL_SKILLS=@()\n"
            probe += body + "\n$result=Download-Skills\nif (-not $result) { exit 1 }\nWrite-Output $result\n"
            script = work / 'probe.ps1'
            script.write_text(probe, encoding='utf-8-sig')
            env = dict(os.environ, TEMP=str(work))
            return subprocess.run([shell, '-NoProfile', '-File', str(script)],
                                  env=env, capture_output=True, text=True)
        source = (ROOT / 'install-all.sh').read_text()
        body = source.split('download_skills() {', 1)[1].split('# Skill 安装', 1)[0]
        probe = 'info() { :; }; success() { :; }; error() { :; }; DRY_RUN=false\n'
        probe += 'TIMEM_COS_BASE_URL="$1"; TMPDIR_WORK="$2"\n'
        probe += 'download_skills() {' + body + '\ndownload_skills\n'
        script = work / 'probe.sh'
        script.write_text(probe)
        return subprocess.run(['bash', str(script), self.base, str(work)],
                              capture_output=True, text=True)

    def test_extracts_versioned_release_including_new_nested_files(self):
        result = self.run_downloader()
        self.assertEqual(0, result.returncode, result.stderr + result.stdout)
        matches = list((self.root / 'work').rglob('nested.txt'))
        self.assertEqual(1, len(matches))
        self.assertEqual('future', matches[0].read_text())

    def test_rejects_corrupted_release_before_extraction(self):
        self.archive.write_bytes(self.archive.read_bytes() + b'tampered')
        result = self.run_downloader()
        self.assertNotEqual(0, result.returncode)
        self.assertEqual([], list((self.root / 'work').rglob('SKILL.md')))


if __name__ == '__main__':
    unittest.main()
