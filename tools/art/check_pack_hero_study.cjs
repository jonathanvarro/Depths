// #61: inspect the actual browser study in the skill's sandboxed wrapper.
const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
const out=path.resolve(__dirname,'../../art/concepts/interface/pack-heroes-v2');
const preview=process.argv[2];
if(!preview)throw new Error('Pass the absolute rendered wrapper path');
let checks=0;const failures=[],errors=[];
function check(ok,message){checks++;if(!ok)failures.push(message);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 for(const [name,width,height] of [['desktop',1024,720],['phone',1278,590],['compact',736,590],['narrow',320,900]]){
  const context=await browser.newContext({viewport:{width,height},hasTouch:true});
  const page=await context.newPage();page.setDefaultTimeout(7000);page.on('pageerror',e=>errors.push(name+': '+e.message));
  await page.goto(pathToFileURL(preview).href);
  const frame=page.frames().find(f=>f.parentFrame());
  await frame.waitForSelector('#depths-pack-heroes .equipment .slot');
  await frame.evaluate(()=>document.fonts.ready);
  const q=s=>frame.locator('#depths-pack-heroes '+s);
  const text=async s=>(await q(s).textContent()).trim();
  const capture=async label=>{await frame.locator('#depths-pack-heroes').screenshot({path:path.join(out,name+'-'+label+'.png')});};
  async function bounds(label){
    const bad=await frame.evaluate(()=>{const r=document.getElementById('depths-pack-heroes').getBoundingClientRect();return [...document.querySelectorAll('#depths-pack-heroes button,#depths-pack-heroes img,#depths-pack-heroes p,#depths-pack-heroes h1,#depths-pack-heroes h2,#depths-pack-heroes h3,#depths-pack-heroes .inspect')].filter(e=>e.getClientRects().length).filter(e=>{const b=e.getBoundingClientRect();return b.left<r.left-1||b.right>r.right+1||b.top<r.top-1||b.bottom>r.bottom+1||e.scrollWidth>e.clientWidth+2;}).map(e=>e.className+': '+e.textContent.slice(0,35));});
    check(!bad.length,name+' '+label+' bounds: '+bad.join(', '));
    const small=await frame.evaluate(()=>[...document.querySelectorAll('#depths-pack-heroes button')].filter(e=>e.getClientRects().length&&!e.disabled).filter(e=>{const r=e.getBoundingClientRect();return r.width<43||r.height<43;}).map(e=>e.getAttribute('aria-label')||e.textContent));
    check(!small.length,name+' '+label+' touch targets: '+small.join(', '));
    if(name==='phone')check(await frame.locator('#depths-pack-heroes').evaluate(e=>e.getBoundingClientRect().height)<=590,name+' '+label+' fits 590px phone canvas');
  }
  check(await text('.page-title')==='Equipment',name+' Equipment default');
  check(await frame.evaluate(()=>[...document.fonts].filter(f=>['DepthsBody','DepthsHeading'].includes(f.family)).every(f=>f.status==='loaded')),name+' bundled fonts loaded');
  await bounds('equipment');await capture('equipment');
  await q('#depths-status-tab').click();check(await q('#depths-status').isVisible(),name+' status tab');
  await bounds('status');await capture('status');
  await q('[data-hero="1"]').click();check(await text('.hero-name')==='Hero II'&&await q('#depths-status').isVisible(),name+' hero switch retains Status');
  await q('[data-hero="2"]').click();check(await text('.hero-name')==='Hero III',name+' third portrait');
  await q('[data-hero="0"]').click();
  await q('.destination').click();check(await text('.page-title')==='Pack',name+' shared Pack');
  check(await q('.bag .slot img').count()===8,name+' image slots and quantities');
  await bounds('pack');await capture('pack');
  const ration=q('.bag [data-item="ration"]');await ration.hover();
  check(await q('.inspect').isVisible()&&await text('#depths-inspect-title')==='Ration',name+' mouse hover description');
  check(await q('.bag [data-item="ration"] .qty').textContent()==='×2',name+' hover never consumes');
  await bounds('hover');
  await ration.tap();await q('.inspect').hover();
  check(await text('.inspect .primary')==='Eat ration · 1 time',name+' touch pins explicit action');
  await bounds('touch detail');await capture('item-detail');
  await page.keyboard.press('Escape');check(!await q('.inspect').isVisible()&&await q('.window').isVisible(),name+' Escape closes detail first');
  check(await ration.evaluate(e=>e===document.activeElement),name+' detail focus restored');
  await ration.tap();await q('.inspect .primary').click();
  check(await q('.bag [data-item="ration"] .qty').textContent()==='×1',name+' explicit use changes sample stack');
  await ration.tap();await q('.inspect .primary').click();await ration.tap();
  check(await q('.inspect .primary').isDisabled()&&await text('.inspect .primary')==='None left',name+' depleted stack inspectable');
  await q('.inspect .close').click();
  await q('.bag [data-item="dressing"]').tap();check(await q('.inspect .primary').isDisabled(),name+' unavailable reason');
  await q('.inspect .close').click();
  await q('[data-hero="1"]').click();check(await text('.page-title')==='Equipment',name+' portrait from Pack opens Equipment');
  const club=q('.spares [data-item="club"]');await club.tap();await q('.inspect .primary').click();
  check(await q('.equipment [data-item="club"]').count()===1,name+' equip for selected hero');
  await q('[data-hero="0"]').click();check(await q('.equipment [data-item="knife"]').count()===1,name+' independent hero loadouts');
  await q('.equipment [data-item="knife"]').tap();await q('.inspect .primary').click();check(await q('.spares [data-item="knife"]').count()===1,name+' unequip returns to shared bag');
  await q('#depths-status-tab').focus();await page.keyboard.press('ArrowLeft');check(await q('#depths-equipment').isVisible(),name+' keyboard tabs');
  await q('.back').click();check(await q('.launcher').isVisible(),name+' Back closes window');
  await q('[data-open="equipment"]').click();check(await text('.page-title')==='Equipment',name+' reopen defaults Equipment');
  await page.keyboard.press('Escape');check(await q('.launcher').isVisible(),name+' Escape closes window');
  check(await q('[data-open="equipment"]').evaluate(e=>e===document.activeElement),name+' opener focus restored');
  // Restored host state updates the page without sending a new message.
  await frame.evaluate(()=>window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:{privateContent:{version:2,page:'status',hero:0,open:true}}}}})));
  check(await q('#depths-status').isVisible(),name+' saved state restores');
  await context.close();
 }
 await browser.close();check(errors.length===0,'No browser runtime errors: '+errors.join('; '));
 const report={checks,failures,errors,viewports:[[1024,720],[1278,590],[736,590],[320,900]],live_game_changed:false,physical_phone_test:false};
 fs.writeFileSync(path.join(out,'validation.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify(report));if(failures.length)process.exitCode=1;
})().catch(e=>{console.error(e);process.exit(1);});
