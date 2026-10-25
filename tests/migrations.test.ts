import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import pg from 'pg';
import type {Pool as PgPool} from 'pg';
import {createStore} from '../db.js';
import {startPostgres} from './postgres.js';

const {Pool}=pg;

async function applyMigrations(pool: PgPool,files: string[]){
 for(const file of files){
  await pool.query(await fs.readFile(path.join(process.cwd(),'db/migrations',file),'utf8'));
  await pool.query('INSERT INTO schema_migrations(version) VALUES($1)',[file]);
 }
}

test('migrations 004 and 005 must not promote legacy photos or flags into verified proof',async t=>{
 const database=await startPostgres();
 t.after(()=>database.stop());
 const pool=new Pool({connectionString:database.connectionString});
 await applyMigrations(pool,['001_core.sql','002_oidc.sql','003_product_events.sql']);
 const legacy={version:2,projects:[
  {id:'self',plan:{steps:[{id:'one'},{id:'two'}]},proof:{checklist:[true,true],verified:'self',image:null,date:'2026-01-01'}},
  {id:'photo',plan:{steps:[{id:'one'}]},proof:{checklist:[true],verified:'self',object:{key:'proof/old.jpg'},date:'2026-01-01'}},
  {id:'old-expert',plan:{steps:[{id:'one'}]},proof:{checklist:[true],verified:'expert',object:{key:'proof/legacy.jpg'},date:'2026-01-01'}},
  {id:'draft',plan:{steps:[{id:'one'}]},proof:null},
  {id:'missing-proof',plan:{steps:[{id:'one'}]}}
 ]};
 await pool.query('INSERT INTO app_state(singleton,version,payload) VALUES(true,1,$1::jsonb)',[JSON.stringify(legacy)]);
 await pool.end();
 const store=await createStore({connectionString:database.connectionString});
 const result=await store.pool.query('SELECT payload FROM app_state WHERE singleton=true');
 const payload=result.rows[0].payload;
 assert.equal(payload.version,3);
 assert.equal(payload.projects.length,5);
 for(const project of payload.projects.filter((item: {proof?: unknown})=>item.proof)){
  assert.equal(project.proof.status,'SELF_REPORTED',project.id);
  assert.equal(project.proof.verified,'self',project.id);
  assert.equal(project.proof.inspectorId,null,project.id);
  assert.equal(project.proof.verifiedAt,null,project.id);
 }
 assert.deepEqual(payload.projects[0].proof.stepIds,['one','two']);
 assert.deepEqual(payload.projects[1].proof.stepIds,['one']);
 assert.equal(payload.projects[3].proof,null);
 assert.equal(Object.prototype.hasOwnProperty.call(payload.projects[4],'proof'),false);
 assert.equal((await store.readState()).projects[2].proof?.status,'SELF_REPORTED');
 await store.close();
});

test('corrective migration preserves genuine evidence and independently verified records',async t=>{
 const database=await startPostgres();
 t.after(()=>database.stop());
 const pool=new Pool({connectionString:database.connectionString});
 await applyMigrations(pool,['001_core.sql','002_oidc.sql','003_product_events.sql','004_proof_statuses.sql']);
 const evidence={
  status:'EVIDENCE_SUBMITTED',checklist:[true],stepIds:['inspect'],note:'Фото приложено',
  verified:'self',object:{key:'proof/new.jpg',mime:'image/jpeg',size:24,storage:'local'},
  photoHash:'a'.repeat(64),digest:'b'.repeat(64),inspectorId:null,verifiedAt:null,date:'2026-10-25'
 };
 const expert={
  ...evidence,status:'EXPERT_VERIFIED',verified:'expert',inspectorId:'inspector-1',
  verifiedAt:'2026-10-25T18:00:00.000Z'
 };
 const incomplete={...expert,photoHash:null};
 const projects=[
  {id:'evidence',plan:{steps:[{id:'inspect'}]},proof:evidence},
  {id:'expert',plan:{steps:[{id:'inspect'}]},proof:expert},
  {id:'incomplete',plan:{steps:[{id:'inspect'}]},proof:incomplete}
 ];
 await pool.query('INSERT INTO app_state(singleton,version,payload) VALUES(true,1,$1::jsonb)',[JSON.stringify({version:3,projects})]);
 await pool.end();
 const store=await createStore({connectionString:database.connectionString});
 const fromDatabase=(await store.pool.query('SELECT payload FROM app_state WHERE singleton=true')).rows[0].payload.projects;
 assert.deepEqual(fromDatabase.map((project: {proof: {status: string}})=>project.proof.status),[
  'EVIDENCE_SUBMITTED','EXPERT_VERIFIED','SELF_REPORTED'
 ]);
 const normalized=await store.readState();
 assert.deepEqual(normalized.projects.map(project=>project.proof?.status),[
  'EVIDENCE_SUBMITTED','EXPERT_VERIFIED','SELF_REPORTED'
 ]);
 assert.equal(normalized.projects[1].proof?.inspectorId,'inspector-1');
 assert.equal(normalized.projects[2].proof?.inspectorId,null);
 await store.close();
});
