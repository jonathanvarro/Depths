const {chromium}=require('playwright');
const path=require('path'),fs=require('fs'),{pathToFileURL}=require('url');
const root=path.resolve(__dirname,'../..'),out=path.join(root,'art/concepts/results-v1');
let checks=0;const failures=[];
function check(ok,label){checks++;if(!ok)failures.push(label)}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 for(const [tag,width,height]of[['desktop',1280,720],['phone',1278,590]]){
  const page=await browser.newPage({viewport:{width,height}});page.on('pageerror',error=>failures.push(String(error)));
  await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);
  await page.waitForFunction(()=>Array.from(cache.values()).every(im=>im.complete&&im.naturalWidth));
  await page.locator('[data-tab=portraits]').click();
  check(await page.evaluate(()=>!reviewState.running),'Initially paused '+tag);
  await page.locator('#step').click();check(await page.evaluate(()=>reviewState.frame===1),'One-step held frame '+tag);
  await page.locator('#pose').selectOption('2');await page.screenshot({path:path.join(out,'inspector-closed-'+tag+'.png')});
  await page.locator('#pose').selectOption('5');await page.screenshot({path:path.join(out,'inspector-round-'+tag+'.png')});
  await page.locator('#bare').check();check(await page.locator('#bare').isChecked(),'Bare clean plate control '+tag);await page.locator('#bare').uncheck();
  await page.locator('#light').selectOption('warm');await page.locator('#play').click();await page.waitForTimeout(220);
  check(await page.evaluate(()=>reviewState.running),'Playback starts '+tag);await page.locator('#play').click();let frame=await page.evaluate(()=>reviewState.frame);await page.waitForTimeout(220);check(await page.evaluate(f=>reviewState.frame===f,frame),'Pause holds exact frame '+tag);
  await page.locator('[data-tab=arrivals]').click();
  for(const kind of ['slash','smash','pierce','fire']){await page.locator('#effect').selectOption(kind);for(let i=0;i<3;i++)await page.locator('#fx-step').click();check(await page.evaluate(()=>reviewState.fx===3),'Effect frame4 '+kind+tag);await page.screenshot({path:path.join(out,'inspector-'+kind+'-'+tag+'.png')});}
  await page.locator('[data-tab=results]').click();await page.locator('#screen').selectOption('wipe-phone');await page.waitForFunction(()=>document.getElementById('capture').complete);check(await page.locator('#capture').getAttribute('src')==='wipe-phone.png','Wipe selection '+tag);
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+tag);
  check(await page.locator('button').evaluateAll(bs=>bs.filter(b=>b.getClientRects().length).every(b=>b.getBoundingClientRect().height>=44)),'44px visible controls '+tag);
  await page.close();
 }
 await browser.close();fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,failures},null,2)+'\n');console.log(`RESULTS_INSPECTOR checks=${checks} failures=${failures.length}`);if(failures.length){console.error(failures);process.exitCode=1}
})().catch(e=>{console.error(e);process.exitCode=1});
