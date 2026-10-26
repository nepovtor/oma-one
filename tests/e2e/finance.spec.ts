import {expect,test} from '@playwright/test';
import fs from 'node:fs/promises';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {startPostgres} from '../postgres.js';

let appUrl='';
let child: ReturnType<typeof spawn>;
let database: Awaited<ReturnType<typeof startPostgres>>;
let objectDir='';

async function freePort(){
 const server=net.createServer();
 await new Promise<void>((resolve,reject)=>{server.once('error',reject);server.listen(0,'127.0.0.1',resolve);});
 const address=server.address();
 if(!address||typeof address==='string')throw new Error('TCP test port unavailable');
 await new Promise<void>((resolve,reject)=>server.close(error=>error?reject(error):resolve()));
 return address.port;
}

test.beforeAll(async()=>{
 database=await startPostgres();
 objectDir=await fs.mkdtemp(path.join(os.tmpdir(),'oma-finance-e2e-'));
 const port=await freePort();
 child=spawn(process.execPath,['dist/server.js'],{
  cwd:process.cwd(),
  env:{...process.env,DATABASE_URL:database.connectionString,PORT:String(port),NODE_ENV:'test',OMA_DEMO_AUTH:'1',OMA_OBJECT_DIR:objectDir},
  stdio:['ignore','pipe','pipe']
 });
 let stderr='';child.stderr?.on('data',chunk=>{stderr+=chunk.toString();});
 appUrl=`http://127.0.0.1:${port}`;
 for(let index=0;index<100;index++){
  if(child.exitCode!==null)throw new Error(`OMA app server exited: ${stderr}`);
  try{if((await fetch(`${appUrl}/api/v1/health`)).ok)return;}catch{}
  await new Promise(resolve=>setTimeout(resolve,75));
 }
 throw new Error(`OMA app server did not start: ${stderr}`);
});

test.afterAll(async()=>{
 if(child?.exitCode===null){child.kill('SIGTERM');await Promise.race([once(child,'exit'),new Promise(resolve=>setTimeout(resolve,5_000))]);}
 if(database)await database.stop();
 if(objectDir)await fs.rm(objectDir,{recursive:true,force:true});
});

test('OMA Finance demo mutates only synthetic state, persists and fits small iPhones',async({page})=>{
 const javascriptErrors:string[]=[];
 page.on('pageerror',error=>javascriptErrors.push(error.message));
 page.on('console',message=>{if(message.type()==='error'&&!message.text().includes('401 (Unauthorized)'))javascriptErrors.push(message.text());});

 for(const width of [320,375,390]){
  await page.setViewportSize({width,height:844});
  await page.goto(`${appUrl}/?view=finance`,{waitUntil:'networkidle'});
  await expect(page.getByRole('heading',{name:'OMA Finance'})).toBeVisible();
  await expect(page.locator('.mobile-tabs .mobile-tab')).toHaveCount(6);
  const geometry=await page.evaluate(`({client:document.documentElement.clientWidth,scroll:document.documentElement.scrollWidth})`) as {client:number;scroll:number};
  expect(geometry.scroll,`${width}px document overflow`).toBeLessThanOrEqual(geometry.client+1);
 }

 const before=await page.locator('.finance-balance').textContent();
 await page.getByRole('button',{name:/Перевести/}).click();
 await page.locator('#finance-operation-form input[name="amount"]').fill('25,50');
 await page.locator('#finance-operation-form input[name="counterparty"]').fill('Синтетический получатель E2E');
 const save=page.waitForResponse(response=>response.request().method()==='PUT'&&new URL(response.url()).pathname==='/api/v1/finance');
 await page.locator('#finance-operation-form').getByRole('button',{name:'Добавить синтетическую операцию'}).click();
 expect((await save).status()).toBe(200);
 await expect(page.locator('.finance-balance')).not.toHaveText(before||'');
 await expect(page.locator('.finance-transaction').first()).toContainText('Синтетический получатель E2E');

 await page.reload({waitUntil:'networkidle'});
 await expect(page.locator('.finance-transaction').first()).toContainText('Синтетический получатель E2E');
 await expect(page.getByText('DEMO · демонстрация')).toBeVisible();
 expect(javascriptErrors).toEqual([]);
});
