import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import pg from 'pg';
import type {Pool as PgPool, PoolClient} from 'pg';
import {seed} from './seed.js';
import {asAppError} from './types.js';
import type {AppError,AppState} from './types.js';
import {createDemoFinanceState} from './finance-domain.js';
import type {FinanceState} from './finance-domain.js';

const {Pool}=pg;
const root=path.dirname(fileURLToPath(import.meta.url));
const migrationsDir=path.join(root,'db','migrations');

export interface StoreOptions {connectionString?: string}
export interface AuditMeta {
 actorUserId?: string | null;
 action: string;
 resourceType: string;
 resourceId?: string | null;
 correlationId: string;
 ip?: string;
 metadata?: Record<string, unknown>;
}
export interface SessionOptions {ttlSeconds?: number; correlationId?: string; ip?: string}
export interface DeleteSessionMeta {correlationId?: string; ip?: string}
export interface SessionRecord {userId: string; csrfHash: string; expiresAt: string | Date}

const hash=(value: unknown)=>crypto.createHash('sha256').update(String(value)).digest('hex');
const auditKey=process.env.OMA_AUDIT_HMAC_KEY||crypto.randomBytes(32).toString('hex');
const hashIp=(value: unknown)=>crypto.createHmac('sha256',auditKey).update(String(value)).digest('hex');
const clone=<T>(value: T): T=>structuredClone(value);

function normalizeState(value: unknown): AppState{
 const state=value&&typeof value==='object'?value as AppState:seed();
 state.version=Math.max(3,Number(state.version)||3);
 state.calculations=Array.isArray(state.calculations)?state.calculations:[];
 state.reservations=Array.isArray(state.reservations)?state.reservations:[];
 for(const user of state.users||[])user.roles=Array.isArray(user.roles)&&user.roles.length?user.roles:['client'];
 for(const project of state.projects||[]){
  const proof=project.proof;
  if(!proof)continue;

  const planIds=Array.isArray(project.plan?.steps)?project.plan.steps.map(step=>step.id):[];
  proof.stepIds=Array.isArray(proof.stepIds)?proof.stepIds:planIds;
  proof.photoHash=typeof proof.photoHash==='string'?proof.photoHash:null;
  proof.digest=typeof proof.digest==='string'?proof.digest:null;

  // Legacy "verified" flags and raw images are not evidence or an expert attestation.
  // Both newly submitted and migrated records must satisfy the same minimum proof contract.
  const hasCompleteSteps=planIds.length>0&&
   Array.isArray(proof.checklist)&&proof.checklist.length===planIds.length&&
   proof.checklist.every(done=>done===true)&&
   proof.stepIds.length===planIds.length&&
   proof.stepIds.every((id,index)=>id===planIds[index]);
  const hasEvidence=hasCompleteSteps&&typeof proof.object?.key==='string'&&
   proof.object.key.length>0&&/^[a-f0-9]{64}$/i.test(proof.photoHash||'')&&
   /^[a-f0-9]{64}$/i.test(proof.digest||'');
  const hasExpertAttestation=hasEvidence&&
   typeof proof.inspectorId==='string'&&proof.inspectorId.trim().length>0&&
   typeof proof.verifiedAt==='string'&&Number.isFinite(Date.parse(proof.verifiedAt));
  if(proof.status==='EXPERT_VERIFIED'&&hasExpertAttestation){
   proof.status='EXPERT_VERIFIED';
  }else if((proof.status==='EVIDENCE_SUBMITTED'||proof.status==='EXPERT_VERIFIED')&&hasEvidence){
   proof.status='EVIDENCE_SUBMITTED';
  }else if(proof.status==='IN_PROGRESS'){
   proof.status='IN_PROGRESS';
  }else{
   proof.status='SELF_REPORTED';
  }
  proof.verified=proof.status==='EXPERT_VERIFIED'?'expert':'self';
  if(proof.status!=='EXPERT_VERIFIED'){
   proof.inspectorId=null;
   proof.verifiedAt=null;
  }
 }
 return state;
}
async function migrate(pool: PgPool){
 await pool.query('CREATE TABLE IF NOT EXISTS schema_migrations (version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())');
 const files=(await fs.readdir(migrationsDir)).filter(name=>name.endsWith('.sql')).sort();
 for(const file of files){
  const exists=await pool.query('SELECT 1 FROM schema_migrations WHERE version=$1',[file]);
  if(exists.rowCount)continue;
  const client=await pool.connect();
  try{
   await client.query('BEGIN');
   await client.query(await fs.readFile(path.join(migrationsDir,file),'utf8'));
   await client.query('INSERT INTO schema_migrations(version) VALUES($1)',[file]);
   await client.query('COMMIT');
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}
 }
}

