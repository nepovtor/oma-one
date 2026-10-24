import test from 'node:test';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import type {ChildProcess} from 'node:child_process';
import {FIXTURES} from '../proof-fixtures.js';
const port=25000+process.pid%10000;
const base=`http://127.0.0.1:${port}`;
let child: ChildProcess | null=null;
const sleep=(ms: number)=>new Promise<void>(resolve=>setTimeout(resolve,ms));
test('Demo HTTP: start server and check status',async()=>{
 child=spawn(process.execPath,['proof-server.js'],{cwd:new URL('../',import.meta.url),env:{...process.env,PROOF_PORT:String(port)},stdio:'pipe'});
 for(let i=0;i<50;i++){try{const r=await fetch(base+'/proof-api/status');if(r.ok){const d=await r.json() as {liveOMA: boolean; realCustomers: boolean; modules: string[]};assert.equal(d.liveOMA,false);assert.equal(d.realCustomers,false);assert.equal(d.modules.length,9);return;}}catch{}await sleep(65);}
 throw new Error('Demo server did not start');
});
test('Demo HTTP: mobile lab HTML, JS and CSS served',async()=>{
 for(const [uri,mime] of [['/proof.html','text/html'],['/proof.css','text/css'],['/proof-ui.js','javascript']]){const r=await fetch(base+uri);assert.equal(r.status,200);assert.ok((r.headers.get('content-type')??'').includes(mime));assert.ok((await r.text()).length>500);}
});
test('Demo HTTP: every fixture has executable route and explanatory evidence',async()=>{
 for(const [id,input] of Object.entries(FIXTURES)){
  const r=await fetch(base+'/proof-api/run/'+id,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(input)});
  assert.equal(r.status,200,id);const out=await r.json() as {module: string; version: string; result: unknown; limits: string[]};assert.equal(out.module.toLowerCase(),id);assert.ok(out.version&&out.result&&out.limits.length>0,id);
 }
});
test('Demo HTTP: invalid JSON and wrong module are rejected',async()=>{
 let r=await fetch(base+'/proof-api/run/antifail',{method:'POST',body:'invalid'});assert.equal(r.status,400);
 r=await fetch(base+'/proof-api/run/unknown',{method:'POST',body:'{}'});assert.equal(r.status,404);
 r=await fetch(base+'/../.env.example');assert.notEqual(r.status,200);
});
test('Demo HTTP: stop standalone process',async()=>{assert.ok(child);child.kill('SIGTERM');await Promise.race([new Promise<void>(resolve=>child?.on('exit',()=>resolve())),sleep(3000)]);});
