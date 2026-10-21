"""Build the offline #132 art review from the exported catalogue."""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]
cat=json.loads((ROOT/'art/dressing/landmarks-v1/catalog.json').read_text())
html=r'''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Depths · landmark art</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#161c18;color:#e5d9bf;font:16px/1.45 system-ui,sans-serif}main{max-width:1440px;margin:auto;padding:24px}h1{font:600 27px Georgia,serif;margin:0 0 6px}h2{font:600 20px Georgia,serif;margin:0 0 12px}p{margin:8px 0 16px;color:#b9bba9}a{color:#dcc085}button,select{font:inherit;color:inherit;background:#2c362e;border:1px solid #68725f;border-radius:4px;min-height:44px;padding:8px 12px;cursor:pointer}button[aria-pressed=true]{border-color:#d8b66f;background:#414b37}button:focus-visible,a:focus-visible,select:focus-visible{outline:3px solid #e0c180;outline-offset:3px}label{display:inline-flex;align-items:center;gap:8px;min-height:44px}input{width:22px;height:22px;accent-color:#c2a367}.toolbar{display:flex;gap:8px;flex-wrap:wrap;align-items:center}.panels{display:grid;grid-template-columns:minmax(280px,400px) minmax(0,1fr);gap:20px;margin:18px 0}.panel{border:1px solid #475243;background:#202823;padding:16px;min-width:0}.stage{display:grid;place-items:center;background:#293229;min-height:320px}canvas{image-rendering:pixelated;display:block;width:min(100%,384px);height:auto}.meta{font-size:14px;color:#c0c3b2;min-height:42px}.room{display:block;width:100%;height:auto;border:1px solid #475243;margin-top:12px}.library{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:8px}.library button{display:flex;flex-direction:column;align-items:center;padding:6px;font-size:13px;overflow-wrap:anywhere}.library img{width:96px;height:96px;image-rendering:pixelated}.glyphs{background:#d6c3a1;color:#362b20;padding:16px;display:flex;gap:24px;flex-wrap:wrap;align-items:center}.glyphs span{display:grid;gap:8px;justify-items:center;font-size:13px}.glyphs img{image-rendering:auto}.footer{font-size:14px;margin-top:20px}.small{font-size:14px}@media(max-width:850px){main{padding:16px}.panels{grid-template-columns:1fr}.stage{min-height:280px}canvas{width:280px}.library{grid-template-columns:repeat(auto-fit,minmax(112px,1fr))}}
</style>
<main>
<h1>Landmarks in the mine</h1>
<p>Roots and a buried royal cache for the cave; a miners’ shrine with a spent state. Select a piece to inspect its native pixels.</p>
<div class="panels">
 <section class="panel"><h2 id="asset-title">Shrine offerings</h2><div class="stage"><canvas id="art" width="128" height="128" aria-label="Native asset preview"></canvas></div><p class="meta" id="meta"></p>
 <div class="toolbar" id="state-controls"><button id="fresh" aria-pressed="true">Fresh</button><button id="used" aria-pressed="false">Resolved</button></div>
 <div class="toolbar" id="glow-controls"><label><input type="checkbox" id="glow" checked>Candle glow</label><button id="pause">Pause</button><button id="step">Step frame</button><span id="frame" class="small"></span></div>
 </section>
 <section class="panel"><h2>Mounted in the cave</h2><div class="toolbar"><label for="room">View</label><select id="room"><option value="roots">Roots</option><option value="cache">Collapsed cache</option><option value="shrine-fresh" selected>Shrine · fresh</option><option value="shrine-used">Shrine · resolved</option><option value="shrine-glow-off">Shrine · glow off</option><option value="map">Map and discoveries</option></select><select id="shape" aria-label="Screen shape"><option value="phone">Phone shape</option><option value="desktop">Desktop shape</option></select></div><img id="room-image" class="room" src="shrine-fresh-phone.png" alt="Shrine mounted in the cave at phone size"><p class="small">Actual Godot 4.7.2 captures from an isolated room. The scene scale uses 2 m cells and 2.4 m walls. These new scenery sets await live placement.</p></section>
</div>
<h2>All fourteen pieces</h2><div class="library" id="library"></div>
<h2 style="margin-top:24px">Known-place map mark</h2><p>The cairn replaces the diamond on the corner map, full map and Discoveries list.</p><div class="glyphs" id="glyphs"></div>
<p class="footer"><a href="overview.png">Overview</a> · <a href="../../../docs/landmark-art.md">Integration notes</a> · <a href="../../source/landmarks-v1/generation.json">Original prompts and source hashes</a></p>
</main>
<script>
const catalogue=__CATALOGUE__;
const base='../../dressing/landmarks-v1/';
const names=id=>id.split('-').map(w=>w[0].toUpperCase()+w.slice(1)).join(' ');
const images=new Map();
let selected='shrine-offerings', paused=false, glow=true, frame=0, last=0;
const ctx=document.querySelector('#art').getContext('2d');ctx.imageSmoothingEnabled=false;
function bitmap(id){if(!images.has(id)){const im=new Image();im.src=base+id+'.png';im.onload=draw;images.set(id,im)}return images.get(id)}
function draw(){ctx.clearRect(0,0,128,128);const im=bitmap(selected);if(im.complete&&im.naturalWidth)ctx.drawImage(im,0,0);if(selected==='fallen-banner'){const seal=bitmap('banner-seal');if(seal.complete&&seal.naturalWidth)ctx.drawImage(seal,0,0)}if(selected==='shrine-offerings'&&glow){const light=bitmap('shrine-candle-glow');if(light.complete&&light.naturalWidth)ctx.drawImage(light,frame*128,0,128,128,0,0,128,128)}document.querySelector('#frame').textContent='Frame '+(frame+1)+' / 2';}
function select(id){selected=id;const asset=catalogue.assets.find(a=>a.id===id);document.querySelector('#asset-title').textContent=names(id);document.querySelector('#meta').textContent=`128 × 128 · ${asset.mount} · ${asset.metres} m ${asset.measured_axis} · floors ${asset.floors.join('–')}`;document.querySelector('#state-controls').hidden=!asset.state_family;document.querySelector('#glow-controls').hidden=!id.startsWith('shrine-offerings');document.querySelector('#fresh').setAttribute('aria-pressed',String(!id.endsWith('-used')));document.querySelector('#used').setAttribute('aria-pressed',String(id.endsWith('-used')));document.querySelectorAll('[data-asset]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.asset===id)));draw();}
for(const a of catalogue.assets){const b=document.createElement('button');b.dataset.asset=a.id;b.setAttribute('aria-pressed',String(a.id===selected));const im=document.createElement('img');im.src=base+a.id+'.png';im.alt='';b.append(im,document.createTextNode(names(a.id)));b.onclick=()=>select(a.id);document.querySelector('#library').append(b);}
for(const px of [10,16,20,32]){const s=document.createElement('span');const im=document.createElement('img');im.src='../../ui/backlog96-v1/map/landmark.png';im.width=im.height=px;im.alt='Known-place cairn';s.append(im,document.createTextNode(px+' px'));document.querySelector('#glyphs').append(s);}
document.querySelector('#fresh').onclick=()=>select(selected.replace(/-used$/,''));
document.querySelector('#used').onclick=()=>select(selected.replace(/-used$/,'')+'-used');
document.querySelector('#glow').onchange=e=>{glow=e.target.checked;draw()};
document.querySelector('#pause').onclick=()=>{paused=!paused;document.querySelector('#pause').textContent=paused?'Play':'Pause'};
document.querySelector('#step').onclick=()=>{paused=true;document.querySelector('#pause').textContent='Play';frame=1-frame;draw()};
function room(){const id=document.querySelector('#room').value,shape=document.querySelector('#shape').value,im=document.querySelector('#room-image');im.src=id+'-'+shape+'.png';im.alt=names(id)+' mounted review · '+shape;}
document.querySelector('#room').onchange=room;document.querySelector('#shape').onchange=room;
function tick(now){if(!paused&&now-last>=500){frame=1-frame;last=now;draw()}requestAnimationFrame(tick)}
select(selected);requestAnimationFrame(tick);
</script></html>'''
# hidden must override toolbar flex, otherwise a hidden native control stays visible.
html=html.replace('*{box-sizing:border-box}','[hidden]{display:none!important}*{box-sizing:border-box}')
html=html.replace('__CATALOGUE__',json.dumps(cat,separators=(',',':')))
(ROOT/'art/concepts/landmarks-v1/inspector.html').write_text(html,encoding='utf-8',newline='\n')
print('LANDMARK_INSPECTOR: offline native/state/frame and mounted-room review')
