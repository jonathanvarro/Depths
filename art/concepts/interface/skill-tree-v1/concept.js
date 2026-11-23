/* #268: presentation-only study. No save, live gameplay or spending API. */
const ART = '../../../';
const icons = {
  heart:'ui/visual105-v1/heart.png', guard:'ui/visual105-v1/guard.png',
  force:'ui/physical-kit-v1/weapon.svg', aim:'ui/expedition-v1/marks/eye.svg',
  critical:'ui/expedition-v1/journal/weak-to.svg', nerve:'ui/visual105-v1/nerves.png',
  spell:'items/prayers-v1/tome_light-64.png', heal:'ui/backlog96-v1/status/healing.png',
  grudge:'ui/expedition-v1/combat/tastes-blood.svg', hand:'ui/expedition-v1/marks/hand.svg',
  last:'ui/expedition-v1/marks/cross.svg', web:'ui/visual105-v1/webbed.png',
  lamp:'items/prayers-v1/votive_candle-64.png', moon:'ui/expedition-v1/marks/moon.svg',
};
const skill = (id,name,icon,rank,effect,flavour,unlock='Learned through deeds, manuals or camp training.') => ({id,name,icon,rank,max:4,effect,flavour,unlock});
const classes = {
  Melee:[
    [skill('health','Hardiness','heart',2,'Next rank: +2 maximum health.','A body made stubborn by hardship.'),skill('guard','Guard','guard',1,'Next rank: improve damage resisted while braced.','A good stance is worth another layer of iron.')],
    [skill('aim','Accuracy','aim',2,'Next rank: +2% chance to hit.','No strength wasted on an empty swing.'),skill('critical','Critical strike','critical',0,'First rank: +2% critical chance.','Learn where the armour gives.')],
    [skill('force','Force','force',1,'Next rank: a small increase to melee damage.','Make each blow count.'),skill('nerve','Resolve','nerve',0,'First rank: strain builds a little more slowly.','Keep breathing. Keep your footing.')],
  ],
  Scout:[
    [skill('health','Hardiness','heart',1,'Next rank: +2 maximum health.','Enough breath left for the way home.'),skill('guard','Footwork','guard',1,'Next rank: a small improvement to evasion.','Never stand where the blow will land.')],
    [skill('aim','Accuracy','aim',2,'Next rank: +2% chance to hit.','Find the line through the dark.'),skill('critical','Critical strike','critical',1,'Next rank: +2% critical chance.','One clean opening.')],
    [skill('force','Quick hands','hand',1,'Next rank: act a little sooner in combat.','Move before the moment passes.'),skill('nerve','Resolve','nerve',0,'First rank: strain builds a little more slowly.','A clear head reads the warning signs.')],
  ],
  Mage:[
    [skill('health','Hardiness','heart',1,'Next rank: +2 maximum health.','Frailty is not a virtue.'),skill('guard','Warding','guard',0,'First rank: improve protection while defending.','A brief shelter against the coming blow.')],
    [skill('aim','Focus','aim',2,'Next rank: a small improvement to spell reliability.','The words must hold when the hands shake.'),skill('critical','Potency','critical',1,'Next rank: a small improvement to spell effects.','More meaning in each spoken word.')],
    [skill('force','Spell reserve','spell',1,'Next rank: +1 spell use per expedition.','One prayer kept for the deepest dark.'),skill('nerve','Resolve','nerve',2,'Next rank: strain builds a little more slowly.','Steadiness can be practised.')],
  ],
};
const trait = (id,name,icon,state,effect,flavour,unlock,existing=false)=>({id,name,icon,state,effect,flavour,unlock,existing,personal:true});
const heroes = [
  {id:'corin',name:'Corin',role:'Melee',portrait:'portraits/main-heroes-v1/corin/preview.png',traits:[
    trait('grudge','Grudge','grudge','Known','+1 damage against goblins.','He remembers every face that did not come back.','Part of his nature. Always active.',true),
    trait('answer','Vanguard’s answer','force','Story locked','After an ally takes a heavy blow, his next strike against that attacker gains force.','You hit them. Now look at me.','Explore his memories of the lost vanguard.'),
    trait('debt','Blood debt','last','Story locked','While badly hurt, striking a foe can steady his nerves. The benefit is personal; it does not calm the party.','Pain gives his anger a direction.','Resolve a later chapter of his personal story.'),
  ]},
  {id:'branna',name:'Branna',role:'Melee',portrait:'portraits/named-cast-v1/branna.png',traits:[
    trait('anchor','The anchor','guard','Known','When she braces, the ally behind her takes less damage from the next incoming blow.','Someone has to stay where the roof is falling.','A proposed starting trait, rooted in her rescue work.'),
    trait('notlost','Not one more','hand','Story locked','Once per expedition, reach a downed ally before their condition worsens.','She has carried enough people out in silence.','Complete a rescue in her personal story.'),
    trait('stone','Stone by stone','heart','Story locked','A successful recovery leaves her more composed for the next fight.','No grand speeches. Just the next person who needs help.','Resolve a later chapter of her personal story.'),
  ]},
  {id:'mara',name:'Mara',role:'Scout',portrait:'portraits/mara-neutral-v1/preview.png',traits:[
    trait('keen','Keen eyes','aim','Known','Traps show before she steps on them.','She sees what the others walk past.','Part of her nature. Always active.',true),
    trait('thread','A way through','web','Story locked','After spotting danger, reveal one safer approach before the party commits.','There is always a seam in the trap.','Find the next step in her personal story.'),
    trait('home','The way home','moon','Story locked','Retracing familiar ground gives her a brief advantage when an ambush breaks.','She counted the turns on the way down.','Resolve a later chapter of her personal story.'),
  ]},
  {id:'alwen',name:'Sister Alwen',role:'Mage',portrait:'portraits/main-heroes-v1/alwen/preview.png',traits:[
    trait('medic','Field medic','heal','Known','Healing items heal half again as much; once per trip, bind an injury without a dressing.','Steady hands, even when there is little left to save.','Part of her nature. Always active.',true),
    trait('breath','Count the breaths','nerve','Story locked','Treating a wounded ally also eases some of their strain.','Stay with me. Just this breath, then the next.','Tend to someone important in her personal story.'),
    trait('light','The last light','lamp','Story locked','Once per expedition, keep a final restorative prayer for an ally who has fallen.','Not while she can still speak their name.','Resolve a later chapter of her personal story.'),
  ]},
];
let current=heroes[0], selected=null, selectionPinned=false;
let hoverTimer=null;
const byId=id=>document.getElementById(id);
const image=key=>ART+icons[key];
const panel=byId('inspection');
const clearHover=()=>{clearTimeout(hoverTimer);hoverTimer=null;};
function leavePreview(){clearHover();if(!selectionPinned)hoverTimer=setTimeout(()=>dismiss(false),160);}
function createNode(data){
  const button=document.createElement('button');
  button.type='button'; button.className='skill'+(data.personal?' trait':'')+(data.rank>0||data.state==='Known'?' learned':'')+(data.state==='Story locked'?' locked':'');
  button.dataset.id=data.id; button.setAttribute('aria-pressed','false');
  button.setAttribute('aria-label',data.name+', '+(data.personal?data.state:`rank ${data.rank} of ${data.max}`));
  const seal=document.createElement('span');seal.className='seal';
  const img=document.createElement('img');img.src=image(data.icon);img.alt='';seal.append(img);
  const label=document.createElement('span');label.className='label';label.textContent=data.name;
  button.append(seal,label);
  if(data.personal){const state=document.createElement('span');state.className='state';state.textContent=data.state;button.append(state);}
  else{const pips=document.createElement('span');pips.className='pips';pips.setAttribute('aria-hidden','true');for(let i=0;i<data.max;i++){const pip=document.createElement('i');pip.className='pip'+(i<data.rank?' filled':'');pips.append(pip);}button.append(pips);}
  button.addEventListener('pointerenter',event=>{clearHover();if(event.pointerType==='mouse'&&!selectionPinned)inspect(data,button);});
  button.addEventListener('pointerleave',leavePreview);
  button.addEventListener('focus',()=>{clearHover();if(button.matches(':focus-visible')&&!selectionPinned)inspect(data,button);});
  button.addEventListener('click',()=>{clearHover();selectionPinned=true;inspect(data,button);});
  return button;
}
function inspect(data,button){
  clearHover();
  if(selected)selected.removeAttribute('aria-describedby');
  selected=button;
  button.setAttribute('aria-describedby','inspection');
  document.querySelectorAll('.skill').forEach(b=>b.setAttribute('aria-pressed',String(b===button)));
  byId('detail-kind').textContent=data.personal?'Personal trait':current.role+' training';
  byId('detail-icon').src=image(data.icon);
  byId('detail-name').textContent=data.name;
  byId('detail-state').textContent=data.personal?data.state:`Rank ${data.rank} / ${data.max}`;
  byId('detail-flavour').textContent='“'+data.flavour+'”';
  byId('detail-effect').textContent=data.effect;
  byId('detail-unlock').textContent=data.unlock;
  byId('detail-caption').textContent=data.personal?'Unique to '+current.name:'Shared by heroes of this class';
  panel.hidden=false;
  positionCard();
}
function positionCard(){
  if(panel.hidden||!selected)return;
  const screen=document.querySelector('.screen').getBoundingClientRect();
  const rootStyle=getComputedStyle(document.documentElement);
  const safe=side=>Math.max(12,parseFloat(rootStyle.getPropertyValue('--safe-'+side))||0);
  const bounds={left:Math.max(screen.left,safe('left')),right:Math.min(screen.right,innerWidth-safe('right')),top:Math.max(screen.top,safe('top')),bottom:Math.min(screen.bottom,innerHeight-safe('bottom'))};
  const source=selected.getBoundingClientRect();
  if(source.bottom<bounds.top||source.top>bounds.bottom){dismiss(false);return;}
  const rightSpace=bounds.right-source.right-12;
  const leftSpace=source.left-bounds.left-12;
  const side=rightSpace>=Math.min(340,bounds.right-bounds.left)||rightSpace>=leftSpace?'right':'left';
  const space=side==='right'?rightSpace:leftSpace;
  const width=Math.min(340,Math.max(230,space),bounds.right-bounds.left);
  panel.style.width=width+'px';
  panel.style.maxHeight=Math.min(420,bounds.bottom-bounds.top)+'px';
  const height=panel.getBoundingClientRect().height;
  const x=side==='right'?source.right+12:source.left-width-12;
  const y=Math.max(bounds.top,Math.min(source.top,bounds.bottom-height));
  panel.style.left=Math.max(bounds.left,Math.min(x,bounds.right-width))+'px';
  panel.style.top=y+'px';
  panel.dataset.side=side;
  panel.style.setProperty('--arrow-y',Math.max(16,Math.min(source.top+25-y,height-26))+'px');
}
function chooseHero(hero){
  dismiss(false);current=hero;
  byId('hero-name').textContent=hero.name;byId('hero-role').textContent=hero.role;
  byId('class-note').textContent='Shared by '+hero.role+' heroes';
  document.querySelectorAll('.hero').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.hero===hero.id)));
  byId('class-tree').replaceChildren();
  for(const pair of classes[hero.role]){const branch=document.createElement('div');branch.className='branch';pair.forEach(d=>branch.append(createNode(d)));byId('class-tree').append(branch);}
  byId('personal-tree').replaceChildren(...hero.traits.map(createNode));
}
for(const hero of heroes){const b=document.createElement('button');b.className='hero';b.type='button';b.dataset.hero=hero.id;b.setAttribute('aria-label',hero.name+', '+hero.role);b.setAttribute('aria-pressed','false');const img=document.createElement('img');img.src=ART+hero.portrait;img.alt='';b.append(img);b.addEventListener('click',()=>chooseHero(hero));document.querySelector('.heroes').append(b);}
function dismiss(restoreFocus=true){clearHover();const previous=selected;selected=null;selectionPinned=true;if(previous){previous.removeAttribute('aria-describedby');if(restoreFocus)previous.focus({preventScroll:true});}panel.hidden=true;document.querySelectorAll('.skill').forEach(b=>b.setAttribute('aria-pressed','false'));selectionPinned=false;}
document.querySelector('.dismiss').addEventListener('click',()=>dismiss());
panel.addEventListener('pointerenter',clearHover);
panel.addEventListener('pointerleave',leavePreview);
document.addEventListener('keydown',event=>{if(event.key==='Escape'&&!panel.hidden){event.preventDefault();dismiss();}});
document.addEventListener('pointerdown',event=>{if(!panel.hidden&&!panel.contains(event.target)&&!event.target.closest('.skill'))dismiss(false);});
document.addEventListener('focusin',event=>{if(!selectionPinned&&!panel.hidden&&!panel.contains(event.target)&&!event.target.closest('.skill'))dismiss(false);});
window.addEventListener('resize',positionCard);
window.addEventListener('scroll',positionCard,true);
chooseHero(current);

