import fs from 'node:fs/promises';
import path from 'node:path';

const projectRoot = process.cwd();
const distRoot = path.join(projectRoot, 'dist');

const copies: ReadonlyArray<readonly [string, string]> = [
  ['public/index.html', 'public/index.html'],
  ['public/styles.css', 'public/styles.css'],
  ['public/manifest.webmanifest', 'public/manifest.webmanifest'],
  ['public/icons', 'public/icons'],
  ['public/products', 'public/products'],
  ['proof.html', 'proof.html'],
  ['proof.css', 'proof.css'],
  ['db/migrations', 'db/migrations']
];

for (const [source, destination] of copies) {
  const from = path.join(projectRoot, source);
  const to = path.join(distRoot, destination);
  await fs.mkdir(path.dirname(to), {recursive: true});
  await fs.cp(from, to, {recursive: true});
}
