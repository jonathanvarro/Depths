// Offline review paths, controls and narrow-screen layout; no game saves.
const {chromium}=require('playwright');
const fs=require('fs');
const path=require('path');
const {pathToFileURL}=require('url');
(async()=>{
 const root=path.resolve(__dirname,'../..'),out=path.join(root,'art/concepts/descent-finish-v1');
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:900}}),results=[],errors=[];
 const check=(ok,label)=>results.push({check:label,ok:!!ok});
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);
 await page.evaluate(()=>window.artReadyPromise);
 check(await page.locator('#cards canvas').count()===20,'All twenty native drawings loaded');
 check(await page.locator('#family option').count()===6,'Six surface families');
 for(const family of await page.locator('#family option').evaluateAll(xs=>xs.map(x=>x.value))){
  await page.selectOption('#family',family);
  for(const setting of ['neutral','lantern','phone-lantern']){
   await page.selectOption('#light',setting);
   check(await page.locator('#surface-room').evaluate(i=>i.decode().then(()=>i.naturalWidth>=1278)),'Room loaded: '+family+' '+setting);
  }
 }
 await page.screenshot({path:path.join(out,'inspector-desktop.png'),fullPage:true});
 await page.click('#dressing-tab');
 check(await page.locator('#dressing').isVisible()&&!(await page.locator('#surfaces').isVisible()),'Dressing tab switches panel');
 await page.click('#step');
 const before=await page.evaluate(()=>window.artState);
 await page.waitForTimeout(600);
 check(await page.evaluate(()=>!window.artState.playing&&window.artState.frame)===before.frame,'Paused frame holds');
 // File URLs deliberately retain Chrome's canvas-read security boundary.
 // Compare browser captures of the rendered canvas instead of reading pixels.
 const pixels=await page.locator('[data-id="floor-fungus"] canvas').screenshot();
 await page.click('#glow');
 check(await page.evaluate(()=>!window.artState.glow),'Glow toggle is independent');
 const neutral=await page.locator('[data-id="floor-fungus"] canvas').screenshot();
 check(!pixels.equals(neutral),'Registered pulse contributes visible pixels');
 await page.click('#step');
 check(await page.evaluate(()=>window.artState.frame)===(before.frame+1)%8,'Step advances exactly one frame');
 await page.click('#glow');
 await page.click('#play');
 check(await page.evaluate(()=>window.artState.playing),'Play resumes');
 await page.click('#play');
 for(const room of ['mine-fittings','goblin-fixtures','drowned-details','fungal-details','fungal-dark','buried-details','sealed-details']){
  await page.selectOption('#room',room);
  for(const size of ['desktop','phone']){
   await page.selectOption('#size',size);
   check(await page.locator('#dressing-room').evaluate(i=>i.decode().then(()=>i.naturalWidth>=1278)),'Mounted view loaded: '+room+' '+size);
  }
 }
 await page.screenshot({path:path.join(out,'inspector-dressing-desktop.png'),fullPage:true});
 for(const width of [844,390]){
  await page.setViewportSize({width,height:width===844?390:844});
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow at '+width+'px');
  check(await page.locator('button:visible,select:visible').evaluateAll(xs=>xs.every(x=>x.getBoundingClientRect().height>=44)),'44px controls at '+width+'px');
  check(await page.locator('.card').evaluateAll(xs=>xs.every(x=>{const a=x.getBoundingClientRect();return [...x.children].every(c=>{const b=c.getBoundingClientRect();return b.left>=a.left&&b.right<=a.right&&b.top>=a.top&&b.bottom<=a.bottom})})),'All drawing and label bounds fit cards at '+width+'px');
  await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));
  await page.screenshot({path:path.join(out,'inspector-'+width+'.png'),fullPage:true});
 }
 await page.click('#surface-tab');
 check(await page.locator('#surfaces').isVisible(),'Surface tab returns');
 check(await page.locator('img:visible').evaluateAll(xs=>Promise.all(xs.map(i=>i.decode().then(()=>i.naturalWidth>0).catch(()=>false))).then(xs=>xs.every(Boolean))),'Visible native tiles load');
 check(errors.length===0,'No browser script errors');
 const report={checks:results.length,failures:results.filter(x=>!x.ok),errors,results,limits:'Offline desktop Chrome review. Phone dimensions are simulated.'};
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify(report,null,2)+'\n');
 await browser.close();console.log('DESCENT_BROWSER checks='+results.length+' failures='+report.failures.length);process.exitCode=report.failures.length?1:0;
})().catch(e=>{console.error(e);process.exit(1)});
