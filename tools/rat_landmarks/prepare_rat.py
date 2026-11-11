"""Recolour the original texture without losing its UV-specific features."""
from pathlib import Path
from PIL import Image, ImageEnhance, ImageOps
import hashlib,json
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'art/third-party/oga-rat-v1'
PINS={'rat_source.7z':'3c8ec130b6a3ec3c93e0290107bcebdd5b34e23fd9205fab373feffea27cc883',
      'rat_godot.zip':'b01fb1976ae19ed80713853ec7c28b8cb098d1ced9e8c902791aa33fc4f7b28c',
      'godot/rat.png':'b5ef72933348583c79f789dc3f3316163c600911fc38d5398aaa7d04bf4450bf'}
for name,sha in PINS.items():assert hashlib.sha256((SRC/name).read_bytes()).hexdigest()==sha,name
ART=ROOT/'art/enemies/rat-3d-v1'; ART.mkdir(parents=True,exist_ok=True)
source=Image.open(SRC/'godot/rat.png').convert('RGB').resize((128,128),Image.Resampling.BOX)
# Dirty brown-grey fur; muted ear/tail flesh, tiny dark red eyes, worn ivory teeth.
pixels=[]
for r,g,b in source.getdata():
    light=(r*.299+g*.587+b*.114)/255
    if r>g*1.22 and b>g*1.13:
        colour=tuple(int(a+(z-a)*light**.65) for a,z in zip((48,33,30),(145,103,86)))
    else:
        colour=tuple(int(a+(z-a)*light**.65) for a,z in zip((35,39,36),(176,165,136)))
    pixels.append(colour)
image=Image.new('RGB',source.size); image.putdata(pixels)
image=image.quantize(colors=32,dither=Image.Dither.NONE).convert('RGB')
# Preserve the source's tiny eye islands: global quantization would lose them.
for y in range(128):
    for x in range(128):
        r,g,b=source.getpixel((x,y))
        if r>g*2.2 and r>b*2.2 and r>90:image.putpixel((x,y),(119,49,29))
assert len(image.getcolors(256))<=32
image.save(ART/'rat.png')
proof={'page':'https://opengameart.org/content/rat-0','author':'br-n518','licence':'CC0-1.0',
       'checked':'2026-11-09','files':[]}
for name in ['rat_source.7z','rat_godot.zip','source-page.html','godot/rat.dae','godot/rat.png']:
    data=(SRC/name).read_bytes()
    proof['files'].append({'file':name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
(SRC/'provenance.json').write_text(json.dumps(proof,indent=2)+'\n')
(SRC/'.gdignore').write_text('')
(SRC/'CREDITS.md').write_text('''# CC0 rat source

Rat by br-n518, published 2018-09-17 on https://opengameart.org/content/rat-0.
The submission labels both downloads CC0, including an explicit attribution notice
of CC0. Licence declaration page retained as source-page.html; exact downloaded
bytes and hashes are in provenance.json. CC0 deed: https://creativecommons.org/publicdomain/zero/1.0/.

rat_source.7z contains rat.blend, rat.png and rat.xcf. rat_godot.zip contains
the original COLLADA and texture; extracted copies retained for audit. Originals
are unchanged. Derived rat-3d-v1 uses the original 270-triangle mesh, weights,
UVs and animations, a smaller muted 32-colour texture, fixed metric placement
and an authored recoil. Source death is exposed as fall. No Mixamo content.
''')
print('RAT_TEXTURE',len(image.getcolors(1000)),proof['files'][0]['sha256'])
