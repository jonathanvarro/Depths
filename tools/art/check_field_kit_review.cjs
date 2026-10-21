const {chromium}=require('playwright');
const fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'../..'),out=path.join(root,'art/concepts/field-kit-v1');
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage();let checks=0;const errors=[];
 page.on('pageerror',e=>errors.push(String(e)));
 function check(ok,label){checks++;if(!ok)throw Error(label)}
 await page.goto('file:///'+path.join(out,'inspector.html').replaceAll('\\','/'));
 await page.waitForFunction(()=>[...document.images].every(i=>i.complete&&i.naturalWidth));
 check(await page.locator('#item-grid .asset').count()===8,'Eight inventory images');
 check(await page.locator('#symbol-grid .asset').count()===11,'Eleven effect images');
 for(const view of [{width:1280,height:720},{width:844,height:390}]){
  await page.setViewportSize(view);
  for(const tab of ['inventory','effects']){
   await page.locator('#'+tab).click();
   check(await page.locator('#'+tab).getAttribute('aria-pressed')==='true','Tab '+tab);
   check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No overflow '+view.width+' '+tab);
   await page.locator('#grey').check();await page.locator('#paper').check();
   check(await page.locator('body').evaluate(b=>b.classList.contains('greyscale')&&b.classList.contains('paper')),'Alternative contrast views');
   await page.screenshot({path:path.join(out,'browser-'+view.width+'-'+tab+'.png'),fullPage:true});
   await page.locator('#grey').uncheck();await page.locator('#paper').uncheck();
  }
 }
 for(const shape of ['phone','desktop']){
  await page.locator('#shape').selectOption(shape);
  for(const name of ['pack-leather-satchel','pack-oilcloth-cloak','pack-miners-pick','pack-antidote','party-symbols']){
   await page.locator('#capture').selectOption(name);
   await page.waitForFunction(()=>document.querySelector('#capture-image').complete&&document.querySelector('#capture-image').naturalWidth);
   check(await page.locator('#capture-image').evaluate(i=>i.naturalWidth>0),'Actual control capture '+name+' '+shape);
  }
 }
 check(errors.length===0,'No browser errors');
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,errors,viewports:['1280x720','844x390']},null,2)+'\n');
 console.log('FIELD_KIT_BROWSER checks='+checks+' errors='+errors.length);await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
