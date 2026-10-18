"""Embed project art and losslessly WOFF-compressed project fonts for #61."""
from pathlib import Path
from PIL import Image
import argparse
import base64
import hashlib
import json
import struct
import zlib

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art/concepts/interface/pack-heroes-v2'
ASSETS = OUT / 'assets'
ASSETS.mkdir(exist_ok=True)

def woff(path):
    """WOFF1 container conversion only: retain original tables/names/outlines."""
    data = path.read_bytes()
    flavor, count = data[:4], struct.unpack_from('>H',data,4)[0]
    records, chunks = [], []
    offset = 44+20*count
    total_sfnt = 12+16*count
    for i in range(count):
        tag, checksum, start, length = struct.unpack_from('>4sIII',data,12+16*i)
        raw = data[start:start+length]
        compressed = zlib.compress(raw)
        block = compressed if len(compressed)<length else raw
        records.append(struct.pack('>4sIIII',tag,offset,len(block),length,checksum))
        padded = block+b'\0'*((-len(block))%4)
        chunks.append(padded)
        offset += len(padded)
        total_sfnt += (length+3)&~3
    header = struct.pack('>4s4sIHHIHHIIIII',b'wOFF',flavor,offset,count,0,total_sfnt,1,0,0,0,0,0,0)
    return header+b''.join(records)+b''.join(chunks)

def uri(data, mime):
    return 'data:'+mime+';base64,'+base64.b64encode(data).decode('ascii')

source_map = {
    'mara':'art/concepts/portraits/mara-base-192-v2.png',
    'knife':'art/items/starter-v1/plain-knife.png',
    'club':'art/items/starter-v1/wooden-club.png',
    'spear':'art/items/starter-v1/simple-spear.png',
    'staff':'art/items/starter-v1/plain-staff.png',
    'shield':'art/items/starter-v1/wooden-shield.png',
    'coat':'art/items/starter-v1/padded-coat.png',
    'oil':'art/items/pack-64-v1/oil-flask.png',
    'ration':'art/items/pack-64-v1/ration.png',
    'draught':'art/items/pack-64-v1/restorative-draught.png',
    'dressing':'art/ui/pack-v1/clean-dressing.png',
    'backdrop':'art/title/title-v1/background.png'
}
fragment = (OUT/'source.fragment.html').read_text(encoding='utf-8')
manifest = {'issue':61,'kind':'Code-authored interactive browser UI study; no new generated artwork', 'assets':[]}
for key, relative in source_map.items():
    src = ROOT/relative
    image = Image.open(src)
    if key=='backdrop':
        image = image.convert('RGB'); image.thumbnail((640,360),Image.Resampling.LANCZOS)
        dest = ASSETS/(key+'.jpg'); image.save(dest,quality=75); mime='image/jpeg'
    else:
        image = image.convert('RGBA')
        if key!='mara': image.thumbnail((96,96),Image.Resampling.LANCZOS)
        dest = ASSETS/(key+'.png'); image.save(dest); mime='image/png'
    fragment = fragment.replace('@@'+key+'@@',uri(dest.read_bytes(),mime))
    manifest['assets'].append({'id':key,'source':relative,'output':dest.relative_to(ROOT).as_posix(),
        'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),
        'output_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'size':image.size})
licences=[]
for key, folder, filename in [('headingFont','cinzel','Cinzel-Variable.ttf'),('bodyFont','source-sans-3','SourceSans3-Variable.ttf')]:
    src = ROOT/'art/fonts'/folder/filename
    data = woff(src)
    dest = ASSETS/(key+'.woff'); dest.write_bytes(data)
    fragment = fragment.replace('@@'+key+'@@',uri(data,'font/woff'))
    licence = (src.parent/'OFL.txt').read_text(encoding='utf-8')
    licences.append(filename+'\n'+licence)
    (ASSETS/(folder+'-OFL.txt')).write_text(licence,encoding='utf-8')
    manifest['assets'].append({'id':key,'source':src.relative_to(ROOT).as_posix(),
        'output':dest.relative_to(ROOT).as_posix(),'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),
        'output_sha256':hashlib.sha256(data).hexdigest(),'operation':'WOFF1 lossless table compression only; names, glyphs, metrics and variable axes unchanged'})
fragment += '\n<!-- Bundled font notices; WOFF container conversion only.\n'+'\n\n'.join(licences)+'\n-->\n'
assert '@@' not in fragment
assert len(fragment.encode('utf-8')) < 1_000_000
assert '<!doctype' not in fragment.lower() and '<html' not in fragment.lower()
(OUT/'pack-heroes.html').write_text(fragment,encoding='utf-8',newline='\n')
parser=argparse.ArgumentParser(); parser.add_argument('--inline-path',type=Path)
args=parser.parse_args()
if args.inline_path:
    assert args.inline_path.parent.is_dir()
    args.inline_path.write_text(fragment,encoding='utf-8',newline='\n')
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Built Pack/hero study:',len(fragment.encode('utf-8')),'bytes')