async function insertInitialState(pool: PgPool){
 const value=normalizeState(seed());
 await pool.query('INSERT INTO app_state(singleton,version,payload) VALUES(true,1,$1::jsonb) ON CONFLICT (singleton) DO NOTHING',[JSON.stringify(value)]);
}

export async function createStore(options: StoreOptions={}){
 const connectionString=options.connectionString||process.env.DATABASE_URL;
 if(!connectionString)throw new Error('DATABASE_URL is required. Start PostgreSQL before running OMA ONE.');
 const pool=new Pool({connectionString,max:Number(process.env.OMA_DB_POOL_SIZE||10),idleTimeoutMillis:10_000,connectionTimeoutMillis:5_000});
 await pool.query('SELECT 1');
 await migrate(pool);
 await insertInitialState(pool);

 async function readState(): Promise<AppState>{
  const result=await pool.query('SELECT payload FROM app_state WHERE singleton=true');
  if(!result.rowCount)throw new Error('Application state is not initialized');
  return normalizeState(clone(result.rows[0].payload));
 }

 async function mutate<T>(meta: AuditMeta,fn: (state: AppState, client: PoolClient)=>T | Promise<T>): Promise<T>{
  for(let attempt=0;attempt<3;attempt++){
   const client=await pool.connect();
   try{
    await client.query('BEGIN ISOLATION LEVEL SERIALIZABLE');
    const current=await client.query('SELECT version,payload FROM app_state WHERE singleton=true FOR UPDATE');
    if(!current.rowCount)throw new Error('Application state is not initialized');
    const state=normalizeState(clone(current.rows[0].payload));
    const value=await fn(state,client);
    await client.query('UPDATE app_state SET version=version+1,payload=$1::jsonb,updated_at=now() WHERE singleton=true',[JSON.stringify(state)]);
    await client.query(`INSERT INTO audit_events(actor_user_id,action,resource_type,resource_id,correlation_id,ip_hash,metadata)
      VALUES($1,$2,$3,$4,$5,$6,$7::jsonb)`,[
      meta.actorUserId||null,meta.action,meta.resourceType,meta.resourceId||null,meta.correlationId,meta.ip?hashIp(meta.ip):null,JSON.stringify(meta.metadata||{})
    ]);
    await client.query('COMMIT');
    return value;
   }catch(error){
    await client.query('ROLLBACK');
    if(asAppError(error).code==='40001'&&attempt<2)continue;
    throw error;
   }finally{client.release();}
  }
  throw new Error('Serializable transaction retry limit exceeded');
 }

 async function audit(meta: AuditMeta){
  await pool.query(`INSERT INTO audit_events(actor_user_id,action,resource_type,resource_id,correlation_id,ip_hash,metadata)
    VALUES($1,$2,$3,$4,$5,$6,$7::jsonb)`,[
    meta.actorUserId||null,meta.action,meta.resourceType,meta.resourceId||null,meta.correlationId,meta.ip?hashIp(meta.ip):null,JSON.stringify(meta.metadata||{})
  ]);
 }

 async function createSession(userId: string,{ttlSeconds=8*60*60,correlationId='session',ip=''}: SessionOptions={}){
  const state=await readState();
	  if(!state.users.some(user=>user.id===userId))throw new Error('Session user does not exist');
  const token=crypto.randomBytes(32).toString('base64url');
  const csrf=crypto.randomBytes(24).toString('base64url');
  await pool.query('DELETE FROM user_sessions WHERE expires_at<=now()');
  await pool.query(`INSERT INTO user_sessions(token_hash,user_id,csrf_hash,expires_at)
    VALUES($1,$2,$3,now()+($4::text||' seconds')::interval)`,[hash(token),userId,hash(csrf),ttlSeconds]);
  await audit({actorUserId:userId,action:'session.created',resourceType:'session',correlationId,ip});
  return {token,csrf,expiresIn:ttlSeconds};
 }

 async function getSession(token: string): Promise<SessionRecord | null>{
  if(!token)return null;
  const result=await pool.query(`SELECT user_id,csrf_hash,expires_at FROM user_sessions
    WHERE token_hash=$1 AND expires_at>now()`,[hash(token)]);
  if(!result.rowCount)return null;
  await pool.query('UPDATE user_sessions SET last_seen_at=now() WHERE token_hash=$1',[hash(token)]);
  return {userId:result.rows[0].user_id,csrfHash:result.rows[0].csrf_hash,expiresAt:result.rows[0].expires_at};
 }

 async function deleteSession(token: string | undefined,meta: DeleteSessionMeta={}){
  if(!token)return;
  const result=await pool.query('DELETE FROM user_sessions WHERE token_hash=$1 RETURNING user_id',[hash(token)]);
  if(result.rowCount)await audit({actorUserId:result.rows[0].user_id,action:'session.deleted',resourceType:'session',correlationId:meta.correlationId||'session',ip:meta.ip||''});
 }

 async function readFinanceState(userId: string): Promise<{revision:number;state:FinanceState}>{
  await pool.query(`INSERT INTO finance_states(user_id,payload) VALUES($1,$2::jsonb) ON CONFLICT (user_id) DO NOTHING`,[userId,JSON.stringify(createDemoFinanceState())]);
  const result=await pool.query('SELECT revision,payload FROM finance_states WHERE user_id=$1',[userId]);
  if(!result.rowCount)throw new Error('Finance state is not initialized');
  return {revision:Number(result.rows[0].revision),state:clone(result.rows[0].payload)};
 }

 async function saveFinanceState(userId: string,state: FinanceState,expectedRevision: number,meta: AuditMeta): Promise<{revision:number;state:FinanceState}>{
  const client=await pool.connect();
  try{
   await client.query('BEGIN ISOLATION LEVEL SERIALIZABLE');
   const current=await client.query('SELECT revision FROM finance_states WHERE user_id=$1 FOR UPDATE',[userId]);
   if(!current.rowCount){
    if(expectedRevision!==0){const conflict: AppError=new Error('Финансовый план изменён в другой сессии');conflict.status=409;conflict.code='FINANCE_REVISION_CONFLICT';throw conflict;}
    await client.query('INSERT INTO finance_states(user_id,payload) VALUES($1,$2::jsonb)',[userId,JSON.stringify(state)]);
   }else{
    const revision=Number(current.rows[0].revision);
    if(revision!==expectedRevision){const conflict: AppError=new Error('Финансовый план изменён в другой сессии');conflict.status=409;conflict.code='FINANCE_REVISION_CONFLICT';throw conflict;}
    await client.query('UPDATE finance_states SET revision=revision+1,payload=$2::jsonb,updated_at=now() WHERE user_id=$1',[userId,JSON.stringify(state)]);
   }
   await client.query(`INSERT INTO audit_events(actor_user_id,action,resource_type,resource_id,correlation_id,ip_hash,metadata)
     VALUES($1,$2,'finance_state',$1,$3,$4,$5::jsonb)`,[userId,meta.action,meta.correlationId,meta.ip?hashIp(meta.ip):null,JSON.stringify(meta.metadata||{})]);
   const saved=await client.query('SELECT revision,payload FROM finance_states WHERE user_id=$1',[userId]);
   await client.query('COMMIT');
   return {revision:Number(saved.rows[0].revision),state:clone(saved.rows[0].payload)};
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}
 }

 async function reset(){
  const value=normalizeState(seed());
  const client=await pool.connect();
  try{
   await client.query('BEGIN');
   await client.query('UPDATE app_state SET version=version+1,payload=$1::jsonb,updated_at=now() WHERE singleton=true',[JSON.stringify(value)]);
   await client.query('DELETE FROM user_sessions');
   await client.query('DELETE FROM finance_states');
   await client.query(`INSERT INTO audit_events(actor_user_id,action,resource_type,correlation_id,metadata)
     VALUES(NULL,'system.reset','application','reset',$1::jsonb)`,[JSON.stringify({seedVersion:value.version})]);
   await client.query('COMMIT');
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}
 }

 return {pool,readState,mutate,audit,createSession,getSession,deleteSession,readFinanceState,saveFinanceState,reset,hash,close:()=>pool.end()};
}
