const {chromium}=require('playwright'),fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
(async()=>{
 const root=path.resolve(__dirname,'../..'),out=path.join(root,'art/concepts/traps-lamps-v1'),results=[],errors=[];
 const browser=await chromium.launch({channel:'chrome',headless:true}),page=await browser.newPage({viewport:{width:1280,height:850}});
 const check=(ok,label)=>{results.push({ok,label});if(!ok)throw new Error(label)};
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);
 await page.locator('.grid img').evaluateAll(async images=>Promise.all(images.map(i=>i.decode())));
 check(await page.locator('.grid img').count()===8,'All four ready/used pairs decode');
 for(const size of [128,64,256]){await page.click('[data-zoom="'+size+'"]');check(await page.locator('.grid img').first().evaluate((im,s)=>im.getBoundingClientRect().width===s,size),'Exact zoom '+size)}
 await page.click('#light');check(await page.locator('body').evaluate(b=>b.classList.contains('light')),'Light backing toggles on');
 await page.click('#light');check(await page.locator('body').evaluate(b=>!b.classList.contains('light')),'Dark backing restored');
 for(let i=0;i<24;i++){await page.selectOption('#capture',String(i));await page.locator('#render').evaluate(i=>i.decode());check(await page.locator('#render').evaluate(i=>i.naturalWidth>=1278),'Actual room capture decodes '+i)}
 for(const width of [1280,844,390]){await page.setViewportSize({width,height:850});check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Page fits '+width)}
 check(errors.length===0,'No browser errors');
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks:results.length,failures:results.filter(r=>!r.ok),results,physical_iPhone:false},null,2)+'\n');
 await browser.close();console.log('TRAPS_LAMPS_BROWSER: '+results.length+' checks pass');
})().catch(e=>{console.error(e);process.exit(1)});
