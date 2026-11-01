const {chromium}=require('C:/Users/jonat/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const path=require('path'),fs=require('fs'),{pathToFileURL}=require('url');
(async()=>{
 const dir=path.resolve(__dirname,'../../art/concepts/character-lowpoly-v1');
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:900}});
 const failures=[],errors=[];let checks=0;
 function check(ok,label){checks++;if(!ok)failures.push(label)}
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(dir,'inspector.html')).href);
 for(const view of ['figure','portrait','seated','reading']){
  await page.selectOption('#view',view);
  for(const outfit of ['0','1','2']){
   await page.selectOption('#outfit',outfit);
   await page.locator('#selected').evaluate(i=>i.decode());
   check(await page.locator('#selected').getAttribute('src')===`${view}-${outfit}.png`,'Correct model state');
  }
 }
 for(const value of await page.locator('#detail option').evaluateAll(o=>o.map(x=>x.value))){
  await page.selectOption('#detail',value);await page.locator('#detail-image').evaluate(i=>i.decode());
  check(await page.locator('#detail-image').evaluate(i=>i.naturalWidth>0),'Detail '+value);
 }
 for(const width of [1280,736,360]){
  await page.setViewportSize({width,height:900});
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No overflow '+width);
 }
 for(const href of await page.locator('a').evaluateAll(a=>a.map(x=>x.getAttribute('href'))))check(fs.existsSync(path.resolve(dir,href)),'Link '+href);
 check(errors.length===0,'No JS errors');
 const report={checks,failures,errors};fs.writeFileSync(path.join(dir,'browser-report.json'),JSON.stringify(report,null,2));
 console.log(JSON.stringify(report));await browser.close();process.exitCode=failures.length?1:0;
})().catch(e=>{console.error(e);process.exitCode=1});
