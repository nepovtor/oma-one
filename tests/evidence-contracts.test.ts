import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import vm from 'node:vm';
import {createHash} from 'node:crypto';
import {RUNNERS} from '../proof-engine.js';
import type {ProofModuleId, ProofOutcome} from '../proof-engine.js';

const NEGATIVE_INPUTS: Record<Exclude<ProofModuleId,'economics'>, unknown>={
 zerobuy:{requirements:[{id:'x',qty:1,unitPrice:10}],inventory:[{id:'x',qty:2}]},
 antifail:{surface:'drywall',fastener:'concrete-anchor',loadKg:20,verifiedWiring:false},
 domino:{steps:[{id:'a',after:[]},{id:'b',after:['a']}],order:['b','a']},
 synccity:{requests:[{id:'a',city:'A',zone:'1',slot:'day',service:'x'},{id:'b',city:'A',zone:'1',slot:'day',service:'x'}],selectedId:'a',sharedTripCost:100,individualTripCost:10,minGroup:2},
 proof:{projectId:'negative',steps:[{code:'one',done:true},{code:'two',done:false}],photoHashes:[]},
 dna:{homeType:'panel',room:'bath',area:4,templates:[{id:'x',homeType:'wood',room:'garden',area:40,inspection:'self'}]},
 forge:{projects:[{id:'one',userId:'same',problem:'x',homeType:'flat',optIn:true},{id:'two',userId:'same',problem:'x',homeType:'flat',optIn:true}],interestThreshold:2,skuCosts:[]},
 pulse:{reports:[{userId:'same',model:'x',verifiedByExpert:false},{userId:'same',model:'x',verifiedByExpert:false}],cohortSize:2,minCases:3,minCohort:30}
};

test('all eight mechanism contracts match in Node, browser PWA and iOS for negative inputs',async()=>{
 const browserSource=await fs.readFile(new URL('../public/evidence-engine.js',import.meta.url),'utf8');
 const iosSource=await fs.readFile(new URL('ios/OMAOne/evidence-engine.js',`file://${process.cwd()}/`),'utf8');
 const hash=(text: string)=>createHash('sha256').update(text).digest('hex');
 const browser=vm.createContext({__sha256:hash}),ios=vm.createContext({__sha256:hash});
 vm.runInContext(browserSource,browser);vm.runInContext(iosSource,ios);
 for(const [name,input] of Object.entries(NEGATIVE_INPUTS) as Array<[Exclude<ProofModuleId,'economics'>,unknown]>){
  const expected=(RUNNERS[name] as (value: never)=>ProofOutcome)(structuredClone(input) as never);
  const encoded=JSON.stringify(JSON.stringify(input));
  const browserActual=JSON.parse(vm.runInContext(`omaEvidenceEngine.run(${JSON.stringify(name)}, ${encoded})`,browser));
  const iosActual=JSON.parse(vm.runInContext(`omaRun(${JSON.stringify(name)}, ${encoded})`,ios));
  assert.deepEqual(browserActual,expected,`${name} browser`);
  assert.deepEqual(iosActual,expected,`${name} iOS`);
 }
});
