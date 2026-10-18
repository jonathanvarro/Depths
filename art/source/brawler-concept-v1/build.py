"""Export the preserved generated concept, without changing live portrait resources."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib,json

SOURCE=Path(__file__).resolve().parent
ROOT=SOURCE.parents[2]
OUT=ROOT/'art/concepts/portraits/brawler-concept-v1'

def pixels(im):
    return im.get_flattened_data() if hasattr(im,'get_flattened_data') else im.getdata()

def main():
    im=Image.open(SOURCE/'master.png').convert('RGBA')
    assert im.width==im.height,'Square master required'
    canvas=Image.new('RGBA',(192,192))
    canvas.paste(im.resize((184,184),Image.Resampling.NEAREST),(4,4))
    alpha=canvas.getchannel('A').point(lambda a:255 if a>=96 else 0)
    samples=[p[:3] for p in pixels(canvas) if p[3]>=96]
    strip=Image.new('RGB',(len(samples),1));strip.putdata(samples)
    pal=strip.quantize(colors=48,dither=Image.Dither.NONE)
    canvas=canvas.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA')
    canvas.putalpha(alpha)
    canvas.save(OUT/'portrait-192.png')
    card=canvas.resize((96,96),Image.Resampling.NEAREST);card.save(OUT/'portrait-96.png')
    canvas.resize((768,768),Image.Resampling.NEAREST).save(OUT/'portrait-enlarged.png')
    font=ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),18)
    for name,colour,ink in [('dark','#1b2420','#e6dac1'),('light','#d6cbb4','#262b27')]:
        board=Image.new('RGBA',(768,480),colour);draw=ImageDraw.Draw(board)
        board.alpha_composite(canvas.resize((384,384),Image.Resampling.NEAREST),(24,32))
        board.alpha_composite(canvas,(488,32));board.alpha_composite(card,(536,296))
        draw.text((216,430),'192px portrait · enlarged ×2',font=font,fill=ink,anchor='mt')
        draw.text((584,236),'192px native',font=font,fill=ink,anchor='mt')
        draw.text((584,406),'96px party card',font=font,fill=ink,anchor='mt')
        board.convert('RGB').save(OUT/('review-'+name+'.png'))
    assert set(alpha.get_flattened_data() if hasattr(alpha,'get_flattened_data') else alpha.getdata())=={0,255}
    assert len({p[:3] for p in pixels(canvas) if p[3]})<=48
    assert not alpha.crop((0,0,192,4)).getbbox(),'Head has top margin'
    report={'issue':102,'tool':'built-in image_gen.imagegen','scope':'static concept; not a registered animated rig',
        'transform':{'full_square_resize':[184,184],'offset':[4,4]},'canvas':[192,192],'card_canvas':[96,96],
        'alpha_bounds':alpha.getbbox(),'visible_colours':len({p[:3] for p in pixels(canvas) if p[3]}),
        'source_sha256':hashlib.sha256((SOURCE/'master.png').read_bytes()).hexdigest(),
        'export_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.glob('*.png')},'failures':[]}
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Transparent 192px portrait and 96px card exported; alpha, palette and margins pass.')

if __name__=='__main__':main()
