const {chromium}=require('playwright'),fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
(async()=>{
 const root=path.resolve(__dirname,'../..'),out=path.join(root,'art/concepts/monsters-v1');
 const browser=await chromium.launch({channel:'chrome',headless:true});const page=await browser.newPage({viewport:{width:1280,height:900}}),results=[],errors=[];
 const check=(ok,label)=>results.push({check:label,ok:!!ok});page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);await page.evaluate(()=>window.artReadyPromise);
 check(await page.locator('#monster option').count()===11,'Eleven creature families');
 for(const id of await page.locator('#monster option').evaluateAll(xs=>xs.map(x=>x.value))){
  await page.selectOption('#monster',id);
  for(const pose of await page.locator('#pose option').evaluateAll(xs=>xs.map(x=>x.value))){
   await page.selectOption('#pose',pose);await page.evaluate(()=>window.poseReady);
   check(await page.evaluate(()=>window.currentImage.complete&&document.getElementById('portrait').width===window.currentImage.naturalWidth),'Native pose loaded: '+id+'/'+pose);
  }
 }
 await page.click('#next');await page.evaluate(()=>window.poseReady);const held=await page.evaluate(()=>window.monsterState.pose);await page.waitForTimeout(850);
 check(await page.evaluate(()=>window.monsterState.pose)===held,'Paused pose holds');
 const before=await page.locator('#portrait').screenshot();await page.click('#pivot');const after=await page.locator('#portrait').screenshot();check(!before.equals(after),'Pivot overlay is visible and independent');await page.click('#pivot');
 await page.selectOption('#background','stone');check(await page.locator('#stage').getAttribute('data-bg')==='stone','Stone contrast background');await page.selectOption('#background','dark');
 await page.click('#play');check(await page.evaluate(()=>window.monsterState.playing),'Pose playback starts');await page.click('#play');
 for(const v of await page.locator('#review option').evaluateAll(xs=>xs.map(x=>x.value)))for(const size of ['desktop','phone']){
  await page.selectOption('#review',v);await page.selectOption('#size',size);check(await page.locator('#shot').evaluate(i=>i.decode().then(()=>i.naturalWidth>=1278)),'Combat capture: '+v+' '+size);
 }
 await page.selectOption('#monster','goblin-brute');await page.selectOption('#pose','wind-up');await page.selectOption('#review','goblin-brute-wind-up');await page.evaluate(()=>window.poseReady);
 await page.screenshot({path:path.join(out,'inspector-desktop.png'),fullPage:true});
 for(const width of [844,390]){
  await page.setViewportSize({width,height:width===844?390:844});
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No creature overflow: '+width);
  check(await page.locator('button:visible,select:visible').evaluateAll(xs=>xs.every(x=>x.getBoundingClientRect().height>=44)),'44px creature controls: '+width);
  await page.screenshot({path:path.join(out,'inspector-'+width+'.png'),fullPage:true});
 }
 await page.click('#effects-tab');check(await page.locator('#effects').isVisible()&&!(await page.locator('#creatures').isVisible()),'Effects panel switches');
 check(await page.locator('.mark').count()===13,'Thirteen cue identities including reused heavy');
 check(await page.locator('.mark img').evaluateAll(xs=>Promise.all(xs.map(i=>i.decode().then(()=>i.naturalWidth===32))).then(a=>a.every(Boolean))),'All glyphs load at native32, shown32/24/14');
 await page.click('#fx-step');const frame=await page.evaluate(()=>window.monsterState.effectFrame);await page.waitForTimeout(300);check(await page.evaluate(()=>window.monsterState.effectFrame)===frame,'Effect pause holds');
 await page.click('#fx-play');check(await page.evaluate(()=>window.monsterState.effectPlaying),'Effect playback starts');await page.click('#fx-play');
 for(const width of [844,390]){
  await page.setViewportSize({width,height:width===844?390:844});
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No symbol overflow: '+width);
  check(await page.locator('button:visible,select:visible').evaluateAll(xs=>xs.every(x=>x.getBoundingClientRect().height>=44)),'44px effect controls: '+width);
  await page.screenshot({path:path.join(out,'inspector-effects-'+width+'.png'),fullPage:true});
 }
 check(errors.length===0,'No browser errors');const report={checks:results.length,failures:results.filter(e=>!e.ok),errors,results,limits:'Offline desktop Chrome, simulated phone sizes; no physical iPhone.'};fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify(report,null,2)+'\n');await browser.close();console.log('MONSTER_BROWSER checks='+results.length+' failures='+report.failures.length);process.exitCode=report.failures.length?1:0;
})().catch(e=>{console.error(e);process.exit(1)});
