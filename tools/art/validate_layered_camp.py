"""Layer provenance, native texture budget and unchanged camp rules."""
from pathlib import Path
from PIL import Image
import hashlib,json,re,subprocess

ROOT=Path(__file__).resolve().parents[2]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    source=ROOT/'art/source/camp-layered-v3'
    manifest=json.loads((source/'generation-manifest.json').read_text(encoding='utf-8'))
    correction=json.loads((source/'fire-correction.json').read_text(encoding='utf-8'))
    entries=manifest['entries']+[correction]
    assert len(entries)==9
    for entry in entries:
        assert entry['args']['prompt'].strip() and (source/entry['preserved_file']).exists()
    out=ROOT/'art/camp/organic-v3'
    report=json.loads((ROOT/'art/concepts/camp-layered-v3/export-validation.json').read_text())
    for path,expected in report['sha256'].items():assert sha(ROOT/path)==expected,path
    for path,expected in report['source_sha256'].items():assert sha(source/path)==expected,path
    colours=set();pixels=0
    for path in out.glob('*.png'):
        im=Image.open(path).convert('RGBA');pixels+=im.width*im.height
        assert set(im.getchannel('A').get_flattened_data())<={0,255},path.name
        colours.update(p[:3] for p in im.get_flattened_data() if p[3])
        if path.name=='terrain.png':assert im.size==(640,360) and im.getchannel('A').getextrema()==(255,255)
    assert len(colours)<=64,len(colours)
    layout=json.loads((out/'layout.json').read_text())
    for site in layout['sites']:
        im=Image.open(out/(site['id']+'.png')).convert('RGBA')
        x,y=layout['registration'][site['id']]['position']
        assert x>=0 and y>=0 and x+im.width<=640 and y+im.height<=360,site['id']
        for light in site.get('lights',[]):
            assert im.getpixel((int(light[0]-x),int(light[1]-y)))[3]==255,site['id']+' light must meet its own hardware'
    previous=subprocess.check_output(['git','show','HEAD:scripts/camp_state.gd'],cwd=ROOT).decode('utf-8')
    current=(ROOT/'scripts/camp_state.gd').read_text(encoding='utf-8')
    assert previous[previous.index('func start('):].splitlines()==current[current.index('func start('):].splitlines(),'Existing camp resource/day/recruitment rules changed'
    for path in [ROOT/'docs/layered-camp.md',ROOT/'docs/camp-composition-v2.md']:
        for link in re.findall(r'\]\(([^)]+)\)',path.read_text(encoding='utf-8')):
            if '://' not in link:assert (path.parent/link.split('#')[0]).exists(),(path.name,link)
    print('PASS: nine masters/prompts, source/output hashes, binary alpha/shared 64 colours, lantern alignment and unchanged camp rules.')
    print('Native camp texture budget:',round(pixels*4/1024/1024,2),'MiB RGBA before import.')

if __name__=='__main__':main()
