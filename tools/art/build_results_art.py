"""#130: mechanical master exports and native UI/arrival drawings.

Generated illustrations are reduced only. Native glyphs extend the SVG system;
native pixel effects are independently authored, not painted over raster art.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
import hashlib, json, math

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT/'art/source/results-v1'
OUT = ROOT/'art/ui/results-v1'
REVIEW = ROOT/'art/concepts/results-v1'

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8', newline='\n')

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    write(REVIEW/'.gdignore', '')
    manifest = json.loads((SOURCE/'generation.json').read_text())
    for entry in manifest['assets']:
        path = ROOT/entry['source']
        actual = sha(path)
        assert entry.get('sha256', actual) == actual, entry['id']
        entry['sha256'] = actual
        raw = Image.open(path).convert('RGB')
        assert raw.width >= 1280 and raw.height >= 720
        image = ImageOps.fit(raw, (1280,720), Image.Resampling.BOX)
        image = image.quantize(128, dither=Image.Dither.NONE).convert('RGB')
        image.save(OUT/(entry['id']+'.png'))
    write(SOURCE/'generation.json', json.dumps(manifest, indent=2)+'\n')
    purse_path = ROOT/'art/items/refined-v2/old-coin-purse.png'
    purse = Image.open(purse_path).convert('RGBA')
    # Existing coin/purse identity, uniformly reduced with no redrawing.
    small = purse.resize((32,32), Image.Resampling.BOX)
    small.save(OUT/'coin-pouch.png')
    glyphs = {
      'experience': '<path d="M7 7v17m6-19v19m6-19v19m6-19v19M4 22l24-12" fill="none" stroke="#e3d4ad" stroke-width="2.5" stroke-linecap="square"/>',
      'level-up': '<path d="M6 16 16 5 26 16h-6v10h-8V16Z" fill="#bd9a55" stroke="#eddbac" stroke-width="2"/><path d="M8 29h16" stroke="#eddbac" stroke-width="2"/>',
    }
    for name, body in glyphs.items():
        write(SOURCE/(name+'.svg'), '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">'+body+'</svg>\n')
    inputs = [{'path':str(purse_path.relative_to(ROOT)).replace('\\','/'), 'sha256':sha(purse_path)}]
    for name in ['danger','object','down']:
        path = ROOT/f'art/source/backlog96-v1/glyphs/map/{name}.svg'
        text = path.read_text().replace('#362b20','#e3d4ad')
        write(SOURCE/(name+'-light.svg'), text)
        inputs.append({'path':str(path.relative_to(ROOT)).replace('\\','/'), 'sha256':sha(path)})
    write(SOURCE/'native-inputs.json', json.dumps(inputs,indent=2)+'\n')
    for kind in ['slash','smash','pierce','fire']:
        frames=[]
        for i in range(8):
            image=Image.new('RGBA',(128,64)); d=ImageDraw.Draw(image)
            # Empty endpoints permit safe one-shot cleanup; no screen-sized flash.
            if 0 < i < 7:
                a=[0,145,225,200,140,85,35,0][i]
                pale=(239,218,179,a); shade=(152,127,95,a)
                if kind=='slash':
                    p=i/6
                    x=round(10+p*86); y=round(8+p*41)
                    d.polygon([(6,6),(x,y-3),(min(123,x+18),min(59,y+5)),(x-3,y+2)],fill=pale)
                    d.line([(9,9),(x,y+3)],fill=shade,width=2)
                elif kind=='pierce':
                    x=round(16+i*14)
                    d.polygon([(max(3,x-45),30),(x-7,28),(x,32),(x-7,35),(max(3,x-45),34)],fill=pale)
                    d.line([(max(3,x-65),32),(x-12,32)],fill=shade,width=1)
                elif kind=='smash':
                    for j in range(9):
                        angle=j*math.tau/9+.12
                        length=min(27,5+i*4)+(j%3)*2
                        c=(64,32); bend=(round(64+math.cos(angle)*length*.55),round(32+math.sin(angle)*length*.55))
                        tip=(round(64+math.cos(angle+.11)*length*1.5),round(32+math.sin(angle+.11)*length*.8))
                        d.line([c,bend,tip],fill=pale if j%2 else shade,width=1 if i>3 else 2)
                    if i<4:d.polygon([(62,27),(66,29),(70,32),(65,35),(61,34),(58,30)],fill=pale)
                else:
                    for x in range(7,122):
                        y=round(53-i*5+4*math.sin(x*.19+i))
                        d.line([(x,y),(x,y+3+(x%5))],fill=(191,79,29,a),width=1)
                        if x%3==0:d.point((x,y),fill=(238,164,70,a))
                    for j in range(18):
                        x=8+(j*47)%110;y=52-(j*13+i*6)%44
                        d.point((x,y),fill=(216,124,46,a))
            frames.append(image)
        sheet=Image.new('RGBA',(512,128))
        for i,image in enumerate(frames):sheet.paste(image,((i%4)*128,(i//4)*64))
        sheet.save(OUT/(kind+'.png'))
        resources='[gd_resource type="SpriteFrames" load_steps=10 format=3]\n\n[ext_resource type="Texture2D" path="res://art/ui/results-v1/'+kind+'.png" id="sheet"]\n'
        for i in range(8):
            resources+=f'\n[sub_resource type="AtlasTexture" id="f{i}"]\natlas = ExtResource("sheet")\nregion = Rect2({i%4*128}, {i//4*64}, 128, 64)\n'
        resources+='\n[resource]\nanimations = [{"frames": ['+','.join('{"duration":1.0,"texture":SubResource("f%d")}'%i for i in range(8))+'], "loop":false, "name":&"arrival", "speed":20.0}]\n'
        write(OUT/(kind+'-frames.tres'), resources)
    write(OUT/'catalog.json', json.dumps({'issue':130,'backdrops':[1280,720], 'glyphs':[32,32], 'effects':{'names':['slash','smash','pierce','fire'],'canvas':[128,64],'frames':8,'fps':20,'loop':False},'purse_source':inputs[0]},indent=2)+'\n')
    print('RESULTS_ART: two backgrounds, reused purse, five native SVGs, four 8-frame arrivals.')

if __name__=='__main__': main()
