"""Export two new poses in the approved idle's fixed source coordinate frame."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, hashlib
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/underhound-v1'
OUT = ROOT / 'art/enemies/underhound-v1'
REVIEW = ROOT / 'art/concepts/underhound-poses-v1'
REVIEW.mkdir(parents=True, exist_ok=True)

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def write(p, text):
    p.write_text(text, encoding='utf-8', newline='\n')

approval = json.loads((OUT / 'approval.json').read_text())
idle_meta = json.loads((SOURCE / 'generation.json').read_text())
manifest = json.loads((SOURCE / 'poses.json').read_text())
assert sha(OUT / 'idle.png') == approval['native_png_sha256']
assert sha(SOURCE / 'idle-master.png') == approval['master_sha256']
if 'hurt' in approval:
    assert sha(OUT / 'hurt.png') == approval['hurt']['native_png_sha256']
for ref in manifest['references']:
    value = sha(ROOT / ref['path'])
    assert not ref.get('sha256') or value == ref['sha256'], ref['path']
    ref['sha256'] = value

# Same continuous transform as the approved cropped idle export, including its
# integer output rounding. Apply it to whole canvases; never fit/ground a pose.
source_box = (59, 236, 1229, 1168)
source_canvas = Image.open(SOURCE / 'idle-master.png').size
scale_x, scale_y = 112 / 1170, 89 / 932
translate_x, translate_y = 8 - 59 * scale_x, 32 - 236 * scale_y
source_window = (-translate_x / scale_x, -translate_y / scale_y,
                 (128 - translate_x) / scale_x, (128 - translate_y) / scale_y)
pad = 128
window = tuple(v + pad for v in source_window)
palette_rgb = json.loads((OUT / 'palette.json').read_text())['rgb']
palette = Image.new('P', (1, 1))
palette.putpalette([c for rgb in palette_rgb + [palette_rgb[-1]] * (256 - len(palette_rgb)) for c in rgb])
images = {'idle': Image.open(OUT / 'idle.png').convert('RGBA')}
records = {}
for entry in manifest['poses']:
    path = ROOT / entry['source']
    original = Path(entry['original_path'])
    if original.exists():
        assert original.read_bytes() == path.read_bytes(), entry['id']
    value = sha(path)
    assert not entry.get('sha256') or value == entry['sha256'], entry['id']
    entry['sha256'] = value
    raw = Image.open(path).convert('RGBA')
    assert raw.size == source_canvas, 'Pose must share the approved source canvas; review instead of auto-fitting'
    a = np.array(raw)
    a[:, :, 3] = np.where(a[:, :, 3] >= 128, 255, 0)
    a[a[:, :, 3] == 0] = 0
    padded = Image.new('RGBA', (raw.width + 2 * pad, raw.height + 2 * pad))
    padded.paste(Image.fromarray(a), (pad, pad))
    resized = padded.resize((128, 128), Image.Resampling.BOX, box=window)
    a = np.array(resized)
    a[:, :, 3] = np.where(a[:, :, 3] >= 128, 255, 0)
    rgb = Image.fromarray(a[:, :, :3]).quantize(palette=palette, dither=Image.Dither.NONE).convert('RGBA')
    rgb.putalpha(Image.fromarray(a[:, :, 3]))
    a = np.array(rgb)
    a[a[:, :, 3] == 0] = 0
    result = Image.fromarray(a)
    images[entry['id']] = result
    records[entry['id']] = {'source': entry['source'], 'source_sha256': value,
                            'bounds': list(result.getbbox()), 'lowest_visible_y': result.getbbox()[3] - 1}

colours = set()
for name, image in images.items():
    a = np.array(image)
    visible = a[a[:, :, 3] > 0]
    colours.update(tuple(int(c) for c in p[:3]) for p in visible)
    assert set(np.unique(a[:, :, 3])) == {0, 255}, name
    bounds = image.getbbox()
    assert bounds[0] >= 4 and bounds[2] <= 124 and bounds[1] >= 8 and bounds[3] <= 124, (name, bounds)
    if name != 'idle':
        image.save(OUT / (name + '.png'))
    records.setdefault(name, {'bounds': list(bounds), 'lowest_visible_y': bounds[3] - 1})
    records[name]['sha256'] = sha(OUT / (name + '.png'))
assert len(colours) <= 32 and set(colours).issubset({tuple(c) for c in palette_rgb})
assert sha(OUT / 'idle.png') == approval['native_png_sha256'], 'Approved idle must remain byte-identical'
write(SOURCE / 'poses.json', json.dumps(manifest, indent=2) + '\n')

names = ['idle', 'attack', 'hurt']
ext = '\n'.join(f'[ext_resource type="Texture2D" path="res://art/enemies/underhound-v1/{name}.png" id="{name}"]' for name in names)
animations = ',\n'.join('{"frames":[{"duration":1.0,"texture":ExtResource("'+name+'")}],"loop":'+('true' if name == 'idle' else 'false')+',"name":&"'+name+'","speed":8.0}' for name in names)
write(OUT / 'frames.tres', '[gd_resource type="SpriteFrames" load_steps=4 format=3]\n'+ext+'\n\n[resource]\nanimations = ['+animations+']\n')
pixel_size = 0.8 / 89
pose_tops = ', '.join('"'+name+'": ['+str(images[name].getbbox()[1])+']' for name in names)
write(OUT / 'scene.tscn', f'''[gd_scene load_steps=3 format=3]
[ext_resource type="SpriteFrames" path="res://art/enemies/underhound-v1/frames.tres" id="frames"]
[ext_resource type="Script" path="res://art/enemies/underhound-v1/mount.gd" id="mount"]

[node name="UnderhoundPoseFamily" type="Node3D"]
script = ExtResource("mount")
pose_tops = {{{pose_tops}}}
metadata/pivot = Vector2(64, 120)
metadata/visual_height = 0.8
metadata/status = "Accepted idle/hurt; open-maw attack revision, no encounter assignment"

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
catalog = json.loads((OUT / 'catalog.json').read_text())
catalog.update(status='Owner accepted idle/hurt; open-maw attack revision awaiting review',
               animations=names, attack_hurt='Distinct authored poses; no aliases', poses=records,
               shared_registration={'source_canvas': list(source_canvas), 'source_window': source_window,
                                    'scale_xy': [scale_x, scale_y], 'translate_xy': [translate_x, translate_y],
                                    'per_pose_fit_or_grounding': False},
               family_visible_colours=len(colours), review='art/concepts/underhound-poses-v1/inspector.html')
catalog['tag_headroom_metres'] = 0.12
write(OUT / 'catalog.json', json.dumps(catalog, indent=2) + '\n')

def font(n):
    face = ImageFont.truetype(str(ROOT / 'art/fonts/source-sans-3/SourceSans3-Variable.ttf'), n)
    face.set_variation_by_axes([400])
    return face

sheet = Image.new('RGB', (1200, 940), '#171d19')
pen = ImageDraw.Draw(sheet)
pen.text((20, 12), 'Underhound · approved idle / attack / hurt', font=font(27), fill='#e6dac1')
pen.text((20, 52), 'One palette and coordinate frame · idle unchanged · pause/step in the review gallery', font=font(18), fill='#b6b59f')
for column, name in enumerate(names):
    x = column * 400
    image = images[name]
    for y, bg in [(92, '#202720'), (528, '#b4b5aa')]:
        pen.rectangle((x + 8, y, x + 391, y + 383), fill=bg)
        up = image.resize((384, 384), Image.Resampling.NEAREST)
        sheet.paste(up, (x + 8, y), up)
    pen.text((x + 16, 484), name.title(), font=font(23), fill='#e6dac1')
# A second compact strip retains true native and 64px display for comparison.
sheet.save(REVIEW / 'three-poses.png')
native = Image.new('RGB', (840, 240), '#202720')
pen = ImageDraw.Draw(native)
for i, name in enumerate(names):
    native.paste(images[name], (i * 280 + 12, 40), images[name])
    tiny = images[name].resize((64, 64), Image.Resampling.NEAREST)
    native.paste(tiny, (i * 280 + 170, 82), tiny)
    pen.text((i * 280 + 12, 8), name.title()+' · 128px / 64px', font=font(18), fill='#e6dac1')
native.save(REVIEW / 'native-strip.png')
write(REVIEW / 'export-validation.json', json.dumps({'canvas': [128, 128], 'colours': len(colours), 'idle_unchanged': True, 'poses': records, 'shared_registration': catalog['shared_registration']}, indent=2) + '\n')
html = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Depths · Underhound poses</title>
<style>body{margin:0;background:#141b17;color:#e6dac1;font:17px system-ui}main{max-width:1220px;margin:auto;padding:20px}
h1{font:30px Georgia;margin:8px 0}p{color:#b6b59f;line-height:1.5;max-width:85ch}a{color:#dbb477}
nav{display:flex;gap:9px;flex-wrap:wrap;margin:14px 0}button,select{font:inherit;background:#263025;color:#e6dac1;border:1px solid #796746;padding:10px;min-height:44px;max-width:100%}
button[aria-pressed=true]{border-color:#dbb477;color:#fff0cc}label{display:flex;align-items:center;gap:6px;min-height:44px}input{width:22px;height:22px}
.stage{height:400px;overflow:auto;display:flex;align-items:center;justify-content:flex-start;background:#202720;border:1px solid #4a4d3e}
canvas{width:var(--size,384px);height:var(--size,384px);image-rendering:pixelated;flex-shrink:0;margin:auto}
.light{background:#b4b5aa}.strip{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px;margin:16px 0}.strip article{padding:12px;border:1px solid #4a4d3e;text-align:center}.strip img{width:128px;height:128px;image-rendering:pixelated}
figure{margin:16px 0}figure img{display:block;width:100%;height:auto}figcaption{color:#b6b59f;margin-top:10px}#status{color:#dbb477}
</style><main><small>ACCEPTED IDLE / HURT · OPEN-MAW ATTACK REVISION</small><h1>The Underhound · three-pose review</h1>
<p>Idle and hurt are accepted and unchanged. At the owner’s request, attack now opens a broad hinged maw with two rows of teeth, replacing the projecting tooth strip. All three share the exact 32-colour palette, body scale and (64,120) origin. The hurt drawing keeps its lifted paw above that origin.</p>
<nav aria-label="Pose controls"><button id="play">Play comparison</button><button id="previous">Previous</button><button id="next">Next</button><button class="pose" data-pose="idle">Idle</button><button class="pose" data-pose="attack">Attack</button><button class="pose" data-pose="hurt">Hurt</button></nav>
<nav aria-label="Pixel inspection"><button class="zoom" data-zoom="1">128 px</button><button class="zoom" data-zoom="0.5">64 px</button><button class="zoom" data-zoom="3">3× nearest</button><label><input id="light" type="checkbox">Light backing</label><label><input id="ghost" type="checkbox">Ghost idle</label><label><input id="guides" type="checkbox">Origin guides</label></nav>
<p id="status"></p><div class="stage"><canvas id="frame" width="128" height="128" aria-label="Paused Underhound pose inspection"></canvas></div>
<div class="strip">__CARDS__</div>
<p>Ghost idle is an optional alignment overlay, off by default. The comparison cycles the authored drawings; it is not an additional game animation. Native strip: <a href="native-strip.png">128px / 64px</a> · <a href="three-poses.png">dark/light pose sheet</a>.</p>
<h2>Combat display review</h2><p>Actual BattleStage, CombatScreen and Mara card in an isolated art fixture. Existing breach-hound numbers are copied in memory solely for the preview. These images do not add an enemy or floor assignment.</p>
<select id="capture" aria-label="Combat view"></select><figure><img id="render" alt=""><figcaption id="caption"></figcaption></figure>
<p><a href="../../../docs/underhound-poses.md">Review findings and checks</a> · <a href="../../source/underhound-v1/poses.json">Exact built-in ImageGen prompts and masters</a> · <a href="../../enemies/underhound-v1/approval.json">Approved idle hashes</a></p>
</main><script>
const names=['idle','attack','hurt'],images={},state={pose:'idle',playing:false,zoom:innerWidth<600?1:3,ghost:false,guides:false};let timer=null;
const by=id=>document.getElementById(id),ctx=by('frame').getContext('2d');
function draw(){ctx.clearRect(0,0,128,128);ctx.imageSmoothingEnabled=false;if(state.ghost&&state.pose!=='idle'){ctx.globalAlpha=.23;ctx.drawImage(images.idle,0,0);ctx.globalAlpha=1;}ctx.drawImage(images[state.pose],0,0);if(state.guides){ctx.strokeStyle='#79b2a3';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(64.5,0);ctx.lineTo(64.5,128);ctx.moveTo(0,120.5);ctx.lineTo(128,120.5);ctx.stroke();}by('status').textContent=state.pose.toUpperCase()+' · '+(state.playing?'playing comparison':'paused')+' · '+(128*state.zoom)+'px view';document.querySelectorAll('.pose').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.pose===state.pose)));window.poseState={...state};}
function pause(){clearInterval(timer);timer=null;state.playing=false;by('play').textContent='Play comparison';}
function show(pose){pause();state.pose=pose;draw();}
function zoom(z){state.zoom=z;document.documentElement.style.setProperty('--size',(128*z)+'px');document.querySelectorAll('.zoom').forEach(b=>b.setAttribute('aria-pressed',String(Number(b.dataset.zoom)===z)));draw();}
document.querySelectorAll('.pose').forEach(b=>b.onclick=()=>show(b.dataset.pose));document.querySelectorAll('.zoom').forEach(b=>b.onclick=()=>zoom(Number(b.dataset.zoom)));
by('previous').onclick=()=>show(names[(names.indexOf(state.pose)+2)%3]);by('next').onclick=()=>show(names[(names.indexOf(state.pose)+1)%3]);
by('play').onclick=()=>{if(state.playing){pause();draw();return;}state.playing=true;by('play').textContent='Pause';let i=0;const sequence=['idle','attack','idle','hurt'];timer=setInterval(()=>{state.pose=sequence[i++%sequence.length];draw();},500);draw();};
by('light').onchange=e=>document.querySelector('.stage').classList.toggle('light',e.target.checked);for(const id of ['ghost','guides'])by(id).onchange=e=>{state[id]=e.target.checked;draw();};
const captures=__CAPTURES__;captures.forEach(([file,label],i)=>by('capture').add(new Option(label,i)));function capture(){const[file,label]=captures[by('capture').selectedIndex];by('render').src=file+'.png';by('render').alt=label;by('caption').textContent=label+' · Windows Mobile renderer; physical iPhone testing remains open.';}by('capture').onchange=capture;capture();
window.artReady=Promise.all(names.map(name=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>{images[name]=im;resolve();};im.onerror=reject;im.src='../../enemies/underhound-v1/'+name+'.png';}))).then(()=>zoom(state.zoom));
</script></html>'''
cards = ''.join(f'<article><strong>{name.title()}</strong><br><img src="../../enemies/underhound-v1/{name}.png" alt="{name} at native128"></article>' for name in names)
captures = [(f'combat-{width}-{scale}-{name}', f'{name.title()} · {width}px · {scale}')
            for width in (1278, 1280) for scale in ('normal', 'larger') for name in names]
write(REVIEW / 'inspector.html', html.replace('__CARDS__', cards).replace('__CAPTURES__', json.dumps(captures)))
print('UNDERHOUND_POSES:', len(images), 'distinct drawings,', len(colours), 'shared colours;', {n: im.getbbox() for n, im in images.items()})
