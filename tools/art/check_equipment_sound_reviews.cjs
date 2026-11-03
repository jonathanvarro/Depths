// Gallery loading/readability/playback only. No app/player save lifecycle.
const {chromium}=require('playwright');
const fs=require('fs');
const root='E:/GitHub/Depths/';
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 let checks=0;const failures=[];
 const check=(ok,msg)=>{checks++;if(!ok)failures.push(msg)};
 for(const name of ['equipment-live-v1','galleries-audio-v1']){
  const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto('file:///'+root+'art/concepts/'+name+'/inspector.html');
  if(name==='equipment-live-v1'){
   check(await page.locator('article').count()===7,'Seven equipment entries');
   check(await page.locator('img').evaluateAll(imgs=>imgs.length===14&&imgs.every(i=>i.complete&&i.naturalWidth>0)),'All14 images loaded');
  }else{
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('audio')).every(a=>a.readyState>=1));
   check(await page.locator('audio').count()===11,'Eleven audio entries');
   for(let i=0;i<11;i++){
    const result=await page.locator('audio').nth(i).evaluate(async a=>{a.muted=true;await a.play();await new Promise(r=>setTimeout(r,90));const out={duration:a.duration,time:a.currentTime,error:a.error?.message};a.pause();return out});
    check(result.duration>1&&!result.error,'Decoded audio'+i);check(result.time>0,'Playback advances'+i);
   }
  }
  for(const [width,height] of [[1280,720],[852,393],[667,375]]){
   await page.setViewportSize({width,height});
   check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+name+width);
   check(await page.locator('article').evaluateAll(as=>as.every(a=>a.scrollWidth<=a.clientWidth)),'Card content fits '+name+width);
  }
  check(errors.length===0,'No script errors '+name);
  await page.screenshot({path:root+'art/concepts/'+name+'/browser-phone.png',fullPage:true});await page.close();
 }
 const result={checks,failures,headless_browser:true,physical_iphone:false};
 for(const name of ['equipment-live-v1','galleries-audio-v1'])fs.writeFileSync(root+'art/concepts/'+name+'/browser-validation.json',JSON.stringify(result,null,2)+'\n');
 await browser.close();console.log(JSON.stringify(result));if(failures.length)process.exitCode=1;
})();
