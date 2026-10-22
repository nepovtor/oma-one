import fs from 'node:fs/promises';
import {FIXTURES} from '../proof-fixtures.mjs';

const source = await fs.readFile(new URL('../proof-engine.mjs',import.meta.url),'utf8');
const imported = "import {createHash} from 'node:crypto';";
const hashCall = "createHash('sha256').update(JSON.stringify(attestation)).digest('hex')";
if (!source.includes(imported) || !source.includes(hashCall)) {
  throw new Error('The evidence engine changed; update the iOS bridge deliberately.');
}
const body = source
  .replace(imported,'')
  .replaceAll('export const ','const ')
  .replaceAll('export function ','function ')
  .replace(hashCall,'__sha256(JSON.stringify(attestation))');
const output = `// Generated from proof-engine.mjs. Run node scripts/build-ios-evidence.mjs.\n${body}\n`+
  `const OMA_FIXTURES = ${JSON.stringify(FIXTURES)};\n`+
  `function omaRun(name, inputJSON) {\n`+
  `  const runner = RUNNERS[name];\n`+
  `  if (!runner) throw new Error('Unknown module: ' + name);\n`+
  `  const input = inputJSON ? JSON.parse(inputJSON) : OMA_FIXTURES[name];\n`+
  `  return JSON.stringify(runner(input));\n`+
  `}\n`;
const destination = new URL('../ios/OMAOne/evidence-engine.js',import.meta.url);
if (process.argv.includes('--check')) {
  if (await fs.readFile(destination,'utf8') !== output) throw new Error('iOS evidence bundle is stale');
} else {
  await fs.writeFile(destination,output);
}
