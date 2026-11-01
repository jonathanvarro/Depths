/* File-safe #190 artwork review checks, with a headless browser. */
const {chromium}=require('playwright');
const fs=require('node:fs'),path=require('node:path');
const {pathToFileURL,fileURLToPath}=require('node:url');
const root=path.resolve(__dirname,'../..'),out=path.join(root,'art/concepts/overlook-v1');
let checks=0;const failures=[];
function check(ok,label){checks++;if(!ok)failures.push(label);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 try{
  const context=await browser.newContext({viewport:{width:1440,height:1000},reducedMotion:'reduce'});
  const page=await context.newPage(),errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);
  await page.waitForFunction(()=>Array.from(document.images).every(i=>i.complete));
  check(await page.locator('#screen').evaluate(e=>e.classList.contains('still')),'Reduced motion starts still');
  check(await page.locator('#poses .pose').count()===5,'Five companion activities');
  for(const item of await page.locator('img').evaluateAll(all=>all.map(i=>({src:i.src,w:i.naturalWidth}))))check(item.w>0,'Image '+item.src.split('/').pop());
  for(const href of await page.locator('a').evaluateAll(all=>all.map(a=>a.href))){const url=new URL(href);check(url.protocol==='file:'&&fs.existsSync(fileURLToPath(url)),'Local handoff '+url.pathname);}
  check(await page.locator('.target:visible').count()===5,'Provisioned targets');
  for(const id of ['stash','fire','survey','mine','onward']){
   await page.locator(`.target[data-id=${id}]`).click();check(await page.locator('#selection').getAttribute('data-target')===id,'Mouse selection '+id);
   check(await page.locator('#caption').isVisible(),'Caption visible '+id);
  }
  await page.locator('.target[data-id=stash]').focus();await page.keyboard.press('Enter');check(await page.locator('#selection').getAttribute('data-target')==='stash','Keyboard selection');
  await page.locator('#state').selectOption('discovered');check(await page.locator('.target:visible').count()===2,'Bare routes only');
  check(await page.locator('#art .layer:not(.hidden)').count()===0,'Bare terrain has no furnishings/people');
  await page.locator('#state').selectOption('connected');await page.locator('#party').selectOption('none');
  for(const id of ['corin equipment','mara warming','alwen reading','fixer planning','mara relaxing'])check(await page.locator(`#art img[alt="${id}"]`).evaluate(e=>e.classList.contains('hidden')),'No assumed person '+id);
  await page.locator('#party').selectOption('planning');
  check(await page.locator('#art img[alt="mara warming"]').evaluate(e=>e.classList.contains('hidden')),'Only one Mara activity');
  check(await page.locator('#art img[alt="mara relaxing"]').isVisible(),'Relaxing activity');
  await page.locator('input[data-site=survey]').uncheck();check(await page.locator('.target[data-id=survey]').isHidden(),'Absent table has no target');
  check(await page.locator('#art img[alt="fixer planning"]').isHidden(),'Planner follows table');
  await page.locator('input[data-site=survey]').check();
  await page.locator('input[data-site=shelter]').uncheck();check(await page.locator('#art img[alt="mara relaxing"]').isHidden(),'Resting follows shelter');
  check(await page.locator('#art img[alt=lantern]').isHidden(),'Lantern follows shelter');await page.locator('input[data-site=shelter]').check();
  await page.locator('#fire').uncheck();check(await page.locator('#art .flame').isHidden(),'Cold fire');await page.locator('#fire').check();
  await page.locator('input[data-site=firepit]').uncheck();check(await page.locator('.target[data-id=fire]').isHidden(),'Absent pit has no target');
  check(await page.locator('#art img[alt="corin equipment"]').isHidden(),'Equipment pose follows seat');await page.locator('input[data-site=firepit]').check();
  await page.locator('#reference').check();check(await page.locator('.target:visible').count()===0,'Reference comparison has no stray targets');await page.locator('#reference').uncheck();
  await page.locator('#motion').check();check(await page.locator('#screen').evaluate(e=>!e.classList.contains('still')),'Motion enabled');await page.locator('#motion').uncheck();
  for(const value of await page.locator('#capture option').evaluateAll(all=>all.map(o=>o.value))){await page.locator('#capture').selectOption(value);await page.waitForFunction(()=>document.getElementById('capture-image').complete);check(await page.locator('#capture-image').evaluate(i=>i.naturalWidth>0),'Native capture '+value);}
  await page.locator('#party').selectOption('starting');await page.locator('#state').selectOption('provisioned');
  for(const width of [1440,1278,844,667]){
   await page.setViewportSize({width,height:width>1000?900:390});await page.locator('#large').check();
   check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+width);
   const rects=await page.locator('.target:visible').evaluateAll(all=>all.map(b=>({id:b.dataset.id,x:b.offsetLeft,y:b.offsetTop,w:b.offsetWidth,h:b.offsetHeight})));
   for(const r of rects)check(r.w>=44&&r.h>=44,'Target44 '+width+' '+r.id);
   for(let i=0;i<rects.length;i++)for(let j=i+1;j<rects.length;j++){const a=rects[i],b=rects[j];check(a.x+a.w<=b.x||b.x+b.w<=a.x||a.y+a.h<=b.y||b.y+b.h<=a.y,'Separate targets '+width+' '+a.id+'/'+b.id);}
   await page.locator('#screen').screenshot({path:path.join(out,`browser-${width}.png`)});
  }
  const touch=await browser.newContext({viewport:{width:844,height:390},hasTouch:true,reducedMotion:'reduce'});
  const phone=await touch.newPage();await phone.goto(pathToFileURL(path.join(out,'inspector.html')).href);
  await phone.locator('.target[data-id=stash]').tap();check(await phone.locator('#selection').getAttribute('data-target')==='stash','Phone tap stash');
  await phone.locator('.target[data-id=onward]').tap();check(await phone.locator('#selection').getAttribute('data-target')==='onward','Phone tap departure');await touch.close();
  check(errors.length===0,'No script errors '+errors.join(', '));
 }finally{await browser.close();}
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,failures,viewports:[1440,1278,844,667],has_touch_review:true,physical_iphone_tested:false},null,2)+'\n');
 console.log(`OVERLOOK_BROWSER: ${checks} checks, ${failures.length} failures`);if(failures.length){console.error(failures);process.exitCode=1;}
})().catch(e=>{console.error(e);process.exitCode=1;});
