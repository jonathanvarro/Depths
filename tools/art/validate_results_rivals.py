"""Source preservation, native component replacement and delivery contracts."""
from pathlib import Path
from PIL import Image, ImageChops
import hashlib, json
ROOT=Path(__file__).resolve().parents[2]
checks=0
def check(ok,label):
    global checks
    checks+=1
    if not ok:raise AssertionError(label)
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(path):return Image.open(path).convert('RGBA')
def main():
    for group in ['results-v1','dark-elves-v1']:
        manifest=json.loads((ROOT/f'art/source/{group}/generation.json').read_text())
        for e in manifest['assets']:
            check(sha(ROOT/e['source'])==e['sha256'],'Immutable master '+e['id'])
            check(bool(e['prompt']) and e['tool']=='built-in image_gen','Exact prompt '+e['id'])
    for entry in json.loads((ROOT/'art/source/results-v1/native-inputs.json').read_text()):
        check(sha(ROOT/entry['path'])==entry['sha256'],'Reused art unchanged '+entry['path'])
    result=ROOT/'art/ui/results-v1'
    for name in ['results-dawn','results-wipe']:
        im=load(result/(name+'.png'))
        check(im.size==(1280,720),'Landscape background '+name)
        check(im.getchannel('A').getextrema()==(255,255),'Opaque background '+name)
    check(sha(result/'results-dawn.png')!=sha(result/'results-wipe.png'),'Distinct ending treatments')
    for name in ['coin-pouch','experience','level-up','danger-light','object-light','down-light']:
        im=load(result/(name+'.png'))
        check(im.size==(32,32) and im.getbbox() is not None,'Readable glyph '+name)
        check(im.getchannel('A').getextrema()[0]==0,'Transparent glyph '+name)
    for name in ['slash','smash','pierce','fire']:
        sheet=load(result/(name+'.png'))
        check(sheet.size==(512,128),'Effect atlas '+name)
        frames=[sheet.crop((i%4*128,i//4*64,i%4*128+128,i//4*64+64)) for i in range(8)]
        check(not frames[0].getbbox() and not frames[-1].getbbox(),'Empty endpoints '+name)
        check(all(f.getbbox() for f in frames[1:-1]),'Visible intermediate frames '+name)
        check(len({f.tobytes() for f in frames[1:-1]})==6,'Six distinct animated drawings '+name)
    for ident in ['dark-elf-man','dark-elf-woman']:
        folder=ROOT/'art/portraits/dark-elves-v1'/ident
        original=load(folder/'resting.png');clean=load(folder/'character-clean.png')
        eyes=Image.open(ROOT/'art/source/dark-elves-v1'/ident/'eye-mask.png').convert('L')
        mouth=Image.open(ROOT/'art/source/dark-elves-v1'/ident/'mouth-mask.png').convert('L')
        check(not ImageChops.multiply(eyes,mouth).getbbox(),'Independent feature mattes '+ident)
        reconstructed=clean.copy()
        for kind in ['eyes','mouth']:reconstructed.alpha_composite(load(folder/(kind+'-neutral.png')))
        check(reconstructed.tobytes()==original.tobytes(),'Exact neutral reconstruction '+ident)
        check(clean.tobytes()!=original.tobytes(),'Features actually erased '+ident)
        check(clean.getchannel('A').tobytes()==original.getchannel('A').tobytes(),'Silhouette unchanged '+ident)
        for file in sorted(folder.glob('*.png')):
            im=load(file)
            check(im.size==(192,192),'Full canvas '+str(file.name))
            if file.stem not in ['shadow','highlight']:
                check(set(im.getchannel('A').get_flattened_data())<=set([0,255]),'Binary native matte '+file.name)
                check(len({p[:3] for p in im.get_flattened_data() if p[3]})<=96,'Native portrait palette '+file.name)
        for name,mask in [('eyes-half',eyes),('eyes-closed',eyes),('mouth-small',mouth),('mouth-open',mouth),('mouth-round',mouth)]:
            frame=load(folder/(name+'.png'))
            check(frame.getchannel('A').tobytes()==mask.tobytes(),'Complete component replacement '+name+ident)
            neutral=load(folder/('eyes-neutral.png' if name.startswith('eyes') else 'mouth-neutral.png'))
            check(frame.tobytes()!=neutral.tobytes(),'Distinct drawing '+name+ident)
        for eye in ['eyes-half','eyes-closed','eyes-neutral']:
            for lip in ['mouth-small','mouth-open','mouth-round','mouth-neutral']:
                merged=clean.copy();merged.alpha_composite(load(folder/(eye+'.png')));merged.alpha_composite(load(folder/(lip+'.png')))
                difference=ImageChops.difference(merged,original).convert('RGB').getbbox()
                outside=ImageChops.invert(ImageChops.lighter(eyes,mouth))
                changed=ImageChops.difference(merged,original).convert('RGB')
                changed.paste((0,0,0),(0,0,192,192),ImageChops.lighter(eyes,mouth))
                check(not changed.getbbox(),'Combined animation stays inside full feature mattes '+ident+eye+lip)
        for kind in ['shadow','highlight']:
            layer=load(folder/(kind+'.png'))
            check(not ImageChops.multiply(layer.getchannel('A'),ImageChops.invert(original.getchannel('A'))).getbbox(),'Light never paints outside character '+ident+kind)
        closed=Image.open(ROOT/'art/source/dark-elves-v1'/ident/'eyes-closed-iris.png')
        check(not closed.getbbox(),'Closed drawing contains no retained iris mask '+ident)
        text=(ROOT/'data/portraits/dark-elves-v1'/(ident+'.tres')).read_text()
        check('rig_kind = "Unique"' in text and ('face_id = &"'+ident+'"') in text,'Unique resource identity '+ident)
    enemy=ROOT/'art/enemies/dark-elves-v1/spearman'
    metadata=json.loads((enemy/'registration.json').read_text());palette=set()
    for pose in metadata['poses']:
        im=load(enemy/(pose['pose']+'.png'))
        palette.update(p[:3] for p in im.get_flattened_data() if p[3])
        check(im.size==(128,128) and im.getbbox()[3]==121,'128px planted combat pose '+pose['pose'])
        check(set(im.getchannel('A').get_flattened_data())=={0,255},'Hard alpha '+pose['pose'])
        check(sha(enemy/(pose['pose']+'.png'))==pose['sha256'],'Combat export matches registration '+pose['pose'])
    check(len(palette)<=32,'Shared combat palette')
    check(metadata['pivot']==[64,120],'Shared combat pivot')
    report={'checks':checks,'failures':[], 'limits':'Visual inspection and physical iPhone review remain distinct from these data checks.'}
    (ROOT/'art/concepts/results-v1/pixel-validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print('RESULTS_RIVALS_SOURCE checks=%d failures=0'%checks)
if __name__=='__main__':main()
