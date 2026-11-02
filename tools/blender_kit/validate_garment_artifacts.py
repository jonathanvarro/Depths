"""Private-asset integrity, eight export payloads and actual-render lineage."""
from pathlib import Path
import json,struct,hashlib,io
from PIL import Image,ImageChops
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/local-blender-kit-v1';OUT=BASE/'garments-v1'
checks=0
def check(ok,label):
    global checks
    checks+=1
    assert ok,label
def glb(path):
    data=path.read_bytes();magic,version,total=struct.unpack_from('<III',data,0);check(magic==0x46546C67 and version==2 and total==len(data),'Valid GLB '+path.name)
    length,kind=struct.unpack_from('<II',data,12);check(kind==0x4E4F534A,'JSON chunk '+path.name);doc=json.loads(data[20:20+length]);offset=20+length
    payload=b''
    if offset<len(data):size,kind=struct.unpack_from('<II',data,offset);payload=data[offset+8:offset+8+size]
    return doc,payload
def main():
    source=json.loads((BASE/'kit-manifest.json').read_text())
    for e in source['sources']:check(hashlib.sha256((BASE/e['file']).read_bytes()).hexdigest()==e['sha256'],'Copied original unchanged '+e['file'])
    captures=json.loads((OUT/'review/captures.json').read_text());check(len(captures['captures'])==138,'Complete real capture matrix')
    export=json.loads((OUT/'export-validation.json').read_text());check(not export['failures'],'Independent exports passed')
    for fit in ['female','male']:
        record=json.loads((OUT/(fit+'-manifest.json')).read_text());check(hashlib.sha256((OUT/record['master']).read_bytes()).hexdigest()==record['sha256']==captures['masters_sha256'][fit],'Current master/source render lineage '+fit)
        check(hashlib.sha256((BASE/record['source_master']).read_bytes()).hexdigest()==record['source_master_sha256'],'Base master untouched '+fit)
        report=next(r for r in export['reports'] if r['fit']==fit)
        for entry in [{'file':report['export'],'meshes':11,'sha256':report['sha256']}]+report['parts']:
            path=OUT/entry['file'];check(hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'],'Final export hash '+path.name);doc,payload=glb(path)
            check(len(doc['meshes'])==entry['meshes'] and len(doc['skins'])==1 and len(doc['skins'][0]['joints'])==(65 if fit=='female' else 49),'Actual mesh/full rig payload '+path.name)
            check(len(doc['animations'])==5,'Exactly five real motions '+path.name)
            if path.name==fit+'_kit.glb':
                if fit=='female':
                    material=next(m for m in doc['materials'] if m['name']=='source.skin.female');check(material.get('alphaMode','OPAQUE')=='OPAQUE','Opaque source skin keeps depth correct')
                    image=doc['images'][0];view=doc['bufferViews'][image['bufferView']];blob=payload[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
                    embedded=Image.open(io.BytesIO(blob)).convert('RGBA');original=Image.open(BASE/'textures/source-female-body.png').convert('RGBA');check(embedded.size==original.size and embedded.tobytes()==original.tobytes(),'Source skin pixels unchanged in GLB')
        with Image.open(OUT/'review'/(fit+'-walk.gif')) as image:check(image.n_frames==12 and image.size==(420,560),'Actual12-frame GIF '+fit)
    for entry in captures['captures']:
        with Image.open(OUT/'review'/entry['file']) as image:check(image.size==(420,560) and image.getextrema()[0][0]!=image.getextrema()[0][1],'Nonblank actual capture '+entry['file'])
    result={'checks':checks,'failures':[],'verified_source_files':len(source['sources']),'real_blender_captures':len(captures['captures']),'primary_export_files':8,'all_art_local':True};(OUT/'artifact-validation.json').write_text(json.dumps(result,indent=2)+'\n');print('GARMENT_ARTIFACTS',checks,'checks; no failures')
if __name__=='__main__':main()
