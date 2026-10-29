const {chromium}=require('playwright'),fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
const out=path.resolve(__dirname,'../../art/concepts/drowned-water-v1');let checks=0;const failures=[],errors=[];
function check(ok,label){checks++;if(!ok)failures.push(label);}
(async()=>{const browser=await chromium.launch({channel:'chrome',headless:true});
for(const [name,width,height] of [['desktop',1280,900],['landscape',844,390],['narrow',390,844]]){
 const context=await browser.newContext({viewport:{width,height},hasTouch:true}),page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);const q=s=>page.locator(s);
 check(await q('#view option').count()===16,name+' sixteen actual renderer views');
 await q('#open').tap();check((await q('#wheel').getAttribute('src')).endsWith('sluice-open.png'),name+' open state');
 await q('#closed').tap();check(await q('#closed').getAttribute('aria-pressed')==='true',name+' closed state');
 for(const value of ['192','96']){await q('#scale').selectOption(value);check(await q('#wheel').evaluate(e=>e.getBoundingClientRect().width)===+value,name+' native display '+value);}
 const views=await q('#view option').evaluateAll(options=>options.map(o=>o.value));
 for(const file of views){await q('#view').selectOption(file);await q('#render').evaluate(im=>im.decode());check(await q('#render').evaluate(im=>im.naturalWidth>1000&&im.naturalHeight>=590),name+' decode '+file);}
 await q('#motion').tap();check(await q('#motion').getAttribute('aria-pressed')==='true',name+' motion capture plays');await q('#movie').evaluate(im=>im.decode());
 await q('#motion').tap();check((await q('#movie').getAttribute('src')).endsWith('motion-still.png'),name+' motion pauses');
 check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),name+' no horizontal overflow');
 check(await page.evaluate(()=>[...document.querySelectorAll('button,select')].every(e=>e.getBoundingClientRect().height>=44)),name+' touch targets');
 check(await page.evaluate(()=>[...document.images].every(im=>im.complete&&im.naturalWidth>0)),name+' all images decode');
 await page.screenshot({path:path.join(out,'browser-'+name+'.png'),fullPage:true});await context.close();
}await browser.close();check(errors.length===0,'No browser errors');fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,failures,errors,captures:3},null,2)+'\n');console.log({checks,failures,errors});if(failures.length)process.exitCode=1;})();
