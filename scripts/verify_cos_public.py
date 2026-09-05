#!/usr/bin/env python3
"""Verify the published snapshot and installer aliases without COS credentials."""
import argparse
import hashlib
import json
from urllib.request import Request, urlopen

BASE_URL = 'https://careerfun-1257357192.cos.ap-beijing.myqcloud.com'


def fetch(key):
    request = Request(f'{BASE_URL}/{key}', headers={'Cache-Control': 'no-cache'})
    with urlopen(request, timeout=120) as response:
        return response.read()


def verify_public(expected_version):
    latest = json.loads(fetch('releases/latest.json'))
    if latest['version'] != expected_version:
        raise RuntimeError('Public latest.json does not point to this release')
    manifest = json.loads(fetch(latest['artifacts']['manifest']))
    if manifest['version'] != expected_version:
        raise RuntimeError('Public manifest version mismatch')
    for name in ('release', 'full_skill', 'install_all_ps1', 'install_all_sh'):
        record = manifest['artifacts'][name]
        keys = [latest['artifacts'][name]]
        if name in ('install_all_ps1', 'install_all_sh'):
            keys.append('installers/' + record['file'])
        for key in keys:
            content = fetch(key)
            if len(content) != record['size'] or hashlib.sha256(content).hexdigest() != record['sha256']:
                raise RuntimeError(f'Public artifact checksum mismatch: {key}')
            print(f'Public download verified: {BASE_URL}/{key}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', required=True)
    verify_public(parser.parse_args().version)
