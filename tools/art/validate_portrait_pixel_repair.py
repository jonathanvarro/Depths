"""Independently validate every changed pixel and unchanged resting layer for #121."""
from pathlib import Path
from PIL import Image,ImageChops
import hashlib,json,re,subprocess

ROOT=Path(__file__).resolve().parents[2]
REVIEW=ROOT/'art/concepts/portrait-pixel-repair-v1'
report=json.loads((REVIEW/'pixel-validation.json').read_text())
checks=0;frames=0;counts=[]
for face in report['faces']:
    base=Image.open(ROOT/'art/source/portrait-pixel-repair-v1'/face['face']/'resting-reference.png').convert('RGBA')
    assert hashlib.sha256(base.tobytes()).hexdigest()==face['base_sha256']
    for source,sha in face['input_layers'].items():
        path=ROOT/source.removeprefix('res://')
        assert hashlib.sha256(path.read_bytes()).hexdigest()==sha,(face['face'],source,'resting source altered')
        # Compare original tracked source byte-for-byte, not just the generated report.
        original=subprocess.check_output(['git','show',report['baseline']+':'+path.relative_to(ROOT).as_posix()],cwd=ROOT)
        assert path.read_bytes()==original,(source,'original changed')
        checks+=1
    for frame in face['frames']:
        path=ROOT/frame['texture'].removeprefix('res://');image=Image.open(path).convert('RGBA')
        mask=Image.open(ROOT/frame['mask'].removeprefix('res://')).convert('L')
        assert image.size==mask.size==(192,192)
        assert image.getpixel((0,0))[3]==0 and {c[3] for c in image.get_flattened_data()}=={0,255}
        assert hashlib.sha256(path.read_bytes()).hexdigest()==frame['sha256']
        composed=base.copy();composed.alpha_composite(image)
        changed=[(x,y) for y in range(192) for x in range(192) if composed.getpixel((x,y))!=base.getpixel((x,y))]
        assert len(changed)==frame['changed_pixels'] and all(mask.getpixel(p)==255 for p in changed),(face['face'],frame['name'],'outside fitted region')
        # Eyebrow bar, head, nose, other facial feature and body pixels must not move.
        outside=ImageChops.invert(mask)
        assert not ImageChops.multiply(ImageChops.difference(base,composed).convert('RGB').convert('L'),outside).getbbox()
        assert all(y>=65 for x,y in changed) if frame['name'].startswith('eyes') else all(y>=89 for x,y in changed)
        palette={p[:3] for p in base.get_flattened_data() if p[3]}
        assert all(p[:3] in palette for p in image.get_flattened_data() if p[3]),(face['face'],'new foreign colour')
        frames+=1;checks+=7;counts.append(len(changed))
assert frames==51 and len(report['faces'])==12
validation={'checks':checks,'faces':12,'frames':frames,'changed_pixels_per_frame':[min(counts),max(counts)],'resting_sources_byte_identical_to':report['baseline'],'outside_fitted_lid_lip_masks_changed_pixels':0,'native_palette_preserved':True,'failures':[]}
(REVIEW/'independent-validation.json').write_text(json.dumps(validation,indent=2)+'\n',encoding='utf-8',newline='\n')
print(f'PIXEL_REPAIR: {checks} checks; 51 frames / 12 faces; {min(counts)}–{max(counts)} pixels edited per frame; 0 changed outside fitted masks.')
