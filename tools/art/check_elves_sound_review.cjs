// Offline browser interaction checks. Audio is muted in this test browser only.
const {chromium}=require('playwright'),fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
(async()=>{
 const root=path.resolve(__dirname,'../..'),art=path.join(root,'art/concepts/elves-v1'),sound=path.join(root,'art/concepts/sound-v1');
 const browser=await chromium.launch({channel:'chrome',headless:true,args:['--allow-file-access-from-files']}),page=await browser.newPage({viewport:{width:1280,height:900}});
 let results=[],errors=[];const check=(ok,name)=>results.push({check:name,ok:!!ok});page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(art,'inspector.html')).href);await page.evaluate(()=>window.artReadyPromise);
 check(await page.locator('#sources a').count()===5,'Five retained masters and exact prompts');
 for(const face of ['elf-man','elf-woman']){
  await page.selectOption('#face',face);
  for(const eyes of ['neutral','half','closed'])for(const mouth of ['neutral','small','open','round']){
   await page.selectOption('#eyes',eyes);await page.selectOption('#mouth',mouth);await page.evaluate(()=>window.portraitReady);
   check(await page.locator('#portrait').evaluate(c=>c.width===192&&c.height===192&&c.getContext('2d').getImageData(90,90,1,1).data[3]>0),`Full native composition ${face}/${eyes}/${mouth}`);
  }
  const drawn=await page.locator('#portrait').evaluate(c=>c.toDataURL());await page.check('#bare');await page.evaluate(()=>window.portraitReady);
  check(await page.locator('#portrait').evaluate(c=>c.toDataURL())!==drawn,'Clean plate removes features '+face);
  await page.uncheck('#bare');await page.evaluate(()=>window.portraitReady);
  check(await page.locator('#card').evaluate(c=>c.width===96&&c.height===96),'Native96 card '+face);
 }
 const held=await page.locator('#portrait').evaluate(c=>c.toDataURL());await page.waitForTimeout(700);
 check(await page.locator('#portrait').evaluate(c=>c.toDataURL())===held,'Paused drawing stays fixed');
 await page.click('#step');await page.evaluate(()=>window.portraitReady);check(await page.locator('#portrait').evaluate(c=>c.toDataURL())!==held,'Step changes a held frame');
 await page.click('#play');check(await page.evaluate(()=>elfState.playing),'Playback starts');await page.click('#play');check(!await page.evaluate(()=>elfState.playing),'Playback pauses');
 for(const bg of ['stone','linen','dark']){await page.selectOption('#backdrop',bg);check(await page.locator('#portrait-stage').getAttribute('data-bg')===bg,'Contrast backdrop '+bg)}
 for(const capture of ['runtime-held-192','runtime-held-96','runtime-lighting']){await page.selectOption('#portrait-shot',capture);await page.locator('#portrait-capture').evaluate(i=>i.decode());check(await page.locator('#portrait-capture').evaluate(i=>i.naturalWidth>600),'Actual portrait capture '+capture)}
 await page.screenshot({path:path.join(art,'inspector-portraits-desktop.png'),fullPage:true});
 await page.click('#combat-tab');check(await page.locator('#combat').isVisible()&&!await page.locator('#portraits').isVisible(),'Combat tab switches');
 for(const pose of ['idle','attack','hurt'])for(const size of ['phone','desktop']){
  await page.selectOption('#pose',pose);await page.evaluate(()=>window.poseReady);await page.selectOption('#combat-size',size);await page.evaluate(()=>window.poseReady);
  check(await page.locator('#sprite').evaluate(i=>i.naturalWidth===128&&i.naturalHeight===128),'Native pose '+pose+size);
  check(await page.locator('#combat-capture').evaluate(i=>i.naturalWidth>=1278),'Actual combat view '+pose+size);
 }
 const pose=await page.inputValue('#pose');await page.click('#pose-step');await page.evaluate(()=>window.poseReady);check(await page.inputValue('#pose')!==pose,'Step pose works');
 await page.screenshot({path:path.join(art,'inspector-combat-desktop.png'),fullPage:true});
 for(const width of [844,390]){await page.setViewportSize({width,height:width===844?390:844});for(const tab of ['portrait','combat']){
  await page.click('#'+tab+'-tab');if(tab==='combat')await page.evaluate(()=>window.poseReady);
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+tab+width);
  check(await page.locator('button:visible,select:visible').evaluateAll(xs=>xs.every(x=>x.getBoundingClientRect().height>=44)),'44px controls '+tab+width);
  await page.screenshot({path:path.join(art,'inspector-'+tab+'-'+width+'.png'),fullPage:true});
 }}
 check(errors.length===0,'No art browser errors');let total=results.length,failed=results.filter(r=>!r.ok).length;
 fs.writeFileSync(path.join(art,'browser-validation.json'),JSON.stringify({issue:131,checks:results.length,failed,errors,results},null,2)+'\n');
 results=[];errors=[];await page.setViewportSize({width:1280,height:900});await page.goto(pathToFileURL(path.join(sound,'inspector.html')).href);await page.evaluate(()=>window.artReadyPromise);await page.locator('#player').evaluate(p=>p.muted=true);
 const catalog=JSON.parse(fs.readFileSync(path.join(root,'audio/dark-v1/catalog.json'),'utf8'));
 check(await page.locator('.sound-card').count()===30,'Thirty complete sound cards');check(await page.locator('.wave').evaluateAll(xs=>xs.every(x=>x.complete&&x.naturalWidth===400)),'All real waveform plots decode');
 for(const entry of catalog.assets){
  await page.locator(`[data-id="${entry.id}"] button`).click();await page.evaluate(()=>window.playReady);
  const state=await page.locator('#player').evaluate(p=>({duration:p.duration,playing:!p.paused,muted:p.muted,error:!!p.error}));
  check(state.playing&&state.muted&&!state.error&&Math.abs(state.duration-entry.seconds)<.01,'Native WAV browser playback '+entry.id);
  await page.click('#stop');check(await page.locator('#player').evaluate(p=>p.paused&&p.currentTime===0),'Stop/reset '+entry.id);
 }
 for(const group of ['combat','items','camp','fortress','all']){
  await page.selectOption('#filter',group);
  check(await page.locator('.sound-card:visible').evaluateAll(xs=>xs.length>0&&xs.every(x=>!x.hidden)),'Filter visible '+group);
  if(group!=='all')check(await page.locator('.sound-card:visible').evaluateAll((xs,g)=>xs.every(x=>x.dataset.group===g),group),'Filter membership '+group);
 }
 await page.check('#loop');await page.locator('[data-id="camp-ambience-loop"] button').click();await page.evaluate(()=>window.playReady);check(await page.locator('#player').evaluate(p=>p.loop&&!p.paused),'Ambience repeats on request');await page.click('#stop');
 await page.locator('[data-id="hit-1"] button').click();await page.evaluate(()=>window.playReady);check(await page.locator('#player').evaluate(p=>!p.loop),'One shot never inherits repeat');await page.click('#stop');
 await page.click('#reel');await page.evaluate(()=>window.playReady);check(await page.locator('#player').evaluate((p,seconds)=>Math.abs(p.duration-seconds)<.01&&!p.loop,catalog.audition.seconds),'Complete reel plays its registered duration');await page.click('#stop');
 await page.locator('#volume').fill('0.2');check(await page.locator('#player').evaluate(p=>Math.abs(p.volume-.2)<.01),'Listening volume control');
 for(const width of [1280,844,390]){
  await page.setViewportSize({width,height:width===844?390:900});
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No sound-gallery overflow '+width);
  check(await page.locator('button:visible,select:visible,input[type=range]:visible').evaluateAll(xs=>xs.every(x=>x.getBoundingClientRect().height>=44)),'44px sound controls '+width);
  await page.screenshot({path:path.join(sound,'inspector-'+width+'.png'),fullPage:true});
 }
 check(errors.length===0,'No sound browser errors');const soundFailed=results.filter(r=>!r.ok).length;total+=results.length;failed+=soundFailed;
 fs.writeFileSync(path.join(sound,'browser-validation.json'),JSON.stringify({issues:[96,99],checks:results.length,failed:soundFailed,errors,results},null,2)+'\n');
 await browser.close();console.log(`ELVES_SOUND_BROWSER: ${total} checks, ${failed} failed`);if(failed)process.exitCode=1;
})().catch(e=>{console.error(e);process.exit(1)});
