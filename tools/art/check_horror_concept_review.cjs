// Checks actual decoded sheets, review controls and responsive layout.
const {chromium}=require('playwright'),fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
(async()=>{
 const root=path.resolve(__dirname,'../..'),out=path.join(root,'art/concepts/descent-horror-v1'),cat=JSON.parse(fs.readFileSync(path.join(out,'catalog.json'),'utf8'));
 const browser=await chromium.launch({channel:'chrome',headless:true}),page=await browser.newPage({viewport:{width:1280,height:900}}),results=[],errors=[];
 const check=(ok,name)=>results.push({check:name,ok:!!ok});page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);await page.evaluate(()=>window.artReadyPromise);
 check(await page.locator('.concept-card').count()===10,'Ten concept drafts');check(await page.locator('#sources>details').count()===13,'Thirteen exact prompts and original masters');
 for(const e of cat.entries){
  await page.selectOption('#concept',e.id);await page.evaluate(()=>window.viewReady);
  check((await page.locator('#selection').textContent()).includes(e.id==='underhound'?'Selected first for production':'Production selection pending'),'Production status '+e.id);
  check(await page.locator('#art').evaluate(i=>i.naturalWidth===1536&&i.naturalHeight===1024),'Original sheet decodes '+e.id);
  for(const view of ['sheet','main','state','omen','small']){
   await page.selectOption('#view',view);await page.evaluate(()=>window.viewReady);
   check(await page.locator('#stage').evaluate(s=>s.clientHeight>0&&s.querySelector('img').complete),'Usable region '+e.id+'/'+view);
  }
 }
 await page.click('#next');await page.evaluate(()=>window.viewReady);check(await page.inputValue('#concept')==='underhound','Next wraps through full set');await page.click('#previous');await page.evaluate(()=>window.viewReady);check(await page.inputValue('#concept')==='sleeper-beyond','Previous wraps through full set');
 for(const [batch,count]of [['150',3],['151',4],['152',3],['all',10]]){
  await page.click(`[data-batch="${batch}"]`);await page.evaluate(()=>window.viewReady);
  check(await page.locator('.concept-card:visible').count()===count&&await page.locator('#concept option').count()===count,'Batch membership '+batch);
 }
 for(const id of ['drowned-bell','sleeper-beyond']){
  await page.selectOption('#concept',id);await page.evaluate(()=>window.viewReady);
  check(await page.locator('#variant-label').isVisible(),'Revision comparison available '+id);
  check((await page.locator('#art').getAttribute('src')).endsWith('-revised.png'),'Revised draft is default '+id);
  await page.selectOption('#variant','previous');await page.evaluate(()=>window.viewReady);
  check((await page.locator('#art').getAttribute('src'))===id+'.png','Previous draft still loads '+id);
  await page.selectOption('#variant','current');await page.evaluate(()=>window.viewReady);
  check((await page.locator('#title').textContent()).includes('revised'),'Current draft labelled '+id);
 }
 await page.locator('[data-id="underhound"] button').click();await page.evaluate(()=>window.viewReady);check(await page.inputValue('#concept')==='underhound','Comparison card selects full artwork');
 check(!await page.locator('#variant-label').isVisible(),'Unchanged concepts have no misleading revision control');
 await page.selectOption('#view','sheet');await page.evaluate(()=>window.viewReady);
 for(const width of [1280,844,390]){
  await page.setViewportSize({width,height:width===844?390:900});await page.evaluate(()=>window.scrollTo(0,0));
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+width);
  check(await page.locator('button:visible,select:visible').evaluateAll(xs=>xs.every(x=>x.getBoundingClientRect().height>=44)),'44px controls '+width);
  await page.screenshot({path:path.join(out,'inspector-'+width+'.png'),fullPage:true});
  for(const id of ['drowned-bell','sleeper-beyond']){
   await page.selectOption('#concept',id);await page.evaluate(()=>window.viewReady);
   check(await page.locator('#variant').isVisible()&&await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Revision comparison fits '+id+'/'+width);
  }
 }
 await page.setViewportSize({width:1280,height:900});await page.locator('#gallery').screenshot({path:path.join(out,'comparison.png')});
 check(errors.length===0,'No browser script errors');const failed=results.filter(r=>!r.ok).length;
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({issues:[150,151,152],checks:results.length,failed,errors,scope:'Offline concept gallery, not live game or animation validation',results},null,2)+'\n');
 await browser.close();console.log(`HORROR_CONCEPT_BROWSER: ${results.length} checks, ${failed} failed`);if(failed)process.exitCode=1;
})().catch(e=>{console.error(e);process.exit(1)});
