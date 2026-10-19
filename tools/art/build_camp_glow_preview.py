"""Encode actual Godot captures into an animated review, not an art repaint."""
from pathlib import Path
from PIL import Image
import hashlib,json

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/camp-layered-v3'

def main():
    paths=sorted((ROOT/'build/camp-layered/animation').glob('*.png'))
    assert len(paths)==24
    frames=[Image.open(path).convert('RGB') for path in paths]
    assert all(frame.size==(640,360) for frame in frames)
    samples=Image.new('RGB',(160,90*len(frames)))
    for i,frame in enumerate(frames):samples.paste(frame.resize((160,90),Image.Resampling.NEAREST),(0,90*i))
    palette=samples.quantize(colors=256,dither=Image.Dither.NONE)
    indexed=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
    path=OUT/'camp-glow.gif'
    indexed[0].save(path,save_all=True,append_images=indexed[1:],duration=100,loop=0,disposal=2,optimize=False)
    image=Image.open(path)
    assert image.n_frames>=6 and image.info['loop']==0
    report={'kind':'Actual Godot capture preview','source_frames':24,'gif_frames':image.n_frames,
      'canvas':[640,360],'loop':True,'nominal_frame_duration_ms':100,
      'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    (OUT/'animation-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Encoded live camp glow/flame preview:',image.n_frames,'frames.')

if __name__=='__main__':main()
