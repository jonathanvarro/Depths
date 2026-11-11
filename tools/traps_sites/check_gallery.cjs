const fs=require('fs'),path=require('path'),{pathToFileURL}=require('url'),{chromium}=require('playwright');
async function run(){
 const folder=path.join(process.argv[2],'build/local-traps-sites-mist-v1'),failures=[];
 let checks=0;const check=(ok,label)=>{checks++;if(!ok)failures.push(label);};
 const browser=await chromium.launch({channel:'chrome',headless:true});
 try{
  const page=await browser.newPage();page.on('pageerror',e=>failures.push(e.message));
  await page.goto(pathToFileURL(path.join(folder,'inspector.html')).href);
  async function loaded(){await page.waitForFunction(()=>Array.from(document.images).every(i=>i.complete&&i.naturalWidth>0));}
  for(const light of ['cave','neutral']){
   await page.locator('#light').selectOption(light);
   for(const angle of ['0','1','2']){
    await page.locator('#angle').selectOption(angle);
    for(const state of ['closed','open','empty']){
     await page.locator('#state').selectOption(state);await loaded();
     check(await page.locator('[data-name] img').count()===7,'Seven native state cards load');
    }
   }
  }
  for(const room of ['0','1']){
   await page.locator('#room').selectOption(room);
   for(const fog of ['mist','clear','drift','low-light','resolved']){
    await page.locator('#fog').selectOption(fog);await loaded();check(true,'Room comparison loads');
   }
  }
  for(const batch of ['traps','sites','all']){
   await page.locator('#batch').selectOption(batch);check(await page.locator('section:visible').count()===(batch==='all'?2:1),'Batch filtering');
  }
  await page.locator('#play').click();await loaded();check(await page.locator('#motion').isVisible(),'Native mist preview');await page.locator('#play').click();
  await page.locator('#state').selectOption('closed');await page.locator('#angle').selectOption('0');await page.locator('#light').selectOption('cave');
  await page.locator('#room').selectOption('1');await page.locator('#fog').selectOption('mist');
  for(const viewport of [{width:1280,height:720},{width:852,height:393},{width:667,height:375}]){
   await page.setViewportSize(viewport);check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow');
   check(await page.locator('select,button').evaluateAll(items=>items.every(i=>i.getBoundingClientRect().height>=44)),'Touch targets');
   await page.screenshot({path:path.join(folder,'gallery-'+viewport.width+'.png'),fullPage:true});
  }
  fs.writeFileSync(path.join(folder,'browser-validation.json'),JSON.stringify({checks,failures},null,2)+'\n');
  console.log('TRAPS_SITES_BROWSER',checks,'failures',failures.length);if(failures.length)process.exitCode=1;
 }finally{await browser.close();}
}
run().catch(e=>{console.error(e);process.exitCode=1;});
