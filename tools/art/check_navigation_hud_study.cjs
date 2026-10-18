const {chromium}=require('playwright');
const fs=require('node:fs'),path=require('node:path');
const {pathToFileURL}=require('node:url');
const out=path.resolve(__dirname,'../../art/concepts/interface/navigation-v2');
if(!process.argv[2])throw Error('Pass the rendered review wrapper path');
let checks=0;const failures=[],errors=[];
function check(ok,message){checks++;if(!ok)failures.push(message);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 for(const [name,width,height] of [['desktop',1024,720],['phone',1278,590],['compact',736,590],['small',568,590],['narrow',320,900]]){
  const ctx=await browser.newContext({viewport:{width,height},hasTouch:true});
  const page=await ctx.newPage();page.setDefaultTimeout(6000);page.on('pageerror',e=>errors.push(name+': '+e.message));
  await page.goto(pathToFileURL(process.argv[2]).href);
  const frame=page.frames().find(f=>f.parentFrame());await frame.waitForSelector('#depths-hud .fuel-band');await frame.evaluate(()=>document.fonts.ready);
  const q=s=>frame.locator('#depths-hud '+s),txt=async s=>(await q(s).textContent()).trim();
  const capture=async label=>{await page.mouse.move(width/2,200);await page.waitForTimeout(250);return frame.locator('#depths-hud').screenshot({path:path.join(out,name+'-'+label+'.png')});};
  async function bounds(label){
   const bad=await frame.evaluate(()=>{const root=document.getElementById('depths-hud').getBoundingClientRect();return [...document.querySelectorAll('#depths-hud button,#depths-hud input,#depths-hud img,#depths-hud h1,#depths-hud h2,#depths-hud p,#depths-hud .bottom-hud')].filter(e=>e.getClientRects().length&&!e.classList.contains('notice')).filter(e=>{const b=e.getBoundingClientRect();return b.left<root.left-1||b.right>root.right+1||b.top<root.top-1||b.bottom>root.bottom+1||e.scrollWidth>e.clientWidth+2}).map(e=>e.className+': '+e.textContent.slice(0,32));});
   check(!bad.length,name+' '+label+' bounds: '+bad.join('; '));
   const tiny=await frame.evaluate(()=>[...document.querySelectorAll('#depths-hud button,#depths-hud input')].filter(e=>e.getClientRects().length&&!e.disabled).filter(e=>{const b=e.getBoundingClientRect();return b.width<43||b.height<43}).map(e=>e.getAttribute('aria-label')||e.textContent));
   check(!tiny.length,name+' '+label+' targets: '+tiny.join('; '));
   if(name==='phone')check(await frame.locator('#depths-hud').evaluate(e=>e.getBoundingClientRect().height)<=590,name+' '+label+' fits 590px phone canvas');
  }
  async function oil(value){await frame.evaluate(value=>window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:{privateContent:{version:3,view:'exploration',oil:value,volume:80}}}}})),value);await page.waitForTimeout(230);}
  check(await q('.exploration').isVisible(),name+' exploration default');
  check(await q('.backpack-button svg').count()===1&&await q('.settings-button svg').count()===1,name+' backpack/settings graphics render');
  check(await q('.backpack-button svg').evaluate(e=>e.getBoundingClientRect().width)>=24,name+' recognizable icon size');
  if(name==='desktop')for(const [selector,filename] of [['.backpack-button svg','backpack'],['.settings-button svg','settings'],['.move-forward svg','forward'],['.move-back svg','back'],['.move-left svg','turn-left'],['.move-right svg','turn-right']]){
   const svg=await q(selector).evaluate(e=>{const copy=e.cloneNode(true);copy.setAttribute('xmlns','http://www.w3.org/2000/svg');copy.setAttribute('width','32');copy.setAttribute('height','32');copy.setAttribute('stroke','#e6dac1');copy.setAttribute('stroke-width','1.75');for(const key of ['class','data-lucide','aria-hidden'])copy.removeAttribute(key);return new XMLSerializer().serializeToString(copy);});
   fs.writeFileSync(path.join(out,'assets',filename+'.svg'),svg+'\n');
  }
  const backpack=await q('.backpack-button').boundingBox(), portraits=await q('.hud-portraits').boundingBox();
  check(backpack.x>=portraits.x+portraits.width+4,name+' Pack immediately to right of portraits');
  check((await txt('.backpack-button'))==='',name+' no visible Pack text on HUD button');
  await bounds('HUD');await capture('hud');
  await q('.backpack-button').tap();check(await q('#depths-pack-heroes .pack-page').isVisible(),name+' backpack opens Pack');
  await bounds('pack');if(name==='desktop'||name==='phone')await capture('pack');
  await q('#depths-pack-heroes .back').click();check(await q('.exploration').isVisible(),name+' Pack Back to exploration');
  check(await q('.backpack-button').evaluate(e=>e===document.activeElement),name+' Pack opener focus');
  await q('.mara-button').tap();check(await q('#depths-equipment').isVisible(),name+' portrait opens Equipment');
  await q('#depths-status-tab').click();check(await q('#depths-status').isVisible(),name+' Status retained in hero window');await page.keyboard.press('Escape');
  check(await q('.mara-button').evaluate(e=>e===document.activeElement),name+' hero opener focus');
  await q('.settings-button').tap();check(await q('.settings-page').isVisible(),name+' gear opens Settings');await bounds('settings');
  if(name==='desktop')await capture('settings');
  await q('#depths-volume').fill('35');check(await txt('.volume-value')==='35%',name+' local sound setting');
  await q('.settings-back').focus();await page.keyboard.press('w');check(await txt('.fuel-percent')==='62%',name+' movement input blocked behind Settings');
  await q('.show-controls').click();check(await q('.controls-page').isVisible(),name+' Controls drilldown');await bounds('controls');await page.keyboard.press('Escape');
  check(await q('.settings-page').isVisible()&&await q('.show-controls').evaluate(e=>e===document.activeElement),name+' Controls Back hierarchy');
  await q('#depths-volume').focus();await page.keyboard.press('Escape');check(await q('.exploration').isVisible(),name+' Escape works from settings input');
  check(await q('.settings-button').evaluate(e=>e===document.activeElement),name+' Settings opener focus');
  await q('.map-thumb').tap();check(await q('.map-page').isVisible(),name+' map preserved');await bounds('map');await q('.map-back').click();
  await q('.fuel-button').tap();check(await q('.fuel-details').isVisible()&&await txt('.oil-value')==='62 / 100 oil',name+' tap fuel details');await bounds('fuel details');
  await page.keyboard.press('Escape');check(await q('.exploration').isVisible()&&!await q('.fuel-details').isVisible(),name+' dismiss fuel first');
  await q('.fuel-button').tap();await q('.oil-action').click();check(await txt('#depths-inspect-title')==='Oil flask',name+' fuel leads to oil item');
  await q('.inspect .primary').click();await q('#depths-pack-heroes .back').click();check(parseInt(await txt('.fuel-percent'))>=96,name+' refill updates HUD');
  await oil(62);await q('.move-left').tap();check(await txt('.fuel-percent')==='62%',name+' turning is free');
  await q('.move-forward').tap();check(await txt('.fuel-percent')==='61%',name+' step burns existing-rate fuel');
  const opacity=[];
  for(const [amount,light] of [[100,'Bright'],[62,'Steady'],[12,'Dim'],[0,'Out']]){
   await oil(amount);check(await txt('.fuel-band')===light,name+' band '+light);
   check(await q('.oil').evaluate(e=>e.style.height)===amount+'%',name+' oil reservoir '+amount);
   check(await q('.flame').isVisible()===(amount>0),name+' flame '+amount);
   const style=await frame.evaluate(()=>({veil:Number(getComputedStyle(document.querySelector('#depths-hud .darkness')).opacity),button:getComputedStyle(document.querySelector('#depths-hud .backpack-button')).color}));
   check(style.button==='rgb(230, 218, 193)',name+' HUD text stays readable at '+amount);opacity.push(style.veil);
   await bounds('oil '+amount);if(name==='desktop'||name==='phone')await capture('oil-'+amount);
  }
  check(opacity[0]<opacity[1]&&opacity[1]<opacity[2]&&opacity[2]<opacity[3]&&opacity[3]<.9,name+' cave dims without blacking out');
  await q('.backpack-button').focus();await page.keyboard.press('i');check(await q('.pack-page').isVisible(),name+' keyboard Pack route');await page.keyboard.press('Escape');
  for(const [left,light] of [[50,'Steady'],[9,'Dim'],[0,'Out']]){
   await frame.evaluate(left=>window.dispatchEvent(new CustomEvent('openai:set_globals',{detail:{globals:{widgetState:{privateContent:{version:3,view:'exploration',source:'torch',torchLeft:left,oil:62,volume:80}}}}})),left);
   check(await txt('.fuel-band')===light,name+' torch band '+left);
   check(await txt('.fuel-percent')===left*2+'%',name+' torch life percentage');
   check(await q('.torch-art').isVisible()&&!await q('.lantern-art').isVisible(),name+' torch glyph replaces lantern');
   check(await q('.torch-fire').isVisible()===(left>0),name+' torch flame '+left);
   await bounds('torch '+left);if(name==='desktop'||name==='phone')await capture('torch-'+left);
  }
  await ctx.close();
 }
 await browser.close();check(!errors.length,'No browser errors: '+errors.join('; '));
 const report={checks,failures,errors,viewports:[[1024,720],[1278,590],[736,590],[568,590],[320,900]],physical_phone_test:false,live_game_changed:false};
 fs.writeFileSync(path.join(out,'validation.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));if(failures.length)process.exitCode=1;
})().catch(e=>{console.error(e);process.exit(1)});
