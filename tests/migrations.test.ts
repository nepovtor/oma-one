import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import pg from 'pg';
import {createStore} from '../db.js';
import {startPostgres} from './postgres.js';

const {Pool}=pg;

test('proof status migration preserves legacy records without inventing evidence',async t=>{
 const database=await startPostgres();
 t.after(()=>database.stop());
 const pool=new Pool({connectionString:database.connectionString});
 for(const file of ['001_core.sql','002_oidc.sql','003_product_events.sql']){
  await pool.query(await fs.readFile(path.join(process.cwd(),'db/migrations',file),'utf8'));
  await pool.query('INSERT INTO schema_migrations(version) VALUES($1)',[file]);
 }
 const legacy={version:2,projects:[
  {id:'self',plan:{steps:[{id:'one'},{id:'two'}]},proof:{checklist:[true,true],verified:'self',image:null,date:'2026-01-01'}},
  {id:'photo',plan:{steps:[{id:'one'}]},proof:{checklist:[true],verified:'self',object:{key:'proof/2026/01/x.jpg'},date:'2026-01-01'}}
 ]};
 await pool.query('INSERT INTO app_state(singleton,version,payload) VALUES(true,1,$1::jsonb)',[JSON.stringify(legacy)]);
 await pool.end();

 const store=await createStore({connectionString:database.connectionString});
 const result=await store.pool.query('SELECT payload FROM app_state WHERE singleton=true');
 await store.close();
 const payload=result.rows[0].payload;
 assert.equal(payload.version,3);
 assert.equal(payload.projects[0].proof.status,'SELF_REPORTED');
 assert.deepEqual(payload.projects[0].proof.stepIds,['one','two']);
 assert.equal(payload.projects[1].proof.status,'EVIDENCE_SUBMITTED');
 assert.deepEqual(payload.projects[1].proof.stepIds,['one']);
});
