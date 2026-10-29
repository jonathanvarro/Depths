// Headless offline review checks; never opens a user browser/window.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
(async()=>{
 const out=path.resolve('art/concepts/wounded-keeper-v1');
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:850}});
 const failures=[],errors=[];let checks=0;
 page.on('pageerror',e=>errors.push(e.message));
 const check=(ok,label)=>{checks++;if(!ok)failures.push(label)};
 await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);
 await page.waitForSelector('body[data-ready="true"]');
 const wait=async text=>page.waitForFunction(t=>document.querySelector('#status').textContent.includes(t),text);
 check((await page.locator('#status').innerText()).startsWith('Paused'),'Paused on opening');
 const sig=()=>page.locator('#current').evaluate(c=>c.toDataURL());
 for(const id of ['neutral','pained','defiant']){
  await page.selectOption('#who',id);await wait(id+' · Rest');
  const seen=[];
  for(let n=0;n<5;n++){
   await page.locator('[data-frame="'+n+'"]').click();await wait(['Rest','Half lid','Closed','Small mouth','Open mouth'][n]);
   seen.push(await sig());
   check(await page.locator('[data-frame="'+n+'"]').getAttribute('aria-pressed')==='true',id+' held '+n);
  }
  check(new Set(seen).size===5,id+' five distinct held drawings');
  await page.check('#bare');await page.waitForFunction(()=>document.querySelector('#selected').textContent==='Clean plate');
  check(!seen.includes(await sig()),id+' clean face has features removed');
  await page.uncheck('#bare');
  for(const light of ['warm','dim','neutral']){
   await page.selectOption('#light',light);
   await page.waitForTimeout(80);
   check(await page.locator('#light').inputValue()===light,id+' light '+light);
  }
 }
 await page.selectOption('#who','map-reading');await wait('Static pose');
 for(const selector of ['#prev','#next','#play','#bare','[data-frame="2"]'])check(await page.locator(selector).isDisabled(),'Static disables '+selector);
 const map=await sig();await page.keyboard.press('ArrowRight');await page.waitForTimeout(200);check(await sig()===map,'Map keyboard does not borrow animation');
 await page.selectOption('#who','neutral');await wait('neutral · Rest');
 await page.locator('#play').click();await wait('Playing');check(await page.locator('#play').getAttribute('aria-pressed')==='true','Play state');
 await page.locator('#play').click();await wait('Paused');const held=await sig();await page.waitForTimeout(400);check(await sig()===held,'Pause holds pixels');
 for(const width of [1280,844,390]){
  await page.setViewportSize({width,height:850});
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),width+' no horizontal overflow');
  check(await page.locator('button').first().evaluate(e=>e.getBoundingClientRect().height>=44),width+' touch control height');
 }
 await page.setViewportSize({width:1280,height:1000});
 await page.screenshot({path:path.join(out,'browser-review.png'),fullPage:true});
 check(errors.length===0,'No browser errors');
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,failures,errors,physical_iphone_test:false},null,2)+'\n');
 await browser.close();console.log({checks,failures,errors});if(failures.length)process.exitCode=1;
})().catch(e=>{console.error(e);process.exitCode=1});
