/* Local review QA only; no player files, live application or visible browser. */
const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const {pathToFileURL,fileURLToPath}=require('node:url');
const root=path.resolve(__dirname,'../..');
const out=path.join(root,'art/concepts/descent-completion-v1');
let checks=0;
const failures=[];
function check(ok,label){checks++;if(!ok)failures.push(label);}
(async()=>{
  const browser=await chromium.launch({channel:'chrome',headless:true});
  try{
    const context=await browser.newContext({viewport:{width:1440,height:900}});
    const page=await context.newPage();
    const errors=[];page.on('pageerror',e=>errors.push(e.message));
    await page.goto(pathToFileURL(path.join(out,'inspector.html')).href);
    await page.waitForFunction(()=>Array.from(document.images).every(i=>i.complete));
    check((await page.locator('#brews h2').textContent()).includes('six shapes × six colours × six marks'),'UTF-8 headings');
    check(await page.locator('#glyphs .glyph').count()===28,'28 glyph pairs');
    check(await page.locator('#thumbs .thumb').count()===26,'26 journal silhouettes');
    check(await page.locator('#mastery-samples .badge').count()===3,'Three corner mastery stages');
    const images=await page.locator('img').evaluateAll(all=>all.map(i=>({src:i.src,w:i.naturalWidth})));
    for(const i of images)check(i.w>0,'Image loads '+i.src.split('/').pop());
    for(const href of await page.locator('a').evaluateAll(all=>all.map(a=>a.href))){
      const u=new URL(href);if(u.hash)continue;
      check(u.protocol==='file:'&&fs.existsSync(fileURLToPath(u)),'Local link '+u.pathname);
    }
    await page.locator('#anchors').click();
    check(await page.locator('#concept').evaluate(e=>e.classList.contains('show-anchors')),'Camp targets toggle');
    check(await page.locator('#concept .anchor').count()===5,'Five proposed targets');
    await page.locator('#concept').screenshot({path:path.join(out,'review-overlook-desktop.png')});
    await page.locator('#anchors').click();
    for(const value of await page.locator('#world option').evaluateAll(all=>all.map(o=>o.value))){
      await page.locator('#world').selectOption(value);
      await page.waitForFunction(()=>document.getElementById('world-picture').complete);
      check(await page.locator('#world-picture').evaluate(i=>i.naturalWidth>0),'World selector '+value);
    }
    for(const value of await page.locator('#painting option').evaluateAll(all=>all.map(o=>o.value))){
      await page.locator('#painting').selectOption(value);
      await page.waitForFunction(()=>document.getElementById('painting-picture').complete);
      check(await page.locator('#painting-picture').evaluate(i=>i.naturalWidth>0),'Painting selector '+value);
    }
    for(let s=0;s<6;s++){
      await page.locator('#shape').selectOption(String(s));
      await page.locator('#colour').selectOption(String(5-s));
      await page.locator('#mark').selectOption(String(s));
      check(await page.locator('#brew-native').getAttribute('data-appearance')===`${s}:${5-s}:${s}:`,'Composed selection '+s);
    }
    for(const kind of ['restorative','caustic','slumber','frenzy','revealing']){
      await page.locator('#known').selectOption(kind);
      check((await page.locator('#brew-big').getAttribute('data-appearance')).endsWith(':'+kind),'Identification label '+kind);
    }
    await page.locator('#brew-background').click();await page.locator('#grey').click();
    check(await page.locator('#brew-native').evaluate(e=>e.classList.contains('paper')),'Parchment comparison');
    check(await page.locator('#brew-row').evaluate(e=>e.classList.contains('greyscale')),'Greyscale comparison');
    await page.locator('#grey').click();await page.locator('#brew-background').click();
    await page.locator('#known').selectOption('');
    await page.locator('#brews').screenshot({path:path.join(out,'review-brews-desktop.png')});
    for(let i=0;i<6;i++){
      await page.locator('#splash-frame').selectOption(String(i));
      await page.waitForFunction(()=>document.getElementById('splash').complete);
      check(await page.locator('#splash').evaluate(e=>e.naturalWidth===64),'Splash held frame '+i);
    }
    await page.locator('#play-splash').click();await page.waitForTimeout(200);
    await page.locator('#play-splash').click();
    for(const [width,height] of [[1440,900],[1278,590],[844,390]]){
      await page.setViewportSize({width,height});
      check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No horizontal overflow '+width);
      const small=await page.locator('#brew-small').boundingBox();
      check(small.width===32&&small.height===32,'Phone icon32 '+width);
      const glyph=await page.locator('.glyph .tiny').first().boundingBox();
      check(glyph.width===20&&glyph.height===20,'Glyph20 '+width);
      await page.locator('.journal-page').screenshot({path:path.join(out,`review-journal-${width}.png`)});
      if(width===844)await page.locator('#concept').screenshot({path:path.join(out,'review-overlook-phone.png')});
    }
    const touch=await browser.newContext({viewport:{width:844,height:390},hasTouch:true});
    const phone=await touch.newPage();await phone.goto(pathToFileURL(path.join(out,'inspector.html')).href);
    await phone.locator('#anchors').tap();
    check(await phone.locator('#concept').evaluate(e=>e.classList.contains('show-anchors')),'Touch camp target toggle');
    await touch.close();check(errors.length===0,'No browser script errors: '+errors.join(', '));
  }finally{await browser.close();}
  fs.writeFileSync(path.join(out,'browser-validation.json'),JSON.stringify({checks,failures,viewports:[[1440,900],[1278,590],[844,390]],physical_iphone_tested:false},null,2)+'\n');
  console.log(`DESCENT_BROWSER: ${checks} checks, ${failures.length} failures`);
  if(failures.length){console.error(failures);process.exitCode=1;}
})().catch(e=>{console.error(e);process.exitCode=1;});
