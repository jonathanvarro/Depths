// Verify real image decoding, reference comparison and phone-width controls.
const {chromium}=require('playwright'),fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
(async()=>{
 const out=path.resolve(__dirname,'../../art/concepts/reference-creatures-v1'),cat=JSON.parse(fs.readFileSync(path.join(out,'catalog.json'),'utf8'));
 const browser=await chromium.launch({channel:'chrome',headless:true}),page=await browser.newPage({viewport:{width:1280,height:900}}),results=[],errors=[];
 const check=(ok,name)=>results.push({check:name,ok:!!ok});page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);await page.evaluate(()=>window.artReadyPromise);
 check(await page.locator('#gallery article').count()===5,'Five complete concept paintings');
 for(const e of cat.entries){
  await page.selectOption('#study',e.id);await page.evaluate(()=>window.viewReady);
  check(await page.locator('#art').evaluate(i=>i.naturalWidth===1024&&i.naturalHeight===1536),'Full concept decodes '+e.id);
  await page.check('#compare');check(await page.locator('#reference-panel').isVisible()&&await page.locator('#reference').evaluate(i=>i.complete&&i.naturalWidth>0),'Correct supplied reference loads '+e.id);
 }
 await page.click('#next');await page.evaluate(()=>window.viewReady);check(await page.inputValue('#study')==='veiled-sovereign','Next wraps through set');await page.click('#prev');await page.evaluate(()=>window.viewReady);check(await page.inputValue('#study')==='ribbound-wraith','Previous wraps through set');
 await page.locator('[data-id="pale-hollow"] button').click();await page.evaluate(()=>window.viewReady);check(await page.inputValue('#study')==='pale-hollow','Comparison card selects concept');
 for(const width of [1280,844,390]){await page.setViewportSize({width,height:width===844?390:900});
  for(const compare of [false,true]){await page.locator('#compare').setChecked(compare);check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Layout fits '+width+'/'+compare)}
  check(await page.locator('button:visible,select:visible').evaluateAll(xs=>xs.every(x=>x.getBoundingClientRect().height>=44)),'44px controls '+width);
  await page.screenshot({path:path.join(out,'inspector-'+width+'.png'),fullPage:true});
 }
 await page.setViewportSize({width:1400,height:1000});await page.locator('#gallery').screenshot({path:path.join(out,'comparison.png')});
 check(errors.length===0,'No browser errors');const failed=results.filter(r=>!r.ok).length;
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({issue:153,checks:results.length,failed,errors,scope:'Offline concept review, not live game or production validation',results},null,2)+'\n');
 await browser.close();console.log(`REFERENCE_CREATURE_BROWSER: ${results.length} checks, ${failed} failed`);if(failed)process.exitCode=1;
})().catch(e=>{console.error(e);process.exit(1)});
