"""Fetch only pinned CC0 pack data, verifying every official Git blob."""
import hashlib
import json
from pathlib import Path
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/third-party/kaykit-mine-props-v1'
manifest = json.loads((SOURCE / 'intake.json').read_text(encoding='utf-8'))
for entry in manifest['files']:
    url = ('https://raw.githubusercontent.com/' + manifest['repository'] + '/'
           + manifest['commit'] + '/' + entry['official_path'])
    with urlopen(url, timeout=45) as response:
        data = response.read()
    assert len(data) == entry['bytes']
    blob = ('blob ' + str(len(data)) + '\0').encode() + data
    assert hashlib.sha1(blob).hexdigest() == entry['git_blob_sha1']
    target = SOURCE / entry['file']
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    entry['sha256'] = hashlib.sha256(data).hexdigest()
assert b'CC0' in (SOURCE / 'halloween/LICENSE.txt').read_bytes()
(SOURCE / 'provenance.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print('Verified', len(manifest['files']), 'pinned source files')
