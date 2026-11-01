const {chromium}=require('C:/Users/jonat/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const path=require('path'),fs=require('fs'),{pathToFileURL}=require('url');
(async()=>{
 const dir=path.resolve(__dirname,'../../build/local-fbx-trial/review');
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:900}});
 let checks=0;const failures=[],errors=[];
 const check=(ok,label)=>{checks++;if(!ok)failures.push(label)};
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(dir,'inspector.html')).href);
 for(const value of await page.locator('#view option').evaluateAll(xs=>xs.map(x=>x.value))){
  await page.selectOption('#view',value);await page.locator('#selected').evaluate(i=>i.decode());
  check(await page.locator('#selected').getAttribute('src')===value+'.png','Selected '+value);
 }
 for(const width of [1280,736,360]){
  await page.setViewportSize({width,height:900});
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No overflow '+width);
 }
 for(const href of await page.locator('a').evaluateAll(xs=>xs.map(x=>x.getAttribute('href'))))check(fs.existsSync(path.resolve(dir,href)),'Local link '+href);
 await page.locator('img[src="seated-motion.gif"]').evaluate(i=>i.decode());check(true,'Motion GIF decodes');
 check(errors.length===0,'No JS errors');
 const report={checks,failures,errors};fs.writeFileSync(path.join(dir,'browser-report.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));
 await browser.close();process.exitCode=failures.length?1:0;
})().catch(e=>{console.error(e);process.exitCode=1});
