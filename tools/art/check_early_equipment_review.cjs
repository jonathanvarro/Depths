// #194/#195: local review controls, image/source links and landscape layouts.
const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const {pathToFileURL,fileURLToPath}=require('node:url');
const root=path.resolve(__dirname,'../..');
const review=path.join(root,'art/concepts/early-equipment-v1');
let activeBrowser;
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 activeBrowser=browser;
 const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 let checks=0;const check=(ok,label)=>{checks++;if(!ok)throw Error(label);};
 await page.goto(pathToFileURL(path.join(review,'inspector.html')).href);
 for(const shape of [{width:1440,height:1000},{width:1278,height:590},{width:844,height:390}]){
  await page.setViewportSize(shape);
  for(const region of ['cave-mine','goblin-territory']){
   await page.selectOption('#region',region);
   check(await page.locator('#grid .card').count()===11,'Eleven regional choices');
   for(const size of ['128','64','32']){
    await page.selectOption('#size',size);
    for(const bg of ['dark','paper']){
     await page.selectOption('#background',bg);
     for(const treatment of ['colour','grey','silhouette']){
      await page.selectOption('#treatment',treatment);
      await page.waitForFunction(()=>[...document.images].every(i=>i.complete&&i.naturalWidth>0));
      check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow');
      check(await page.locator('#grid img').first().evaluate(i=>Math.abs(i.getBoundingClientRect().width-Number(document.querySelector('#size').value))<1),'Exact requested review size');
     }
    }
   }
   for(const card of await page.locator('#grid .card').all()){
    const name=await card.locator('span').first().textContent();await card.click();
    check(await page.locator('#name').textContent()===name,'Card selects correct drawing');
    check(await page.locator('#large').getAttribute('alt')===name,'Selected image has readable name');
    const master=await page.locator('#master').evaluate(a=>a.href);
    check(fs.existsSync(fileURLToPath(master)),'Source master link exists');
    const rect=await card.boundingBox();check(rect.width>=44&&rect.height>=44,'Mouse/touch choice target');
   }
  }
 }
 for(const href of await page.locator('main > p.links a').evaluateAll(a=>a.map(n=>n.href)))check(fs.existsSync(fileURLToPath(href)),'Handoff/provenance link exists');
 check(errors.length===0,'No browser errors');
 await page.setViewportSize({width:1278,height:800});await page.selectOption('#region','goblin-territory');await page.selectOption('#size','128');await page.selectOption('#background','dark');await page.selectOption('#treatment','colour');
 await page.screenshot({path:path.join(review,'browser-review.png'),fullPage:true});
 fs.writeFileSync(path.join(review,'browser-validation.json'),JSON.stringify({checks,failures:[],viewports:[[1440,1000],[1278,590],[844,390]],physical_iPhone:false},null,2)+'\n');
 await browser.close();console.log(`EARLY_EQUIPMENT_REVIEW: ${checks} checks, no failures`);
})().catch(async error=>{console.error(error);process.exitCode=1;if(activeBrowser)await activeBrowser.close();});
