"""Export #244's immutable generated master through the field-kit fitter."""
import hashlib
import json
from pathlib import Path
import re
import sys
from PIL import Image

sys.dont_write_bytecode=True
from build_field_kit_art import fitted, nonvisual
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/calming-herbs-v1'
OUT=ROOT/'art/items/field-kit-v1'
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    record=json.loads((SOURCE/'generation.json').read_text(encoding='utf-8'))
    master=SOURCE/'master.png'
    assert sha(master)==record['sha256']
    raw=Image.open(master).convert('RGBA')
    exports=[]
    for size,colours,path in [(128,64,OUT/'calming-herbs.png'),(64,32,OUT/'compact64/calming-herbs.png')]:
        image,fit=fitted(raw,size,colours)
        path.parent.mkdir(parents=True,exist_ok=True)
        image.save(path)
        assert set(image.getchannel('A').get_flattened_data())=={0,255}
        bounds=image.getchannel('A').getbbox()
        margin=size//16
        assert bounds[0]>=margin and bounds[1]>=margin and bounds[2]<=size-margin and bounds[3]<=size-margin
        assert len({pixel[:3] for pixel in image.get_flattened_data() if pixel[3]})<=colours
        exports.append({'file':str(path.relative_to(ROOT)).replace('\\','/'),'sha256':sha(path),'canvas':size,'colours':colours,**fit})
    resource=ROOT/'data/items/calming_herbs.tres'
    text=resource.read_text(encoding='utf-8')
    before=nonvisual(text)
    text=re.sub(r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="icon"\])',r'\g<1>res://art/items/field-kit-v1/calming-herbs.png\2',text,count=1)
    assert nonvisual(text)==before
    resource.write_text(text,encoding='utf-8',newline='\n')
    record['exports']=exports
    record['nonvisual_resource_sha256']=hashlib.sha256(before.encode()).hexdigest()
    (SOURCE/'generation.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('CALMING_HERBS exports, padding, hard alpha, palette and resource invariants PASS')

if __name__=='__main__': main()
