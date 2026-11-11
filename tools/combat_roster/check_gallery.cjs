const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
const { chromium } = require('playwright');

async function main() {
  const folder = path.resolve(process.argv[2]);
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 1278, height: 590 } });
    const errors = [];
    const decoded = new Set();
    page.on('pageerror', error => errors.push(error.message));
    page.on('requestfailed', request => errors.push(request.url()));
    async function image(selector) {
      decoded.add(await page.locator(selector).evaluate(async element => {
        await element.decode();
        return element.getAttribute('src');
      }));
    }
    await page.goto(pathToFileURL(path.join(folder, 'inspector.html')).href);
    await image('#pose-image');
    await image('#game-image');
    assert.match(await page.locator('#pose-image').getAttribute('src'), /goblin-queen-idle-0/);
    const buttons = page.locator('[data-asset]');
    assert.equal(await buttons.count(), 11);
    for (const button of await buttons.all()) {
      await button.click();
      assert.equal(await button.getAttribute('aria-pressed'), 'true');
      await page.selectOption('#view','quarter');
      const poses = await page.locator('#pose option').evaluateAll(options => options.map(option => option.value));
      for (const pose of poses) {
        await page.selectOption('#pose',pose);
        for (let frame = 0; frame <= 4; frame += 1) {
          await image('#pose-image');
          if (frame < 4) await page.click('#next');
        }
        assert.ok(await page.locator('#next').isDisabled());
        await page.click('#previous');
        assert.match(await page.locator('#pose-image').getAttribute('src'), /-3\.png$/);
      }
      await page.selectOption('#view','front');
      await image('#pose-image');
      const views = await page.locator('#game-view option').evaluateAll(options => options.map(option => option.value));
      for (const view of views) {
        await page.selectOption('#game-view',view);
        if (await page.locator('#width').isDisabled()) {
          await image('#game-image');
          continue;
        }
        for (const width of ['1278','852','667']) {
          await page.selectOption('#width',width);
          await image('#game-image');
        }
      }
    }
    for (const [width,height] of [[1278,590],[852,393],[667,375]]) {
      await page.setViewportSize({ width, height });
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      assert.ok(await page.locator('#next').evaluate(button => button.getBoundingClientRect().height >= 44));
    }
    for (let index = 0; index < 4; index += 1) await image('#comparison img >> nth=' + index);
    assert.deepEqual(errors,[]);
    const result = { assets: 11, distinctImages: decoded.size, widths: [1278,852,667], errors };
    await fs.writeFile(path.join(folder,'browser-validation.json'),JSON.stringify(result,null,2) + '\n');
    console.log(result);
  } finally {
    await browser.close();
  }
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
