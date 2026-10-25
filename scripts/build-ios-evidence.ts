import fs from 'node:fs/promises';
import path from 'node:path';
import {FIXTURES} from '../proof-fixtures.js';
import {portableEvidenceBody} from './evidence-bundle.js';

const source = await fs.readFile(new URL('../proof-engine.js',import.meta.url),'utf8');
const body=portableEvidenceBody(source);
const output = `// Generated from proof-engine.ts. Run npm run build:ios-evidence.\n${body}\n`+
  `const OMA_FIXTURES = ${JSON.stringify(FIXTURES)};\n`+
  `function omaRun(name, inputJSON) {\n`+
  `  const runner = name === 'shelf' ? shelfDecision : RUNNERS[name];\n`+
  `  if (!runner) throw new Error('Unknown module: ' + name);\n`+
  `  const input = inputJSON ? JSON.parse(inputJSON) : OMA_FIXTURES[name];\n`+
  `  return JSON.stringify(runner(input));\n`+
  `}\n`+
  `function omaShelfToggle(completedJSON, stepId) {\n`+
  `  return JSON.stringify(toggleShelfStep(JSON.parse(completedJSON), stepId));\n`+
  `}\n`;
const destination = path.join(process.cwd(),'ios/OMAOne/evidence-engine.js');
if (process.argv.includes('--check')) {
  if (await fs.readFile(destination,'utf8') !== output) throw new Error('iOS evidence bundle is stale');
} else {
  await fs.writeFile(destination,output);
}
