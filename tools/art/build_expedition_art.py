"""Package generated artwork into the exact canvases requested in #31.

Generation prompts/raw images are in art/source/expedition-v1. This does not
regenerate art or edit the original Mara master. Run from any directory.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/source/expedition-v1'
MASTER = ROOT / 'art/concepts/portraits/mara-layered-v1'
PORTRAIT = ROOT / 'art/portraits/mara-animation-v1'
FEATURES = ROOT / 'art/features/cave-v1'
TEXTURES = ROOT / 'art/textures/cave-v1'
ENEMIES = ROOT / 'art/enemies/cave-v1'
ICONS = ROOT / 'art/items/pack-64-v1'
REPORT = ROOT / 'art/expedition-v1'
NEAREST = Image.Resampling.NEAREST


def save(im, folder, name):
    folder.mkdir(parents=True, exist_ok=True)
    im.save(folder / name)


def raw(name, size=None):
    im = Image.open(RAW / (name + '.png')).convert('RGBA')
    if size:
        im = im.resize((size, size), NEAREST)
    a = np.array(im)
    # Remove highly saturated red/yellow matte contamination observed in
    # generated transparent gaps, retaining ordinary rust, blood and skin.
    bad = ((a[:, :, 0] > 225) & (a[:, :, 1] < 65) & (a[:, :, 2] < 65)) | (
        (a[:, :, 0] > 220) & (a[:, :, 1] > 200) & (a[:, :, 2] < 105))
    a[:, :, 3][bad | (a[:, :, 3] < 12)] = 0
    a[a[:, :, 3] == 0] = 0
    return Image.fromarray(a)


def composite(layers, size=(192, 192)):
    out = Image.new('RGBA', size)
    for im in layers:
        out = Image.alpha_composite(out, im)
    return out


def sheet(entries, columns, cell=256):
    rows = (len(entries) + columns - 1) // columns
    out = Image.new('RGB', (columns * cell, rows * (cell + 25)), '#18201d')
    draw = ImageDraw.Draw(out)
    for i, (name, im) in enumerate(entries):
        x, y = (i % columns) * cell, (i // columns) * (cell + 25)
        display = im.copy()
        display.thumbnail((cell, cell), NEAREST)
        out.paste(display, (x + (cell-display.width)//2, y + (cell-display.height)//2), display)
        draw.text((x + 8, y + cell + 5), name, fill='#e8ddc3')
    return out


def portraits():
    base = Image.open(MASTER / 'base.png').convert('RGBA')
    tunic = Image.open(MASTER / 'tunic.png').convert('RGBA')
    background = Image.open(MASTER / 'background.png').convert('RGBA')
    neutral = composite([background, base,
        Image.open(MASTER/'eyes-neutral.png').convert('RGBA'),
        Image.open(MASTER/'mouth-neutral.png').convert('RGBA'), tunic])
    registrations = []
    previews = [('neutral', neutral)]
    definitions = [('eyes-half', (83, 60, 137, 79)), ('eyes-closed', (83, 60, 137, 79)),
                   ('mouth-small', (94, 94, 125, 108)), ('mouth-open', (94, 94, 125, 108)),
                   ('mouth-round', (94, 94, 125, 108))]
    frames = {}
    b = np.array(base).astype(float)
    for name, roi in definitions:
        generated = raw('mara-' + name, 192)
        # Register using unchanged nose/forehead areas, never using the moving
        # eyes/mouth as anchors. Only integer translation, no facial warping.
        g = np.array(generated).astype(float)
        score = []
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                err = []
                for x0,y0,x1,y1 in [(107,79,118,91),(105,45,124,55)]:
                    ref = b[y0:y1,x0:x1,:3]
                    test = g[y0+dy:y1+dy,x0+dx:x1+dx,:3]
                    err.append(np.mean(np.abs(ref-test)))
                score.append((sum(err), dx, dy))
        _, dx, dy = min(score)
        aligned = Image.new('RGBA', (192, 192))
        aligned.paste(generated, (-dx, -dy))
        # Start with exact original pixels in the existing replacement patch.
        patch = Image.new('RGBA', (192, 192))
        patch.paste(neutral.crop(roi), roi[:2])
        regions = [(85,65,106,76),(118,64,135,76)] if name.startswith('eyes') else [(96,96,124,106)]
        for rect in regions:
            patch.paste(aligned.crop(rect), rect[:2])
        save(patch, PORTRAIT, name + '.png')
        preview = composite([neutral, patch])
        # Mathematical guarantee: no pixels outside the existing patch change.
        diff = np.any(np.array(preview) != np.array(neutral), axis=2)
        allowed = np.zeros((192,192), bool)
        for x0,y0,x1,y1 in regions:
            allowed[y0:y1,x0:x1] = True
        assert not diff[~allowed].any(), name
        assert diff.any(), name
        registrations.append({'file': name+'.png', 'source_translation':[-dx,-dy],
                              'allowed_regions':regions, 'outside_region_changes':0})
        frames[name] = preview
        previews.append((name, preview))
    skin = Image.new('L',(192,192))
    sd = ImageDraw.Draw(skin)
    sd.polygon([(117,34),(131,41),(140,59),(138,82),(133,102),(122,119),
                (104,120),(85,106),(76,82),(81,63),(98,50)], fill=255)
    sd.polygon([(90,112),(123,115),(129,140),(142,152),(125,162),(71,159),(53,152),(82,136)], fill=255)
    original_alpha = base.getchannel('A')
    skin = ImageChops.multiply(skin, original_alpha)
    conditions = {}
    for name in ['blood','dirt','bandage','pallor']:
        overlay = raw('mara-'+name,192)
        mask = original_alpha if name=='bandage' else skin
        alpha = ImageChops.multiply(overlay.getchannel('A'), mask)
        if name=='pallor':
            # Tint only: original face and expression remain visible.
            alpha = alpha.point(lambda v: round(v * .32))
        elif name=='dirt':
            # Earth smudges, not a second face painted over the portrait.
            alpha = alpha.point(lambda v: round(v * .45))
            overlay = Image.blend(overlay, Image.new('RGBA',(192,192),(68,58,43,255)), .65)
        overlay.putalpha(alpha)
        # Never obscure the registered eyes or mouth with a condition mark.
        for rect in [(83,60,137,79),(94,94,125,108)]:
            overlay.paste((0,0,0,0),rect)
        save(overlay,PORTRAIT,name+'.png')
        conditions[name] = overlay
        previews.append((name,composite([neutral,overlay])))
    save(sheet(previews,5,192),PORTRAIT,'preview.png')
    blink=[neutral,frames['eyes-half'],frames['eyes-closed'],frames['eyes-half'],neutral]
    blink[0].save(PORTRAIT/'blink-preview.gif',save_all=True,append_images=blink[1:],
                  duration=[1200,80,90,80,1200],loop=0,disposal=2)
    talk=[neutral,frames['mouth-small'],frames['mouth-open'],frames['mouth-round'],neutral]
    talk[0].save(PORTRAIT/'talk-preview.gif',save_all=True,append_images=talk[1:],duration=160,loop=0,disposal=2)
    return registrations


def textures():
    for name in ['wall','floor','ceiling']:
        im=raw('cave-'+name).convert('RGB').resize((64,64),NEAREST)
        pixels=np.array(im)
        # Exact opposite-edge colour equality; no baked lighting. This small
        # seam pass changes the outermost texels only, retaining the artwork.
        avg=((pixels[:,0].astype(int)+pixels[:,-1].astype(int))//2).astype('uint8')
        pixels[:,0]=pixels[:,-1]=avg
        avg=((pixels[0].astype(int)+pixels[-1].astype(int))//2).astype('uint8')
        pixels[0]=pixels[-1]=avg
        im=Image.fromarray(pixels)
        assert np.array_equal(pixels[:,0],pixels[:,-1])
        assert np.array_equal(pixels[0],pixels[-1])
        save(im,TEXTURES,name+'.png')
        text='[gd_resource type="StandardMaterial3D" load_steps=2 format=3]\n\n'
        text+=f'[ext_resource type="Texture2D" path="res://art/textures/cave-v1/{name}.png" id="1"]\n\n'
        text+=f'[resource]\nresource_name = "Cave v1 - {name}"\ntexture_filter = 0\nalbedo_texture = ExtResource("1")\nroughness = 1.0\n'
        (TEXTURES/(name+'.tres')).write_text(text,encoding='utf-8')
    tiles=[]
    for name in ['wall','floor','ceiling']:
        im=Image.open(TEXTURES/(name+'.png')).convert('RGBA')
        tiled=Image.new('RGBA',(256,256))
        for y in range(4):
            for x in range(4):tiled.paste(im,(x*64,y*64))
        tiles.append((name+' repeat 4x4',tiled))
    save(sheet(tiles,3,256),TEXTURES,'repeat-preview.png')


def features():
    images={name:raw(name,256) for name in ['web-intact','web-torn','root-barrier','pit-opening','hanging-roots']}
    # A common fixed normalized canvas; never independently crop/recenter.
    # Retain exact intact-web anchors outside the central tear rectangle.
    torn=images['web-intact'].copy()
    torn.paste(images['web-torn'].crop((48,48,208,240)),(48,48))
    # Guarantee a clear traversable opening through the generated torn silk.
    hole=Image.new('L',(256,256));hd=ImageDraw.Draw(hole)
    hd.polygon([(110,77),(147,84),(173,116),(173,211),(87,211),(82,130)],fill=255)
    torn.paste((0,0,0,0),(0,0),hole)
    images['web-torn']=torn
    for name,im in images.items():save(im,FEATURES,name+'.png')
    save(sheet(list(images.items()),3,256),FEATURES,'preview.png')
    a,b=np.array(images['web-intact']),np.array(torn)
    outside=np.ones((256,256),bool);outside[48:240,48:208]=False
    assert np.array_equal(a[outside],b[outside])


def enemies():
    all_previews=[]
    for enemy in ['rat','spider','goblin']:
        poses={pose:raw(enemy+'-'+pose,256) for pose in ['idle','attack','hurt']}
        bounds={p:im.getchannel('A').point(lambda v:255 if v>=80 else 0).getbbox() for p,im in poses.items()}
        # One scale for all three drawings of an enemy, not a per-pose fit.
        scale=min(1.,224/max(b[2]-b[0] for b in bounds.values()),224/max(b[3]-b[1] for b in bounds.values()))
        pose_info=[]
        for pose,im in poses.items():
            b=bounds[pose]
            scaled=im.resize((round(256*scale),round(256*scale)),NEAREST)
            x=128-round((b[0]+b[2])*scale/2)
            y=240-round(b[3]*scale)
            out=Image.new('RGBA',(256,256));out.paste(scaled,(x,y))
            # Tiny transparent fringes are removed without changing body scale.
            a=np.array(out);a[a[:,:,3]<20]=0;out=Image.fromarray(a)
            save(out,ENEMIES/enemy,pose+'.png')
            ground=out.getchannel('A').point(lambda v:255 if v>=80 else 0).getbbox()[3]
            assert abs(ground-240)<=1, (enemy,pose,ground)
            pose_info.append({'pose':pose,'scale':scale,'translation':[x,y],'pivot':[128,240],
                              'solid_ground_y':ground})
            all_previews.append((enemy+' '+pose,out))
        (ENEMIES/enemy/'registration.json').write_text(json.dumps(pose_info,indent=2)+'\n',encoding='utf-8')
        sf='[gd_resource type="SpriteFrames" load_steps=4 format=3]\n\n'
        for i,pose in enumerate(poses,1):sf+=f'[ext_resource type="Texture2D" path="res://art/enemies/cave-v1/{enemy}/{pose}.png" id="{i}"]\n'
        sf+='\n[resource]\nanimations = [{\n'
        anim=[]
        for i,pose in enumerate(poses,1):anim.append('"frames": [{"duration": 1.0, "texture": ExtResource("'+str(i)+'")}], "loop": false, "name": &"'+pose+'", "speed": 6.0')
        sf+='\n}, {\n'.join(anim)+'\n}]\n'
        (ENEMIES/enemy/'frames.tres').write_text(sf,encoding='utf-8')
    save(sheet(all_previews,3,256),ENEMIES,'preview.png')


def icons():
    for source,target in [('oil-flask','oil-flask'),('party-ration','ration'),('restorative-draught','restorative-draught')]:
        im=Image.open(ROOT/f'art/items/starter-v1/{source}.png').convert('RGBA')
        # Explicit 64px output request: keep full source framing and alpha.
        im=im.resize((64,64),Image.Resampling.LANCZOS)
        save(im,ICONS,target+'.png')
    save(sheet([(n,Image.open(ICONS/(n+'.png')).convert('RGBA')) for n in ['oil-flask','ration','restorative-draught']],3,128),ICONS,'preview.png')


if __name__=='__main__':
    registration=portraits()
    textures();features();enemies();icons()
    REPORT.mkdir(parents=True,exist_ok=True)
    rows=[]
    for folder in [PORTRAIT,TEXTURES,FEATURES,ENEMIES,ICONS]:
        for p in sorted(folder.rglob('*.png')):
            if 'preview' in p.name:continue
            with Image.open(p) as im:
                im.verify()
            with Image.open(p) as im:
                rows.append({'file':p.relative_to(ROOT).as_posix(),'size':list(im.size),'mode':im.mode,
                             'alpha':list(im.getchannel('A').getextrema()) if 'A' in im.getbands() else None,
                             'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    report={'portrait_registration':registration,'web_outer_anchors_identical':True,
            'texture_opposite_edges_equal':True,'files':rows}
    (REPORT/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'runtime_pngs':len(rows),'portrait_registration':registration,'checks':'passed'}))
