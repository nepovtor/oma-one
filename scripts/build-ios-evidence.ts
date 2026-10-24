import fs from 'node:fs/promises';
import path from 'node:path';
import {FIXTURES} from '../proof-fixtures.js';

const source = await fs.readFile(new URL('../proof-engine.js',import.meta.url),'utf8');
const importPattern = /import\s*\{\s*createHash\s*\}\s*from\s*['"]node:crypto['"];?\s*/;
const hashPattern = /createHash\(['"]sha256['"]\)\.update\(JSON\.stringify\(attestation\)\)\.digest\(['"]hex['"]\)/;
if (!importPattern.test(source) || !hashPattern.test(source)) {
  throw new Error('The evidence engine changed; update the iOS bridge deliberately.');
}
const body = source
  .replace(importPattern,'')
  .replaceAll('export const ','const ')
  .replaceAll('export function ','function ')
  .replace(hashPattern,'__sha256(JSON.stringify(attestation))')
  .replace(/^\/\/# sourceMappingURL=.*$/m,'');
const output = `// Generated from proof-engine.ts. Run npm run build:ios-evidence.\n${body}\n`+
  `const OMA_FIXTURES = ${JSON.stringify(FIXTURES)};\n`+
  `function omaRun(name, inputJSON) {\n`+
  `  const runner = RUNNERS[name];\n`+
  `  if (!runner) throw new Error('Unknown module: ' + name);\n`+
  `  const input = inputJSON ? JSON.parse(inputJSON) : OMA_FIXTURES[name];\n`+
  `  return JSON.stringify(runner(input));\n`+
  `}\n`;
const destination = path.join(process.cwd(),'ios/OMAOne/evidence-engine.js');
if (process.argv.includes('--check')) {
  if (await fs.readFile(destination,'utf8') !== output) throw new Error('iOS evidence bundle is stale');
} else {
  await fs.writeFile(destination,output);
}
