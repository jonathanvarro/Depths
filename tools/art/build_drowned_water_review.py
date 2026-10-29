"""Build the #166 offline review from exported art and real renderer captures."""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/concepts/drowned-water-v1'
def main():
 report=json.loads((OUT/'render-validation.json').read_text(encoding='utf-8'))
 frames=[Image.open(p).convert('RGB').resize((640,296),Image.Resampling.NEAREST) for p in sorted((ROOT/'build/drowned-water-review/motion').glob('*.png'))]
 if frames:
  frames[0].save(OUT/'motion-still.png')
  frames[0].save(OUT/'motion.gif',save_all=True,append_images=frames[1:],duration=250,loop=0)
 options=''.join('<option value="'+name+'">'+name.removesuffix('.png').replace('-',' ')+'</option>' for name in report['captures'])
 html=(OUT/'layout.html').read_text(encoding='utf-8').replace('@@options@@',options)
 (OUT/'inspector.html').write_text(html,encoding='utf-8',newline='\n')
 (OUT/'review.json').write_text(json.dumps({'captures':report['captures'],'motion_frames':len(frames),'motion_frame_ms':250,'source':'Actual isolated Godot 4.7.2 Mobile/D3D12 renderer; no Main/save/preferences','live_integration':False},indent=2)+'\n',encoding='utf-8')
 print('Review built with '+str(len(report['captures']))+' actual captures and '+str(len(frames))+' motion frames.')
if __name__=='__main__':main()
