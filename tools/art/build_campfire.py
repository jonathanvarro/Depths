"""Slice generated art into registered, small campfire assets; never repaint it."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/campfire-v1'
OUT = ROOT / 'art/features/campfire-v1'
REVIEW = ROOT / 'art/concepts/campfire-v1'
SIZE = 128


def silhouette(image):
    return image.getchannel('A').point(lambda a: 255 if a >= 96 else 0)


def export(image, palette):
    alpha = silhouette(image)
    quantized = image.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE).convert('RGBA')
    quantized.putalpha(alpha)
    return quantized


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    base_source = Image.open(SOURCE / 'base-generated.png').convert('RGBA')
    flame_source = Image.open(SOURCE / 'flames-generated.png').convert('RGBA')
    box = silhouette(base_source).getbbox()
    assert box is not None
    base = base_source.crop(box)
    scale = min(112 / base.width, 50 / base.height)
    base = base.resize((round(base.width * scale), round(base.height * scale)), Image.Resampling.NEAREST)
    base_canvas = Image.new('RGBA', (SIZE, SIZE))
    base_canvas.paste(base, (64 - base.width // 2, 121 - base.height))

    # Exact grid cells are preserved in the source. One scale across the cycle.
    cells = []
    boxes = []
    for index in range(6):
        col, row = index % 3, index // 3
        cell = flame_source.crop((round(col * flame_source.width / 3), round(row * flame_source.height / 2),
                                  round((col + 1) * flame_source.width / 3), round((row + 1) * flame_source.height / 2)))
        bounds = silhouette(cell).getbbox()
        assert bounds is not None, index
        cells.append(cell)
        boxes.append(bounds)
    scale = min(64 / max(b[2] - b[0] for b in boxes), 82 / max(b[3] - b[1] for b in boxes))
    flames = []
    registration = []
    for cell, bounds in zip(cells, boxes):
        # Register the root, not the moving tip/whole-silhouette centre.
        mask = silhouette(cell)
        root_points = [(x, y) for y in range(max(bounds[1], bounds[3] - 8), bounds[3])
                       for x in range(bounds[0], bounds[2]) if mask.getpixel((x, y))]
        root_x = sum(x for x, _ in root_points) / len(root_points)
        resized = cell.resize((round(cell.width * scale), round(cell.height * scale)), Image.Resampling.NEAREST)
        canvas = Image.new('RGBA', (SIZE, SIZE))
        offset = (round(64 - root_x * scale), round(102 - bounds[3] * scale))
        canvas.paste(resized, offset)
        flames.append(canvas)
        registration.append({'source_bounds': bounds, 'source_root_x': root_x, 'scale': scale, 'offset': offset})

    # Quantize the two material layers separately, sharing one flame palette
    # across all frames. Transparent RGB never contributes to palette selection.
    def palette_for(images, count):
        pixels = [p[:3] for image in images for p in image.get_flattened_data() if p[3] >= 96]
        strip = Image.new('RGB', (len(pixels), 1)); strip.putdata(pixels)
        return strip.quantize(colors=count, dither=Image.Dither.NONE)
    base_canvas = export(base_canvas, palette_for([base_canvas], 20))
    flame_palette = palette_for(flames, 10)
    flames = [export(f, flame_palette) for f in flames]
    base_canvas.save(OUT / 'base.png')
    atlas = Image.new('RGBA', (SIZE * 3, SIZE * 2))
    combined = []
    for i, flame in enumerate(flames):
        atlas.paste(flame, ((i % 3) * SIZE, (i // 3) * SIZE))
        composite = Image.alpha_composite(flame, base_canvas)
        combined.append(composite)
    atlas.save(OUT / 'flames.png')
    sheet = Image.new('RGB', (SIZE * 3, SIZE * 2), '#1b201f')
    for i, frame in enumerate(combined):
        sheet.paste(frame, ((i % 3) * SIZE, (i // 3) * SIZE), frame)
    sheet.resize((768, 512), Image.Resampling.NEAREST).save(REVIEW / 'contact-sheet.png')
    previews = []
    for frame in combined:
        bg = Image.new('RGBA', (SIZE, SIZE), '#1b201f'); bg.alpha_composite(frame)
        previews.append(bg.convert('RGB').resize((384, 384), Image.Resampling.NEAREST))
    # GIF timing is in hundredths of a second: alternate 120/130ms to
    # preserve the exact 750ms cycle without drifting from the 8fps resource.
    durations = [120, 130] * 3
    previews[0].save(REVIEW / 'campfire-loop.gif', save_all=True, append_images=previews[1:], duration=durations, loop=0)
    combined[0].save(REVIEW / 'campfire.png')
    if all((REVIEW / f'loop-{i}.png').exists() for i in range(6)):
        cave_frames = [Image.open(REVIEW / f'loop-{i}.png').convert('RGB') for i in range(6)]
        assert all(f.size == (768, 432) for f in cave_frames)
        assert len({f.tobytes() for f in cave_frames}) == 6
        palette_source = Image.new('RGB', (768 * 6, 432))
        for i, frame in enumerate(cave_frames): palette_source.paste(frame, (768 * i, 0))
        cave_palette = palette_source.quantize(colors=256, dither=Image.Dither.NONE)
        cave_frames = [f.quantize(palette=cave_palette, dither=Image.Dither.NONE) for f in cave_frames]
        cave_frames[0].save(REVIEW / 'cave-loop.gif', save_all=True,
                            append_images=cave_frames[1:], duration=durations, loop=0)
    report = {'canvas': [SIZE, SIZE], 'frame_count': 6, 'fps': 8, 'cycle_seconds': .75,
              'base_contact': [64, 120], 'flame_root': [64, 102], 'registration': registration,
              'frames': [], 'failures': []}
    for name, image in [('base', base_canvas)] + [(f'flame-{i}', f) for i, f in enumerate(flames)]:
        alpha = image.getchannel('A'); bounds = alpha.getbbox()
        colours = set(p[:3] for p in image.get_flattened_data() if p[3])
        assert bounds and bounds[0] > 0 and bounds[1] > 0 and bounds[2] < SIZE and bounds[3] < SIZE
        assert set(alpha.get_flattened_data()) == {0, 255}
        assert len(colours) <= (20 if name == 'base' else 10)
        report['frames'].append({'name': name, 'bounds': bounds, 'visible_colours': len(colours)})
    assert len({f.tobytes() for f in flames}) == 6
    report['sha256'] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in [OUT/'base.png', OUT/'flames.png']}
    report['source_sha256'] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                               for p in [SOURCE/'base-generated.png', SOURCE/'flames-generated.png']}
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'frames': 6, 'fps': 8, 'runtime_rgba_bytes': SIZE * SIZE * 7 * 4, 'failures': []}))


if __name__ == '__main__':
    main()
