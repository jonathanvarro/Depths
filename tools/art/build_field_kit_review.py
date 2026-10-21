"""Offline #138 native-size/greyscale review and reproducible symbol sheet."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/concepts/field-kit-v1'
cat=json.loads((ROOT/'art/items/field-kit-v1/catalog.json').read_text())
font=ImageFont.truetype(str(next((ROOT/'art/fonts/source-sans-3').glob('*.ttf'))),17)
board=Image.new('RGB',(1000,580),'#1b2420');d=ImageDraw.Draw(board)
for i,e in enumerate(cat['symbols']):
 x=i%4*250;y=i//4*190;im=Image.open(ROOT/e['icon'].removeprefix('res://')).convert('RGBA')
 big=im.resize((96,96),Image.Resampling.NEAREST);board.paste(big,(x+8,y+8),big);board.paste(im,(x+122,y+22),im)
 tiny=im.resize((14,14),Image.Resampling.NEAREST);board.paste(tiny,(x+178,y+30),tiny)
 grey=ImageOps.grayscale(tiny).convert('RGBA');grey.putalpha(tiny.getchannel('A'));board.paste(grey,(x+210,y+30),grey)
 d.text((x+10,y+116),e['name'],font=font,fill='#e6dac1');d.text((x+10,y+142),'96 / 32 / 14 / grey 14 px',font=font,fill='#aeb5a4')
board.save(OUT/'symbol-overview.png')
html=r'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Depths · field kit and conditions</title>
<style>
*{box-sizing:border-box}[hidden]{display:none!important}body{margin:0;background:#171e1a;color:#e6dac1;font:16px/1.5 system-ui,sans-serif;--bg:#222d24;--ink:#e6dac1}main{max-width:1440px;margin:auto;padding:24px}h1{font:600 28px Georgia,serif;margin:0 0 8px}h2{font:600 21px Georgia,serif;margin:24px 0 12px}p{color:#bfc1ae}button,select{font:inherit;min-height:44px;padding:8px 12px;background:#2b362d;color:#e6dac1;border:1px solid #6c7861;border-radius:4px;cursor:pointer}button[aria-pressed=true]{border-color:#dfc085;background:#465139}button:focus-visible,a:focus-visible,select:focus-visible{outline:3px solid #dfc085;outline-offset:3px}.toolbar{display:flex;flex-wrap:wrap;gap:10px;align-items:center}label{display:inline-flex;gap:8px;min-height:44px;align-items:center}input{width:22px;height:22px;accent-color:#d5b474}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(245px,1fr));gap:12px;margin-top:16px}.asset{background:var(--bg);color:var(--ink);border:1px solid #52604d;padding:16px;min-width:0}.samples{display:flex;align-items:center;justify-content:space-around;gap:12px;min-height:144px}.samples img{image-rendering:pixelated;max-width:100%;object-fit:contain}.asset h3{font-size:16px;margin:8px 0}.asset p{font-size:14px;color:inherit;opacity:.8;margin:4px 0}.effects .samples{min-height:112px}.greyscale .samples img{filter:grayscale(1)}.paper{--bg:#d6c3a1;--ink:#302b23}.capture{display:block;width:100%;height:auto;border:1px solid #52604d;margin-top:16px}a{color:#dfc085}.hint{font-size:14px}.footer{margin-top:24px;font-size:14px}@media(max-width:650px){main{padding:16px}.grid{grid-template-columns:1fr}.samples{min-height:140px}}
</style>
<main><h1>The field kit and its consequences</h1><p>Eight new item illustrations and eleven distinct effect symbols. These are connected to the current inventory resources and hero cards.</p>
<div class="toolbar"><button id="inventory" aria-pressed="true">Inventory</button><button id="effects" aria-pressed="false">Boons and banes</button><label><input type="checkbox" id="grey">Greyscale</label><label><input type="checkbox" id="paper">Parchment background</label></div>
<section id="items"><p class="hint">Each item: 128 px source export, direct-source 64 px compact export, then 40 px display.</p><div class="grid" id="item-grid"></div></section>
<section id="symbols" class="effects" hidden><p class="hint">Each symbol: enlarged 96 px, native 32 px and actual 14 px card size. Round corner mark for boons; downward triangle for banes. Shape carries the specific identity.</p><div class="grid" id="symbol-grid"></div></section>
<h2>Actual game controls</h2><div class="toolbar"><label for="capture">Review</label><select id="capture"><option value="pack-leather-satchel">Pack · bags</option><option value="pack-oilcloth-cloak">Pack · cloak and cape</option><option value="pack-miners-pick">Pack · tools</option><option value="pack-antidote">Pack · treatments</option><option value="party-symbols">Party cards · all effects</option></select><select id="shape" aria-label="Screen shape"><option value="phone">Phone dimensions</option><option value="desktop">Desktop dimensions</option></select></div><img class="capture" id="capture-image" src="pack-leather-satchel-phone.png" alt="Actual Pack at phone dimensions"><p class="hint">Godot 4.7.2 Mobile renderer, isolated Pack/PartyCard fixtures. Phone-size Windows renders; physical iPhone readability remains to be checked.</p>
<p class="footer"><a href="inventory-overview.png">Inventory sheet</a> · <a href="symbol-overview.png">Symbol sheet</a> · <a href="../../../docs/field-kit-art.md">Handoff</a> · <a href="../../source/field-kit-v1/generation.json">Original ImageGen prompts and sources</a></p></main>
<script>
const data=__CATALOGUE__;
function add(entry,grid,effect){const card=document.createElement('article');card.className='asset';const samples=document.createElement('div');samples.className='samples';for(const size of effect?[96,32,14]:[128,64,40]){const im=new Image();im.src='../../../'+(size===64&&!effect?entry.compact_icon:entry.icon).replace('res://','');im.width=im.height=size;im.alt=entry.name+' at '+size+' pixels';samples.append(im)}const title=document.createElement('h3');title.textContent=entry.name;const text=document.createElement('p');text.textContent=entry.design;card.append(samples,title,text);document.querySelector(grid).append(card)}
data.items.forEach(e=>add(e,'#item-grid',false));data.symbols.forEach(e=>add(e,'#symbol-grid',true));
for(const id of ['inventory','effects'])document.querySelector('#'+id).onclick=()=>{document.querySelector('#items').hidden=id!=='inventory';document.querySelector('#symbols').hidden=id!=='effects';for(const b of ['inventory','effects'])document.querySelector('#'+b).setAttribute('aria-pressed',String(b===id))};
document.querySelector('#grey').onchange=e=>document.body.classList.toggle('greyscale',e.target.checked);document.querySelector('#paper').onchange=e=>document.body.classList.toggle('paper',e.target.checked);
function show(){const im=document.querySelector('#capture-image'),id=document.querySelector('#capture').value,shape=document.querySelector('#shape').value;im.src=id+'-'+shape+'.png';im.alt=id+' · '+shape}document.querySelector('#capture').onchange=show;document.querySelector('#shape').onchange=show;
</script></html>'''
html=html.replace('__CATALOGUE__',json.dumps(cat,separators=(',',':')))
(OUT/'inspector.html').write_text(html,encoding='utf-8',newline='\n')
print('FIELD_KIT_REVIEW: native item/effect, greyscale and actual-control gallery')
