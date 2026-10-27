const {chromium}=require('playwright'),fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
(async()=>{
 const root=path.resolve(__dirname,'../..'),out=path.join(root,'art/concepts/interface/journal-settings-v1'),results=[],errors=[];
 const catalog=JSON.parse(fs.readFileSync(path.join(out,'catalog.json'),'utf8'));
 const browser=await chromium.launch({channel:'chrome',headless:true}),page=await browser.newPage({viewport:{width:1280,height:900}});
 const check=(ok,label)=>{results.push({ok,label});if(!ok)throw new Error(label)};
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);
 check(await page.locator('#view option').count()===catalog.captures.length,'Every recorded capture selectable');
 for(let i=0;i<catalog.captures.length;i++){await page.selectOption('#view',String(i));await page.locator('#render').evaluate(i=>i.decode());check(await page.locator('#render').evaluate(i=>i.naturalWidth>=844),'Capture decodes '+catalog.captures[i])}
 for(const button of await page.locator('[data-view]').all()){const target=await button.getAttribute('data-view');await button.click();check((await page.locator('#render').getAttribute('src'))===target,'Quick review '+target)}
 for(const width of [1280,844,390]){await page.setViewportSize({width,height:850});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Review fits '+width)}
 check(errors.length===0,'No browser errors');
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks:results.length,failures:results.filter(r=>!r.ok),results},null,2)+'\n');
 await browser.close();console.log('MENU_REVIEW_BROWSER: '+results.length+' checks pass');
})().catch(e=>{console.error(e);process.exit(1)});
