const {chromium}=require('playwright');
const fs=require('fs'),path=require('path'),{pathToFileURL,fileURLToPath}=require('url');
const root=path.resolve(__dirname,'../../art/concepts/field-audio-v1');
(async()=>{
 let checks=0;const failures=[];const check=(ok,label)=>{checks++;if(!ok)failures.push(label)};
 const browser=await chromium.launch({channel:'chrome',headless:true});
 try{
  const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto(pathToFileURL(path.join(root,'inspector.html')).href);
  check(await page.locator('article').count()===57,'All assets represented');
  check(await page.locator('audio').evaluateAll(a=>a.every(x=>x.paused&&!x.autoplay)),'No autoplay');
  await page.locator('audio').evaluateAll(a=>a.forEach(x=>{x.muted=true;x.load()}));
  await page.waitForFunction(()=>[...document.querySelectorAll('audio')].every(a=>a.readyState>=1&&Number.isFinite(a.duration)));
  check(true,'All audio metadata decodes');
  for(const src of await page.locator('audio').evaluateAll(a=>a.map(x=>x.src)))check(fs.existsSync(fileURLToPath(src)),'Audio source exists');
  const categories=await page.locator('#category option').evaluateAll(a=>a.map(x=>x.value));
  for(const category of categories){
   await page.selectOption('#category',category);
   const result=await page.locator('article').evaluateAll(a=>a.filter(x=>!x.hidden).map(x=>x.dataset.category));
   check(result.length>0&&(!category||result.every(x=>x===category)),'Role filter '+(category||'all'));
  }
  await page.selectOption('#category','');
  await page.locator('audio[aria-label="Field sound sampler"]').evaluate(a=>a.play());
  check(await page.locator('audio[aria-label="Field sound sampler"]').evaluate(a=>!a.paused),'Actual muted sampler playback');
  await page.locator('audio[aria-label="Below the Sluice complete score"]').evaluate(a=>a.play());
  check(await page.locator('audio[aria-label="Field sound sampler"]').evaluate(a=>a.paused),'Starting score pauses other player');
  check(await page.locator('audio[aria-label="Below the Sluice complete score"]').evaluate(a=>a.loop&&Math.abs(a.duration-72)<.01),'Complete score and loop control');
  await page.locator('audio').evaluateAll(a=>a.forEach(x=>x.pause()));
  for(const [width,height] of [[1280,720],[1278,590],[852,393],[667,375]]){
   await page.setViewportSize({width,height});
   check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Phone/desktop width '+width);
   check(await page.locator('select').evaluate(e=>e.getBoundingClientRect().height>=44),'Touch filter '+width);
  }
  for(const href of await page.locator('a').evaluateAll(a=>a.map(x=>x.href)))check(fs.existsSync(fileURLToPath(href)),'Local listening/handoff link');
  check(!errors.length,'No page errors');
  await page.screenshot({path:path.join(root,'browser-phone.png'),fullPage:true});
 }finally{await browser.close()}
 fs.writeFileSync(path.join(root,'browser-validation.json'),JSON.stringify({checks,failures,physical_iphone_tested:false},null,2)+'\n');
 console.log('FIELD_AUDIO_BROWSER',checks,'checks;',failures.length,'failures');if(failures.length)process.exitCode=1;
})();
