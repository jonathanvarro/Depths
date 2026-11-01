const {chromium}=require('C:/Users/jonat/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const path=require('path'), fs=require('fs'), {pathToFileURL}=require('url');
(async()=>{
 const dir=path.resolve(__dirname,'../../art/concepts/character-3d-trial-v1');
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:900}});
 const failures=[], errors=[];let checks=0;
 const check=(ok,label)=>{checks++;if(!ok)failures.push(label)};
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(dir,'inspector.html')).href);
 for(const view of ['standing','portrait','seated','reading','back']){
  await page.selectOption('#capture',view);
  for(const sample of ['0','1','2']){
   await page.selectOption('#sample',sample);
   await page.locator('#selected').evaluate(img=>img.decode());
   check(await page.locator('#selected').evaluate(img=>img.complete&&img.naturalWidth>0),'Decoded '+view+sample);
   check((await page.locator('#selected').getAttribute('src'))===`${view}-${sample}.png`,'Selection '+view+sample);
  }
 }
 for(const width of [1280,736,360]){
  await page.setViewportSize({width,height:900});
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+width);
 }
 check(errors.length===0,'No JavaScript errors');
 const report={checks,failures,errors};fs.writeFileSync(path.join(dir,'browser-report.json'),JSON.stringify(report,null,2));
 console.log(JSON.stringify(report));await browser.close();process.exitCode=failures.length?1:0;
})().catch(e=>{console.error(e);process.exitCode=1});
