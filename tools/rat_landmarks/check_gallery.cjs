const {chromium}=require('playwright');
const fs=require('fs');
const {pathToFileURL}=require('url');
const root='E:/GitHub/Depths/build/local-rat-landmarks-v1';
(async()=>{
const browser=await chromium.launch({channel:'chrome',headless:true});
const page=await browser.newPage({viewport:{width:1280,height:900}});
let checks=0;const errors=[];
page.on('pageerror',e=>errors.push(String(e)));
function check(ok,label){checks++;if(!ok)throw new Error(label)}
await page.goto(pathToFileURL(root+'/inspector.html').href);
async function loaded(id){await page.waitForFunction(id=>{let i=document.getElementById(id);return i.complete&&i.naturalWidth>0},id);check(true,'Image '+id)}
await loaded('main');await loaded('live');
for(const asset of ['rat','defiled-shrine','fouled-well','buried-cache']){
 await page.locator(`[data-asset="${asset}"]`).click();await loaded('main');
 check(await page.locator(`[data-asset="${asset}"]`).getAttribute('aria-pressed')==='true','Selection '+asset);
 if(asset==='rat'){
  for(const pose of ['idle','attack','hurt','fall','walk','run']){await page.selectOption('#pose',pose);await page.fill('#time','4');await loaded('main');}
  await page.locator('#back').click();check(await page.inputValue('#time')==='3','Previous frame');
  await page.locator('#next').click();check(await page.inputValue('#time')==='4','Next frame');
 }else{await page.selectOption('#state','empty');await page.selectOption('#light','neutral');await loaded('main');}
 for(const view of ['1','2']){await page.selectOption('#view',view);await loaded('main');}
}
for(const width of ['1278','852','667']){await page.selectOption('#screen',width);await loaded('live');}
for(const pose of ['attack','hurt','fall']){await page.selectOption('#livepose',pose);await loaded('live');}
await page.locator('[data-asset="rat"]').click();await page.selectOption('#view','0');await page.selectOption('#pose','idle');await page.fill('#time','0');await loaded('main');
await page.screenshot({path:root+'/browser-desktop.png',fullPage:true});
await page.setViewportSize({width:852,height:393});
check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No phone horizontal overflow');
await page.screenshot({path:root+'/browser-phone.png',fullPage:true});
check(errors.length===0,'No page exceptions');
fs.writeFileSync(root+'/browser-validation.json',JSON.stringify({checks,failures:errors},null,2)+'\n');
console.log('RAT_LANDMARK_BROWSER',checks,'failures',errors.length);
await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
