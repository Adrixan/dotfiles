// q.mjs list | q.mjs set <index> <label> : radiogroups in the tab panel in order with their question
import { createRequire } from 'node:module';
const require = createRequire(process.env.PLAYWRIGHT_ROOT || '/usr/local/lib/node_modules/@playwright/mcp/');
const { chromium } = require('playwright-core');
const [mode, idx, label] = process.argv.slice(2);
const b = await chromium.connectOverCDP((process.env.PLAY_CDP || 'http://127.0.0.1:9333'));
const page = b.contexts().flatMap(c=>c.pages()).findLast(p=>p.url().includes('play.google.com'));
const root = page.locator('[role=tabpanel]:visible').first();
if (mode === 'set') {
  await root.locator('[role=radiogroup]:visible').nth(Number(idx)).getByRole('radio', { name: label, exact: true }).first().click({ force: true });
  await page.waitForTimeout(700);
}
const lines = (await root.ariaSnapshot()).split('\n');
let q = '', k = 0, out = [];
for (let i = 0; i < lines.length; i++) {
  const l = lines[i];
  const t = l.match(/- text: "?(?:Completed )?(.*?)"?$/); if (t && t[1].length > 15) q = t[1];
  if (/- radiogroup/.test(l)) {
    const ind = l.search(/\S/); const opts = [];
    for (let j = i + 1; j < lines.length && lines[j].search(/\S/) > ind; j++) { const r = lines[j].match(/- radio "(.*?)"( \[checked\])?/); if (r) opts.push(r[2] ? `[${r[1]}]` : r[1]); }
    out.push(`${k++}: ${q.slice(0, 200)} => ${opts.join(' | ')}`);
  }
}
console.log(out.join('\n'));
await b.close();
