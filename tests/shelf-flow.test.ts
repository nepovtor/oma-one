import test from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {existsSync, mkdtempSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {pathToFileURL} from 'node:url';
import {antiFail, zeroBuy, domino, proof} from '../proof-engine.js';

const shelfSteps = [
  {id:'inspect',after:[]}, {id:'utilities',after:['inspect']},
  {id:'load',after:['inspect']}, {id:'fastener',after:['utilities','load']},
  {id:'mount',after:['fastener']}, {id:'final',after:['mount']}
];

async function webShelfModule(){
  const moduleUrl=pathToFileURL(join(process.cwd(),'dist/public/shelf.js')).href;
  return import(moduleUrl);
}

test('successful shelf inputs produce a preliminary kit and a self-reported, not inspected, result', () => {
  const safety = antiFail({surface:'concrete',fastener:'concrete-anchor',loadKg:7,verifiedWiring:true}).result;
  assert.equal(safety.status,'PRELIMINARY_PASS');
  assert.equal(safety.canAutoApprove,false);
  const items = zeroBuy({requirements:[
    {id:'p07',name:'Полка',qty:1,unitPrice:89},
    {id:'p08',name:'Дюбель',qty:1,unitPrice:12},
    {id:'p25',name:'Очки',qty:1,unitPrice:19}
  ],inventory:[{id:'p25',qty:1}]}).result;
  assert.deepEqual(items.items.map(item => [item.id,item.toBuy]),[['p07',1],['p08',1],['p25',0]]);
  assert.equal(items.after,101);
  assert.equal(domino({order:shelfSteps.map(s=>s.id),steps:shelfSteps}).result.valid,true);
  const recorded = proof({projectId:'local-shelf',steps:shelfSteps.map(s=>({code:s.id,done:true})),photoHashes:['a'.repeat(64)],ownerConsent:false}).result;
  assert.equal(recorded.status,'SELF_RECORDED');
  assert.equal(recorded.canPublishToDNA,false);
});

test('incompatible anchor is blocked and out-of-order work is rejected', () => {
  assert.equal(antiFail({surface:'drywall',fastener:'concrete-anchor',loadKg:7,verifiedWiring:true}).result.status,'BLOCKED');
  assert.equal(domino({order:['inspect','mount','utilities','load','fastener','final'],steps:shelfSteps}).result.valid,false);
});

test('unfinished shelf stays unfinished, including without a photo', () => {
  assert.equal(antiFail({surface:'drywall',fastener:'drywall-anchor',loadKg:7,verifiedWiring:false}).result.status,'REVIEW');
  assert.equal(proof({projectId:'draft',steps:shelfSteps.map(s=>({code:s.id,done:false})),photoHashes:[]}).result.status,'INCOMPLETE');
  assert.equal(proof({projectId:'draft',steps:shelfSteps.map(s=>({code:s.id,done:true})),photoHashes:[]}).result.status,'INCOMPLETE');
});

test('native shelf model passes complete, unsafe and persisted-draft checks', () => {
  const folder = mkdtempSync(join(tmpdir(),'oma-shelf-test-'));
  try {
    const binary = join(folder,'shelf-flow-checks');
    execFileSync('swiftc',['ios/OMAOne/ShelfFlow.swift','tests/shelf-flow.swift','-o',binary],{cwd:process.cwd()});
    assert.match(execFileSync(binary,{encoding:'utf8'}),/persistence passed/);
  } finally { rmSync(folder,{recursive:true,force:true}); }
});

test('every demo product has an individual local catalog image', () => {
  for (let n=1;n<=28;n++) {
    const name=`ProductP${String(n).padStart(2,'0')}`;
    const path=join(process.cwd(),`ios/OMAOne/Assets.xcassets/${name}.imageset/${name}.png`);
    assert.ok(existsSync(path),name);
  }
});

test('web shelf flow builds the same preliminary ZeroBuy basket as iOS', async () => {
  const {createShelfDraft,evaluateShelf}=await webShelfModule();
  const draft={...createShelfDraft(),wall:'concrete',shelfWeightKg:2,plannedLoadKg:5,fastener:'concreteAnchor',utilitiesChecked:true,wallInspected:true,manufacturerInstructionsChecked:true,ownedQuantities:{p25:1}};
  const result=evaluateShelf(draft,[{id:'p07',name:'Полка',price:89},{id:'p08',name:'Дюбель',price:12},{id:'p25',name:'Очки',price:19}]);
  assert.equal(result.status,'PRELIMINARY_PASS');
  assert.equal(result.readiness,'candidate');
  assert.deepEqual(result.basket.map((item: {id:string;toBuy:number})=>[item.id,item.toBuy]),[['p07',1],['p08',1],['p25',0]]);
  assert.equal(result.total,101);
});

test('web shelf flow blocks an incompatible anchor and refuses a basket', async () => {
  const {createShelfDraft,evaluateShelf}=await webShelfModule();
  const draft={...createShelfDraft(),wall:'drywall',shelfWeightKg:2,plannedLoadKg:5,fastener:'concreteAnchor',utilitiesChecked:true,wallInspected:true,manufacturerInstructionsChecked:true};
  const result=evaluateShelf(draft,[]);
  assert.equal(result.status,'BLOCKED');
  assert.equal(result.readiness,'blocked');
  assert.deepEqual(result.candidateProductIDs,[]);
});

test('web Domino completion follows dependencies and revokes downstream steps', async () => {
  const {createShelfDraft,toggleShelfStep}=await webShelfModule();
  let draft=createShelfDraft();
  draft=toggleShelfStep(draft,'mount');
  assert.deepEqual(draft.completedStepIDs,[]);
  for(const id of ['inspect','utilities','load','fastener','mount','final'])draft=toggleShelfStep(draft,id);
  assert.equal(draft.completedStepIDs.length,6);
  draft=toggleShelfStep(draft,'inspect');
  assert.deepEqual(draft.completedStepIDs,[]);
});
