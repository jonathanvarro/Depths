// Paused native frame identity, playback controls and decoded combat captures.
const {chromium}=require('playwright'),fs=require('fs'),path=require('path'),http=require('http');
(async()=>{
 const root=path.resolve(__dirname,'../..'),out=path.join(root,'art/concepts/underhound-poses-v1'),results=[],errors=[];
 // Same-origin loopback serving lets canvas pixels be inspected without relaxing browser security.
 const server=http.createServer((request,response)=>{
   const file=path.resolve(root,'.'+decodeURIComponent(new URL(request.url,'http://localhost').pathname));
   if(!file.startsWith(root+path.sep)){response.writeHead(403);response.end();return}
   fs.readFile(file,(error,data)=>{
     if(error){response.writeHead(404);response.end();return}
     response.setHeader('Content-Type',({'.html':'text/html','.png':'image/png','.json':'application/json'})[path.extname(file)]||'application/octet-stream');
     response.end(data);
   });
 });
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const browser=await chromium.launch({channel:'chrome',headless:true}),page=await browser.newPage({viewport:{width:1280,height:900}});
 const check=(ok,label)=>{results.push({ok,label});if(!ok)throw new Error(label)};
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://127.0.0.1:'+server.address().port+'/art/concepts/underhound-poses-v1/inspector.html');await page.evaluate(()=>window.artReady);
 check(await page.evaluate(()=>!window.poseState.playing&&!window.poseState.ghost),'Starts paused with no duplicate idle layer');
 async function matches(name){return page.evaluate(async name=>{
   const image=new Image();image.src='../../enemies/underhound-v1/'+name+'.png';await image.decode();
   const canvas=document.createElement('canvas');canvas.width=canvas.height=128;const ctx=canvas.getContext('2d');ctx.drawImage(image,0,0);
   const expected=ctx.getImageData(0,0,128,128).data,actual=document.querySelector('#frame').getContext('2d').getImageData(0,0,128,128).data;
   return expected.every((v,i)=>v===actual[i]);
 },name)}
 for(const name of ['idle','attack','hurt','attack','idle']){
   await page.click('[data-pose="'+name+'"]');check(await matches(name),'Displayed pixels exactly match '+name);
 }
 await page.click('#next');check(await page.evaluate(()=>poseState.pose==='attack'&&!poseState.playing),'Next steps to paused attack');
 await page.click('#previous');check(await matches('idle'),'Previous restores clean idle');
 await page.click('[data-pose="hurt"]');await page.check('#ghost');check(!(await matches('hurt')),'Optional ghost is visibly distinct');
 await page.uncheck('#ghost');check(await matches('hurt'),'Disabling ghost removes all previous layers');
 for(const zoom of ['1','0.5','3']){await page.click('[data-zoom="'+zoom+'"]');check(await page.locator('#frame').evaluate((c,z)=>c.getBoundingClientRect().width===128*Number(z),zoom),'Exact pixel zoom '+zoom)}
 await page.click('#play');await page.waitForTimeout(1150);check(await page.evaluate(()=>poseState.playing),'Comparison plays');
 await page.click('#play');const paused=await page.evaluate(()=>poseState.pose);await page.waitForTimeout(650);
 check(await page.evaluate(p=>!poseState.playing&&poseState.pose===p,paused),'Pause holds an unchanged state');
 for(let i=0;i<12;i++){await page.selectOption('#capture',String(i));await page.locator('#render').evaluate(i=>i.decode());check(await page.locator('#render').evaluate(i=>i.naturalWidth>=1278),'Combat capture decodes '+i)}
 for(const width of [1280,844,390]){await page.setViewportSize({width,height:800});await page.click('[data-zoom="1"]');check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Page fits '+width)}
 check(errors.length===0,'No browser errors');
 fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks:results.length,failures:results.filter(r=>!r.ok),results,physical_iPhone:false},null,2)+'\n');
 await browser.close();await new Promise(resolve=>server.close(resolve));console.log('UNDERHOUND_BROWSER: '+results.length+' checks pass');
})().catch(e=>{console.error(e);process.exit(1)});
