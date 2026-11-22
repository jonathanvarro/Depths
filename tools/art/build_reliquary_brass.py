"""Size the exact owner-approved #269 SVG frames for native 12px nine-slices."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/reliquary-brass-v1'
DEST = ROOT / 'art/ui/reliquary-brass-v1'

def main():
    DEST.mkdir(parents=True,exist_ok=True)
    records=[]
    for edge in ['left','centre','right']:
        source=SOURCE/f'brass-{edge}.svg'
        text=source.read_text(encoding='utf-8')
        assert 'width="600" height="132"' in text
        target=DEST/f'{edge}.svg'
        target.write_text(text.replace('width="600" height="132"','width="300" height="66"'),encoding='utf-8')
        records.append({'edge':edge,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'runtime':str(target.relative_to(ROOT)).replace('\\','/'),'changes':'SVG viewport size only, 600x132 to 300x66; original geometry, colours and viewBox preserved'})
        if edge=='centre':
            # Interior scratches/chevrons must not stretch down a tall modal.
            panel=text.split('<g clip-path="url(#inside)">')[0]+'</svg>'
            (DEST/'panel.svg').write_text(panel.replace('width="600" height="132"','width="300" height="66"'),encoding='utf-8')
    (DEST/'catalog.json').write_text(json.dumps({'issue':271,'approved_direction':'Reliquary brass, owner 2026-11-21 (#269)','frames':records},indent=2)+'\n',encoding='utf-8')
    print('Prepared the three approved brass frames for native nine-slice drawing.')

if __name__=='__main__':main()
