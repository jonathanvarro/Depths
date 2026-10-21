"""Offline review, using final pixels and actual Godot captures for #139."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/descent-finish-v1'
surfaces=json.loads((ROOT/'art/textures/descent-surfaces-v1/catalog.json').read_text())
dressing=json.loads((ROOT/'art/dressing/cave-v2/catalog.json').read_text())
html=r'''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Depths · Cave surfaces and traces</title>
<style>
:root{color-scheme:dark;font:16px/1.5 system-ui,sans-serif;background:#131916;color:#e6ddc9}*{box-sizing:border-box}body{margin:0}main{max-width:1160px;margin:auto;padding:28px 24px 60px}h1{font:500 clamp(26px,5vw,40px)/1.15 Georgia,serif;margin:12px 0}h2{font:500 25px Georgia,serif}p{color:#b9bdae;max-width:78ch}a{color:#dfc99b}header small{letter-spacing:.16em;color:#a6ac93}.controls{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin:20px 0}button,select{font:inherit;border:1px solid #67715f;background:#242d25;color:inherit;border-radius:3px;min-height:44px;padding:9px 15px;cursor:pointer}button[aria-pressed=true],button[aria-selected=true]{border-color:#dbbd80;background:#3e4430}button:focus-visible,select:focus-visible{outline:2px solid #efd59e;outline-offset:3px}label{display:flex;gap:9px;align-items:center;flex-wrap:wrap}select{max-width:100%}[hidden]{display:none!important}.shot{display:block;width:100%;height:auto;border:1px solid #59614e;background:#080b09;image-rendering:pixelated}.tiles{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px;margin:20px 0}.tile{padding:12px;border:1px solid #3a4538;background:#1c241e;min-width:0}.tile img{display:block;width:128px;max-width:100%;image-rendering:pixelated;margin:10px auto}.repeat{height:192px;background-repeat:repeat;background-size:128px;image-rendering:pixelated;border:1px solid #46513e}.tile span,figcaption{color:#aab39f;font-size:14px}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(176px,1fr));gap:12px}.card{border:1px solid #3a4538;background:#1c241e;padding:14px;min-width:0}.card canvas{display:block;width:128px;height:128px;image-rendering:pixelated;margin:0 auto 10px;background:repeating-conic-gradient(#242e25 0 25%,#202922 0 50%) 50%/16px 16px}.card b{font-size:15px;display:block}.card small{color:#abb29e;display:block}.note{border-left:2px solid #a09369;padding-left:14px}footer{border-top:1px solid #414a3a;margin-top:30px;padding-top:20px;font-size:14px;color:#b8beaa}figure{margin:0}output{font-variant-numeric:tabular-nums;min-width:90px}#error{color:#ffaf9d}
@media(max-width:620px){main{padding:18px 14px 40px}.tiles{gap:6px}.tile{padding:7px}.repeat{height:128px}.tile span{font-size:12px}.cards{grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}.card{padding:8px}.card b{font-size:13px}button,select{padding:9px 12px}.controls{gap:7px}.note{font-size:14px}}
</style>
<main><header><small>DEPTHS / ART LIBRARY 139</small><h1>Cave surfaces &amp; traces</h1><p>Six deeper wall families now have matching ground and ceilings. Small fittings, worn remains and quiet growth give each place traces of a past.</p></header>
<div class="controls" role="tablist" aria-label="Art library"><button role="tab" id="surface-tab" aria-selected="true" aria-controls="surfaces">Surfaces</button><button role="tab" id="dressing-tab" aria-selected="false" aria-controls="dressing">Dressing</button></div>
<section id="surfaces" role="tabpanel" aria-labelledby="surface-tab">
<div class="controls"><label>Family <select id="family"></select></label><label>Light / view <select id="light"><option value="lantern">Lantern</option><option value="neutral">Neutral</option><option value="phone-lantern">Phone · lantern</option></select></label></div>
<figure><img class="shot" id="surface-room" alt="Actual Godot cave room with the selected matching surfaces"><figcaption>Actual Godot Mobile rendering, using the existing cave geometry.</figcaption></figure>
<div class="tiles" id="tiles"></div>
<p class="note">Wall, floor and ceiling share the same 32-colour palette. Repeat previews use the native 128px tile. The current wall box UVs stretch the wall texture more than the floor planes; this existing geometry limit is visible above. Family names and later floor ranges remain art proposals.</p>
</section>
<section id="dressing" role="tabpanel" aria-labelledby="dressing-tab" hidden>
<div class="controls"><button id="glow" aria-pressed="true">Glow on</button><button id="play" aria-pressed="true">Pause</button><button id="step">Step frame</button><output id="frame">Frame 1 / 8</output></div>
<p>Moss and floor fungus have separate faint glow layers. Pause and step to check their alignment. The other drawings stay still.</p>
<div class="cards" id="cards"></div>
<h2>Mounted in the cave</h2>
<div class="controls"><label>Room <select id="room"><option value="mine-fittings">Mine fittings</option><option value="goblin-fixtures">Goblin fixtures</option><option value="drowned-details">Damp masonry</option><option value="fungal-details">Moss and fungus</option><option value="fungal-dark">Glow in darkness</option><option value="buried-details">Buried stonework</option><option value="sealed-details">Sealed chamber</option></select></label><label>Size <select id="size"><option value="desktop">Desktop</option><option value="phone">Phone</option></select></label></div>
<figure><img class="shot" id="dressing-room" alt="Actual Godot room showing the mounted dressing"><figcaption>Captured room views are stills. Neutral and glowing plants are shown together; glow adds no light source or party benefit.</figcaption></figure>
<p class="note">The roots and wall fungus already have libraries. The floor fungus retains its original drawing; the drip curtain combines new mineral crust with the existing drip animation. Scratch marks, inscriptions and the seal are provisional ornaments with no assigned story meaning.</p>
</section>
<p id="error" role="alert" hidden></p>
<footer><a href="../../../docs/descent-surfaces-and-dressing.md">Integration handoff</a> · <a href="../../source/descent-surfaces-v1/generation.json">Surface prompts</a> · <a href="../../source/cave-dressing-v2/generation.json">Dressing prompts</a><p>Library prepared for placement. Existing themes, wall files and gameplay are preserved. Phone views are desktop simulations; physical iPhone appearance remains to check.</p></footer>
</main>
<script>
const families=__SURFACES__.families,pieces=__DRESSING__.assets;
const $=id=>document.getElementById(id),url=p=>'../../../'+p.replace('res://',''),name=id=>id.replaceAll('-',' ').replace(/^./,c=>c.toUpperCase());
let frame=0,playing=true,glow=true,loaded=[];window.artReady=false;
const images=new Map();function load(src){if(images.has(src))return images.get(src);const p=new Promise((resolve,reject)=>{const i=new Image();i.onload=()=>resolve(i);i.onerror=()=>reject(Error('Missing image: '+src));i.src=src});images.set(src,p);return p}
families.forEach(f=>{const opt=document.createElement('option');opt.value=f.id;opt.textContent=name(f.id);$('family').append(opt)});
function surface(){const f=families.find(f=>f.id===$('family').value);$('surface-room').src=f.id+'-'+$('light').value+'.png';$('tiles').replaceChildren();for(const role of ['wall','floor','ceiling']){const tile=document.createElement('div');tile.className='tile';tile.innerHTML='<b>'+name(role)+'</b><img alt="'+name(f.id)+' '+role+' native tile" src="'+url(f[role+'_texture'])+'"><div class="repeat" role="img" aria-label="Repeated '+role+' tile"></div><span>128px · repeated</span>';tile.querySelector('.repeat').style.backgroundImage='url("'+url(f[role+'_texture'])+'")';$('tiles').append(tile)}}
function room(){$('dressing-room').src=$('room').value+'-'+$('size').value+'.png'}
function draw(){for(const [canvas,base,pulse] of loaded){const c=canvas.getContext('2d');c.imageSmoothingEnabled=false;c.clearRect(0,0,128,128);c.drawImage(base,0,0);if(glow&&pulse)c.drawImage(pulse,frame%4*128,Math.floor(frame/4)*128,128,128,0,0,128,128)}$('frame').textContent='Frame '+(frame+1)+' / 8';window.artState={frame,playing,glow}}
function tab(id){for(const part of ['surfaces','dressing'])$(part).hidden=part!==id;$('surface-tab').setAttribute('aria-selected',String(id==='surfaces'));$('dressing-tab').setAttribute('aria-selected',String(id==='dressing'))}
$('surface-tab').onclick=()=>tab('surfaces');$('dressing-tab').onclick=()=>tab('dressing');$('family').onchange=surface;$('light').onchange=surface;$('room').onchange=room;$('size').onchange=room;
$('play').onclick=()=>{playing=!playing;$('play').textContent=playing?'Pause':'Play';$('play').setAttribute('aria-pressed',String(playing));draw()};
$('step').onclick=()=>{playing=false;$('play').textContent='Play';$('play').setAttribute('aria-pressed','false');frame=(frame+1)%8;draw()};
$('glow').onclick=()=>{glow=!glow;$('glow').textContent=glow?'Glow on':'Glow off';$('glow').setAttribute('aria-pressed',String(glow));draw()};
surface();room();
window.artReadyPromise=Promise.all(pieces.map(async p=>{const card=document.createElement('article');card.className='card';card.dataset.id=p.id;card.innerHTML='<canvas width="128" height="128" role="img" aria-label="'+name(p.id)+'"></canvas><b>'+name(p.id)+'</b><small>'+p.mount.replaceAll('-',' ')+' · '+p.metres+' m '+p.measured_axis+'</small>'+(p.glow_frames?'<small>neutral + separate pulse</small>':'');$('cards').append(card);const base=await load(url(p.texture)),pulse=p.glow_frames?await load(url(p.glow_frames.replace('.tres','.png'))):null;loaded.push([card.querySelector('canvas'),base,pulse])})).then(()=>{draw();window.artReady=true}).catch(e=>{$('error').hidden=false;$('error').textContent=e.message;throw e});
setInterval(()=>{if(playing){frame=(frame+1)%8;draw()}},250);
</script></html>'''
html=html.replace('__SURFACES__',json.dumps(surfaces)).replace('__DRESSING__',json.dumps(dressing))
(OUT/'inspector.html').write_text(html,encoding='utf-8',newline='\n')
print('DESCENT_INSPECTOR: six material families, twenty drawings, registered pulse stepping and thirty-two room captures')
