/* يصدّر إطارات الإعلان PNG ثم يبنيها ffmpeg إلى MP4
   الاستخدام:  node render.mjs [fps] [outDir]
   أو للمعاينة: node render.mjs probe 1.8 5 10 15 19 23      */
import { chromium } from 'playwright';
import { mkdir, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';

const HERE = path.dirname(new URL(import.meta.url).pathname);
const DUR = 25.0;
const args = process.argv.slice(2);
const probe = args[0] === 'probe';
const fps = probe ? 0 : Number(args[0] || 30);
const outDir = path.join(HERE, probe ? 'probe' : (args[1] || 'frames'));

const browser = await chromium.launch({ args: ['--force-device-scale-factor=1', '--hide-scrollbars'] });
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
page.on('pageerror', e => console.error('PAGE ERROR:', e.message));
await page.goto('file://' + path.join(HERE, 'scene.html') + '?render=1');
await page.waitForFunction('window.__ready === true');
await page.evaluate(() => document.fonts.ready);
await page.waitForTimeout(400);

await mkdir(outDir, { recursive: true });

if (probe) {
  for (const s of args.slice(1)) {
    await page.evaluate(t => window.seek(t), Number(s));
    await page.waitForTimeout(60);
    await page.screenshot({ path: path.join(outDir, `t${s}.png`) });
    console.log('probe', s);
  }
} else {
  const total = Math.round(DUR * fps);
  const from = Number(process.env.FROM || 0), to = Number(process.env.TO || total);
  const t0 = Date.now();
  for (let f = from; f < Math.min(to, total); f++) {
    const fp = path.join(outDir, String(f).padStart(5, '0') + '.png');
    if (existsSync(fp) && !process.env.FORCE) continue;
    await page.evaluate(t => window.seek(t), f / fps);
    await page.screenshot({ path: fp, animations: 'disabled' });
    if (f % 60 === 0) process.stdout.write(`${f}/${total} (${((Date.now() - t0) / 1000).toFixed(0)}s)\n`);
  }
  console.log(`done ${total} frames in ${((Date.now() - t0) / 1000).toFixed(0)}s`);
}
await browser.close();
