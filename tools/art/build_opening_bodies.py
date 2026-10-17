"""Export the final oblique companion art to matching 128px floor-anchored sprites."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/opening-bodies-v1'
OUT = ROOT / 'art/props/opening-bodies-v1'
OUT.mkdir(parents=True, exist_ok=True)
manifest = json.loads((SOURCE / 'generation-manifest.json').read_text())

def pixels(image):
    return getattr(image, 'get_flattened_data', image.getdata)()

images, sources = [], []
for asset in manifest['assets']:
    master = SOURCE / (asset['id'] + '-oblique-master.png')
    if not master.exists():
        shutil.copyfile(asset['generated_path'], master)
    image = Image.open(master).convert('RGBA')
    assert image.getextrema()[3][0] == 0
    scaled = image.resize((128,round(image.height*128/image.width)),Image.Resampling.BOX)
    # Common horizontal scale; only vertical translation aligns floor contact.
    alpha = scaled.getchannel('A').point(lambda a:255 if a >= 128 else 0)
    bounds = alpha.getbbox()
    assert bounds
    canvas = Image.new('RGBA',(128,128))
    canvas.paste(scaled,(0,120-bounds[3]))
    images.append(canvas)
    sources.append({'id':asset['id'], 'master':master.name, 'master_size':image.size,
                    'master_sha256':hashlib.sha256(master.read_bytes()).hexdigest()})
visible = [p[:3] for image in images for p in pixels(image) if p[3] >= 128]
training = Image.new('RGB',(len(visible),1))
training.putdata(visible)
palette = training.quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
exports, colors = [], set()
for asset, image in zip(manifest['assets'],images):
    result = image.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA')
    rgba = [(*c[:3],255) if p[3] >= 128 else (0,0,0,0) for c,p in zip(pixels(result),pixels(image))]
    result.putdata(rgba)
    colors.update(p[:3] for p in rgba if p[3])
    path = OUT / (asset['id']+'.png')
    result.save(path)
    bbox = result.getbbox()
    assert bbox and min(bbox[:2]) > 0 and bbox[2] < 128 and bbox[3] == 120
    exports.append({'file':path.name,'size':result.size,'visible_bounds':bbox,
                    'pivot':[64,120], 'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
assert len(colors) <= 32
report = {'canvas':[128,128],'pivot':[64,120], 'pixel_size_metres':0.015625,
          'sprite_y_metres':0.875, 'billboard':'fixed Y; upright card with pre-drawn lying pose',
          'alpha':[0,255], 'filter':'nearest', 'palette':[list(c) for c in sorted(colors)],
          'export':'BOX resize to common 128px width; translate floor contact to y=120 without trimming; alpha threshold 128; shared 32-colour median-cut palette; no dithering',
          'sources':sources,'exports':exports}
(OUT/'registration.json').write_text(json.dumps(report,indent=2)+'\n')
sheet = Image.new('RGB',(600,200),'#171b17')
draw = ImageDraw.Draw(sheet)
for i, asset in enumerate(manifest['assets']):
    image = Image.open(OUT/(asset['id']+'.png')).resize((256,256),Image.Resampling.NEAREST)
    sheet.paste(image,(22+i*300,-75),image)
    draw.text((22+i*300,16),asset['id']+' / 128px at 2x',fill='#e6dac1')
draw.text((22,180),'Shared 32-colour palette / floor contact (64,120) / transparent sprites',fill='#b7ab93')
sheet.save(OUT/'preview.png')
print('PASS: two registered 128px oblique sprites; shared colours:',len(colors))
