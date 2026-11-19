// Minimal CDP driver for the visible Play Console Chromium (127.0.0.1:9333).
// Usage: node pw.mjs <cmd> [args...]
//   snap [selector]            aria snapshot of the console tab (or a sub-tree)
//   url                        print the current URL
//   goto <url>
//   click <role> <name>        click by ARIA role and accessible name (exact=false)
//   clicktext <text>           click the first visible element with this text
//   fill <label> <value>       fill a textbox by its label
//   fillrole <role> <name> <value>
//   check <role> <name>        check a checkbox/radio
//   upload <selector> <path...> set files on an <input type=file>
//   eval <js>                  evaluate an expression in the page
//   shot <path>                screenshot of the viewport
import { createRequire } from 'node:module';
const require = createRequire(process.env.PLAYWRIGHT_ROOT || '/usr/local/lib/node_modules/@playwright/mcp/');
const { chromium } = require('playwright-core');

async function hit(loc) {
  try { await loc.click({ timeout: 4000 }); }
  catch { await loc.evaluate((e) => { e.scrollIntoView({ block: 'center' }); e.click(); }, null, { timeout: 10000 }); }
}
const [cmd, ...args] = process.argv.slice(2);
if (!cmd) { console.error('missing command'); process.exit(2); }

const browser = await chromium.connectOverCDP((process.env.PLAY_CDP || 'http://127.0.0.1:9333'));
try {
  const pages = browser.contexts().flatMap((c) => c.pages());
  const page = pages.findLast((p) => p.url().includes('play.google.com')) ?? pages.at(-1);
  if (!page) throw new Error('no page open');
  await page.bringToFront();
  switch (cmd) {
    case 'snap': {
      const root = args[0] ? page.locator(args[0]).first() : page.locator('body');
      console.log(`URL: ${page.url()}\n` + (await root.ariaSnapshot({ timeout: 15000 })));
      break;
    }
    case 'url': console.log(page.url()); break;
    case 'goto': await page.goto(args[0], { waitUntil: 'domcontentloaded' }); await page.waitForTimeout(2500); console.log(page.url()); break;
    case 'click': await hit(page.getByRole(args[0], { name: args[1] }).first()); await page.waitForTimeout(1500); console.log('ok', page.url()); break;
    case 'clicktext': await hit(page.getByText(args[0], { exact: true }).filter({ visible: true }).first()); await page.waitForTimeout(1500); console.log('ok', page.url()); break;
    case 'fill': await page.getByLabel(args[0]).first().fill(args[1], { timeout: 15000 }); console.log('ok'); break;
    case 'fillrole': await page.getByRole(args[0], { name: args[1] }).first().fill(args[2], { timeout: 15000 }); console.log('ok'); break;
    case 'fillsel': await page.locator(args[0]).first().fill(args[1], { timeout: 15000 }); console.log('ok'); break;
    case 'clicksel': await hit(page.locator(args[0]).first()); await page.waitForTimeout(1500); console.log('ok', page.url()); break;
    case 'force': await page.locator(args[0]).first().click({ force: true, timeout: 10000 }); await page.waitForTimeout(800); console.log('ok'); break;
    case 'check': await page.getByRole(args[0], { name: args[1] }).first().check({ timeout: 15000 }); console.log('ok'); break;
    case 'upload': await page.locator(args[0]).first().setInputFiles(args.slice(1), { timeout: 15000 }); console.log('ok'); break;
    case 'eval': console.log(JSON.stringify(await page.evaluate(args[0]), null, 1)); break;
    case 'shot': await page.screenshot({ path: args[0] }); console.log(args[0]); break;
    default: throw new Error(`unknown command ${cmd}`);
  }
} catch (e) { console.error('ERROR', e.message.split('\n')[0]); process.exitCode = 1;
} finally {
  // Disconnect only; the browser keeps running.
  await browser.close().catch(() => {});
}
