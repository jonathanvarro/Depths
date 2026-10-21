const {chromium}=require('playwright');
const fs=require('fs');
const path=require('path');
const root=path.resolve(__dirname,'../..');
const out=path.join(root,'art/concepts/landmarks-v1');
const url='file:///'+path.join(out,'inspector.html').replaceAll('\\','/');
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true,args:['--allow-file-access-from-files']});
 const page=await browser.newPage();
 const errors=[];let checks=0;
 page.on('pageerror',e=>errors.push(String(e)));
 function check(ok,name){checks++;if(!ok)throw Error(name)}
 await page.goto(url);
 await page.locator('.library img').last().waitFor();
 await page.waitForFunction(()=>[...document.images].every(i=>i.complete&&i.naturalWidth>0));
 check(await page.locator('[data-asset]').count()===14,'Fourteen assets');
 await page.locator('#pause').click();
 check(await page.locator('#pause').textContent()==='Play','Pause');
 const first=await page.locator('#frame').textContent();
 await page.locator('#step').click();
 check(await page.locator('#frame').textContent()!==first,'Step toggles imported native glow frame');
 await page.locator('#used').click();
 check(await page.locator('#asset-title').textContent()==='Shrine Offerings Used','Resolved offerings');
 await page.locator('#fresh').click();
 await page.locator('#glow').uncheck();
 check(!await page.locator('#glow').isChecked(),'Optional glow off');
 for(const id of ['miners-shrine','miners-shrine-used','fallen-banner','root-curtain-a','cache-spilled-grain']){
  await page.locator(`[data-asset="${id}"]`).click();
  check(await page.locator(`[data-asset="${id}"]`).getAttribute('aria-pressed')==='true','Select '+id);
 }
 for(const view of [{width:1280,height:720},{width:1278,height:590},{width:844,height:390}]){
  await page.setViewportSize(view);
  await page.locator('[data-asset="shrine-offerings"]').click();
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+view.width);
  check(await page.locator('button').evaluateAll(bs=>bs.every(b=>b.getBoundingClientRect().height>=44)),'Touch targets '+view.width);
  for(const room of ['roots','cache','shrine-fresh','shrine-used','shrine-glow-off','map']){
   await page.locator('#room').selectOption(room);
   await page.waitForFunction(()=>document.querySelector('#room-image').complete&&document.querySelector('#room-image').naturalWidth>0);
   check(await page.locator('#room-image').evaluate(i=>i.naturalWidth>0),'Mounted image '+room+' '+view.width);
  }
  await page.locator('#room').selectOption('shrine-fresh');
  await page.screenshot({path:path.join(out,'browser-'+view.width+'.png'),fullPage:true});
 }
 check(errors.length===0,'No browser errors');
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,errors,viewports:['1280x720','1278x590','844x390']},null,2)+'\n');
 console.log('LANDMARK_BROWSER checks='+checks+' errors='+errors.length);
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
