const { chromium }=require('playwright');
const path=require('path');
const fs=require('fs');
const {pathToFileURL}=require('url');
const root=path.resolve(__dirname,'../..');
const out=path.join(root,'art/concepts/cave-dressing-v1');
const failures=[];let checks=0;const captures=[];
function check(ok,label){checks++;if(!ok)failures.push(label)}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 for(const [tag,width,height]of[['desktop',1280,720],['phone',1278,590]]){
  const page=await browser.newPage({viewport:{width,height}});
  page.on('pageerror',error=>failures.push(String(error)));
  await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);
  await page.waitForFunction(()=>window.reviewState&&Array.from(cache.values()).every(i=>i.complete&&i.naturalWidth));
  await page.locator('#play').click();
  await page.waitForFunction(()=>!reviewState.running);
  check(!(await page.evaluate(()=>reviewState.running)),'Pause '+tag);
  let before=await page.evaluate(()=>reviewState.frame);
  await page.locator('#step').click();
  check(await page.evaluate(n=>reviewState.frame===(n+1)%reviewState.count,before),'Step exactly one '+tag);
  for(const [id,name]of[['darkness','darkness'],['eyes-unknown','eyes'],['wall-flame','torch'],['fungus-pulse','fungus']]){
   await page.locator('#asset').selectOption(id);
   await page.waitForFunction(()=>Array.from(cache.values()).every(i=>i.complete&&i.naturalWidth));
   await page.locator('#zoom').selectOption(id==='eyes-unknown'?'4':'2');
   for(let i=0;i<3;i++)await page.locator('#step').click();
   check(await page.evaluate(()=>reviewState.frame===3),'Selected frame 4 '+id+tag);
   const file=`inspector-${name}-${tag}.png`;await page.screenshot({path:path.join(out,file)});captures.push(file);
   const count=await page.evaluate(()=>reviewState.count);
   for(let i=0;i<count;i++)await page.locator('#step').click();
   check(await page.evaluate(()=>reviewState.frame===3),'Complete loop wraps '+id+tag);
  }
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+tag);
  check(await page.locator('button').evaluateAll(buttons=>buttons.every(b=>b.getBoundingClientRect().height>=44)),'44px review controls '+tag);
  await page.close();
 }
 await browser.close();
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,failures,captures},null,2)+'\n');
 console.log(`CAVE_INSPECTOR checks=${checks} failures=${failures.length}`);
 if(failures.length){console.error(failures);process.exitCode=1}
})().catch(error=>{console.error(error);process.exitCode=1});
