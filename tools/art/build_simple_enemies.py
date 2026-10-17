"""Export #33's generated enemy drawings into registered combat resources.

Run with Pillow and NumPy. Originals/prompts live in the .gdignore source folder.
All poses share a 128px scale and a single 32-colour palette per enemy.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/source/enemies-simple-v1'
OUT = ROOT / 'art/enemies/cave-simple-v1'
POSES = ('idle', 'attack', 'hurt')
HEIGHTS = {'rat': .5, 'spider': .55, 'goblin': 1.4}


def load(enemy, pose):
    source = RAW / f'{enemy}-{pose}.png'
    if enemy == 'goblin' and pose == 'idle':
        source = ROOT / 'art/enemies/style-study-v1/goblin-simple-128.png'
    im = Image.open(source).convert('RGBA').resize((128, 128), Image.Resampling.NEAREST)
    a = np.array(im)
    bad = ((a[:, :, 0] > 225) & (a[:, :, 1] < 65) & (a[:, :, 2] < 65)) | (
        (a[:, :, 0] > 220) & (a[:, :, 1] > 200) & (a[:, :, 2] < 105))
    a[:, :, 3] = np.where((a[:, :, 3] >= 128) & ~bad, 255, 0)
    a[a[:, :, 3] == 0] = 0
    return Image.fromarray(a)


def register(im, xshift):
    dy = 121 - im.getbbox()[3]
    out = Image.new('RGBA', (128, 128))
    out.paste(im, (xshift, dy))
    assert np.count_nonzero(np.array(im)[:, :, 3]) == np.count_nonzero(np.array(out)[:, :, 3]), 'Clipped sprite'
    return out, [xshift, dy]


def resources(enemy, idle):
    folder = OUT / enemy
    frames = '[gd_resource type="SpriteFrames" load_steps=4 format=3]\n\n'
    for i, pose in enumerate(POSES, 1):
        frames += f'[ext_resource type="Texture2D" path="res://art/enemies/cave-simple-v1/{enemy}/{pose}.png" id="{i}"]\n'
    frames += '\n[resource]\nanimations = ['
    frames += ', '.join('{\n"frames": [{"duration": 1.0, "texture": ExtResource("%s")}], "loop": false, "name": &"%s", "speed": 6.0\n}' % (i, p) for i, p in enumerate(POSES, 1))
    (folder / 'frames.tres').write_text(frames + ']\n', encoding='utf-8')
    pixel_size = HEIGHTS[enemy] / (121 - idle.getbbox()[1])
    scene = '[gd_scene load_steps=2 format=3]\n\n'
    scene += f'[ext_resource type="SpriteFrames" path="res://art/enemies/cave-simple-v1/{enemy}/frames.tres" id="1"]\n\n'
    scene += f'[node name="{enemy}" type="Node3D"]\n\n'
    scene += '[node name="Sprite" type="AnimatedSprite3D" parent="."]\n'
    scene += f'position = Vector3(0, {56 * pixel_size:.9f}, 0)\npixel_size = {pixel_size:.9f}\n'
    scene += 'billboard = 1\nshaded = true\ntexture_filter = 0\nalpha_cut = 1\nalpha_scissor_threshold = 0.5\nsprite_frames = ExtResource("1")\nanimation = &"idle"\n'
    (folder / 'scene.tscn').write_text(scene, encoding='utf-8')
    return pixel_size


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    report = {'canvas': [128, 128], 'pivot': [64, 120], 'enemies': {}}
    preview = Image.new('RGB', (768, 3 * 286), '#1d2422')
    native = Image.new('RGB', (3 * 144, 3 * 154), '#1d2422')
    draw, ndraw = ImageDraw.Draw(preview), ImageDraw.Draw(native)
    for row, enemy in enumerate(HEIGHTS):
        folder = OUT / enemy
        folder.mkdir(parents=True, exist_ok=True)
        originals = [load(enemy, p) for p in POSES]
        box = originals[0].getbbox()
        xshift = 64 - (box[0] + box[2]) // 2
        registered = [register(im, xshift) for im in originals]
        # Build one palette from opaque pixels only across the whole family.
        pixels = np.concatenate([np.array(im)[:, :, :3][np.array(im)[:, :, 3] > 0] for im, _ in registered])
        palette = Image.fromarray(pixels.reshape((1, -1, 3))).quantize(colors=32, method=Image.Quantize.MEDIANCUT)
        visible_union, outputs, entries = set(), [], []
        for col, (pose, (im, shift)) in enumerate(zip(POSES, registered)):
            a = np.array(im)
            quantized = im.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE).convert('RGB')
            a[:, :, :3] = np.array(quantized)
            a[a[:, :, 3] == 0] = 0
            result = Image.fromarray(a)
            path = folder / f'{pose}.png'
            result.save(path)
            colours = {tuple(map(int, p)) for p in a[:, :, :3][a[:, :, 3] > 0]}
            visible_union.update(colours)
            assert result.size == (128, 128) and result.mode == 'RGBA'
            assert set(np.unique(a[:, :, 3])) == {0, 255}
            assert result.getbbox()[3] - 1 == 120
            assert len(colours) <= 32
            outputs.append(result)
            entries.append(dict(pose=pose, translation=shift, scale=1.0, bounds=list(result.getbbox()),
                                visible_colours=len(colours), ground_y=120,
                                sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
            preview.paste(result.resize((256, 256), Image.Resampling.NEAREST), (col * 256, row * 286), result.resize((256, 256), Image.Resampling.NEAREST))
            draw.text((col * 256 + 8, row * 286 + 260), f'{enemy} / {pose}', fill='#eadfc6')
            native.paste(result, (col * 144 + 8, row * 154), result)
            ndraw.text((col * 144 + 8, row * 154 + 132), f'{enemy} / {pose}', fill='#eadfc6')
        assert len(visible_union) <= 32
        (folder / 'palette.json').write_text(json.dumps(sorted([list(p) for p in visible_union]), indent=2) + '\n', encoding='utf-8')
        registration = dict(canvas=[128, 128], pivot=[64, 120], common_scale=1.0, frames=entries,
                            shared_visible_colours=len(visible_union), pixel_size=resources(enemy, outputs[0]))
        (folder / 'registration.json').write_text(json.dumps(registration, indent=2) + '\n', encoding='utf-8')
        report['enemies'][enemy] = registration
    preview.save(OUT / 'preview.png')
    native.save(OUT / 'native-preview.png')
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print('SIMPLE_ENEMY_EXPORT_PASSED: 9 exact canvases; binary alpha; shared palettes <=32; ground y=120; no clipping')


if __name__ == '__main__':
    main()
