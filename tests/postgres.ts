import fs from 'node:fs/promises';

import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';

const run=promisify(execFile);

async function freePort(){
 const server=net.createServer();
 await new Promise<void>((resolve,reject)=>{server.once('error',reject);server.listen(0,'127.0.0.1',resolve);});
 const address=server.address();if(!address||typeof address==='string')throw new Error('TCP test port unavailable');const {port}=address;
 await new Promise<void>((resolve,reject)=>server.close(error=>error?reject(error):resolve()));
 return port;
}

export async function startPostgres(){
 const root=await fs.mkdtemp(path.join(os.tmpdir(),'oma-one-pg-'));
 const data=path.join(root,'data');
 const socket=path.join(root,'socket');
 const port=await freePort();
 await fs.mkdir(socket);
 await run('initdb',['-D',data,'-A','trust','-U','postgres','--no-locale','--encoding=UTF8']);
 await run('pg_ctl',['-D',data,'-l',path.join(root,'postgres.log'),'-o',`-F -p ${port} -h 127.0.0.1 -k ${socket}`,'-w','start']);
 let stopped=false;
 return {
  connectionString:`postgresql://postgres@127.0.0.1:${port}/postgres`,
  async stop(){
   if(stopped)return;
   stopped=true;
   try{await run('pg_ctl',['-D',data,'-m','fast','-w','stop']);}finally{await fs.rm(root,{recursive:true,force:true});}
  }
 };
}
