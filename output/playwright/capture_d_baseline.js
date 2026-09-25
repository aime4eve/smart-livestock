const { chromium } = require('playwright');

const URL =
  'file:///Volumes/DEV/00-products-dev/01-solutions/02-smart-livestock/docs/prototypes/nix-246-fence-tab-redesign-prototype.html';

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 1600, height: 1200 },
    deviceScaleFactor: 2,
  });
  await page.goto(URL, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1200);
  await page.addStyleTag({
    content:
      '.rec-mark::after,.redo-mark::after,.new-mark::after,.keep-mark::after{display:none !important}',
  });

  const groups = page.locator('.screen-group');
  const count = await groups.count();
  const targets = [
    { label: '晨报台账 · 形状沙盘', nth: 0, file: 'screen1.png' },
    { label: '选中详情 · 暗色仪表盘', nth: 0, file: 'screen2.png' },
  ];
  for (const t of targets) {
    const group = page
      .locator('.screen-group', { has: page.locator(`.screen-label:has-text("${t.label}")`) })
      .nth(t.nth);
    const phone = group.locator('.phone');
    await phone.screenshot({ path: `output/fidelity/fence-d/${t.file}` });
    console.log(`captured ${t.file}`);
  }
  const listGroup = page
    .locator('.screen-group', {
      has: page.locator('.screen-label:has-text("晨报台账 · 形状沙盘")'),
    })
    .nth(0);
  const listPhone = listGroup.locator('.phone');
  const scroller = listPhone.locator('.tab-content');
  await page.addStyleTag({ content: '.bottom-nav{visibility:hidden !important}' });
  await scroller.evaluate((el) => {
    el.scrollTop = el.scrollHeight;
  });
  await page.waitForTimeout(300);
  await listPhone.screenshot({ path: 'output/fidelity/fence-d/screen3.png' });
  console.log('captured screen3.png');
  console.log(`total groups: ${count}`);
  await browser.close();
})();
