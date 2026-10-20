"""Validate the art library and build a pause/step inspector from its catalogues."""
from pathlib import Path
import hashlib
import json
import math
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
REVIEW=ROOT/'art/concepts/cave-dressing-v1'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    sources=json.loads((ROOT/'art/source/cave-dressing-v1/generation.json').read_text(encoding='utf-8'))
    dressing=json.loads((ROOT/'art/dressing/cave-v1/catalog.json').read_text(encoding='utf-8'))
    effects=json.loads((ROOT/'art/effects/ambient-v1/catalog.json').read_text(encoding='utf-8'))
    total_bytes=0
    max_dimension=0
    for source in sources['assets']:
        path=ROOT/source['source']
        assert sha(path)==source['sha256'],('Changed source',source['id'])
        original=Path(source['original'])
        if original.exists():assert sha(original)==source['sha256']
    for entry in dressing['assets']:
        path=ROOT/entry['texture'].removeprefix('res://')
        assert sha(path)==entry['export_sha256']
        assert sha(ROOT/entry['source'].removeprefix('res://'))==entry['source_sha256']
        image=Image.open(path).convert('RGBA')
        assert image.size==(128,128)
        assert len({p[:3] for p in image.get_flattened_data() if p[3]})<=64,entry['id']
        assert image.getchannel('A').getextrema()==(0,255)
        assert entry['collision'] is False
        total_bytes+=128*128*4
    for effect in effects['effects']:
        image=Image.open(ROOT/effect['texture'].removeprefix('res://')).convert('RGBA')
        assert max(image.size)<=4096
        max_dimension=max(max_dimension,*image.size)
        total_bytes+=image.width*image.height*4
        if effect.get('frames'):
            width,height=effect['frame_size'];columns=effect['columns'];count=effect['frame_count']
            assert image.size==(width*columns,height*math.ceil(count/columns))
            assert 6<=effect['fps']<=10
            frames=[image.crop((i%columns*width,i//columns*height,(i%columns+1)*width,(i//columns+1)*height)) for i in range(count)]
            assert any(frame.getchannel('A').getextrema()[1]>0 for frame in frames)
            if effect['id']=='darkness':
                assert all(f.crop((192,108,448,252)).getchannel('A').getextrema()==(0,0) for f in frames)
            if effect['id'].startswith('eyes'):
                assert frames[0].getchannel('A').getextrema()==(0,0)
                assert frames[-1].getchannel('A').getextrema()==(0,0)
                assert frames[5].getchannel('A').getextrema()==(0,0)
            if effect['id'] in ('shadow','drip'):
                assert frames[0].getchannel('A').getextrema()==(0,0)
                assert frames[-1].getchannel('A').getextrema()==(0,0),effect['id']
        if effect['id']=='fog-strip':
            assert list(image.crop((0,0,1,64)).get_flattened_data())==list(image.crop((255,0,256,64)).get_flattened_data())
    # Registered timber components must reconstruct the authored full frame.
    assembled=Image.new('RGBA',(128,128))
    for name in ('mine-post-left','mine-post-right','mine-crossbeam'):
        assembled.alpha_composite(Image.open(ROOT/'art/dressing/cave-v1'/f'{name}.png').convert('RGBA'))
    full=Image.new('RGBA',(128,128))
    full.alpha_composite(Image.open(ROOT/'art/dressing/cave-v1/mine-support.png').convert('RGBA'))
    assert assembled.tobytes()==full.tobytes()
    data={'sources':len(sources['assets']),'dressing_assets':len(dressing['assets']),'effects':len(effects['effects']),
          'native_rgba_mib':round(total_bytes/1024**2,3),'max_atlas_dimension':max_dimension,'failures':[],
          'scope':'Art library and isolated previews; no live floor placement or ambient controller.'}
    (REVIEW/'export-validation.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    html=HTML.replace('ASSET_JSON',json.dumps(dressing['assets'])).replace('EFFECT_JSON',json.dumps(effects['effects']))
    (REVIEW/'inspector.html').write_text(html,encoding='utf-8')
    print(json.dumps(data))


HTML=r'''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Depths | Cave art inspector</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#111715;color:#e6dac1;font:16px system-ui;height:100svh;display:flex;flex-direction:column}
header{display:flex;gap:12px;flex-wrap:wrap;align-items:center;padding:12px 18px;border-bottom:1px solid #575548}h1{font-size:19px;margin:0 auto 0 0}
button,select{color:inherit;background:#292d24;border:1px solid #786a4b;border-radius:3px;min-height:44px;padding:8px 12px;font:inherit;cursor:pointer}
label{display:flex;align-items:center;gap:8px}input{accent-color:#c5a66b}main{display:flex;flex:1;min-height:0;align-items:center;justify-content:center;padding:8px}
canvas{width:min(100%,calc((100svh - 155px)*1.7777));height:auto;image-rendering:pixelated;max-height:100%;background:#141b18}
footer{min-height:52px;padding:8px 18px;display:flex;gap:16px;align-items:center;flex-wrap:wrap;color:#adb4a7}#description{font-size:14px}button:focus-visible,select:focus-visible{outline:2px solid #f4d894}
@media(max-height:650px){header{padding:5px 12px;gap:6px}h1{font-size:16px}canvas{width:min(100%,calc((100svh - 125px)*1.7777))}footer{padding:4px 12px;min-height:38px}}
</style>
<header><h1>Depths | Cave art</h1><label>View <select id="asset"></select></label><button id="play">Pause</button><button id="step">Step frame</button><label>Strength <input id="strength" type="range" min="0" max="1" value="0.65" step=".05"></label></header>
<main><canvas id="view" width="640" height="360"></canvas></main>
<footer><span id="frame"></span><span id="description"></span><label>Zoom <select id="zoom"><option value="1">Native</option><option value="2" selected>2×</option><option value="4">4×</option></select></label></footer>
<script>
const dressing=ASSET_JSON,effects=EFFECT_JSON,canvas=document.querySelector('canvas'),ctx=canvas.getContext('2d');
const select=document.querySelector('#asset'),play=document.querySelector('#play'),step=document.querySelector('#step'),strength=document.querySelector('#strength'),zoom=document.querySelector('#zoom');
const items=[...effects.map(e=>({...e,kind:'effect'})),...dressing.map(e=>({...e,kind:'dressing'}))],cache=new Map();let running=true,tick=0,elapsed=0,last=performance.now();
const path=s=>s.replace('res://art/','../../');
function get(src){if(!cache.has(src)){const image=new Image();image.src=src;cache.set(src,image)}return cache.get(src)}
for(const kind of ['effect','dressing']){const group=document.createElement('optgroup');group.label=kind==='effect'?'Ambient animation':'Dressing';for(const item of items.filter(e=>e.kind===kind)){const o=document.createElement('option');o.value=item.id;o.textContent=item.id.replaceAll('-',' ');group.append(o)}select.append(group)}
select.value='darkness';select.addEventListener('change',()=>{tick=0;elapsed=0});
play.addEventListener('click',()=>{running=!running;elapsed=tick/(items.find(e=>e.id===select.value).fps||8)*1000;play.textContent=running?'Pause':'Play'});
step.addEventListener('click',()=>{running=false;play.textContent='Play';tick++;elapsed=tick/(items.find(e=>e.id===select.value).fps||8)*1000;draw()});
function draw(){const item=items.find(e=>e.id===select.value),image=get(path(item.texture));ctx.imageSmoothingEnabled=false;ctx.globalAlpha=1;ctx.globalCompositeOperation='source-over';ctx.fillStyle='#101612';ctx.fillRect(0,0,640,360);const bg=get('damp-cave-desktop.png');if(bg.complete&&bg.naturalWidth)ctx.drawImage(bg,0,0,640,360);
 const k=Number(zoom.value),gain=Number(strength.value);let frame=0;
 if(image.complete&&image.naturalWidth){if(item.kind==='dressing'){ctx.fillStyle='#1e2723';ctx.fillRect(230,55,180,230);ctx.drawImage(image,320-64*k,180-64*k,128*k,128*k)}
 else if(item.id==='fog-strip'){ctx.globalAlpha=gain;const shift=Math.floor(tick*.32)%256;for(let x=-256;x<900;x+=256)ctx.drawImage(image,x+shift,265,256,64)}
 else if(item.frame_count){frame=tick%item.frame_count;const[w,h]=item.frame_size,sx=(frame%item.columns)*w,sy=Math.floor(frame/item.columns)*h;ctx.globalAlpha=gain;
  if(item.id==='darkness')ctx.drawImage(image,sx,sy,w,h,0,0,640,360);
  else if(item.id==='wall-flame'){const base=get('../../dressing/cave-v1/goblin-torch-base.png');ctx.globalAlpha=1;if(base.complete)ctx.drawImage(base,256,152,128,128);ctx.globalAlpha=gain;ctx.drawImage(image,sx,sy,w,h,320-16*.821,166-61*.821,w*.821,h*.821)}
  else{if(item.id==='fungus-pulse'){const base=get('../../dressing/cave-v1/wall-fungus.png');ctx.globalAlpha=1;if(base.complete)ctx.drawImage(base,320-w*k/2,180-h*k/2,w*k,h*k);ctx.globalAlpha=gain}
   if(item.blend==='additive')ctx.globalCompositeOperation='lighter';ctx.drawImage(image,sx,sy,w,h,320-w*k/2,180-h*k/2,w*k,h*k)}
 }else{ctx.globalAlpha=gain;ctx.drawImage(image,320-image.width*k/2,250-image.height*k/2,image.width*k,image.height*k)}}
 ctx.globalAlpha=1;ctx.globalCompositeOperation='source-over';document.querySelector('#frame').textContent=item.frame_count?`Frame ${frame+1} / ${item.frame_count}`:'Static texture';document.querySelector('#description').textContent=item.kind==='dressing'?`${item.mount} · ${item.metres.toFixed(2)}m`:item.id==='darkness'?'Strong loop; fade for hint or medium. Centre stays clear.':item.id.startsWith('eyes')?'Atmosphere only. No connection to encounters.':`${item.blend||'alpha'} · ${item.fps||'scroll'}${item.fps?' fps':''}`;
 window.reviewState={id:item.id,frame,running,count:item.frame_count||1};}
function animate(now){const delta=now-last;last=now;if(running){elapsed+=delta;const item=items.find(e=>e.id===select.value);tick=Math.floor(elapsed/1000*(item.fps||8))}draw();requestAnimationFrame(animate)}requestAnimationFrame(animate);
</script></html>'''


if __name__=='__main__':main()
