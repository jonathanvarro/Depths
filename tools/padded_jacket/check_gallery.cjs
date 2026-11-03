// #220: real local gallery states, local links and landscape touch sizing.
const fs=require('fs'),path=require('path');
const {pathToFileURL,fileURLToPath}=require('url');
const {chromium}=require('playwright');
const workspace=process.argv[2];if(!workspace)throw Error('Pass the shared workspace');
const out=path.join(workspace,'build/local-padded-jacket-v2'),review=path.join(out,'review');
let checks=0;const check=(ok,label)=>{checks++;if(!ok)throw Error(label)};
let activeBrowser;
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 activeBrowser=browser;
 const page=await browser.newPage({viewport:{width:1440,height:900}});const errors=[];
 page.on('pageerror',e=>errors.push(String(e)));
 await page.goto(pathToFileURL(path.join(review,'inspector.html')).href);
 async function loaded(){await page.waitForFunction(()=>[...document.querySelectorAll('.model')].every(i=>i.complete&&i.naturalWidth>0));const images=await page.locator('.model').evaluateAll(a=>a.map(i=>({src:i.getAttribute('src'),width:i.naturalWidth})));for(const im of images){check(fs.existsSync(path.join(review,im.src))&&im.width>0,'Real native image '+im.src)}}
 for(const outfit of ['jacket','tunic']){
  await page.locator(`[data-outfit="${outfit}"]`).click();check(await page.locator(`[data-outfit="${outfit}"]`).getAttribute('aria-pressed')==='true','Selected outfit');
  for(const view of ['detail','figure']){
   await page.locator('#view').selectOption(view);
   for(const pose of view==='detail'?['walk']:['walk','sit_down','seated','stand_up','rest','dying']){
    if(view==='figure')await page.locator('#pose').selectOption(pose);
    for(const angle of ['0','1','2','3']){await page.locator('#angle').selectOption(angle);await loaded();}
   }
  }
 }
 for(const href of await page.locator('a[href]').evaluateAll(a=>a.map(x=>x.href))){check(href.startsWith('file:'),'Local-only gallery link');check(fs.existsSync(fileURLToPath(href)),'Existing review link '+href)}
 await page.locator('[data-outfit="jacket"]').click();await page.locator('#view').selectOption('detail');await page.locator('#angle').selectOption('1');await loaded();
 await page.screenshot({path:path.join(review,'gallery-desktop.png'),fullPage:true});
 for(const shape of [{width:1278,height:590},{width:852,height:393},{width:667,height:375}]){
  await page.setViewportSize(shape);check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No sideways overflow '+shape.width);
  for(const box of await page.locator('button:visible,select:visible').evaluateAll(a=>a.map(x=>{const r=x.getBoundingClientRect();return {w:r.width,h:r.height}}))){check(box.h>=44&&box.w>=44,'Touch-size gallery control')}
  await page.screenshot({path:path.join(review,`gallery-${shape.width}.png`),fullPage:true});
 }
 check(!errors.length,'No gallery script errors');await browser.close();
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,failures:[],errors},null,2)+'\n');console.log('JACKET_BROWSER',checks,'checks, 0 failures');
})().catch(async e=>{console.error(e);if(activeBrowser)await activeBrowser.close();process.exitCode=1});
