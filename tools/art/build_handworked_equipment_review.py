"""Export the two ImageGen roughness studies; preserve every original drawing."""
from pathlib import Path
import hashlib
import json
import sys
sys.dont_write_bytecode = True
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from build_field_kit_art import fitted

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/equipment-handworked-v1'
OUT = ROOT / 'art/concepts/equipment-handworked-v1'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    manifest = json.loads((SOURCE / 'generation.json').read_text())
    board = Image.new('RGB', (700, 530), '#1b2420')
    d = ImageDraw.Draw(board)
    font = ImageFont.truetype(str(next((ROOT / 'art/fonts/source-sans-3').glob('*.ttf'))), 19)
    d.text((20, 15), 'Handworked equipment | Previous / Revised / Revised at 64px', font=font, fill='#e6dac1')
    cards = []
    checks = 0
    for row, entry in enumerate(e for e in manifest['assets'] if e['source']):
        id = entry['id']
        source = ROOT / entry['source']
        original = ROOT / 'art/source/early-equipment-v1' / (id + '-master.png')
        before = sha(original)
        if entry.get('sha256'):
            assert entry['sha256'] == sha(source)
        icon, transform = fitted(Image.open(source).convert('RGBA'), 128, 64)
        icon.save(OUT / (id + '.png'))
        old = Image.open(ROOT / 'art/concepts/early-equipment-v1/candidates128' / (id + '.png')).convert('RGBA')
        a = np.array(icon)
        box = icon.getchannel('A').getbbox()
        tests = [icon.size == (128,128), icon.mode == 'RGBA', set(np.unique(a[:,:,3])) <= {0,255},
                 min(box[0],box[1],128-box[2],128-box[3]) >= 8,
                 len(np.unique(a[:,:,:3][a[:,:,3]>0],axis=0)) <= 64,
                 not a[a[:,:,3]==0].any(), before == sha(original), transform['scale'] < 1]
        assert all(tests), id
        checks += len(tests)
        entry.update(sha256=sha(source), input_sha256=before, export_sha256=sha(OUT/(id+'.png')), registration=transform)
        y = 65 + row * 230
        board.paste(old, (20,y), old);board.paste(icon, (230,y), icon)
        small = icon.resize((64,64), Image.Resampling.NEAREST);board.paste(small,(450,y+30),small)
        name = id.replace('-',' ').title()
        d.text((20,y+145), name, font=font, fill='#e6dac1')
        d.text((20,y+174), 'Previous', font=font, fill='#aeb5a4');d.text((230,y+174), 'Handworked study', font=font, fill='#aeb5a4')
        cards.append(f'<section><h2>{name}</h2><div class="pair"><figure><img src="../early-equipment-v1/candidates128/{id}.png" alt="Previous {name}"><figcaption>Previous</figcaption></figure><figure><img src="{id}.png" alt="Handworked {name}"><figcaption>Handworked study</figcaption></figure></div><div class="small"><img src="{id}.png" width="64" height="64" alt="64 pixel {name}"><img src="{id}.png" width="32" height="32" alt="32 pixel {name}"></div></section>')
    board.save(OUT/'comparison.png')
    (SOURCE/'generation.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (OUT/'validation.json').write_text(json.dumps({'checks':checks,'failures':[],'revised_items':2,'originals_preserved':True,'live_bindings_changed':False},indent=2)+'\n')
    html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Depths · Handworked equipment</title><style>body{margin:0;background:#10140f;color:#e6dac1;font:18px/1.5 system-ui,sans-serif}main{max-width:1000px;margin:auto;padding:20px}h1,h2{font-family:Georgia,serif;font-weight:normal}a{color:inherit}button{font:inherit;padding:10px;min-height:44px;cursor:pointer}.pair{display:flex;flex-wrap:wrap;gap:20px}.pair figure{margin:0;padding:16px;background:#1b2420}.pair img{width:256px;height:256px;object-fit:contain;image-rendering:pixelated}.small{display:flex;gap:24px;align-items:center;padding:18px}.small img{image-rendering:pixelated}.paper{background:#d7c5a3;color:#302d25}.paper figure{background:#e4d4b4}@media(max-width:700px){.pair img{width:128px;height:128px}main{padding:12px}}</style><main><h1>Handworked equipment</h1><p>Uneven forging, hand-shaped timber, imperfect stitching and ingrained grime. Two representative finish studies; original drawings remain preserved. Material character does not introduce item deterioration or new stats.</p><button onclick="document.body.classList.toggle('paper')">Dark / parchment</button>'''+''.join(cards)+'''<p>The coat is the stronger end of this roughness pass; its visible dents and patch need not be repeated on every item. The spear keeps a nearly straight usable shaft with irregular grain and forging.</p><p>The blade revision was rejected by the image service; its original is retained. No substitute revision is presented.</p><p><a href="../../../docs/early-equipment-art-review.md">Art direction and handoff</a> · <a href="../../source/equipment-handworked-v1/generation.json">Exact edit prompts and sources</a> · <a href="../early-equipment-v1/inspector.html">Full original set</a></p></main></html>'''
    (OUT/'inspector.html').write_text(html)
    print(f'HANDWORKED: {checks} checks, 0 failures; two comparison studies')


if __name__ == '__main__':
    main()
