import fs from 'node:fs/promises';
import path from 'node:path';
import {portableEvidenceBody} from './evidence-bundle.js';

const projectRoot = process.cwd();
const distRoot = path.join(projectRoot, 'dist');

const copies: ReadonlyArray<readonly [string, string]> = [
  ['public/index.html', 'public/index.html'],
  ['public/styles.css', 'public/styles.css'],
  ['public/oma-brand.css', 'public/oma-brand.css'],
  ['ios/OMAOne/Assets.xcassets/OMALogoReference.imageset/OMALogoReference.jpg', 'public/icons/oma-logo.jpg'],
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

const proofSource=await fs.readFile(path.join(distRoot,'proof-engine.js'),'utf8');
const browserEvidence=`// Generated from proof-engine.ts during npm run build.\n${portableEvidenceBody(proofSource)}\n`+
 `globalThis.omaEvidenceEngine=Object.freeze({\n`+
 ` version:PROOF_VERSION,\n`+
 ` run(name,inputJSON){const runner=name==='shelf'?shelfDecision:RUNNERS[name];if(!runner)throw new Error('Unknown module: '+name);return JSON.stringify(runner(JSON.parse(inputJSON)));}\n`+
 `});\n`+
 `globalThis.omaShelfEngine=Object.freeze({\n`+
 ` version:PROOF_VERSION,\n`+
 ` steps:SHELF_STEPS.map(step=>({id:step.id,title:step.name,after:step.after||[]})),\n`+
 ` evaluate(inputJSON){return globalThis.omaEvidenceEngine.run('shelf',inputJSON);},\n`+
 ` canComplete(completedJSON,stepId){return canCompleteShelfStep(JSON.parse(completedJSON),stepId);},\n`+
 ` toggle(completedJSON,stepId){return JSON.stringify(toggleShelfStep(JSON.parse(completedJSON),stepId));}\n`+
 `});\n`;
await fs.writeFile(path.join(distRoot,'public','evidence-engine.js'),browserEvidence);
