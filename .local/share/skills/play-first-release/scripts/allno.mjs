// Answer every visible unanswered Yes/No radiogroup with "No", repeat until none; print Q&A.
import { createRequire } from 'node:module';
const require = createRequire(process.env.PLAYWRIGHT_ROOT || '/usr/local/lib/node_modules/@playwright/mcp/');
const { chromium } = require('playwright-core');
const b = await chromium.connectOverCDP((process.env.PLAY_CDP || 'http://127.0.0.1:9333'));
const page = b.contexts().flatMap(c=>c.pages()).findLast(p=>p.url().includes('play.google.com'));
for (let round = 0; round < 40; round++) {
  const groups = page.locator('[role=tabpanel] [role=radiogroup]');
  const n = await groups.count(); let acted = false;
  for (let i = 0; i < n; i++) {
    const g = groups.nth(i);
    if (!(await g.isVisible())) continue;
    const checked = await g.locator('[role=radio][aria-checked=true], [role=radio][aria-checked="true"], input[type=radio]:checked').count();
    if (checked) continue;
    const no = g.getByRole('radio', { name: 'No', exact: true });
    if (await no.count() === 0) { console.log('NON-YESNO group', i); continue; }
    await no.first().click({ force: true }); await page.waitForTimeout(400); acted = true; break;
  }
  if (!acted) break;
}
const snap = await page.locator('[role=tabpanel]').first().ariaSnapshot();
console.log(snap.split('\n').filter(l => /text:|radio .*checked|heading/.test(l) && !/Learn more/.test(l)).map(l=>l.slice(0,260)).join('\n'));
await b.close();
