"""Register/limit the generated idle candidate; do not redraw its anatomy."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib, json
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/underhound-v1'
OUT = ROOT / 'art/enemies/underhound-v1'
REVIEW = ROOT / 'art/concepts/underhound-idle-v1'
OUT.mkdir(parents=True, exist_ok=True)
REVIEW.mkdir(parents=True, exist_ok=True)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def write(path, text):
    path.write_text(text, encoding='utf-8', newline='\n')

manifest = json.loads((SOURCE / 'generation.json').read_text())
master = SOURCE / 'idle-master.png'
original = Path(manifest['original_path'])
if original.exists():
    assert original.read_bytes() == master.read_bytes(), 'Preserve the generated master exactly'
if manifest.get('sha256'):
    assert sha(master) == manifest['sha256'], 'Generated master changed'
manifest['sha256'] = sha(master)
for ref in manifest['reference_images']:
    if ref.get('sha256'):
        assert sha(ROOT / ref['path']) == ref['sha256'], 'Reference changed'
    ref['sha256'] = sha(ROOT / ref['path'])
write(SOURCE / 'generation.json', json.dumps(manifest, indent=2) + '\n')

raw = Image.open(master).convert('RGBA')
rgba = np.array(raw)
rgba[:, :, 3] = np.where(rgba[:, :, 3] >= 128, 255, 0)
rgba[rgba[:, :, 3] == 0] = 0
raw = Image.fromarray(rgba)
bounds = raw.getbbox()
assert bounds
cropped = raw.crop(bounds)
# Reserve the same common envelope for future poses. No per-pose fitting later.
scale = min(112 / cropped.width, 92 / cropped.height)
size = (round(cropped.width * scale), round(cropped.height * scale))
small = cropped.resize(size, Image.Resampling.BOX)
offset = (64 - size[0] // 2, 121 - size[1])
sprite = Image.new('RGBA', (128, 128))
sprite.alpha_composite(small, offset)
a = np.array(sprite)
a[:, :, 3] = np.where(a[:, :, 3] >= 128, 255, 0)
samples = a[:, :, :3][a[:, :, 3] > 0]
palette = Image.fromarray(samples.reshape(1, -1, 3)).quantize(32, dither=Image.Dither.NONE)
rgb = Image.fromarray(a[:, :, :3]).quantize(palette=palette, dither=Image.Dither.NONE).convert('RGBA')
rgb.putalpha(Image.fromarray(a[:, :, 3]))
a = np.array(rgb)
a[a[:, :, 3] == 0] = 0
sprite = Image.fromarray(a)
approval_path = OUT / 'approval.json'
approval = json.loads(approval_path.read_text()) if approval_path.exists() else None
if approval:
    assert sha(master) == approval['master_sha256'], 'Approved master must not change'
    assert hashlib.sha256(sprite.tobytes()).hexdigest() == approval['native_rgba_sha256'], 'Approved idle pixels must not drift'
sprite.save(OUT / 'idle.png')
box = sprite.getbbox()
colours = sorted({tuple(int(c) for c in p[:3]) for p in a.reshape(-1, 4) if p[3]})
assert len(colours) <= 32 and box[3] - 1 == 120
assert set(np.unique(a[:, :, 3])) == {0, 255}
assert not a[:8, :, 3].any() and not a[121:, :, 3].any()
assert not a[:, :7, 3].any() and not a[:, 121:, 3].any()
write(OUT / 'palette.json', json.dumps({'status': 'Provisional idle palette; rebalance only as a complete pose family', 'rgb': colours}, indent=2) + '\n')
pixel_size = 0.8 / (box[3] - box[1])
write(OUT / 'frames.tres', '''[gd_resource type="SpriteFrames" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://art/enemies/underhound-v1/idle.png" id="idle"]

[resource]
animations = [{"frames":[{"duration":1.0,"texture":ExtResource("idle")}],"loop":true,"name":&"idle","speed":1.0}]
''')
write(OUT / 'scene.tscn', f'''[gd_scene load_steps=3 format=3]
[ext_resource type="SpriteFrames" path="res://art/enemies/underhound-v1/frames.tres" id="frames"]
[ext_resource type="Script" path="res://art/enemies/monsters-v1/pose_bounds.gd" id="mount"]

[node name="UnderhoundIdleCandidate" type="Node3D"]
script = ExtResource("mount")
pose_tops = {{"idle": [{box[1]}]}}
metadata/pivot = Vector2(64, 120)
metadata/visual_height = 0.8
metadata/status = "Idle candidate only; not assigned to encounters"

[node name="Sprite" type="AnimatedSprite3D" parent="."]
position = Vector3(0, {56 * pixel_size}, 0)
pixel_size = {pixel_size}
billboard = 1
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
cast_shadow = 0
sprite_frames = ExtResource("frames")
animation = &"idle"
''')
report = {'issue': 150, 'status': 'Owner-approved idle; full pose family pending' if approval else 'Idle production candidate awaiting review',
          'canvas': [128, 128], 'pivot': [64, 120], 'bounds': list(box), 'visible_colours': len(colours),
          'source_bounds': list(bounds), 'source_to_native_scale': scale, 'source_to_native_offset': list(offset),
          'resize': 'Proportional BOX once, then hard alpha >=128 and 32-colour visible-pixel median cut, no dithering',
          'source': manifest['source'], 'source_sha256': sha(master), 'idle_sha256': sha(OUT / 'idle.png'),
          'pixel_size': pixel_size, 'visual_height_metres': 0.8, 'animations': ['idle'],
          'attack_hurt': 'Not authored; do not alias them to idle', 'floor_or_enemy_type': None}
if approval:
    report['owner_approval'] = 'art/enemies/underhound-v1/approval.json'
write(OUT / 'catalog.json', json.dumps(report, indent=2) + '\n')

font_path = next((ROOT / 'art/fonts/source-sans-3').glob('*.ttf'))
def font(n):
    face = ImageFont.truetype(str(font_path), n)
    face.set_variation_by_axes([400])
    return face
sheet = Image.new('RGB', (1000, 704), '#171d19')
draw = ImageDraw.Draw(sheet)
draw.text((24, 14), 'Underhound · idle candidate', fill='#e6dac1', font=font(28))
draw.text((24, 52), '128 × 128 · 32 colours · transparent · planted contact y120', fill='#b8b5a0', font=font(18))
for x, bg, label in [(24, '#202720', 'Cave-dark'), (516, '#b4b5aa', 'Light backing')]:
    draw.rectangle((x, 90, x + 459, 501), fill=bg)
    enlarged = sprite.resize((384, 384), Image.Resampling.NEAREST)
    sheet.paste(enlarged, (x + 36, 106), enlarged)
    draw.text((x, 516), label + ' · 3× nearest', fill='#e6dac1', font=font(18))
    sheet.paste(sprite, (x, 552), sprite)
    native64 = sprite.resize((64, 64), Image.Resampling.NEAREST)
    sheet.paste(native64, (x + 160, 583), native64)
    draw.text((x + 246, 579), '128px / 64px', fill='#b8b5a0', font=font(18))
    draw.text((x + 246, 609), 'Same silhouette', fill='#b8b5a0', font=font(18))
sheet.save(REVIEW / 'native-review.png')
html = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Depths · Underhound idle</title>
<style>body{margin:0;background:#131a16;color:#e6dac1;font:17px system-ui}main{max-width:1200px;margin:auto;padding:20px}
h1{font:30px Georgia;margin:8px 0}p{color:#b6b59f;line-height:1.5;max-width:85ch}a{color:#dbb477}
nav{display:flex;gap:10px;flex-wrap:wrap;margin:16px 0}button,select{font:inherit;background:#263025;color:#e6dac1;border:1px solid #796746;padding:10px;min-height:44px;max-width:100%}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px}.card{border:1px solid #4a4d3e;padding:12px;min-width:0}
.window{height:390px;overflow:auto;display:flex;align-items:center;justify-content:center;background:#202720}.light{background:#b4b5aa}
.window img{width:var(--size,384px);height:var(--size,384px);image-rendering:pixelated;flex-shrink:0}.caption{font-size:15px;margin:10px 0 0}
figure{margin:16px 0}figure img{display:block;width:100%;height:auto}figcaption{color:#b6b59f;margin-top:10px}
</style><main><small>CHECKPOINT ONE · IDLE CANDIDATE</small><h1>The Underhound</h1>
<p>Long blind head, four planted legs and opposing rib masses. The sliding inner jaw stays mostly concealed. 128×128 RGBA · 32 colours · common pivot (64,120). Review the idle before attack and hurt are authored.</p>
<nav aria-label="Native pixel zoom"><button data-zoom="1">128 px</button><button data-zoom="0.5">64 px</button><button data-zoom="3">3× nearest</button></nav>
<div class="cards"><div class="card"><div class="window"><img class="sprite" src="../../enemies/underhound-v1/idle.png" alt="Underhound idle on cave-dark backing"></div><p class="caption">Cave-dark backing</p></div>
<div class="card"><div class="window light"><img class="sprite" src="../../enemies/underhound-v1/idle.png" alt="Underhound idle on light backing"></div><p class="caption">Light backing · transparent silhouette</p></div></div>
<h2>First-person size review</h2><p>Actual Godot art fixture with the existing camera and lantern, at 2.4m. The candidate is not assigned to an encounter. No game saves or Main scene are loaded.</p>
<select id="view" aria-label="First-person review view"></select><figure><img id="render" alt=""><figcaption id="label"></figcaption></figure>
<p><a href="../../../docs/underhound-idle.md">Handoff and checks</a> · <a href="../../enemies/underhound-v1/idle.png">Native PNG</a> · <a href="../../source/underhound-v1/generation.json">Exact prompt and source record</a> · <a href="../../../docs/underhound-production.md">Production brief</a></p>
</main><script>
function zoom(z){document.documentElement.style.setProperty('--size',(128*z)+'px');document.querySelectorAll('[data-zoom]').forEach(b=>b.setAttribute('aria-pressed',String(Number(b.dataset.zoom)===z)));}
document.querySelectorAll('[data-zoom]').forEach(b=>b.onclick=()=>zoom(Number(b.dataset.zoom)));zoom(innerWidth<600?1:3);
const views=[['family-1278','Existing breach hound (left) · Underhound (right) · phone'],['idle-cave-1278','Underhound · cave · phone'],['idle-fungal-caverns-1278','Underhound · fungal materials · phone'],['family-1280','Family comparison · desktop'],['idle-cave-1280','Underhound · cave · desktop'],['idle-fungal-caverns-1280','Underhound · fungal materials · desktop'],['native-review','Native128 / 64px review plate']];
const select=document.querySelector('#view'),render=document.querySelector('#render'),label=document.querySelector('#label');views.forEach(([file,title],i)=>select.add(new Option(title,i)));function show(){const[file,title]=views[select.selectedIndex];render.src=file+'.png';render.alt=title;label.textContent=title+' · Physical iPhone testing and final combat UI clearance remain open.';}select.onchange=show;show();
</script></html>'''
if approval:
    html = html.replace('CHECKPOINT ONE · IDLE CANDIDATE', 'CHECKPOINT ONE · APPROVED IDLE')
    html = html.replace('Review the idle before attack and hurt are authored.', 'Owner accepted this idle on 2026-10-25. It is the reference for the pending attack and hurt poses.')
write(REVIEW / 'inspector.html', html)
print(f'UNDERHOUND_IDLE: {sprite.size}, {len(colours)} visible colours, bounds {box}, contact y120')
