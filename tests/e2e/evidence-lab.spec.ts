import {expect,test} from '@playwright/test';

const modules=[
 {id:'zerobuy',title:'ZeroBuy',engine:'ZeroBuy',decision:'Сокращён объём покупки'},
 {id:'antifail',title:'AntiFail',engine:'AntiFail',decision:'BLOCKED'},
 {id:'domino',title:'Domino',engine:'Domino',decision:'Порядок отклонён'},
 {id:'synccity',title:'SyncCity',engine:'SyncCity',decision:'Кандидат на группу'},
 {id:'proof',title:'Proof',engine:'Proof',decision:'EVIDENCE_SUBMITTED'},
 {id:'dna',title:'OMA DNA',engine:'DNA',decision:'Шаблон-кандидат'},
 {id:'forge',title:'OMA FORGE',engine:'FORGE',decision:'Идея для закупщика'},
 {id:'pulse',title:'OMA PULSE',engine:'PULSE',decision:'Без внешних уведомлений'},
 {id:'economics',title:'Экономика',engine:'Economics',decision:'Положительный вклад'}
] as const;

test('Evidence Lab loads every module, calculates results and fits a 390 px viewport',async({page})=>{
 await page.setViewportSize({width:390,height:844});
 const javascriptErrors: string[]=[];
 const resourceResponses=new Map<string,{status: number; contentType: string}>();
 page.on('pageerror',error=>javascriptErrors.push(`pageerror: ${error.message}`));
 page.on('console',message=>{if(message.type()==='error')javascriptErrors.push(`console: ${message.text()}`);});
 page.on('response',response=>{
  const pathname=new URL(response.url()).pathname;
  if(['/proof.html','/proof.css','/proof-ui.js'].includes(pathname))resourceResponses.set(pathname,{status:response.status(),contentType:response.headers()['content-type']??''});
 });

 const documentResponse=await page.goto('/proof.html',{waitUntil:'networkidle'});
 expect(documentResponse?.status()).toBe(200);
 expect(documentResponse?.headers()['content-type']).toContain('text/html');
 await expect(page.locator('#moduleNav button')).toHaveCount(modules.length);
 expect(resourceResponses.get('/proof.html')).toEqual({status:200,contentType:expect.stringContaining('text/html')});
 expect(resourceResponses.get('/proof.css')).toEqual({status:200,contentType:expect.stringContaining('text/css')});
 expect(resourceResponses.get('/proof-ui.js')).toEqual({status:200,contentType:expect.stringContaining('javascript')});

 for(const module of modules){
  await page.locator('#moduleNav button').filter({hasText:module.title}).click();
  await expect(page.locator('#moduleTitle')).toHaveText(module.title);
  await expect(page.locator('#runBtn')).toBeEnabled();

  const resultResponsePromise=page.waitForResponse(response=>response.request().method()==='POST'&&new URL(response.url()).pathname===`/proof-api/run/${module.id}`);
  await page.locator('#runBtn').click();
  const resultResponse=await resultResponsePromise;
  expect(resultResponse.status(),module.id).toBe(200);
  const apiResult=await resultResponse.json() as {module: string; version: string; result: unknown; limits: string[]};

  await expect(page.locator('#decision')).toHaveText(module.decision);
  await expect(page.locator('#summary')).not.toContainText('Не удалось');
  await expect(page.locator('#metrics .metric')).toHaveCount(3);
  await expect(page.locator('#caveats p')).not.toHaveCount(0);
  await expect(page.locator('#outputJson')).toContainText(`"module": "${module.engine}"`);
  const renderedResult=JSON.parse((await page.locator('#outputJson').textContent())??'') as typeof apiResult;
  expect(renderedResult).toEqual(apiResult);
  expect(renderedResult.module).toBe(module.engine);
  expect(renderedResult.version).not.toBe('');
  expect(renderedResult.result).toBeTruthy();
  expect(renderedResult.limits.length).toBeGreaterThan(0);

  const geometry=await page.evaluate(`({
   rootClientWidth:document.documentElement.clientWidth,
   rootScrollWidth:document.documentElement.scrollWidth,
   bodyClientWidth:document.body.clientWidth,
   bodyScrollWidth:document.body.scrollWidth
  })`) as {rootClientWidth: number; rootScrollWidth: number; bodyClientWidth: number; bodyScrollWidth: number};
  expect(geometry.rootScrollWidth,`${module.id}: document overflow`).toBeLessThanOrEqual(geometry.rootClientWidth+1);
  expect(geometry.bodyScrollWidth,`${module.id}: body overflow`).toBeLessThanOrEqual(geometry.bodyClientWidth+1);
 }

 expect(javascriptErrors).toEqual([]);
});
