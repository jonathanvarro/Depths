const fs=require('fs');
const path=require('path');
const {pathToFileURL,fileURLToPath}=require('url');
const {chromium}=require('playwright');
(async()=>{
 const directory=path.join(process.argv[2]||process.cwd(),'art/concepts/mine-polish-v2');
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const failures=[];let checks=0;
 try{
  const page=await browser.newPage();
  page.on('pageerror',error=>failures.push(error.message));
  await page.goto(pathToFileURL(path.join(directory,'inspector.html')).href);
  const count=await page.locator('option').count();
  for(let index=0;index<count;index++){
   await page.selectOption('#view',{index});
   await page.waitForFunction(()=>{const image=document.querySelector('#preview');return image.complete&&image.naturalWidth>0});
   checks++;
  }
  for(const href of await page.locator('a').evaluateAll(nodes=>nodes.map(node=>node.href))){checks++;if(!fs.existsSync(fileURLToPath(href)))failures.push('Missing '+href)}
  const report={checks,captures:count,failures};
  fs.writeFileSync(path.join(directory,'browser-validation.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report));
 }finally{await browser.close()}
 process.exitCode=failures.length?1:0;
})().catch(error=>{console.error(error);process.exitCode=1});
