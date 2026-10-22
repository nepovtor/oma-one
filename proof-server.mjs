// Standalone demo server. No DB, external APIs, user accounts or paid AI key needed.
// Intentionally separate from the production-intended backend.
import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {RUNNERS,PROOF_VERSION} from './proof-engine.mjs';
import {FIXTURES} from './proof-fixtures.mjs';
const dir=path.dirname(fileURLToPath(import.meta.url));
const port=Number(process.env.PROOF_PORT||8790);
const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'application/javascript; charset=utf-8'};
function send(res,status,body,type='application/json; charset=utf-8'){
 res.writeHead(status,{'content-type':type,'cache-control':'no-store','x-content-type-options':'nosniff','referrer-policy':'no-referrer','content-security-policy':"default-src 'self'; style-src 'self'; script-src 'self'; connect-src 'self'; img-src 'self' data:; base-uri 'none'; frame-ancestors 'none'"});res.end(typeof body==='string'?body:JSON.stringify(body));
}
const allowed=new Map([['/proof.html','proof.html'],['/','proof.html'],['/proof-ui.js','proof-ui.js'],['/proof.css','proof.css']]);
const server=http.createServer(async(req,res)=>{
 try{
  const url=new URL(req.url,'http://localhost');
  if(req.method==='GET'&&url.pathname==='/proof-api/status')return send(res,200,{mode:'DEMO',version:PROOF_VERSION,modules:Object.keys(RUNNERS),liveOMA:false,realCustomers:false});
  if(req.method==='GET'&&url.pathname==='/proof-api/fixtures')return send(res,200,FIXTURES);
  if(req.method==='POST'&&url.pathname.startsWith('/proof-api/run/')){
   const name=url.pathname.slice('/proof-api/run/'.length),fn=RUNNERS[name];if(!fn)return send(res,404,{error:'Unknown module'});
   let raw='';for await(const part of req){raw+=part.toString();if(raw.length>120000)return send(res,413,{error:'Too large'});}
   let input;try{input=JSON.parse(raw||'{}');}catch{return send(res,400,{error:'Invalid JSON'});}
   if(!input||typeof input!=='object'||Array.isArray(input))return send(res,422,{error:'Expected an object'});
   return send(res,200,fn(input));
  }
  if(req.method==='GET'&&allowed.has(url.pathname)){
   const filename=allowed.get(url.pathname),data=await fs.readFile(path.join(dir,filename));return send(res,200,data,types[path.extname(filename)]||'text/plain');
  }
  send(res,404,{error:'Not found'});
 }catch(e){send(res,500,{error:'Demo processing failure',detail:String(e.message||e).slice(0,120)});}
});
server.listen(port,'0.0.0.0',()=>console.log(`OMA ONE Evidence Lab ready: http://localhost:${port} (DEMO fixtures, no real OMA data)`));
