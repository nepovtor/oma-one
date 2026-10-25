import test from 'node:test';
import type {TestContext} from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import net from 'node:net';
import os from 'node:os';
import fs from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {fileURLToPath} from 'node:url';
import {startPostgres} from './postgres.js';

type ApiJson = Record<string, any>;
interface RequestOptions {csrf?: boolean; headers?: Record<string, string>}

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');

async function freePort(){
 const server=net.createServer();
	 await new Promise<void>((resolve,reject)=>{server.once('error',reject);server.listen(0,'127.0.0.1',resolve);});
	 const address=server.address();if(!address||typeof address==='string')throw new Error('TCP test port unavailable');const {port}=address;
	 await new Promise<void>((resolve,reject)=>server.close(error=>error?reject(error):resolve()));
 return port;
}

async function startup(t: TestContext){
 const database=await startPostgres();
 const objectDir=await fs.mkdtemp(path.join(os.tmpdir(),'oma-one-objects-'));
 const port=await freePort();
 const child=spawn(process.execPath,['server.js'],{
  cwd:root,
  env:{...process.env,DATABASE_URL:database.connectionString,PORT:String(port),NODE_ENV:'test',OMA_DEMO_AUTH:'1',OMA_OBJECT_DIR:objectDir},
  stdio:['ignore','pipe','pipe']
 });
 let stderr='';
 child.stderr.on('data',(chunk: Buffer)=>{stderr+=chunk.toString();});
 t.after(async()=>{
  if(child.exitCode===null){child.kill('SIGTERM');await Promise.race([once(child,'exit'),new Promise(resolve=>setTimeout(resolve,5_000))]);}
  await database.stop();
  await fs.rm(objectDir,{recursive:true,force:true});
 });
 const url=`http://127.0.0.1:${port}`;
 for(let i=0;i<100;i++){
  if(child.exitCode!==null)throw new Error(`Server exited during startup: ${stderr}`);
  try{const response=await fetch(url+'/api/v1/health');if(response.ok)return url;}catch{}
  await new Promise(resolve=>setTimeout(resolve,75));
 }
 throw new Error(`Server did not start: ${stderr}`);
}

function createClient(url: string){
 const cookies=new Map<string, string>();
 function remember(headers: Headers){
  const values=headers.getSetCookie?.()||[headers.get('set-cookie')].filter(Boolean);
  for(const value of values.flatMap(item=>item.split(/, (?=[^;,]+=)/))){
   const pair=value.split(';',1)[0];
   const at=pair.indexOf('=');
   if(at>0)cookies.set(pair.slice(0,at),decodeURIComponent(pair.slice(at+1)));
  }
 }
 async function request(endpoint: string,method='GET',body: unknown=undefined,{csrf=true,headers={}}: RequestOptions={}){
  const requestHeaders: Record<string, string>={accept:'application/json',...headers};
  if(cookies.size)requestHeaders.cookie=[...cookies].map(([key,value])=>`${key}=${encodeURIComponent(value)}`).join('; ');
  if(method!=='GET'){
   requestHeaders['content-type']='application/json';
	   const csrfToken=cookies.get('oma_csrf');if(csrf&&csrfToken)requestHeaders['x-csrf-token']=csrfToken;
  }
  const response=await fetch(url+'/api/v1'+endpoint,{method,headers:requestHeaders,body:method==='GET'?undefined:JSON.stringify(body||{})});
  remember(response.headers);
  let json: ApiJson={};
  try{json=await response.json() as ApiJson;}catch{}
  return {response,json};
 }
 async function call(endpoint: string,method='GET',body: unknown=undefined,options: RequestOptions={}): Promise<ApiJson>{
  const result=await request(endpoint,method,body,options);
  if(!result.response.ok)throw new Error(`${result.response.status}: ${JSON.stringify(result.json)}`);
  return result.json;
 }
 async function login(userId: string){return call('/auth/demo','POST',{userId},{csrf:false});}
 return {request,call,login,cookies};
}

