const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const { chromium } = require('playwright');

async function run() {
    const output = path.join(process.argv[2], 'build/local-bone-decor-v1');
    const browser = await chromium.launch({ channel: 'chrome', headless: true });
    let checks = 0;
    const failures = [];
    function check(ok, message) {
        checks += 1;
        if (!ok) failures.push(message);
    }
    try {
        const page = await browser.newPage();
        page.on('pageerror', error => failures.push(error.message));
        await page.goto(pathToFileURL(path.join(output, 'inspector.html')).href);
        for (const light of ['cave', 'neutral']) {
            await page.locator('#light').selectOption(light);
            for (const angle of ['0', '1', '2', '3']) {
                await page.locator('#angle').selectOption(angle);
                await page.waitForFunction(() => Array.from(document.images).every(image => image.complete && image.naturalWidth > 0));
                check(await page.locator('article img').count() === 4, 'All four real captures loaded');
            }
        }
        await page.locator('#light').selectOption('cave');
        await page.locator('#angle').selectOption('0');
        for (const viewport of [{width:1280,height:720}, {width:852,height:393}, {width:667,height:375}]) {
            await page.setViewportSize(viewport);
            check(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'No sideways overflow');
            for (const box of await page.locator('select').evaluateAll(controls => controls.map(control => control.getBoundingClientRect().height))) {
                check(box >= 44, 'Touch-sized review selector');
            }
            await page.screenshot({path:path.join(output, 'gallery-' + viewport.width + '.png'), fullPage:true});
        }
        fs.writeFileSync(path.join(output, 'browser-validation.json'), JSON.stringify({checks,failures}, null, 2) + '\n');
        console.log('BONE_BROWSER', checks, 'failures', failures.length);
        if (failures.length) process.exitCode = 1;
    } finally {
        await browser.close();
    }
}
run().catch(error => { console.error(error); process.exitCode = 1; });
