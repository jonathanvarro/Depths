const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const { chromium } = require('playwright');

async function run() {
    const workspace = process.argv[2];
    if (!workspace) throw new Error('Pass the shared workspace directory.');
    const output = path.join(workspace, 'build/prayer-stool-review-v1');
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
        for (const size of ['128', '64', '48']) {
            await page.locator('#size').selectOption(size);
            await page.waitForFunction(() => Array.from(document.images).every(image => image.complete && image.naturalWidth > 0));
            check(await page.locator('.item').count() === 4, 'Four inventory items');
            check(await page.locator('.marks img').count() === 5, 'Five prayer/status marks');
            const widths = await page.locator('.item').evaluateAll(images => images.map(image => image.getBoundingClientRect().width));
            check(widths.every(width => width === Number(size)), 'Requested display size');
        }
        await page.locator('#size').selectOption('64');
        for (const viewport of [{width: 1280, height: 720}, {width: 852, height: 393}, {width: 667, height: 375}]) {
            await page.setViewportSize(viewport);
            check(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'No sideways overflow');
            const selector = await page.locator('#size').boundingBox();
            check(selector.height >= 44, 'Touch-sized selector');
            await page.screenshot({path: path.join(output, 'gallery-' + viewport.width + '.png'), fullPage: true});
        }
        check(await page.locator('.capture').count() === 4, 'Four real native captures');
        const report = { checks, failures, physical_iphone: false };
        fs.writeFileSync(path.join(output, 'browser-validation.json'), JSON.stringify(report, null, 2) + '\n');
        console.log(JSON.stringify(report));
        if (failures.length) process.exitCode = 1;
    } finally {
        await browser.close();
    }
}
run().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
