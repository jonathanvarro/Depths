const {chromium}=require('playwright');
const fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
const out=path.resolve(__dirname,'../../art/concepts/fixer-v1');
let checks=0;const failures=[],errors=[];
function check(ok,message){checks++;if(!ok)failures.push(message);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 for(const [tag,width,height] of [['desktop',1280,900],['landscape',844,390],['narrow',390,844]]){
  const context=await browser.newContext({viewport:{width,height},hasTouch:true});
  const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));
  await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);
  const q=s=>page.locator(s);
  await q('#status').filter({hasText:'Paused · fixer-a · Neutral'}).waitFor();
  check(await q('#who option').count()===3,tag+' three faces');
  const resting=await q('#current').evaluate(c=>c.toDataURL());
  await page.waitForTimeout(350);
  check(resting===await q('#current').evaluate(c=>c.toDataURL()),tag+' starts paused');
  for(const id of ['fixer-a','fixer-b','fixer-c']){
   await q('#who').selectOption(id);await q('#status').filter({hasText:'Paused · '+id+' · Neutral'}).waitFor();
   check(await page.evaluate(async id=>{
    const img=new Image();img.src=DATA.assets[DATA.out+'/'+id+'/preview.png'];await img.decode();
    let c=document.createElement('canvas');c.width=c.height=192;c.getContext('2d').drawImage(img,0,0);
    let a=c.getContext('2d').getImageData(0,0,192,192).data,b=document.querySelector('#current').getContext('2d').getImageData(0,0,192,192).data;
    return a.every((v,i)=>v===b[i]);
   },id),tag+' '+id+' browser exactly restores native neutral');
   for(const frame of [1,2,3,4]){
    await q('[data-frame="'+frame+'"]').tap();await page.waitForTimeout(70);
    const neutral=await q('#neutral').evaluate(c=>c.toDataURL());
    check(neutral!==await q('#current').evaluate(c=>c.toDataURL()),tag+' '+id+' authored frame '+frame);
   }
   await q('#bare').check();await q('#selected').filter({hasText:'components hidden'}).waitFor();
   const clean=await q('#current').evaluate(c=>c.toDataURL());
   await q('[data-frame="2"]').tap();await page.waitForTimeout(70);
   check(clean===await q('#current').evaluate(c=>c.toDataURL()),tag+' '+id+' clean underlying face does not retain previous frame');
   await q('#bare').uncheck();
  }
  await q('#light').selectOption('warm');await q('#condition').selectOption('bandage');
  await page.waitForTimeout(120);const warm=await q('#current').evaluate(c=>c.toDataURL());
  await q('#light').selectOption('dim');await q('#condition').selectOption('pallor');
  await page.waitForTimeout(120);
  check(warm!==await q('#current').evaluate(c=>c.toDataURL()),tag+' independent light and condition controls');
  await q('#light').selectOption('neutral');await q('#condition').selectOption('');
  await q('#play').tap();await page.waitForTimeout(800);
  check((await q('#status').textContent()).startsWith('Playing'),tag+' explicit playback');
  await q('#next').tap();await page.waitForTimeout(70);
  check((await q('#status').textContent()).startsWith('Paused'),tag+' step pauses playback');
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),tag+' no horizontal overflow');
  check(await page.evaluate(()=>[...document.querySelectorAll('button,select')].every(e=>e.getBoundingClientRect().height>=44)),tag+' touch target size');
  check(await page.evaluate(()=>[...document.querySelectorAll('.cards canvas')].every(c=>c.getBoundingClientRect().width===96)),tag+' actual 96px card display');
  await q('#who').selectOption('fixer-a');await q('[data-frame="2"]').tap();await page.waitForTimeout(120);
  await page.screenshot({path:path.join(out,'browser-'+tag+'.png'),fullPage:true});
  check(await page.evaluate(()=>[...document.images].every(im=>im.complete&&im.naturalWidth>0)),tag+' all native renderer captures decode');
  await context.close();
 }
 await browser.close();check(errors.length===0,'No browser errors: '+errors.join(';'));
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,failures,errors,captures:3,paused_by_default:true},null,2)+'\n');
 console.log({checks,failures,errors});if(failures.length)process.exitCode=1;
})();
