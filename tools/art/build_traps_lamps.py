"""Export #158/#159 state pairs with one full-canvas transform per family."""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib, json, sys
import numpy as np
sys.dont_write_bytecode = True
from build_treasure_art import palette, font

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/traps-lamps-v1'
OUT = ROOT / 'art/props/traps-lamps-v1'
REVIEW = ROOT / 'art/concepts/traps-lamps-v1'

def write(path, value):
    path.write_text(value, encoding='utf-8', newline='\n')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

manifest = json.loads((SOURCE / 'generation.json').read_text())
for entry in manifest['assets']:
    path = SOURCE / (entry['id'] + '.png')
    original = Path(entry['original_path'])
    if original.exists():
        assert path.read_bytes() == original.read_bytes(), entry['id']
    assert not entry.get('sha256') or sha(path) == entry['sha256'], entry['id']
    entry['sha256'] = sha(path)
    with Image.open(path) as im:
        entry['dimensions'] = list(im.size)
for entry in manifest['references']:
    value = sha(ROOT / entry['path'])
    assert not entry.get('sha256') or value == entry['sha256'], entry['path']
    entry['sha256'] = value
write(SOURCE / 'generation.json', json.dumps(manifest, indent=2) + '\n')

images, records = {}, {}
families = [('snare', True, 0.008), ('dart', True, 0.008),
            ('bell', False, 0.0125), ('lamp', False, 0.00989010989010989)]
for name, flat, pixel in families + [('dart-ports', False, 0.00625)]:
    ids = [name] if name == 'dart-ports' else [name + '-closed', name + '-used']
    frames = []
    for id in ids:
        raw = Image.open(SOURCE / (id + '.png')).convert('RGBA')
        assert raw.width == raw.height, id
        # Full square -> full square; no per-state silhouette fit or grounding.
        im = raw.resize((128, 128), Image.Resampling.BOX)
        a = np.array(im)
        a[:, :, 3] = np.where(a[:, :, 3] >= 128, 255, 0)
        a[a[:, :, 3] == 0] = 0
        frames.append(Image.fromarray(a))
    pal = palette(frames, 32)
    for id, im in zip(ids, frames):
        alpha = im.getchannel('A')
        result = im.convert('RGB').quantize(palette=pal, dither=Image.Dither.NONE).convert('RGBA')
        result.putalpha(alpha)
        a = np.array(result); a[a[:, :, 3] == 0] = 0
        result = Image.fromarray(a)
        result.save(OUT / (id + '.png'))
        images[id] = result
        records[id] = {'bounds': list(result.getbbox()), 'sha256': sha(OUT / (id + '.png'))}
    if name == 'dart-ports':
        continue
    bottom = images[name + '-closed'].getbbox()[3] - 1
    y = 0.018 if flat else (bottom - 64) * pixel
    dart = name == 'dart'
    script = 'res://art/props/cave-events-v1/container.gd' if name == 'lamp' else 'res://art/props/traps-lamps-v1/dart_mount.gd'
    scene = f'''[gd_scene load_steps={5 if dart else 4} format=3]
[ext_resource type="Texture2D" path="res://art/props/traps-lamps-v1/{name}-closed.png" id="fresh"]
[ext_resource type="Texture2D" path="res://art/props/traps-lamps-v1/{name}-used.png" id="used"]
[ext_resource type="Script" path="{script}" id="state"]
'''
    if dart:
        scene += '[ext_resource type="Texture2D" path="res://art/props/traps-lamps-v1/dart-ports.png" id="ports"]\n'
    scene += f'''[node name="{name}" type="Node3D"]
script = ExtResource("state")
closed_texture = ExtResource("fresh")
empty_texture = ExtResource("used")
metadata/family = "{name}"
[node name="Sprite" type="Sprite3D" parent="."]
position = Vector3(0, {y}, 0)
rotation = Vector3({-1.5707963267948966 if flat else 0}, 0, 0)
billboard = {0 if flat else 2}
pixel_size = {pixel}
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
texture = ExtResource("fresh")
'''
    if dart:
        scene += '''[node name="Ports" type="Sprite3D" parent="."]
visible = false
pixel_size = 0.00625
shaded = true
billboard = 0
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
texture = ExtResource("ports")
'''
    write(OUT / (name + '.tscn'), scene)
    records[name] = {'flat': flat, 'pixel_size': pixel, 'position_y': y,
                     'registration': 'Same normalized full canvas for both states; no independent fitting'}
write(OUT / 'catalog.json', json.dumps({'issues': [158, 159], 'canvas': [128, 128],
       'palette_limit_per_pair': 32, 'records': records}, indent=2) + '\n')

