import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');

test('P2 shell exposes accessible, installable and offline UI primitives',async()=>{
 const [html,app,css,manifestRaw,serviceWorker]=await Promise.all([
  fs.readFile(path.join(root,'public/index.html'),'utf8'),
  fs.readFile(path.join(root,'public/app.js'),'utf8'),
  fs.readFile(path.join(root,'public/styles.css'),'utf8'),
  fs.readFile(path.join(root,'public/manifest.webmanifest'),'utf8'),
  fs.readFile(path.join(root,'public/sw.js'),'utf8')
 ]);
 const manifest=JSON.parse(manifestRaw);
 assert.match(html,/class="skip-link"/);
 assert.match(html,/aria-live="polite"/);
 assert.match(html,/name="mobile-web-app-capable" content="yes"/);
 assert.doesNotMatch(html+app,/\sonclick=/);
 assert.match(app,/aria-current="page"/);
 assert.match(app,/role="dialog"/);
 assert.match(app,/offline-banner/);
 assert.match(css,/prefers-reduced-motion/);
 assert.match(css,/prefers-contrast:more/);
 assert.ok(manifest.icons.some(icon=>icon.sizes==='192x192'&&icon.type==='image/png'));
 assert.ok(manifest.icons.some(icon=>icon.sizes==='512x512'&&icon.purpose.includes('maskable')));
 assert.match(serviceWorker,/url\.origin!==self\.location\.origin/);
 for(const icon of manifest.icons.filter(icon=>icon.type==='image/png'))await fs.access(path.join(root,'public',icon.src));
});
