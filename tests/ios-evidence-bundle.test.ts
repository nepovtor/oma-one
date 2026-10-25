import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import vm from 'node:vm';
import {createHash} from 'node:crypto';
import {RUNNERS, shelfDecision} from '../proof-engine.js';
import type {ProofModuleId, ProofOutcome} from '../proof-engine.js';
import {FIXTURES} from '../proof-fixtures.js';

test('iPhone JavaScript bundle matches source rules for every fixture',async()=>{
  const source = await fs.readFile(new URL('ios/OMAOne/evidence-engine.js',`file://${process.cwd()}/`),'utf8');
  const context = vm.createContext({__sha256:(text: string)=>createHash('sha256').update(text).digest('hex')});
  vm.runInContext(source,context);
  for (const name of Object.keys(RUNNERS) as ProofModuleId[]) {
    const runner=RUNNERS[name] as (input: never)=>ProofOutcome;
    const expected = runner(structuredClone(FIXTURES[name]) as never);
    const actual = JSON.parse(vm.runInContext(`omaRun(${JSON.stringify(name)}, null)`,context));
    assert.deepEqual(actual,expected,name);
  }
});

test('iPhone bundle exposes the same composite shelf decision and Domino toggle',async()=>{
  const source = await fs.readFile(new URL('ios/OMAOne/evidence-engine.js',`file://${process.cwd()}/`),'utf8');
  const context = vm.createContext({__sha256:(text: string)=>createHash('sha256').update(text).digest('hex')});
  vm.runInContext(source,context);
  const input={surface:'concrete',fastener:'concrete-anchor',shelfWeightKg:2,plannedLoadKg:5,wallInspected:true,verifiedWiring:true,manufacturerInstructionsChecked:true,completedStepIds:['inspect','utilities','load','fastener','mount','final'],photoHashes:[]};
  const actual=JSON.parse(vm.runInContext(`omaRun('shelf', ${JSON.stringify(JSON.stringify(input))})`,context));
  assert.deepEqual(actual,shelfDecision(input));
  const toggled=JSON.parse(vm.runInContext(`omaShelfToggle('[]', 'mount')`,context));
  assert.deepEqual(toggled,[]);
});
