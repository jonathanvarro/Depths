"""Export a small torch body/icon; reuse the campfire flame library unchanged."""
from pathlib import Path
from PIL import Image, ImageSequence
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/torch-v1/torch-generated.png'
OUT = ROOT / 'art/props/torch-v1'
REVIEW = ROOT / 'art/concepts/torch-v1'
ICON = ROOT / 'art/items/pack-64-v1/torch.png'
FIRE = ROOT / 'art/features/campfire-v1/flames.png'


def pixels(image):
    return image.get_flattened_data() if hasattr(image, 'get_flattened_data') else image.getdata()


def mask(image):
    return image.getchannel('A').point(lambda a: 255 if a >= 96 else 0)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    original = Image.open(SOURCE).convert('RGBA')
    bounds = mask(original).getbbox()
    assert bounds
    cropped = original.crop(bounds)
    ratio = min(44 / cropped.width, 168 / cropped.height)
    small = cropped.resize((round(cropped.width * ratio), round(cropped.height * ratio)), Image.Resampling.NEAREST)
    body = Image.new('RGBA', (128, 256))
    body.paste(small, (64 - small.width // 2, 248 - small.height))
    samples = [p[:3] for p in pixels(body) if p[3] >= 96]
    strip = Image.new('RGB', (len(samples), 1)); strip.putdata(samples)
    palette = strip.quantize(colors=20, dither=Image.Dither.NONE)

    def quantize(image):
        result = image.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE).convert('RGBA')
        result.putalpha(mask(image))
        return result

    body = quantize(body)
    body.save(OUT / 'body.png')
    icon_art = cropped.rotate(-28, resample=Image.Resampling.NEAREST, expand=True)
    icon_art.thumbnail((56, 56), Image.Resampling.NEAREST)
    icon = Image.new('RGBA', (64, 64))
    icon.paste(icon_art, ((64 - icon_art.width) // 2, (64 - icon_art.height) // 2))
    icon = quantize(icon)
    icon.save(ICON)
    fire = Image.open(FIRE).convert('RGBA')
    states = {}
    for state in ['steady', 'dim', 'unlit']:
        frames = []
        for i in range(6):
            flame = fire.crop(((i % 3) * 128, (i // 3) * 128, (i % 3 + 1) * 128, (i // 3 + 1) * 128))
            frame = Image.new('RGBA', (128, 256))
            if state == 'steady': frame.paste(flame, (0, -10))  # shared root (64,102) -> (64,92)
            elif state == 'dim':
                # Match FlameAnchor.scale = 0.6; root stays at (64,92).
                scaled = flame.resize((77, 77), Image.Resampling.NEAREST)
                frame.paste(scaled, (26, 31))
            frame.alpha_composite(body)
            frames.append(frame)
        states[state] = frames
    for name in states: states[name][0].save(REVIEW / (name + '.png'))
    combined = []
    for i in range(6):
        board = Image.new('RGBA', (128 * 3, 256), '#1b201f')
        for j, state in enumerate(states): board.alpha_composite(states[state][i], (128 * j, 0))
        combined.append(board.convert('RGB').resize((576, 384), Image.Resampling.NEAREST))
    combined[0].save(REVIEW / 'states.png')
    combined[0].save(REVIEW / 'torch-loop.gif', save_all=True, append_images=combined[1:], duration=[120, 130] * 3, loop=0)
    review = Image.new('RGBA', (256, 256), '#1b201f')
    review.alpha_composite(icon.resize((256, 256), Image.Resampling.NEAREST))
    review.save(REVIEW / 'icon-enlarged.png')
    report = {'canvas': [128, 256], 'icon_canvas': [64, 64], 'flame_anchor': [64, 92],
              'frames': 6, 'fps': 8, 'cycle_seconds': .75, 'body_contact_y': 247,
              'source_bounds': bounds, 'body_scale': ratio, 'assets': [], 'failures': []}
    for name, image in [('body', body), ('icon', icon)]:
        alpha = image.getchannel('A'); box = alpha.getbbox()
        colours = set(p[:3] for p in pixels(image) if p[3])
        assert box and box[0] > 0 and box[1] > 0 and box[2] < image.width and box[3] < image.height
        assert set(pixels(alpha)) == {0, 255}
        assert len(colours) <= 20
        report['assets'].append({'name': name, 'size': image.size, 'bounds': box, 'visible_colours': len(colours)})
    for name, frames in states.items():
        for f in frames:
            assert f.getchannel('A').getbbox()[1] > 0
        assert len({f.tobytes() for f in frames}) == (1 if name == 'unlit' else 6)
    report['sha256'] = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                         for p in [SOURCE, OUT/'body.png', ICON, FIRE, ROOT/'art/features/campfire-v1/frames.tres']}
    (OUT/'validation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8', newline='\n')
    print('Torch canvas, alpha, palette, registration, six-frame states and hashes verified.')


if __name__ == '__main__':
    main()
