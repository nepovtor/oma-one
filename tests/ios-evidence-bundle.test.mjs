import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import vm from 'node:vm';
import {createHash} from 'node:crypto';
import {RUNNERS} from '../proof-engine.mjs';
import {FIXTURES} from '../proof-fixtures.mjs';

test('iPhone JavaScript bundle matches source rules for every fixture',async()=>{
  const source = await fs.readFile(new URL('../ios/OMAOne/evidence-engine.js',import.meta.url),'utf8');
  const context = vm.createContext({__sha256:text=>createHash('sha256').update(text).digest('hex')});
  vm.runInContext(source,context);
  for (const [name,runner] of Object.entries(RUNNERS)) {
    const expected = runner(structuredClone(FIXTURES[name]));
    const actual = JSON.parse(vm.runInContext(`omaRun(${JSON.stringify(name)}, null)`,context));
    assert.deepEqual(actual,expected,name);
  }
});