for light in [False, True]:
    sheet = Image.new('RGB', (1100, 690), '#b1b0a4' if light else '#1a211d')
    pen = ImageDraw.Draw(sheet)
    ink = '#24241e' if light else '#e6dac1'
    pen.text((18, 12), 'Traps and dead lamps · ready / resolved', font=font(27), fill=ink)
    for col, (name, _, _) in enumerate(families):
        x = 14 + col * 275
        pen.text((x, 53), name.title(), font=font(22), fill=ink)
        for row, state in enumerate(['closed', 'used']):
            im = images[name + '-' + state]
            y = 88 + row * 285
            sheet.paste(im.resize((256, 256), Image.Resampling.NEAREST), (x, y), im.resize((256, 256), Image.Resampling.NEAREST))
            pen.text((x, y + 252), 'Ready' if row == 0 else 'Resolved', font=font(18), fill=ink)
    sheet.save(REVIEW / ('overview-light.png' if light else 'overview-dark.png'))

cards = ''
for name, _, _ in families:
    cards += '<article><h2>' + name.title() + '</h2>'
    for state in ['closed', 'used']:
        path = '../../props/traps-lamps-v1/' + name + '-' + state + '.png'
        cards += f'<figure><img src="{path}" alt="{name} {state}"><figcaption>{state}</figcaption></figure>'
    cards += '</article>'
views = [(f'{name}-{state}-{shape}.png', f'{name.title()} · {state} · {shape}')
         for shape in ['desktop', 'phone'] for name, _, _ in families for state in ['closed', 'used']]
views += [(f'{name}-{state}-near-{shape}.png', f'{name.title()} · {state} · one cell away · {shape}')
          for shape in ['desktop', 'phone'] for name in ['snare', 'dart'] for state in ['closed', 'used']]
html = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Depths · traps and dead lamps</title><style>
body{background:#171e19;color:#e6dac1;font:17px system-ui;margin:0}main{max-width:1200px;margin:auto;padding:20px}p{line-height:1.5;max-width:85ch;color:#bcb9a8}a{color:#d7b780}h1{font:30px Georgia}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px}article{border:1px solid #575444;padding:12px;text-align:center}figure{margin:10px 0}figure img{width:var(--size,256px);max-width:100%;image-rendering:pixelated}figcaption{color:#bcb9a8}nav{display:flex;gap:9px;flex-wrap:wrap;margin:12px 0}button,select{font:inherit;background:#283025;color:#e6dac1;border:1px solid #796746;padding:10px;min-height:44px;max-width:100%}.light article{background:#b1b0a4;color:#24241e}.light figcaption{color:#24241e}#render{width:100%;height:auto}#caption{color:#bcb9a8}</style>
<main><h1>Traps and the dead-lamp store</h1><p>Ready and resolved states at native128 and small display sizes. The lamp rack never emits light; its sealed flasks disappear after searching. Dart holes mount on real cave rock at knee height. Trap visibility and event rules remain unchanged.</p>
<nav><button data-zoom="128">Native128</button><button data-zoom="64">64 px</button><button data-zoom="256">2× nearest</button><button id="light">Toggle light backing</button></nav><div class="grid">__CARDS__</div>
<h2>Actual first-person review</h2><select id="capture" aria-label="Room view"></select><figure><img id="render" alt=""><figcaption id="caption"></figcaption></figure>
<p><a href="../../../docs/traps-and-dead-lamps.md">Handoff and mounting details</a> · <a href="../../source/traps-lamps-v1/generation.json">Exact built-in ImageGen prompts and sources</a> · <a href="overview-dark.png">Dark sheet</a> · <a href="overview-light.png">Light sheet</a></p></main>
<script>document.querySelectorAll('[data-zoom]').forEach(b=>b.onclick=()=>document.documentElement.style.setProperty('--size',b.dataset.zoom+'px'));document.getElementById('light').onclick=()=>document.body.classList.toggle('light');
const views=__VIEWS__,select=document.getElementById('capture'),render=document.getElementById('render');views.forEach(([f,l],i)=>select.add(new Option(l,i)));function show(){const[f,l]=views[select.selectedIndex];render.src=f;render.alt=l;document.getElementById('caption').textContent=l+' · Windows capture; physical iPhone review remains open.';}select.onchange=show;show();</script></html>'''
write(REVIEW / 'inspector.html', html.replace('__CARDS__', cards).replace('__VIEWS__', json.dumps(views)))
print('TRAPS_LAMPS_EXPORT:', len(images), 'native128 textures; four state pairs and wall ports')
