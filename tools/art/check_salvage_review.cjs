const {chromium}=require('playwright');
const fs=require('node:fs'),path=require('node:path');
const {pathToFileURL,fileURLToPath}=require('node:url');
const root=path.resolve(__dirname,'../..'),out=path.join(root,'art/concepts/salvage-v1');
let checks=0;const failures=[];
function check(ok,label){checks++;if(!ok)failures.push(label);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 try{
  const context=await browser.newContext({viewport:{width:1440,height:900}});
  const page=await context.newPage(),errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);
  await page.waitForFunction(()=>Array.from(document.images).every(i=>i.complete));
  check(await page.locator('.card').count()===7,'Seven actual items');
  for(const image of await page.locator('img').evaluateAll(all=>all.map(i=>({w:i.naturalWidth,src:i.src}))))check(image.w>0,'Image '+image.src.split('/').pop());
  for(const href of await page.locator('a').evaluateAll(all=>all.map(a=>a.href))){const u=new URL(href);check(u.protocol==='file:'&&fs.existsSync(fileURLToPath(u)),'Source/handoff '+u.pathname);}
  for(const size of [128,64,40,32]){
   const rect=await page.locator(`.samples img[width="${size}"]`).first().boundingBox();check(rect.width===size&&rect.height===size,'Display size '+size);
  }
  await page.locator('#paper').click();check(await page.locator('#paper').getAttribute('aria-pressed')==='true','Parchment toggle');
  await page.locator('#grey').click();check(await page.locator('body').evaluate(e=>e.classList.contains('grey')),'Greyscale toggle');
  await page.locator('#grey').click();await page.locator('#paper').click();
  for(const name of await page.locator('#capture option').evaluateAll(all=>all.map(o=>o.value))){await page.locator('#capture').selectOption(name);await page.waitForFunction(()=>document.getElementById('shot').complete);check(await page.locator('#shot').evaluate(i=>i.naturalWidth>0),'Native view '+name);}
  for(const width of [1440,1278,844,667]){
   await page.setViewportSize({width,height:width>1000?900:390});
   check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+width);
   for(const id of ['paper','grey'])check((await page.locator('#'+id).boundingBox()).height>=44,'Control44 '+id+' '+width);
  }
  await page.setViewportSize({width:1278,height:590});
  await page.locator('.cards').screenshot({path:path.join(out,'browser-cards-1278.png')});
  const touch=await browser.newContext({viewport:{width:844,height:390},hasTouch:true});const phone=await touch.newPage();
  await phone.goto(pathToFileURL(path.join(out,'inspector.html')).href);await phone.locator('#paper').tap();
  check(await phone.locator('#paper').getAttribute('aria-pressed')==='true','Phone tap comparison');await touch.close();
  check(errors.length===0,'No gallery script errors '+errors.join(', '));
 }finally{await browser.close();}
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,failures,viewports:[1440,1278,844,667],physical_iphone_tested:false},null,2)+'\n');
 console.log(`SALVAGE_BROWSER: ${checks} checks, ${failures.length} failures`);if(failures.length){console.error(failures);process.exitCode=1;}
})().catch(e=>{console.error(e);process.exitCode=1;});