test('P1 API: sessions, RBAC, validation, audit and atomic stock',async t=>{
 const url=await startup(t);
 const anonymous=createClient(url);

 const unauthenticated=await anonymous.request('/bootstrap');
 assert.equal(unauthenticated.response.status,401);
 assert.equal(unauthenticated.json.error.code,'UNAUTHENTICATED');
 assert.equal(unauthenticated.response.headers.get('x-frame-options'),'DENY');
	 assert.match(unauthenticated.response.headers.get('content-security-policy')??'',/default-src 'self'/);
 const foreignOrigin=await anonymous.request('/health','GET',undefined,{headers:{origin:'https://attacker.example'}});
 assert.equal(foreignOrigin.response.status,403);
 assert.equal(foreignOrigin.json.error.code,'ORIGIN_FORBIDDEN');

 const client=createClient(url);
 await client.login('demo1');
 const initial=await client.call('/bootstrap');
 assert.equal(initial.user.id,'demo1');
 assert.equal(initial.products.length,28);
 assert.equal(initial.scenarios.length,6);
 assert.equal(initial.permissions.canManageForge,false);

 const missingCsrf=await client.request('/inventory','POST',{productId:'p03',qty:1},{csrf:false});
 assert.equal(missingCsrf.response.status,403);
 assert.equal(missingCsrf.json.error.code,'CSRF_INVALID');

 const impersonation=await client.request('/inventory','POST',{userId:'demo2',productId:'p03',qty:1});
 assert.equal(impersonation.response.status,422);
 assert.equal(impersonation.json.error.code,'VALIDATION_ERROR');
 const negative=await client.request('/cart/items','POST',{productId:'p01',quantity:-1});
 assert.equal(negative.response.status,422);

 const forbidden=await client.request('/forge/forge1/approve','POST',{});
 assert.equal(forbidden.response.status,403);
 assert.equal(forbidden.json.error.code,'FORBIDDEN');

 await client.call('/inventory','POST',{productId:'p03',qty:1});
 const solved=await client.call('/solve','POST',{scenarioId:'faucet',budget:220,area:1,mode:'hybrid'});
 assert.match(solved.calculationId,/^calc_/);
 assert.ok(solved.plan.saved>0);
 const projectResult=await client.call('/projects','POST',{calculationId:solved.calculationId});
 assert.equal(projectResult.project.status,'planned');
 await client.call('/cart/import-plan','POST',{calculationId:solved.calculationId});
 const reserved=await client.call('/cart/reserve','POST',{});
 assert.equal(reserved.reservation.status,'active');
 const order=await client.call('/orders','POST',{reservationId:reserved.reservation.id});
 assert.equal(order.order.status,'Демонстрационный заказ');
 assert.ok(order.order.total>0);

	 const orderedIds=solved.plan.steps.map((step: {id: string})=>step.id);
 const sequence=await client.call('/sequence/validate','POST',{calculationId:solved.calculationId,stepIds:orderedIds});
 assert.equal(sequence.conflicts.length,0);
 const assistant=await client.call('/assistant','POST',{message:'Как поменять смеситель?',scenarioId:'faucet'});
 assert.ok(assistant.answer.includes('смесител'));
 const dna=await client.call('/dna/match','POST',{room:'Ванная',area:4});
 assert.ok(dna.templates.length>=4);
 const finance=await client.call('/metrics','POST',{aov:300,margin:20,avgService:140,commission:12,cost:35});
 assert.equal(finance.contribution,41.8);
 const analytics=await client.call('/analytics/events','POST',{name:'page_view',properties:{view:'planner'}});
 assert.equal(analytics.accepted,true);
 const analyticsWithText=await client.request('/analytics/events','POST',{name:'page_view',properties:{view:'planner',message:'personal text'}});
 assert.equal(analyticsWithText.response.status,422);

 const other=createClient(url);
 await other.login('demo2');
 const crossProfile=await other.request(`/projects/${projectResult.project.id}/complete`,'POST',{checklist:[true,true,true],note:'Нет доступа'});
 assert.equal(crossProfile.response.status,403);
 const completed=await client.call(`/projects/${projectResult.project.id}/complete`,'POST',{checklist:[true,true,true],note:'Готово',image:'data:image/jpeg;base64,/9j/2Q=='});
 assert.equal(completed.project.proof.object.storage,'local');
 assert.equal(completed.project.proof.image,undefined);
 const proofImage=await client.request(`/projects/${projectResult.project.id}/proof-image`);
 assert.equal(proofImage.response.status,200);
 assert.equal(proofImage.response.headers.get('content-type'),'image/jpeg');
 const managerBootstrap=await other.call('/bootstrap');
 assert.equal(managerBootstrap.permissions.canManageForge,true);
 await other.call('/forge/forge1/approve','POST',{});
 const audit=await other.call('/audit');
	 assert.ok(audit.events.some((event: {action: string})=>event.action==='forge.approval_changed'));
	 assert.ok(audit.events.some((event: {action: string})=>event.action==='order.created'));

 const first=createClient(url),second=createClient(url);
 await first.login('demo1');
 await second.login('demo2');
 await first.call('/cart/items','POST',{productId:'p06',quantity:13});
 await second.call('/cart/items','POST',{productId:'p06',quantity:13});
 const reservations=await Promise.all([first.request('/cart/reserve','POST',{}),second.request('/cart/reserve','POST',{})]);
 assert.deepEqual(reservations.map(result=>result.response.status).sort((a,b)=>a-b),[200,409]);
	 const loser=reservations.find(result=>result.response.status===409);assert.ok(loser);assert.equal(loser.json.error.code,'STOCK_CHANGED');
 const winner=reservations.find(result=>result.response.status===200);
	 assert.ok(winner);
 const winningClient=winner===reservations[0]?first:second;
 const checkout=await winningClient.call('/orders','POST',{reservationId:winner.json.reservation.id});
 assert.equal(checkout.order.reservationId,winner.json.reservation.id);

 const retired=await fetch(url+'/api/bootstrap');
 assert.equal(retired.status,410);

 const malformed=await fetch(url+'/%E0%A4%A');
 assert.equal(malformed.status,400);
 assert.equal(await malformed.text(),'Bad Request');
 const healthAfterMalformed=await fetch(url+'/api/v1/health');
 assert.equal(healthAfterMalformed.status,200);
 const traversal=await fetch(url+'/%2e%2e%2f.env.example');
 assert.equal(traversal.status,403);
});
