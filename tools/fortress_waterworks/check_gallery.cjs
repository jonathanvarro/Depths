const fs=require('fs');
const path=require('path');
const {pathToFileURL}=require('url');
const {chromium}=require('playwright');

async function run() {
    const folder=path.join(process.argv[2],'build/local-fortress-waterworks-v1');
    const browser=await chromium.launch({channel:'chrome',headless:true});
    const failures=[];
    let checks=0;
    const check=(ok,text)=>{checks++; if(!ok) failures.push(text);};
    try {
        const page=await browser.newPage();
        page.on('pageerror',error=>failures.push(error.message));
        await page.goto(pathToFileURL(path.join(folder,'inspector.html')).href);
        for(const light of ['cave','neutral']) {
            await page.locator('#light').selectOption(light);
            for(const angle of ['0','1','2']) {
                await page.locator('#angle').selectOption(angle);
                for(const state of ['closed','open','empty']) {
                    await page.locator('#state').selectOption(state);
                    await page.waitForFunction(()=>Array.from(document.images).every(image=>image.complete && image.naturalWidth>0));
                    check(await page.locator('[data-name] img').count()===10,'Ten real native model captures');
                }
            }
        }
        for(const phase of ['0','25','50','75','100']) {
            await page.locator('#phase').fill(phase);
            await page.locator('#phase').dispatchEvent('input');
            await page.waitForFunction(()=>Array.from(document.images).every(image=>image.complete && image.naturalWidth>0));
            check(await page.locator('#phase-value').textContent()===phase+'%','Paused pose selection');
        }
        for(const batch of ['fortress','waterworks','all']) {
            await page.locator('#batch').selectOption(batch);
            check(await page.locator('section:visible').count()===(batch==='all'?2:1),'Batch filtering');
        }
        await page.locator('#state').selectOption('closed');
        await page.locator('#light').selectOption('cave');
        await page.locator('#angle').selectOption('0');
        for(const viewport of [{width:1280,height:720},{width:852,height:393},{width:667,height:375}]) {
            await page.setViewportSize(viewport);
            check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow');
            check(await page.locator('select,input').evaluateAll(items=>items.every(item=>item.getBoundingClientRect().height>=44)),'44px touch selectors');
            await page.screenshot({path:path.join(folder,'gallery-'+viewport.width+'.png'),fullPage:true});
        }
        fs.writeFileSync(path.join(folder,'browser-validation.json'),JSON.stringify({checks,failures},null,2)+'\n');
        console.log('FORTRESS_WATERWORKS_BROWSER',checks,'failures',failures.length);
        if(failures.length) process.exitCode=1;
    } finally { await browser.close(); }
}
run().catch(error=>{console.error(error); process.exitCode=1;});
