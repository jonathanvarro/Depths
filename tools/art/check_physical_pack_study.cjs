// #109: review real layout and inherited inspection interactions.
const {chromium}=require('playwright');
const fs=require('node:fs'),path=require('node:path');
const {pathToFileURL}=require('node:url');
const out=path.resolve(__dirname,'../../art/concepts/interface/pack-heroes-v3');
let checks=0;const failures=[],errors=[];
function check(ok,label){checks++;if(!ok)failures.push(label);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 for(const [name,width,height] of [['desktop',1280,720],['phone',1278,590],['phone-se',1334,750],['compact',736,590]]){
  const context=await browser.newContext({viewport:{width,height},hasTouch:true});
  const page=await context.newPage();page.setDefaultTimeout(7000);
  page.on('pageerror',e=>errors.push(name+': '+e.message));
  await page.goto(pathToFileURL(path.join(out,'pack-heroes.html')).href);
  await page.evaluate(()=>document.fonts.ready);
  const q=s=>page.locator('#depths-pack-heroes '+s);
  const capture=async label=>{await page.mouse.move(0,0);await page.screenshot({path:path.join(out,name+'-'+label+'.png'),fullPage:true});};
  async function bounds(label){
   const result=await page.evaluate(()=>{
    const visible=e=>e.getClientRects().length&&getComputedStyle(e).visibility!=='hidden';
    const controls=[...document.querySelectorAll('#depths-pack-heroes button')].filter(visible);
    const small=controls.filter(e=>!e.disabled).filter(e=>{const r=e.getBoundingClientRect();return r.width<43||r.height<43;}).map(e=>e.getAttribute('aria-label')||e.textContent);
    const outside=controls.filter(e=>{const r=e.getBoundingClientRect();return r.left<0||r.right>innerWidth+1||r.top<0||r.bottom>innerHeight+1;}).map(e=>e.className);
    return {small,outside,overflow:document.documentElement.scrollWidth>innerWidth};
   });
   check(!result.small.length,name+' '+label+' targets: '+result.small.join(','));
   check(!result.outside.length,name+' '+label+' bounds: '+result.outside.join(','));
   check(!result.overflow,name+' '+label+' no horizontal overflow');
  }
  check(await q('.page-title').textContent()==='Equipment',name+' equipment default');
  check(await q('.equipment .slot').count()===2,name+' current weapon/body categories');
  check(await page.evaluate(()=>[...document.images].filter(i=>i.hasAttribute('src')).every(i=>i.complete&&i.naturalWidth>0)),name+' art loads');
  check(await page.evaluate(async()=>Promise.all(['assets/bag.png','assets/roll.png'].map(src=>new Promise(resolve=>{const image=new Image();image.onload=()=>resolve(image.naturalWidth===768);image.onerror=()=>resolve(false);image.src=src;}))).then(results=>results.every(Boolean))),name+' physical surfaces load');
  check(await page.evaluate(()=>[...document.fonts].every(f=>f.status==='loaded')),name+' fonts loaded');
  await bounds('equipment');await capture('equipment');
  await q('#depths-status-tab').tap();await bounds('status');await capture('status');
  await q('[data-hero="1"]').tap();check(await q('#depths-status').isVisible(),name+' hero switch retains tab');
  await q('[data-hero="0"]').tap();await q('.destination').tap();
  await bounds('pack');await capture('pack');
  const ration=q('.bag [data-item="ration"]');
  await ration.hover();check(await q('.inspect').isVisible(),name+' hover inspects');
  check(await q('.bag [data-item="ration"] .qty').textContent()==='×2',name+' hover never consumes');
  await ration.tap();check(await q('.inspect').getAttribute('data-pinned')==='true',name+' touch pins detail');
  await bounds('detail');await capture('detail');
  await page.keyboard.press('Escape');check(!await q('.inspect').isVisible(),name+' Escape closes details first');
  await ration.tap();await q('.inspect .primary').tap();
  check(await q('.bag [data-item="ration"] .qty').textContent()==='×1',name+' explicit sample use');
  await q('[data-hero="1"]').tap();check(await q('#depths-equipment').isVisible(),name+' portrait from bag opens equipment');
  await q('.spares [data-item="club"]').tap();await q('.inspect .primary').tap();
  check(await q('.equipment [data-item="club"]').count()===1,name+' explicit equip for selected hero');
  await q('[data-hero="0"]').tap();check(await q('.equipment [data-item="knife"]').count()===1,name+' separate sample loadouts');
  await q('.equipment [data-item="knife"]').tap();await q('.inspect .primary').tap();
  check(await q('.spares [data-item="knife"]').count()===1,name+' unequip returns to shared bag');
  await q('#depths-status-tab').focus();await page.keyboard.press('ArrowLeft');
  check(await q('#depths-equipment').isVisible(),name+' keyboard tabs');
  await q('.back').tap();await q('[data-open="equipment"]').tap();
  check(await q('#depths-equipment').isVisible(),name+' reopen defaults equipment');
  await context.close();
 }
 await browser.close();check(errors.length===0,'No browser errors: '+errors.join(';'));
 const report={checks,failures,errors,captures:16,live_game_changed:false,physical_phone_test:false};
 fs.writeFileSync(path.join(out,'validation.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify(report));if(failures.length)process.exitCode=1;
})();
