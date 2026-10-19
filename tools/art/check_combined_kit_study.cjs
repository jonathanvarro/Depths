const {chromium}=require('playwright');
const fs=require('node:fs'),path=require('node:path'),{pathToFileURL}=require('node:url');
const out=path.resolve(__dirname,'../../art/concepts/interface/pack-heroes-v4');
let checks=0,captures=0;const failures=[],errors=[];
function check(ok,label){checks++;if(!ok)failures.push(label);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 for(const [name,width,height] of [['desktop',1280,720],['phone',1278,590],['phone-se',1334,750],['compact',736,590]]){
  const context=await browser.newContext({viewport:{width,height},hasTouch:true});
  const page=await context.newPage();page.setDefaultTimeout(7000);page.on('pageerror',e=>errors.push(name+': '+e.message));
  await page.goto(pathToFileURL(path.join(out,'combined-kit.html')).href);await page.evaluate(()=>document.fonts.ready);
  const q=s=>page.locator('#depths-pack-heroes '+s);
  const capture=async label=>{await page.mouse.move(0,0);await page.screenshot({path:path.join(out,name+'-'+label+'.png'),fullPage:true});captures++;};
  async function layout(label){
   const result=await page.evaluate(()=>{
    const visible=e=>e.getClientRects().length&&getComputedStyle(e).visibility!=='hidden';
    const buttons=[...document.querySelectorAll('#depths-pack-heroes button')].filter(visible);
    const small=buttons.filter(e=>!e.disabled).filter(e=>{const r=e.getBoundingClientRect();return r.width<44||r.height<44;}).map(e=>e.getAttribute('aria-label')||e.textContent);
    const outside=buttons.filter(e=>{const r=e.getBoundingClientRect();return r.left<0||r.right>innerWidth+1||r.top<0||r.bottom>innerHeight+1;}).map(e=>e.getAttribute('aria-label')||e.className);
    const bag=document.querySelector('.physical-bag').getBoundingClientRect(),hero=document.querySelector('.hero-panel').getBoundingClientRect(),dock=document.querySelector('.inspection-dock').getBoundingClientRect();
    const body=document.querySelector('.hero-body').getBoundingClientRect(),equipment=document.querySelector('#depths-equipment'),board=document.querySelector('.equip-board').getBoundingClientRect();
    const unclipped=!visible(equipment)||(board.top>=body.top-1&&board.bottom<=body.bottom+1);
    return {small,outside,unclipped,scroll:document.documentElement.scrollHeight>innerHeight+1||document.documentElement.scrollWidth>innerWidth,
     side:hero.right<=bag.left&&bag.right<=innerWidth&&hero.top<bag.bottom,
     dock:bag.bottom<=dock.top+1&&hero.bottom<=dock.top+1};
   });
   check(!result.small.length,name+' '+label+' 44px targets: '+result.small.join(','));
   check(!result.outside.length,name+' '+label+' visible bounds: '+result.outside.join(','));
   check(!result.scroll,name+' '+label+' viewport fits');
   check(result.side,name+' '+label+' equipment left / pack right');
   check(result.dock,name+' '+label+' details never cover either panel');
   check(result.unclipped,name+' '+label+' complete equipment fits without scrolling');
  }
  check(await q('#depths-equipment').isVisible()&&await q('.pack-page').isVisible(),name+' opens combined');
  check(await q('.bag .slot').count()===12,name+' full shared bag');
  check(await page.evaluate(()=>[...document.images].filter(i=>i.hasAttribute('src')).every(i=>i.complete&&i.naturalWidth>0)),name+' art loaded');
  check(await page.evaluate(()=>[...document.fonts].every(f=>f.status==='loaded')),name+' fonts loaded');
  await layout('combined');await capture('combined');
  const club=q('.bag [data-item="club"]');await club.tap();
  check(await q('.inspect').getAttribute('data-pinned')==='true',name+' touch pins in bottom dock');
  check((await q('.inspect-extra').textContent()).includes('Replaces Plain knife'),name+' replacement identity');
  check(await q('.equip-cell.receives').getAttribute('data-role')==='main',name+' matching equipment target highlighted');
  await layout('compare');await capture('compare');
  await q('.inspect .primary').tap();
  check(await q('.equipment [data-item="club"]').count()===1&&await q('.bag [data-item="knife"]').count()===1,name+' swap returns old item to visible bag');
  check(await q('.pack-page').isVisible(),name+' bag persists through equip');
  await q('.bag [data-item="ration"]').hover();check(await q('.inspect').isVisible(),name+' hover inspects');
  check(await q('.bag [data-item="ration"] .qty').textContent()==='×2',name+' inspect never consumes');
  await q('.bag [data-item="ration"]').tap();await q('.inspect .primary').tap();
  check(await q('.bag [data-item="ration"] .qty').textContent()==='×1',name+' explicit sample use');
  await q('#depths-status-tab').tap();
  check(await q('#depths-status').isVisible()&&await q('.pack-page').isVisible(),name+' status replaces left panel only');
  await layout('status');await capture('status');
  await q('[data-hero="1"]').tap();
  check(await q('#depths-status').isVisible()&&await q('.pack-page').isVisible()&&!await q('.inspect').isVisible(),name+' hero switch preserves tab/bag and clears stale detail');
  await q('#depths-equipment-tab').tap();await q('.bag [data-item="spear"]').tap();await q('.inspect .primary').tap();
  check(await q('.equipment [data-item="spear"]').count()===1,name+' equips for new selected hero');
  await q('[data-hero="0"]').tap();check(await q('.equipment [data-item="club"]').count()===1,name+' first hero loadout retained');
  await q('.equipment [data-item="club"]').tap();await q('.inspect .primary').tap();
  check(await q('.bag [data-item="club"]').count()===1,name+' unequip returns to bag');
  await q('.bag [data-item="dressing"]').tap();check(await q('.inspect .primary').isDisabled(),name+' unavailable action has a reason');
  await page.keyboard.press('Escape');check(!await q('.inspect').isVisible()&&await q('.window').isVisible(),name+' Escape closes dock first');
  await q('#depths-status-tab').focus();await page.keyboard.press('ArrowLeft');check(await q('#depths-equipment').isVisible(),name+' keyboard tabs');
  await q('.back').tap();await q('[data-open="equipment"]').tap();check(await q('#depths-equipment').isVisible()&&await q('.pack-page').isVisible(),name+' reopen combined equipment default');
  await context.close();
 }
 await browser.close();check(!errors.length,'No browser errors: '+errors.join(';'));
 const report={checks,failures,errors,captures,live_game_changed:false,physical_phone_test:false};
 fs.writeFileSync(path.join(out,'validation.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));if(failures.length)process.exitCode=1;
})();
