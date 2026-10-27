import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');

test('OMA VIBE ships as an optional route while preserving the classic cart',async()=>{
 const [html,app,vibe,css,sw]=await Promise.all([
  fs.readFile(path.join(root,'public/index.html'),'utf8'),
  fs.readFile(path.join(root,'public/app.js'),'utf8'),
  fs.readFile(path.join(root,'public/vibe.js'),'utf8'),
  fs.readFile(path.join(root,'public/vibe.css'),'utf8'),
  fs.readFile(path.join(root,'public/sw.js'),'utf8')
 ]);
 assert.match(html,/vibe\.css/);
 assert.match(app,/vibe:pageVibe/);
 assert.match(app,/view==='vibe'/);
 assert.match(vibe,/Вернуться в обычный ОМА/);
 assert.match(vibe,/data-view="cart"/);
 assert.match(vibe,/Синтетический интерьерный референс/);
 assert.match(css,/prefers-reduced-motion/);
 assert.match(css,/max-width:380px/);
 assert.match(sw,/vibe\/bedroom\.jpg/);
 for(const asset of ['bedroom.jpg','living.jpg','overview.jpg']){
  await fs.access(path.join(root,'public/vibe',asset));
 }
});
