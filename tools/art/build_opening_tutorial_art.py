"""Export generated damaged gear and registered chest states, preserving masters."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import argparse
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art/source/opening-tutorial-v1'
ITEMS = ROOT / 'art/items/opening-tutorial-v1'
CHEST = ROOT / 'art/props/tutorial-chest-v1'
REVIEW = ROOT / 'art/concepts/opening-tutorial-v1'


def pixels(image):
    return image.get_flattened_data() if hasattr(image, 'get_flattened_data') else image.getdata()


def mask(image):
    return image.getchannel('A').point(lambda a: 255 if a >= 96 else 0)


def palette_for(images, count):
    samples = [p[:3] for image in images for p in pixels(image) if p[3] >= 96]
    strip = Image.new('RGB', (len(samples), 1)); strip.putdata(samples)
    return strip.quantize(colors=count, dither=Image.Dither.NONE)


def quantize(image, palette):
    result = image.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE).convert('RGBA')
    result.putalpha(mask(image))
    return result


def icon(image):
    bounds = mask(image).getbbox()
    assert bounds
    image = image.crop(bounds)
    image.thumbnail((56, 56), Image.Resampling.NEAREST)
    frame = Image.new('RGBA', (64, 64))
    frame.paste(image, ((64-image.width)//2, (64-image.height)//2))
    return frame


def verify(image, max_colours):
    bounds = mask(image).getbbox()
    colours = set(p[:3] for p in pixels(image) if p[3])
    assert bounds and 0 < bounds[0] and 0 < bounds[1] and bounds[2] < image.width and bounds[3] < image.height
    assert set(pixels(image.getchannel('A'))) == {0, 255}
    assert len(colours) <= max_colours
    return {'canvas': image.size, 'bounds': bounds, 'visible_colours': len(colours)}


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--icons-only', action='store_true'); args = parser.parse_args()
    for directory in [ITEMS, CHEST, REVIEW]: directory.mkdir(parents=True, exist_ok=True)
    report = {'issue': 70, 'alpha': 'binary, transparent background', 'assets': [], 'failures': []}
    review_icons = []
    for name, original in [('broken-knife', 'plain-knife'), ('damaged-armour', 'padded-coat')]:
        new = icon(Image.open(SOURCE / (name+'.png')).convert('RGBA'))
        old = icon(Image.open(ROOT / 'art/items/starter-v1' / (original+'.png')).convert('RGBA'))
        palette = palette_for([old, new], 24)
        new, old = quantize(new, palette), quantize(old, palette)
        dest = ITEMS / (name+'.png'); new.save(dest)
        report['assets'].append({'file': dest.relative_to(ROOT).as_posix(), **verify(new, 24)})
        review_icons.extend([(original, old), (name, new)])
    font_path = next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))
    font = ImageFont.truetype(str(font_path), 18)
    try:
        axes = font.get_variation_axes()
        font.set_variation_by_axes([400 if a['name'] == b'Weight' else a['default'] for a in axes])
    except OSError:
        pass
    board = Image.new('RGBA', (768, 480), '#1b201f')
    draw = ImageDraw.Draw(board)
    for index, (name, image) in enumerate(review_icons):
        board.alpha_composite(image.resize((128,128), Image.Resampling.NEAREST), (index*192+32, 38))
        draw.text((index*192+96, 12), name.replace('-', ' ').capitalize(), fill='#e6dac1', font=font, anchor='mt')
        board.alpha_composite(image.resize((40,40), Image.Resampling.NEAREST), (index*192+76, 178))
    board.crop((0,0,768,230)).convert('RGB').save(REVIEW/'gear-comparison.png')
    if args.icons_only:
        print('Two gear icons exported; originals preserved.')
        return
    board = Image.new('RGBA', (768,520), '#1b201f')
    draw = ImageDraw.Draw(board)
    for index, (name, image) in enumerate([review_icons[1], review_icons[3]]):
        centre = 256+index*256
        board.alpha_composite(image.resize((128,128),Image.Resampling.NEAREST),(centre-64,38))
        draw.text((centre,12),name.replace('-',' ').capitalize(),fill='#e6dac1',font=font,anchor='mt')
        board.alpha_composite(image.resize((40,40),Image.Resampling.NEAREST),(centre-20,178))
    frames, registration = [], []
    for state in ['closed', 'open', 'empty']:
        image = Image.open(SOURCE / ('chest-'+state+'.png')).convert('RGBA')
        assert image.width == image.height
        image = image.resize((1024,1024), Image.Resampling.NEAREST)
        # Compare/register only the shared lower box, not the raised lid.
        lower = mask(image).crop((0,666,1024,1024)).getbbox()
        assert lower
        lower = (lower[0], lower[1]+666, lower[2], lower[3]+666)
        registration.append({'state': state, 'lower_box': lower, 'root': [(lower[0]+lower[2])/2, lower[3]]})
        frames.append(image)
    common_scale = 104/max(r['lower_box'][2]-r['lower_box'][0] for r in registration)
    registered = []
    for image, data in zip(frames, registration):
        frame = Image.new('RGBA', (128,128))
        image = image.resize((round(1024*common_scale),round(1024*common_scale)), Image.Resampling.NEAREST)
        offset = (64-round(data['root'][0]*common_scale), 121-round(data['root'][1]*common_scale))
        frame.paste(image, offset)
        data.update({'scale': common_scale, 'offset': offset})
        registered.append(frame)
    # Give the small amber bottle enough weight to retain its identity;
    # otherwise the much larger wooden surfaces can consume the palette.
    contents_sample = registered[1].crop((38,54,66,79))
    palette = palette_for(registered + [contents_sample]*12, 32)
    registered = [quantize(image, palette) for image in registered]
    widths = []
    for i, (image, data) in enumerate(zip(registered, registration)):
        state = data['state']; dest = CHEST/(state+'.png'); image.save(dest)
        item = verify(image, 32)
        assert item['bounds'][3] == 121, (state, item['bounds'])
        lower = mask(image).crop((0,96,128,128)).getbbox()
        widths.append(lower[2]-lower[0])
        report['assets'].append({'file': dest.relative_to(ROOT).as_posix(), **item})
        board.alpha_composite(image.resize((256,256), Image.Resampling.NEAREST), (i*256, 260))
        draw.text((i*256+128, 238), {'closed':'Closed','open':'Open · supplies remain','empty':'Empty'}[state], fill='#e6dac1', font=font, anchor='mt')
    assert max(widths)-min(widths) <= 4, widths
    assert len({image.tobytes() for image in registered}) == 3
    board.convert('RGB').save(REVIEW/'overview.png')
    for bg_name, bg_colour in [('dark','#1b201f'), ('light','#dfd5be')]:
        sheet = Image.new('RGBA', (384,128), bg_colour)
        for i,image in enumerate(registered): sheet.alpha_composite(image, (i*128,0))
        sheet.convert('RGB').resize((768,256),Image.Resampling.NEAREST).save(REVIEW/('chest-'+bg_name+'.png'))
    report['chest_registration'] = registration
    report['pivot'] = [64,120]
    report['lower_box_widths'] = widths
    shared_colours = {p[:3] for image in registered for p in pixels(image) if p[3]}
    assert len(shared_colours) <= 32
    report['chest_shared_visible_colours'] = len(shared_colours)
    paths = [SOURCE/(name+'.png') for name in ['broken-knife','damaged-armour','chest-closed','chest-open','chest-empty']]
    paths += [ROOT/a['file'] for a in report['assets']]
    paths += [ROOT/'art/items/starter-v1'/name for name in ['plain-knife.png','padded-coat.png']]
    report['sha256'] = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    (REVIEW/'asset-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Five exports verified: exact canvases, alpha, palettes, floor contact and chest scale/footprint.')


if __name__ == '__main__': main()
