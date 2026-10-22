const {chromium}=require('playwright'),fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
(async()=>{
 const out=path.resolve(__dirname,'../../art/concepts/events-trinkets-v1'),browser=await chromium.launch({channel:'chrome',headless:true}),page=await browser.newPage({viewport:{width:1280,height:900}}),results=[],errors=[];
 const check=(ok,name)=>results.push({check:name,ok:!!ok});page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);await page.evaluate(()=>window.artReadyPromise);
 check(await page.locator('#item-grid article').count()===9,'Nine distinct trinket designs');
 check(await page.locator('#item-grid img').count()===27,'Each icon shown at 128/64/40px');
 check(await page.locator('#item-grid img').evaluateAll(xs=>xs.every(i=>i.complete&&i.naturalWidth===(i.width===64?64:128))),'Native exports load at all sizes');
 check(await page.locator('#source-list details').count()===15,'All original masters and exact prompts retained');
 for(const id of ['bloodstone','shield-bearers-token','goblin-gold-torc'])for(const size of ['phone','desktop']){
  await page.selectOption('#pack-item',id);await page.selectOption('#pack-size',size);await page.evaluate(()=>window.packReady);check(await page.locator('#pack-shot').evaluate(i=>i.naturalWidth>=1278),'Real Pack capture '+id+size);
 }
 await page.screenshot({path:path.join(out,'inspector-items-desktop.png'),fullPage:true});
 await page.click('#props-tab');check(await page.locator('#props').isVisible()&&!(await page.locator('#items').isVisible()),'Encounter tab switches');
 for(const id of ['defiled-shrine','fouled-well','buried-cache']){
  await page.selectOption('#prop',id);await page.evaluate(()=>window.stateReady);const fresh=await page.locator('#held-art').getAttribute('src');
  check(await page.locator('#held-art').evaluate(i=>i.naturalWidth===128),'Native prop '+id);
  await page.click('#step');await page.evaluate(()=>window.stateReady);check(await page.locator('#held-art').getAttribute('src')!==fresh,'Resolved state changes '+id);
  const held=await page.locator('#held-art').getAttribute('src');await page.waitForTimeout(1100);check(await page.locator('#held-art').getAttribute('src')===held,'Paused state holds '+id);
  for(const size of ['phone','desktop']){await page.selectOption('#room-size',size);await page.evaluate(()=>window.stateReady);check(await page.locator('#room-shot').evaluate(i=>i.naturalWidth>=1278),'Rendered state capture '+id+size)}
 }
 await page.click('#play');check(await page.evaluate(()=>reviewState.playing),'Playback starts');await page.click('#play');check(!(await page.evaluate(()=>reviewState.playing)),'Playback pauses');
 await page.selectOption('#background','linen');check(await page.locator('#stage').getAttribute('data-bg')==='linen','Contrast backdrop switches');await page.selectOption('#background','dark');
 await page.screenshot({path:path.join(out,'inspector-props-desktop.png'),fullPage:true});
 for(const width of [844,390]){
  await page.setViewportSize({width,height:width===844?390:844});
  for(const tab of ['items','props']){
   await page.click('#'+tab+'-tab');check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+tab+width);
   check(await page.locator('button:visible,select:visible').evaluateAll(xs=>xs.every(x=>x.getBoundingClientRect().height>=44)),'44px controls '+tab+width);
   await page.screenshot({path:path.join(out,'inspector-'+tab+'-'+width+'.png'),fullPage:true});
  }
 }
 await page.locator('details.sources>summary').click();check(await page.locator('#source-list a').evaluateAll(xs=>xs.length===15&&xs.every(x=>x.href.endsWith('-master.png'))),'Direct source links');
 check(errors.length===0,'No browser script errors');const failed=results.filter(r=>!r.ok).length;
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({issue:142,checks:results.length,failed,errors,results},null,2)+'\n');
 await browser.close();console.log(`EVENT_TRINKET_BROWSER: ${results.length} checks, ${failed} failed`);if(failed)process.exitCode=1;
})().catch(e=>{console.error(e);process.exitCode=1});
