"""Export eight additional valuables; keep the first treasure set unchanged."""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib
import importlib.util
import json
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('treasure_export', ROOT/'tools/art/build_treasure_art.py')
base = importlib.util.module_from_spec(spec); spec.loader.exec_module(base)
SOURCE = ROOT/'art/source/treasure-extra-v1'
ICONS = ROOT/'art/items/treasure-extra-v1'
ILLUSTRATIONS = ROOT/'art/props/treasure-extra-v1'
REVIEW = ROOT/'art/concepts/treasure-extra-v1'
ITEMS = [('gold-nuggets','Gold nuggets'),('silver-ingot','Silver ingot'),
    ('pearl-necklace','Pearl necklace'),('silver-locket','Silver locket'),
    ('military-medal','Military medal'),('small-reliquary','Small reliquary'),
    ('fine-cloth','Fine cloth'),('spice-pouch','Sealed spice pouch')]
REFERENCES = [ROOT/'art/items/treasure-v1'/name for name in
    ['silver-goblet.png','gold-signet-ring.png','coin-purse.png']]


def main():
    for directory in [ICONS,ILLUSTRATIONS,REVIEW]: directory.mkdir(parents=True,exist_ok=True)
    original = json.loads((ROOT/'art/items/treasure-v1/catalog.json').read_text())
    catalog = json.loads(json.dumps(original))
    catalog.update({'version':2,'issue':91,'base_catalog':'res://art/items/treasure-v1/catalog.json',
        'new_ids':[id for id,label in ITEMS]})
    report = {'issue':91,'assets':{},'failures':[],'new_items':8,'combined_items':22,
        'runtime_rgba_bytes':8*(64*64+128*128)*4}
    for id,label in ITEMS:
        source=Image.open(SOURCE/(id+'.png')).convert('RGBA')
        plate=base.fit_plate(source)
        plate=base.quantize(plate,base.palette([plate],32))
        icon=base.fit_icon(plate)
        for folder,im,size in [(ICONS,icon,(64,64)),(ILLUSTRATIONS,plate,(128,128))]:
            path=folder/(id+'.png');im.save(path)
            report['assets'][path.relative_to(ROOT).as_posix()]=base.verify(im,size,32)
        assert base.mask(plate).getbbox()[3]==121,id
        catalog['assets'].append({'id':id,'label':label,'category':'valuable',
            'icon':base.uri(ICONS/(id+'.png')),'illustration':base.uri(ILLUSTRATIONS/(id+'.png'))})
    assert len(catalog['assets'])==22 and len({e['id'] for e in catalog['assets']})==22
    assert catalog['assets'][:14]==original['assets'],'Original entries changed'
    (ICONS/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8',newline='\n')
    for bg,colour in [('dark','#1b2420'),('light','#d6cbb4')]:
        board=Image.new('RGBA',(768,370),colour);draw=ImageDraw.Draw(board)
        for i,(id,label) in enumerate(ITEMS):
            im=Image.open(ICONS/(id+'.png')).convert('RGBA')
            x=(i%4)*192;y=(i//4)*184
            board.alpha_composite(im.resize((128,128),Image.Resampling.NEAREST),(x+32,y+12))
            draw.text((x+96,y+150),label,font=base.font(17),fill='#e6dac1' if bg=='dark' else '#262b27',anchor='mt')
        board.convert('RGB').save(REVIEW/('overview-'+bg+'.png'))
    board=Image.new('RGBA',(640,370),'#1b2420');draw=ImageDraw.Draw(board)
    for i,(id,label) in enumerate(ITEMS):
        im=Image.open(ICONS/(id+'.png')).convert('RGBA')
        x=(i%4)*160;y=(i//4)*156
        board.alpha_composite(im,(x+48,y+10))
        board.alpha_composite(im.resize((40,40),Image.Resampling.NEAREST),(x+60,y+82))
        draw.text((x+80,y+126),label,font=base.font(15),fill='#e6dac1',anchor='mt')
    for i,name in enumerate(['gold-signet-ring','amber-pendant','silver-goblet']):
        im=Image.open(ROOT/'art/items/treasure-v1'/(name+'.png')).convert('RGBA')
        board.alpha_composite(im.resize((40,40),Image.Resampling.NEAREST),(320+i*88,322))
    draw.text((28,334),'Existing treasure →',font=base.font(17),fill='#e6dac1')
    board.convert('RGB').save(REVIEW/'inventory-sizes.png')
    # One combined native-size index lets the next assistant find all 22 IDs.
    board=Image.new('RGBA',(840,480),'#1b2420');draw=ImageDraw.Draw(board)
    for i,entry in enumerate(catalog['assets']):
        im=Image.open(ROOT/entry['icon'].replace('res://','')).convert('RGBA')
        x=(i%7)*120;y=(i//7)*120
        board.alpha_composite(im,(x+28,y+6))
        for line_index,line in enumerate(entry['id'].split('-')):
            draw.text((x+60,y+76+line_index*14),line,font=base.font(13),fill='#e6dac1',anchor='mt')
    board.convert('RGB').save(REVIEW/'all-treasure.png')
    paths=list(SOURCE.glob('*.png'))+[ROOT/p for p in report['assets']]
    report['sha256']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    report['reference_sha256']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in REFERENCES}
    (REVIEW/'asset-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Eight additional valuables exported; combined catalog has 22 entries. Original art unchanged.')


if __name__=='__main__':main()
