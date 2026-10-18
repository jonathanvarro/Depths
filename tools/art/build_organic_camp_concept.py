"""Phone-scale concept exports; this does not replace the live layered camp."""
from pathlib import Path
import hashlib,json
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art/source/camp-organic-v2'
OUT=ROOT/'art/concepts/camp-organic-v2'

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    (OUT/'.gdignore').write_text('',encoding='utf-8')
    master=Image.open(SOURCE/'master.png').convert('RGB')
    # Keep the whole composition. The source's aspect is within 0.1% of 16:9.
    assert abs(master.width/master.height-16/9)<.002
    native=master.resize((640,360),Image.Resampling.NEAREST)
    native=native.quantize(colors=64,dither=Image.Dither.NONE).convert('RGB')
    native.save(OUT/'camp-640.png')
    native.resize((1280,720),Image.Resampling.NEAREST).save(OUT/'camp-1280.png')
    manifest=json.loads((SOURCE/'generation-manifest.json').read_text(encoding='utf-8'))
    assert manifest['args']['prompt'] and manifest['tool'].endswith('(built-in)')
    assert native.getcolors(maxcolors=64) is not None
    report={'issue':108,'kind':'Composition study, not runtime or touch-target validation',
      'source_canvas':list(master.size),'source_preserved':True,'source_cropped':False,
      'native_canvas':[640,360],'preview_canvas':[1280,720],'native_palette_limit':64,
      'resampling':'nearest','sha256':{}}
    for path in [SOURCE/'master.png',SOURCE/'generation-manifest.json',OUT/'camp-640.png',OUT/'camp-1280.png']:
        report['sha256'][path.relative_to(ROOT).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Preserved complete master; exported 640x360/64-colour concept and exact 2x preview.')

if __name__=='__main__':main()
