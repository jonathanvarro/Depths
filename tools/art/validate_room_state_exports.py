"""Source/output provenance and unchanged event rules for #46."""
from pathlib import Path
import hashlib,json,re,subprocess
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def old(path):return subprocess.check_output(['git','show','HEAD:'+path],cwd=ROOT)

def main():
    source=ROOT/'art/source/room-states-v1'
    manifest=json.loads((source/'generation-manifest.json').read_text(encoding='utf-8'))
    assert len(manifest['entries'])==10
    for entry in manifest['entries']:
        assert entry['args']['prompt'].strip()
        assert entry['args']['transparent_background'] is True
        assert (source/entry['preserved_file']).exists()
    report=json.loads((ROOT/'art/concepts/room-states-v1/export-validation.json').read_text())
    assert len(report['assets'])==11
    for path,expected in report['sha256'].items():assert sha(ROOT/path)==expected,path
    for path,expected in report['source_sha256'].items():assert sha(source/path)==expected,path
    for path,expected in report['original_sha256'].items():
        assert sha(ROOT/path)==expected,path
        assert hashlib.sha256(old(path)).hexdigest()==expected,path
    catalog=json.loads((ROOT/'art/props/room-states-v1/catalog.json').read_text())
    for entry in catalog['props'].values():
        path='data/events/'+entry['event']+'.tres'
        def unchanged(text):
            return '\n'.join(line for line in text.splitlines() if not (line.startswith('[ext_resource type="PackedScene"') and 'id="prop"' in line))
        assert unchanged(old(path).decode('utf-8'))==unchanged((ROOT/path).read_text(encoding='utf-8')),path
    for name in ['hollow-floor-used','still-pool-used']:
        image=Image.open(ROOT/'art/props/room-states-v1'/(name+'.png')).convert('RGBA')
        assert image.getpixel((64,64))[3]==255,name+' interior must cover the floor'
    for path in [ROOT/'docs/room-prop-states.md']:
        for link in re.findall(r'\]\(([^)]+)\)',path.read_text(encoding='utf-8')):
            if '://' not in link:assert (path.parent/link).exists(),link
    print('PASS: ten preserved masters/prompts, eleven exports and all hashes; original art and all eight event rules unchanged.')

if __name__=='__main__':main()
