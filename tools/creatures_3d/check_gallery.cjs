const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
const { chromium } = require('playwright');

async function checkGallery() {
  const folder = path.resolve(process.argv[2]);
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 1278, height: 590 } });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('requestfailed', request => errors.push(request.url()));
    await page.goto(pathToFileURL(path.join(folder, 'inspector.html')).href);
    let images = 0;
    async function verifyImage(selector, suffix) {
      const source = await page.locator(selector).evaluate(async image => {
        await image.decode();
        return image.getAttribute('src');
      });
      assert.ok(source.endsWith(suffix), source);
      images += 1;
    }

    await verifyImage('img[alt^="Three spiders"]', 'spider-family.png');
    await verifyImage('img[alt^="Existing rat"]', 'rat-goblin-scale.png');
    const ids = ['spider', 'webspinner', 'venom-spider', 'goblin'];
    for (const id of ids) {
      const button = page.locator(`[data-id="${id}"]`);
      await button.click();
      assert.equal(await button.getAttribute('aria-pressed'), 'true');
      const poses = await page.locator('#pose option').evaluateAll(options => options.map(option => option.value));
      assert.equal(poses.length, id === 'goblin' ? 4 : 7);
      for (const pose of poses) {
        await page.selectOption('#pose', pose);
        await page.selectOption('#view', '0');
        await page.locator('#time').focus();
        await page.keyboard.press('Home');
        for (const sample of [0, 25, 50, 75, 100]) {
          await verifyImage('#main', `${id}-${pose}-0-${sample}.png`);
          await page.click('#next');
        }
        await page.click('#prev');
        await verifyImage('#main', `${id}-${pose}-0-75.png`);
        for (const view of ['1', '2']) {
          await page.selectOption('#view', view);
          assert.ok(await page.locator('#time').isDisabled());
          await verifyImage('#main', `${id}-${pose}-${view}.png`);
        }
      }
      for (const [width, height] of [[1278, 590], [852, 393], [667, 375]]) {
        await page.setViewportSize({ width, height });
        await page.selectOption('#screen', String(width));
        for (const pose of ['idle', 'attack', 'hurt', 'fall']) {
          await page.selectOption('#livepose', pose);
          await verifyImage('#live', `${id}-steady-${pose}-${width}.png`);
        }
        assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      }
      await verifyImage('#dark', `${id}-band0-idle-852.png`);
      await verifyImage('#bright', `${id}-band3-idle-852.png`);
      await verifyImage('#first', `${id}-first-person-1278.png`);
    }
    await page.check('#gray');
    assert.equal(await page.locator('#main').evaluate(image => getComputedStyle(image).filter), 'grayscale(1)');
    await page.uncheck('#gray');
    assert.deepEqual(errors, []);
    const report = { creatures: ids.length, decodedImages: images, widths: [1278, 852, 667], errors };
    await fs.writeFile(path.join(folder, 'browser-validation.json'), `${JSON.stringify(report, null, 2)}\n`);
    console.log(report);
  } finally {
    await browser.close();
  }
}

checkGallery().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
