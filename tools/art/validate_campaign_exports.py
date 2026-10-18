"""Verify preserved sources, output hashes, local links and gameplay ownership."""
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def previous(path):
    return subprocess.check_output(['git', 'show', 'HEAD:' + path], cwd=ROOT).decode('utf-8')

def filtered(text, patterns):
    return '\n'.join(line for line in text.splitlines()
                     if line.strip() and not any(re.search(p, line) for p in patterns))

def main():
    source = ROOT / 'art/source/campaign-v1'
    manifest = json.loads((source / 'generation-manifest.json').read_text(encoding='utf-8'))
    assert len(manifest['entries']) == 23
    for entry in manifest['entries']:
        assert entry['args']['prompt'].strip()
        assert (source / entry['preserved_file']).is_file()
    report = json.loads((ROOT / 'art/concepts/campaign-v1/asset-validation.json').read_text())
    for path, expected in report['sha256'].items():
        assert digest(ROOT / path) == expected, path
    for path, expected in report['source_sha256'].items():
        assert digest(source / path) == expected, path
    portraits = json.loads((ROOT / 'art/concepts/campaign-v1/portrait-validation.json').read_text())
    for name, record in portraits['characters'].items():
        for path, expected in record['sha256'].items():
            assert digest(ROOT / 'art/portraits/main-heroes-v1' / name / path) == expected
    for name in ['goblin_queen', 'goblin_archer', 'goblin_guard', 'goblin_drummer', 'great_rat', 'webspinner']:
        path = 'data/enemies/' + name + '.tres'
        patterns = [r'^\[ext_resource type="PackedScene"', r'^tint = ', r'^sprite_scale = ']
        assert filtered(previous(path), patterns) == filtered((ROOT / path).read_text(), patterns), path
    for name in ['corin', 'alwen']:
        path = 'data/companions/' + name + '.tres'
        patterns = [r'^\[ext_resource.* id="[23]"\]$']
        assert filtered(previous(path), patterns) == filtered((ROOT / path).read_text(), patterns), path
    for name in ['broken_short_sword', 'cracked_staff', 'padded_coat']:
        path = 'data/gear/' + name + '.tres'
        patterns = [r'^\[ext_resource.* id="campaign_art"\]$', r'^icon = ']
        assert filtered(previous(path), patterns) == filtered((ROOT / path).read_text(), patterns), path
    for path in [ROOT / 'docs' / n for n in ['campaign-art-pass.md', 'camp-dressing-review.md', 'hand-drawn-map-design.md']]:
        for target in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
            if '://' not in target and not target.startswith('#'):
                assert (path.parent / target.split('#')[0]).exists(), (path.name, target)
    print('PASS: 23 preserved prompts/masters, all export hashes and local links; hero/enemy/gear gameplay values unchanged.')

if __name__ == '__main__':
    main()
