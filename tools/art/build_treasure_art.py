"""Export generated treasure art without replacing the existing item/chest set."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/treasure-v1'
ICONS = ROOT / 'art/items/treasure-v1'
PROPS = ROOT / 'art/props/treasure-v1'
REVIEW = ROOT / 'art/concepts/treasure-v1'
OLD_CHEST = ROOT / 'art/props/tutorial-chest-v1'
ITEMS = [
    ('coins-small', 'Loose gold coins', 'currency'),
    ('coins-heap', 'Gold coin heap', 'currency'),
    ('coin-purse', 'Leather coin purse', 'currency_container'),
    ('coin-sack', 'Cloth coin sack', 'currency_container'),
    ('chest-closed', 'Closed chest', 'chest_state'),
    ('chest-full', 'Treasure chest', 'chest_state'),
    ('chest-empty', 'Empty chest', 'chest_state'),
    ('gold-signet-ring', 'Gold signet ring', 'valuable'),
    ('amber-pendant', 'Amber pendant', 'valuable'),
    ('silver-brooch', 'Silver leaf brooch', 'valuable'),
    ('garnet', 'Cut garnet', 'valuable'),
    ('emerald', 'Cut emerald', 'valuable'),
    ('amethyst', 'Rough amethyst', 'valuable'),
    ('silver-goblet', 'Dented silver goblet', 'valuable')]
WORLD_SIZES = {'coins-small': 0.003125, 'coins-heap': 0.0048,
               'coin-purse': 0.004326923, 'coin-sack': 0.00625}


def pixels(im):
    return im.get_flattened_data() if hasattr(im, 'get_flattened_data') else im.getdata()


def mask(im):
    return im.getchannel('A').point(lambda a: 255 if a >= 96 else 0)


def palette(images, count=32):
    samples = [p[:3] for im in images for p in pixels(im) if p[3] >= 96]
    strip = Image.new('RGB', (len(samples), 1)); strip.putdata(samples)
    return strip.quantize(colors=count, dither=Image.Dither.NONE)


def quantize(im, pal):
    result = im.convert('RGB').quantize(palette=pal, dither=Image.Dither.NONE).convert('RGBA')
    result.putalpha(mask(im))
    return result


def uri(path):
    return 'res://' + path.relative_to(ROOT).as_posix()


def font(size):
    result = ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))), size)
    try:
        result.set_variation_by_axes([400 if a['name'] == b'Weight' else a['default'] for a in result.get_variation_axes()])
    except OSError:
        pass
    return result


def fit_icon(im):
    crop = im.crop(mask(im).getbbox())
    crop.thumbnail((56, 56), Image.Resampling.NEAREST)
    result = Image.new('RGBA', (64, 64))
    result.paste(crop, ((64-crop.width)//2, (64-crop.height)//2))
    return result


def fit_plate(im):
    crop = im.crop(mask(im).getbbox())
    crop.thumbnail((104, 104), Image.Resampling.NEAREST)
    result = Image.new('RGBA', (128, 128))
    result.paste(crop, ((128-crop.width)//2, 121-crop.height))
    return result


def chest_full(report):
    im = Image.open(SOURCE/'chest-full.png').convert('RGBA').resize((1024, 1024), Image.Resampling.NEAREST)
    bounds = mask(im).crop((0, 666, 1024, 1024)).getbbox()
    assert bounds
    bounds = (bounds[0], bounds[1]+666, bounds[2], bounds[3]+666)
    scale = 104/(bounds[2]-bounds[0])
    offset = (64-round((bounds[0]+bounds[2])/2*scale), 121-round(bounds[3]*scale))
    resized = im.resize((round(1024*scale),)*2, Image.Resampling.NEAREST)
    result = Image.new('RGBA', (128, 128)); result.paste(resized, offset)
    # Keep the previous chest's wood/iron colours available, then reserve
    # eight gold, four red and four green colours so tiny gems survive.
    old = [Image.open(OLD_CHEST/(state+'.png')).convert('RGBA') for state in ['closed', 'empty']]
    colours = sorted({p[:3] for im in old for p in pixels(im) if p[3]})
    contents = result.crop((30, 52, 104, 82))
    groups = [(8, lambda r,g,b:r>g*1.1 and g>b*1.4 and g>80),
        (4, lambda r,g,b:r>g*2.8 and r>b*1.5 and r>80),
        (4, lambda r,g,b:g>r*1.25 and g>b*1.15 and g>35)]
    for count,select in groups:
        samples=[p for p in pixels(contents) if p[3]>=96 and select(*p[:3])]
        assert samples, 'Missing gold/red/green source contents'
        strip=Image.new('RGBA',(len(samples),1));strip.putdata(samples)
        extra=palette([strip],count).getpalette()[:count*3]
        colours += [tuple(extra[i:i+3]) for i in range(0,len(extra),3)]
    pal = Image.new('P', (1, 1))
    rgb = [channel for colour in colours for channel in colour]
    pal.putpalette((rgb + list(colours[-1])*(256-len(colours)))[:768])
    result = quantize(result, pal)
    counts = {'red':sum(1 for r,g,b,a in pixels(result) if a and r>g*2.8 and r>b*1.5 and r>80),
        'green':sum(1 for r,g,b,a in pixels(result) if a and g>r*1.25 and g>b*1.15 and g>35)}
    assert min(counts.values())>0,counts
    report['chest_registration'] = {'source_lower_box': bounds, 'scale': scale,
        'offset': offset, 'pivot': [64, 120], 'closed_empty': 'existing textures, unchanged',
        'palette_limit': 48, 'reserved_content_colours': {'gold':8,'red':4,'green':4},
        'gem_pixel_counts':counts}
    return result


def save_world(id, pixel_size):
    content = f'''[gd_scene load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://art/props/treasure-v1/{id}.png" id="1"]

[node name="Treasure" type="Node3D"]
metadata/visual_id = "{id}"

[node name="Sprite" type="Sprite3D" parent="."]
position = Vector3(0, {56*pixel_size:.9f}, 0)
pixel_size = {pixel_size:.9f}
billboard = 2
shaded = true
texture_filter = 0
alpha_cut = 1
alpha_scissor_threshold = 0.5
texture = ExtResource("1")
'''
    (PROPS/(id+'.tscn')).write_text(content, encoding='utf-8', newline='\n')


def verify(im, size, limit):
    bounds = mask(im).getbbox()
    assert im.size == size and bounds
    assert bounds[0] > 0 and bounds[1] > 0 and bounds[2] < size[0] and bounds[3] < size[1]
    assert set(pixels(im.getchannel('A'))) == {0, 255}
    count = len({p[:3] for p in pixels(im) if p[3]})
    assert count <= limit, count
    return {'canvas': size, 'bounds': bounds, 'visible_colours': count}


def main():
    for directory in [ICONS, PROPS, REVIEW]: directory.mkdir(parents=True, exist_ok=True)
    report = {'issue': 90, 'assets': {}, 'failures': [], 'alpha': 'binary cutout'}
    catalog = {'version': 1, 'issue': 90, 'icon_canvas': [64, 64],
        'illustration_canvas': [128, 128], 'world_pivot': [64, 120],
        'amounts_and_prices': 'not assigned by artwork', 'assets': []}
    for id, label, kind in ITEMS:
        if id in ['chest-closed', 'chest-empty']:
            plate_path = OLD_CHEST/(id.split('-')[1]+'.png')
            plate = Image.open(plate_path).convert('RGBA')
            limit = 32
        elif id == 'chest-full':
            plate = chest_full(report); plate_path = PROPS/(id+'.png')
            plate.save(plate_path); limit = 48
        else:
            source = Image.open(SOURCE/(id+'.png')).convert('RGBA')
            plate = fit_plate(source)
            plate = quantize(plate, palette([plate], 32))
            plate_path = PROPS/(id+'.png'); plate.save(plate_path); limit = 32
        icon = fit_icon(plate); icon_path = ICONS/(id+'.png'); icon.save(icon_path)
        report['assets'][icon_path.relative_to(ROOT).as_posix()] = verify(icon, (64, 64), limit)
        report['assets'][plate_path.relative_to(ROOT).as_posix()] = verify(plate, (128, 128), limit)
        if id not in ['chest-closed', 'chest-empty']:
            assert mask(plate).getbbox()[3] == 121, id
        entry = {'id': id, 'label': label, 'category': kind, 'icon': uri(icon_path), 'illustration': uri(plate_path)}
        if id in WORLD_SIZES:
            save_world(id, WORLD_SIZES[id]); entry['world_scene'] = uri(PROPS/(id+'.tscn'))
        if kind == 'chest_state':
            entry['world_scene'] = uri(PROPS/'chest.tscn')
            entry['state'] = {'chest-closed': 'closed', 'chest-full': 'open', 'chest-empty': 'empty'}[id]
        catalog['assets'].append(entry)
    (ICONS/'catalog.json').write_text(json.dumps(catalog, indent=2)+'\n', encoding='utf-8', newline='\n')
    for bg, colour in [('dark', '#1b2420'), ('light', '#d6cbb4')]:
        board = Image.new('RGBA', (768, 660), colour); draw = ImageDraw.Draw(board)
        for i, entry in enumerate(catalog['assets']):
            im = Image.open(ROOT/entry['icon'].replace('res://', '')).convert('RGBA')
            x = (i%4)*192; y = (i//4)*164
            board.alpha_composite(im.resize((128,128),Image.Resampling.NEAREST), (x+32, y+8))
            draw.text((x+96, y+138), entry['label'], font=font(16), fill='#e6dac1' if bg=='dark' else '#262b27', anchor='mt')
        board.convert('RGB').save(REVIEW/('overview-'+bg+'.png'))
    # Actual inventory sizes on a dark field, beside the current oil/ration icons.
    board = Image.new('RGBA', (768, 350), '#1b2420'); draw = ImageDraw.Draw(board)
    for i, entry in enumerate(catalog['assets']):
        im = Image.open(ROOT/entry['icon'].replace('res://','')).convert('RGBA')
        x=(i%7)*108+22; y=(i//7)*124+24
        board.alpha_composite(im,(x,y));board.alpha_composite(im.resize((40,40),Image.Resampling.NEAREST),(x+12,y+70))
    for i, name in enumerate(['oil-flask','ration','restorative-draught']):
        board.alpha_composite(Image.open(ROOT/'art/items/pack-64-v1'/(name+'.png')).convert('RGBA'), (220+i*108,280))
    draw.text((24,292), 'Existing supplies →', font=font(17), fill='#e6dac1')
    board.convert('RGB').save(REVIEW/'inventory-sizes.png')
    frames=[]
    for state in ['chest-closed','chest-full','chest-empty']:
        entry=next(e for e in catalog['assets'] if e['id']==state)
        im=Image.open(ROOT/entry['illustration'].replace('res://','')).convert('RGBA')
        frame=Image.new('RGBA',(256,256),'#1b2420');frame.alpha_composite(im.resize((256,256),Image.Resampling.NEAREST))
        frames.append(frame.convert('RGB'))
    frames[0].save(REVIEW/'chest-states.gif',save_all=True,append_images=frames[1:],duration=1000,loop=0,disposal=2)
    paths=[ROOT/name for name in report['assets']]+list(SOURCE.glob('*.png'))
    report['sha256']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    references=[ROOT/'art/items/starter-v1/plain-knife.png',ROOT/'art/items/pack-64-v1/oil-flask.png',
        ROOT/'art/source/opening-tutorial-v1/chest-open.png',OLD_CHEST/'open.png',OLD_CHEST/'chest.gd']
    report['reference_sha256']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in references}
    report['runtime_rgba_bytes']=14*64*64*4+12*128*128*4
    (REVIEW/'asset-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('14 icons, 12 new 128px illustrations, four pickup scenes; existing closed/empty chest reused.')


if __name__ == '__main__': main()
