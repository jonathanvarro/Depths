(()=>{
 const root=document.getElementById('depths-pack-heroes'),$=s=>root.querySelector(s),$$=s=>[...root.querySelectorAll(s)];
 const items=KIT_DATA.items,heroes=KIT_DATA.heroes;
 const stock=['oil_flask','ration','restorative_draught','dressing','plain_knife','wooden_club','simple_spear','padded_coat','gold_signet_ring','copper_ore'];
 const loadouts=[{weapon:'broken_knife'},{weapon:'broken_short_sword'},{weapon:'cracked_staff'}];
 const counts={oil_flask:3,ration:2,restorative_draught:1,dressing:2,gold_signet_ring:1,copper_ore:2};
 let hero=0,tab='equipment',bagPage=0,active=null,timer,restoreFocus=false;
 function clear(focus=false){clearTimeout(timer);const prior=active?.trigger;active=null;$('.inspect').hidden=true;$$('.equip-cell').forEach(e=>e.classList.remove('receives'));$$('[aria-expanded]').forEach(e=>e.setAttribute('aria-expanded','false'));if(focus&&prior?.isConnected){restoreFocus=true;prior.focus();restoreFocus=false;}}
 function slot(id,context,label){
  const b=document.createElement('button');b.className='slot'+(!id?' empty':'');b.type='button';b.setAttribute('aria-label',id?items[id].display_name:label||'Empty compartment');
  if(!id){b.disabled=true;const outline=label?.includes('weapon')?'M11 38 30 8 37 12 18 42Z M9 30 25 40 M10 42 17 32':'M16 7 6 13 10 24 16 21 16 41 32 41 32 21 38 24 42 13 32 7 29 12 19 12Z';b.innerHTML=context==='equipped'?`<svg class="slot-mark" viewBox="0 0 48 48" aria-hidden="true"><path d="${outline}" fill="none" stroke="currentColor" stroke-width="2"/></svg>`:'<span class="empty-mark" aria-hidden="true">·</span>';return b;}
  b.dataset.item=id;b.dataset.context=context;b.setAttribute('aria-haspopup','dialog');b.setAttribute('aria-expanded','false');
  const image=document.createElement('img');image.src=items[id].art;image.alt='';image.className='item-art';b.append(image);
  if(counts[id]!=null){const n=document.createElement('span');n.className='qty number';n.textContent='×'+counts[id];b.append(n);}
  b.addEventListener('pointerenter',e=>{if(e.pointerType!=='touch'&&!active?.pinned)inspect(b,false);});
  b.addEventListener('pointerleave',()=>{if(!active?.pinned)timer=setTimeout(()=>clear(),180);});
  b.addEventListener('focus',()=>{if(!restoreFocus&&!active?.pinned)inspect(b,false);});
  b.addEventListener('click',()=>{inspect(b,true);($('.inspect .primary').disabled?$('.inspect .close'):$('.inspect .primary')).focus();});return b;
 }
 function render(){
  const nav=$('.party');nav.replaceChildren();heroes.forEach((h,i)=>{const b=document.createElement('button');b.type='button';b.className='portrait-button';b.dataset.hero=i;b.setAttribute('aria-label','Inspect '+h.display_name);b.setAttribute('aria-pressed',String(i===hero));const img=document.createElement('img');img.src=h.art;img.alt='';const name=document.createElement('span');name.textContent=h.short_name;b.append(img,name);b.onclick=()=>{clear();hero=i;render();restoreFocus=true;$(`[data-hero="${i}"]`).focus();restoreFocus=false;};nav.append(b);});
  const h=heroes[hero];$('.hero-role').textContent=h.role;
  $('.quick-condition').textContent=h.health+' / '+h.max_health;
  $('#depths-equipment').hidden=tab!=='equipment';$('#depths-status').hidden=tab!=='status';
  for(const t of ['equipment','status'])$('#depths-'+t+'-tab').setAttribute('aria-selected',String(t===tab));
  const grid=$('.equipment');grid.replaceChildren();for(const [key,label] of [['weapon','Weapon'],['body','Body']]){const cell=document.createElement('div');cell.className='equip-cell';cell.dataset.role=key;const b=slot(loadouts[hero][key],'equipped','Empty '+label.toLowerCase()+' slot');b.title=label;cell.append(b);grid.append(cell);}
  const bag=$('.bag'),carried=stock.filter(k=>!loadouts.some(o=>Object.values(o).includes(k))),pages=Math.ceil(carried.length/12);bagPage=Math.min(bagPage,pages-1);bag.replaceChildren();carried.slice(bagPage*12,(bagPage+1)*12).forEach(k=>bag.append(slot(k,'bag')));while(bag.children.length<12)bag.append(slot(null,'bag'));$('.bag-pages').hidden=pages<=1;$('.pack-page').classList.toggle('has-pages',pages>1);$('.page-count').textContent=`${bagPage+1} / ${pages}`;$('.previous').disabled=bagPage===0;$('.next').disabled=bagPage===pages-1;
  const status=$('#depths-status');status.replaceChildren();for(const [title,text] of [['Condition',`Health ${h.health} / ${h.max_health} · Strain ${h.strain||0}`],[h.trait_name,h.trait_text],['Character',h.personality],['Burden',h.vulnerability]]){const s=document.createElement('section');s.className='status-section';const heading=document.createElement('h3');heading.textContent=title;const p=document.createElement('p');p.textContent=text;s.append(heading,p);status.append(s);}
 }
 function inspect(trigger,pinned){
  clearTimeout(timer);const id=trigger.dataset.item,i=items[id];if(active?.trigger!==trigger)clear();active={id,context:trigger.dataset.context,trigger,pinned};trigger.setAttribute('aria-expanded','true');
  $('.inspect-head img').src=i.art;$('#depths-inspect-title').textContent=i.display_name;$('.inspect-type').textContent=i.kind==='gear'?(i.slot==='body'?'Body':'Weapon'):(i.effect===5?'Valuable':'Supply');$('#depths-inspect-description').textContent=i.description;
  const key=i.slot==='body'?'body':'weapon',current=loadouts[hero][key],button=$('.inspect .primary');button.disabled=false;
  if(i.kind==='gear'){
   $('.inspect-extra').textContent=(i.slot==='body'?`Armour ${i.armour||0}`:`Damage ${i.attack_min||1}–${i.attack_max||2}`)+' · '+heroes[hero].short_name+(active.context==='bag'&&current?' · Replaces '+items[current].display_name:'');
   button.textContent=active.context==='equipped'?'Unequip':'Equip';$$('.equip-cell').forEach(e=>e.classList.toggle('receives',active.context==='bag'&&e.dataset.role===key));
  }else{
   $('.inspect-extra').textContent=i.effect===5?'Sell at the merchant':id==='dressing'?'No untreated injury in this party':'';
   button.disabled=i.effect===5||id==='dressing'||counts[id]===0;button.textContent=i.effect===5?'Sell at camp':id==='dressing'?'No injury to bind':counts[id]===0?'None left':`Use · ${i.use_time||1} time`;
  }
  $('.inspect').dataset.pinned=String(pinned);$('.inspect').hidden=false;
 }
 $('.inspect').onpointerenter=()=>clearTimeout(timer);$('.inspect').onpointerleave=()=>{if(!active?.pinned)timer=setTimeout(()=>clear(),180);};$('.inspect .close').onclick=()=>clear(true);
 $('.inspect .primary').onclick=()=>{
  if(!active||$('.inspect .primary').disabled)return;const {id,context}=active,i=items[id],key=i.slot==='body'?'body':'weapon';
  if(i.kind==='gear'){const previous=loadouts[hero][key];if(previous&&!stock.includes(previous))stock.push(previous);if(context==='equipped')delete loadouts[hero][key];else loadouts[hero][key]=id;$('.feedback').textContent=i.display_name+(context==='equipped'?' returned to the pack.':' equipped.');}
  else{counts[id]--;$('.feedback').textContent=i.display_name+' used.';}
  clear();render();restoreFocus=true;($(`[data-item="${id}"]`)||$('.back')).focus();restoreFocus=false;
 };
 function change(t){clear();tab=t;render();}
 for(const t of ['equipment','status'])$('#depths-'+t+'-tab').onclick=()=>change(t);
 $('.previous').onclick=()=>{clear();bagPage--;render();};$('.next').onclick=()=>{clear();bagPage++;render();};
 $('.tabs').onkeydown=e=>{if(['ArrowLeft','ArrowRight'].includes(e.key)){e.preventDefault();change(e.target.id==='depths-equipment-tab'?'status':'equipment');$('#depths-'+tab+'-tab').focus();}};
 $('.back').onclick=()=>{clear();$('.window').hidden=true;$('.launcher').hidden=false;$('[data-open]').focus();};
 $('[data-open]').onclick=()=>{$('.window').hidden=false;$('.launcher').hidden=true;tab='equipment';render();$('.back').focus();};
 root.onkeydown=e=>{if(e.key==='Escape'){e.preventDefault();active?clear(true):$('.back').click();}};
 root.onpointerdown=e=>{if(active&&!$('.inspect').contains(e.target)&&!active.trigger.contains(e.target))clear();};
 render();
})();
