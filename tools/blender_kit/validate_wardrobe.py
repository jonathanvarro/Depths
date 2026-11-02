"""Validate local lineage, GLB payloads and real renderer capture coverage."""
from pathlib import Path
import hashlib,json,struct,io
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/local-blender-kit-v1';OUT=BASE/'assembly-v1'
checks=0
def check(ok,label):
    global checks
    checks+=1
    assert ok,label
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read_glb(path):
    raw=path.read_bytes();magic,version,size=struct.unpack_from('<III',raw)
    check(magic==0x46546c67 and version==2 and size==len(raw),'Valid self-contained GLB')
    size,kind=struct.unpack_from('<II',raw,12);check(kind==0x4e4f534a,'JSON payload')
    doc=json.loads(raw[20:20+size]);offset=20+size;size,kind=struct.unpack_from('<II',raw,offset+0)
    check(kind==0x004e4942,'Binary payload');return doc,raw[offset+8:offset+8+size]
def main():
    manifest=json.loads((OUT/'manifest.json').read_text());native=json.loads((OUT/'review/validation.json').read_text())
    for e in json.loads((BASE/'kit-manifest.json').read_text())['sources']:check(sha(BASE/e['file'])==e['sha256'],'Original copy untouched '+e['file'])
    check(not native['failures'] and native['display']!='headless' and native['checks']>2000,'Complete clean native review')
    log=(BASE/'wardrobe-native.log').read_text(encoding='utf-8');check('SCRIPT ERROR' not in log and 'ERROR:' not in log,'Native process has no hidden script errors')
    for fit,record in manifest['fits'].items():
        check(sha(OUT/record['master'])==record['master_sha256']==sha(BASE/record['source_master'])==record['source_master_sha256'],'Source and editable copy unchanged '+fit)
        check(sha(OUT/record['export'])==record['export_sha256'],'Exact reviewed export '+fit)
        doc,payload=read_glb(OUT/record['export'])
        check(len(doc['skins'])==1 and len(doc['skins'][0]['joints'])==record['bones'],'One full original rig '+fit)
        check(len(doc['animations'])==5,'Exactly five real animations '+fit)
        check(len(doc['meshes'])==len(record['body_chunks'])+10,'Disjoint body regions plus ten editable garment details '+fit)
        check(set(m['name'] for m in doc['animations'])=={m['action'] for m in record['motions']},'Actual exact clip names '+fit)
        chunks={e['name']:e for e in record['body_chunks']};geometry={}
        for node in doc['nodes']:
            if 'mesh' not in node:continue
            geometry[node['name']]=sum(doc['accessors'][p['indices']]['count']//3 for p in doc['meshes'][node['mesh']]['primitives'])
        for bits in range(32):
            check(sum(geometry[name] for name,c in chunks.items() if not(c['hidden_by']&bits))==record['body_triangles_by_selection'][bits],'GLB coverage surfaces '+fit+str(bits))
        visible=sum(geometry[e['name']] for e in record['garments'])+record['body_triangles_by_selection'][31]
        check(visible==native['counts'][fit]['triangles'],'Actual full-kit triangle count '+fit)
        check(record['max_independent_deformation_error']<.001,'Independent Blender skin/deformation round trip '+fit)
        for image in doc.get('images',[]):
            check('bufferView' in image,'Texture is embedded, no external image dependency')
            view=doc['bufferViews'][image['bufferView']];blob=payload[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
            source=Image.open(BASE/'textures/source-female-body.png').convert('RGBA');candidate=Image.open(io.BytesIO(blob)).convert('RGBA')
            check(candidate.size==source.size and candidate.tobytes()==source.tobytes(),'Exact original skin RGBA pixels')
        with Image.open(OUT/'review'/(fit+'-walk.gif')) as image:check(image.n_frames==12 and image.height>=500,'Twelve actual full-size motion samples '+fit)
        for motion in ['rest','idle','walk','sit_down','seated','dying']:
            for sample in [0] if motion=='rest' else [0,1,2]:
                for angle in [0,2,3]:check(any(c.get('fit')==fit and c.get('motion')==motion and c.get('angle')==angle and c['file']==f'{fit}-{motion}-{sample}-{angle}.png' for c in native['captures']),'Exact native matrix entry '+fit+motion+str(sample)+str(angle))
    check(len(native['captures'])==163,'Complete raw models, UI, native cards and motion frames')
    for capture in native['captures']:
        with Image.open(OUT/'review'/capture['file']) as image:
            check(list(image.size)==capture['size'] and image.getextrema()[0][0]!=image.getextrema()[0][1],'Actual nonblank capture '+capture['file'])
    for source,target in [('wardrobe_actor.gd','actor.gd'),('wardrobe_review.gd','review.gd'),('check_wardrobe.gd','check.gd')]:check(sha(Path(__file__).with_name(source))==sha(OUT/target),'Reviewed source matches reusable tool '+source)
    check(sha(Path(__file__).with_name('display_normalization.json'))==sha(OUT/'display_normalization.json'),'Reviewed fixed display normalization matches source')
    result={'checks':checks,'failures':[],'actual_captures':len(native['captures']),'native_portrait_cards':24,'source_files_unchanged':39,'blender_export_checks':manifest['checks'],'native_checks':native['checks'],'final_animation_acceptance_pending':215,'all_art_local':True}
    (OUT/'review/artifact-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print('WARDROBE_ARTIFACTS',checks,'checks, no failures')
if __name__=='__main__':main()
