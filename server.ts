import http from 'node:http';
import type {IncomingMessage, ServerResponse} from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import crypto from 'node:crypto';
import type {JWTPayload} from 'jose';
import {CITIES,scenarios} from './seed.js';
import {detectScenario,computePlan,validateSequence,similarity,estimatedForgePrice,metrics,escapeText,round} from './engine.js';
import {createStore} from './db.js';
import {schemas,parse} from './validation.js';
import {SESSION_COOKIE,parseCookies,sessionCookies,clearSessionCookies,applySecurityHeaders,requestIp,isAllowedOrigin,createRateLimiter,correlationId,csrfMatches} from './security.js';
import {createOidc,oidcConfigured,oidcStateCookie,clearOidcStateCookie} from './oidc.js';
import {createObjectStore} from './object-store.js';
import {asAppError} from './types.js';
import type {AppError, AppState, Calculation, ProjectStep, Reservation, Role, User} from './types.js';
import type {SessionRecord} from './db.js';
import type {OidcResult} from './oidc.js';

interface RequestContext {
 method: string;
 pathname: string;
 data: unknown;
 url: URL;
 cookies: Record<string, string>;
 requestId: string;
 ip: string;
 secure: boolean;
	 readonly session: SessionRecord | null;
 sessionToken: string;
	 readonly user: User | null;
}
interface ResponseCookies {cookies?: string[]}
interface MutationMetadata {fields?: string[]; [key: string]: unknown}
interface LlmResponse {choices?: Array<{message?: {content?: unknown}}>}

const root=path.dirname(fileURLToPath(import.meta.url));
const staticDir=path.join(root,'public');
const PORT=Number(process.env.PORT||8787);
const RULES_VERSION='2026.10.1';
const API_PREFIX='/api/v1';
const store=await createStore();
const objectStore=await createObjectStore();
const rateLimit=createRateLimiter();
const oidc=createOidc();

const id=(prefix: string)=>`${prefix}_${crypto.randomUUID().slice(0,12)}`;
const err=(message: string,status=400,code='BAD_REQUEST',retryable=false,details: unknown[]=[]): AppError=>Object.assign(new Error(message),{status,code,retryable,details});
const pick=<T extends {id: string}>(collection: T[],key: string)=>{const value=collection.find(item=>item.id===key);if(!value)throw err('Объект не найден',404,'NOT_FOUND');return value;};
const getUser=(state: AppState,userId: string)=>pick(state.users,userId);
const hasRole=(user: User,...roles: Role[])=>(user.roles||[]).some(role=>roles.includes(role));
const requireRole=(user: User,...roles: Role[])=>{if(!hasRole(user,...roles))throw err('Нет доступа',403,'FORBIDDEN');};
const isMutation=(method: string | undefined)=>method!==undefined&&['POST','PATCH','PUT','DELETE'].includes(method);
const demoAuthEnabled=()=>process.env.NODE_ENV!=='production'||process.env.OMA_DEMO_AUTH==='1';
const secureCookies=(req: IncomingMessage)=>('encrypted' in req.socket&&req.socket.encrypted===true)||process.env.OMA_SECURE_COOKIES==='1';
const allowedRoles=new Set<Role>(['client','master','operator','manager','administrator']);

function rolesFromClaims(claims: JWTPayload): Role[]{
 const claimName=process.env.OMA_OIDC_ROLES_CLAIM||'roles',raw=claims[claimName],values=Array.isArray(raw)?raw:typeof raw==='string'?raw.split(/[ ,]+/):[];
 const roles=values.filter((role): role is Role=>typeof role==='string'&&allowedRoles.has(role as Role)&&role!=='client');
 return ['client',...new Set(roles)];
}

async function oidcUser(ctx: Pick<RequestContext, 'requestId' | 'ip'>,result: OidcResult): Promise<User>{
 const existing=await store.pool.query('SELECT user_id FROM oidc_identities WHERE issuer=$1 AND subject=$2',[result.issuer,result.claims.sub]);
 if(existing.rowCount){
  const state=await store.readState(),user=getUser(state,existing.rows[0].user_id);
  await store.pool.query('UPDATE oidc_identities SET email=$3,last_login_at=now() WHERE issuer=$1 AND subject=$2',[result.issuer,result.claims.sub,typeof result.claims.email==='string'?result.claims.email:null]);
  return user;
 }
 const userId=id('user');let created: User | undefined;
 await store.mutate({actorUserId:userId,action:'user.oidc_provisioned',resourceType:'user',resourceId:userId,correlationId:ctx.requestId,ip:ctx.ip,metadata:{issuer:result.issuer}},async(state,client)=>{
  const fallback=`Пользователь ${String(result.claims.sub).slice(0,8)}`;
  created={id:userId,name:escapeText(String(result.claims.name||result.claims.preferred_username||result.claims.email||fallback).slice(0,60)),roles:rolesFromClaims(result.claims),city:'Минск',district:'',kind:'Квартира',homeType:'Панельный дом',area:50,rooms:2,roomAreas:{},address:'',inventory:[],cart:[],projectIds:[],orderIds:[],groupIds:[],forgeVotes:[],pulseSubscriptions:[],createdAt:new Date().toISOString()};
  state.users.push(created);
  await client.query(`INSERT INTO oidc_identities(issuer,subject,user_id,email) VALUES($1,$2,$3,$4)`,[result.issuer,result.claims.sub,userId,typeof result.claims.email==='string'?result.claims.email:null]);
 });
 if(!created)throw new Error('OIDC profile creation failed');
 return created;
}

function bootstrap(state: AppState,user: User,demo: boolean){
 const projects=state.projects.filter(project=>project.userId===user.id).sort((a,b)=>b.createdAt.localeCompare(a.createdAt));
 const orders=state.orders.filter(order=>order.userId===user.id).sort((a,b)=>b.createdAt.localeCompare(a.createdAt));
 const cart=user.cart.map(item=>({...item,product:state.products.find(product=>product.id===item.productId)})).filter(item=>item.product);
 const templates=state.templates.map(template=>({...template,match:similarity(template,user,template.room,user.roomAreas?.[template.room])})).sort((a,b)=>b.match-a.match);
 const activeReservation=state.reservations.find(item=>item.userId===user.id&&item.status==='active'&&Date.parse(item.expiresAt)>Date.now())||null;
 return {user:{...user,roles:user.roles||['client']},users:demo?state.users.map(({id,name,city,kind,roles})=>({id,name,city,kind,roles})):[],roles:user.roles||['client'],permissions:{canManageForge:hasRole(user,'manager','administrator'),canViewAudit:hasRole(user,'manager','administrator')},cities:CITIES,scenarios,products:state.products,projects,orders,cart,activeReservation,groups:state.groups,templates,forge:state.forge.map(item=>({...item,priceNow:estimatedForgePrice(item)})),pulse:state.pulse,reports:state.reports.filter(report=>report.userId===user.id),metrics:metrics(state),lastUpdated:new Date().toISOString(),demo};
}

function send(res: ServerResponse,status: number,payload: unknown,{cookies=[]}: ResponseCookies={}){
 const out=JSON.stringify(payload);applySecurityHeaders(res,{api:true});res.statusCode=status;res.setHeader('content-type','application/json; charset=utf-8');if(cookies.length)res.setHeader('set-cookie',cookies);res.end(out);
}
function redirect(res: ServerResponse,location: string,{cookies=[]}: ResponseCookies={}){applySecurityHeaders(res,{api:true});res.statusCode=302;res.setHeader('location',location);res.setHeader('cache-control','no-store');if(cookies.length)res.setHeader('set-cookie',cookies);res.end();}
function sendBinary(res: ServerResponse,{body,mime}: {body: Buffer; mime: string}){applySecurityHeaders(res,{api:true});res.statusCode=200;res.setHeader('content-type',mime);res.setHeader('content-length',String(body.length));res.setHeader('cache-control','private, max-age=300');res.end(body);}
function sendError(res: ServerResponse,error: unknown,requestId: string){
 const caught=asAppError(error),status=Number(caught.status)||500,message=status>=500&&process.env.NODE_ENV!=='development'?'Внутренняя ошибка':caught.message;
 send(res,status,{error:{code:caught.code||'INTERNAL_ERROR',message,correlationId:requestId,retryable:!!caught.retryable,details:caught.details||[]}});if(status>=500)console.error(requestId,caught);
}
function body(req: IncomingMessage): Promise<unknown>{return new Promise((resolve,reject)=>{let raw='',size=0,done=false;req.on('data',(chunk: Buffer)=>{if(done)return;size+=chunk.length;if(size>2_000_000){done=true;reject(err('Слишком большой запрос',413,'PAYLOAD_TOO_LARGE'));req.destroy();return;}raw+=chunk.toString();});req.on('end',()=>{if(done)return;try{resolve(raw?JSON.parse(raw) as unknown:{});}catch{reject(err('Неверный JSON',400,'INVALID_JSON'));}});req.on('error',reject);});}
function mutationMeta(ctx: RequestContext,action: string,resourceType: string,resourceId: string | null,metadata: MutationMetadata={}){if(!ctx.user)throw err('Требуется вход',401,'UNAUTHENTICATED');return {actorUserId:ctx.user.id,action,resourceType,resourceId,metadata,correlationId:ctx.requestId,ip:ctx.ip};}
function findCalculation(state: AppState,ctx: RequestContext,calculationId: string): Calculation{const calculation=pick(state.calculations,calculationId);if(calculation.userId!==ctx.user?.id)throw err('Нет доступа',403,'FORBIDDEN');if(Date.parse(calculation.expiresAt)<=Date.now())throw err('Расчёт устарел. Выполните его снова',409,'CALCULATION_EXPIRED');return calculation;}
function expireReservations(state: AppState){const now=Date.now();for(const reservation of state.reservations)if(reservation.status==='active'&&Date.parse(reservation.expiresAt)<=now)reservation.status='expired';}
function reservedQuantity(state: AppState,productId: string,city: string,exceptId: string | null=null){return state.reservations.filter(item=>item.id!==exceptId&&item.status==='active'&&item.city===city&&Date.parse(item.expiresAt)>Date.now()).reduce((total,item)=>total+(item.items.find(line=>line.productId===productId)?.quantity||0),0);}
function assertAuthenticated(ctx: RequestContext): asserts ctx is RequestContext & {readonly session: SessionRecord; readonly user: User}{if(!ctx.session||!ctx.user)throw err('Требуется вход',401,'UNAUTHENTICATED');}

async function route(ctx: RequestContext): Promise<unknown>{
 const {method,pathname}=ctx;
 if(method==='GET'&&pathname==='/health')return {ok:true,version:'2.0.0',apiVersion:'v1',mode:demoAuthEnabled()?'demo':'production',storage:'postgresql',objectStorage:objectStore.storage,time:new Date().toISOString()};
 if(method==='GET'&&pathname==='/auth/config')return {demo:demoAuthEnabled(),oidc:oidcConfigured()};
 if(method==='GET'&&pathname==='/auth/oidc/start'){
  const result=await oidc.begin(store.pool,ctx.url.searchParams.get('returnTo')||'/');
  return {redirect:result.url,cookies:[oidcStateCookie(result.state,{secure:ctx.secure})]};
 }
 if(method==='GET'&&pathname==='/auth/oidc/callback'){
  const state=ctx.url.searchParams.get('state')||'',storedState=ctx.cookies.oma_oidc_state||'';
  if(!state||state.length!==storedState.length||!crypto.timingSafeEqual(Buffer.from(state),Buffer.from(storedState)))throw err('OIDC state cookie не совпадает',400,'OIDC_STATE_INVALID');
  const result=await oidc.complete(store.pool,{code:ctx.url.searchParams.get('code'),state}),user=await oidcUser(ctx,result);if(ctx.sessionToken)await store.deleteSession(ctx.sessionToken,{correlationId:ctx.requestId,ip:ctx.ip});const session=await store.createSession(user.id,{correlationId:ctx.requestId,ip:ctx.ip});
  return {redirect:result.returnTo,cookies:[...sessionCookies(session,{secure:ctx.secure}),clearOidcStateCookie({secure:ctx.secure})]};
 }
 if(method==='POST'&&pathname==='/auth/demo'){
  if(!demoAuthEnabled())throw err('Демо-вход отключён',404,'NOT_FOUND');
  const input=parse(schemas.demoLogin,ctx.data),state=await store.readState(),user=getUser(state,input.userId);if(ctx.sessionToken)await store.deleteSession(ctx.sessionToken,{correlationId:ctx.requestId,ip:ctx.ip});const session=await store.createSession(user.id,{correlationId:ctx.requestId,ip:ctx.ip});
  return {payload:{user:{id:user.id,name:user.name,roles:user.roles||['client']}},cookies:sessionCookies(session,{secure:ctx.secure})};
 }
	 assertAuthenticated(ctx);
 if(method==='GET'&&pathname==='/auth/session')return {user:{id:ctx.user.id,name:ctx.user.name,roles:ctx.user.roles||['client']}};
 if(method==='POST'&&pathname==='/auth/logout'){parse(schemas.empty,ctx.data);await store.deleteSession(ctx.sessionToken,{correlationId:ctx.requestId,ip:ctx.ip});return {payload:{ok:true},cookies:clearSessionCookies({secure:ctx.secure})};}
 if(method==='GET'&&pathname==='/bootstrap'){const state=await store.readState();return bootstrap(state,getUser(state,ctx.user.id),demoAuthEnabled());}
 if(method==='GET'&&pathname==='/scenarios')return scenarios;

 if(method==='POST'&&pathname==='/users'){
  if(!demoAuthEnabled())throw err('Создание демо-профилей отключено',403,'FORBIDDEN');
	  const input=parse(schemas.createUser,ctx.data);
	  const created=await store.mutate(mutationMeta(ctx,'user.created','user',null),state=>{const user: User={id:id('user'),name:escapeText(input.name),roles:['client'],city:CITIES.includes(input.city)?input.city:'Минск',district:'',kind:'Квартира',homeType:'Панельный дом',area:50,rooms:2,roomAreas:{},address:'',inventory:[],cart:[],projectIds:[],orderIds:[],groupIds:[],forgeVotes:[],pulseSubscriptions:[],createdAt:new Date().toISOString()};state.users.push(user);return user;});
  const session=await store.createSession(created.id,{correlationId:ctx.requestId,ip:ctx.ip});return {payload:{user:created},cookies:sessionCookies(session,{secure:ctx.secure})};
 }
 if(method==='PATCH'&&pathname==='/users/me'){
	  const input=parse(schemas.patchUser,ctx.data);return store.mutate(mutationMeta(ctx,'user.updated','user',ctx.user.id,{fields:Object.keys(input)}),state=>{const user=getUser(state,ctx.user.id);if(input.name!==undefined)user.name=escapeText(input.name);if(input.district!==undefined)user.district=escapeText(input.district);if(input.kind!==undefined)user.kind=escapeText(input.kind);if(input.homeType!==undefined)user.homeType=escapeText(input.homeType);if(input.address!==undefined)user.address=escapeText(input.address);if(input.city!==undefined){if(!CITIES.includes(input.city))throw err('Неизвестный город',422,'VALIDATION_ERROR');user.city=input.city;}if(input.area!==undefined)user.area=input.area;if(input.rooms!==undefined)user.rooms=input.rooms;if(input.roomAreas)user.roomAreas={...(user.roomAreas||{}),...input.roomAreas};return {user};});
 }

 if(method==='POST'&&pathname==='/inventory'){
  const input=parse(schemas.inventoryCreate,ctx.data);return store.mutate(mutationMeta(ctx,'inventory.created','inventory',null),state=>{const user=getUser(state,ctx.user.id),product=input.productId?pick(state.products,input.productId):null,item={id:id('inv'),productId:product?.id||null,name:product?.name||escapeText(input.name),qty:input.qty};user.inventory.push(item);return {item};});
 }
 const inventoryMatch=pathname.match(/^\/inventory\/([^/]+)$/);
 if(method==='DELETE'&&inventoryMatch){parse(schemas.empty,ctx.data);return store.mutate(mutationMeta(ctx,'inventory.deleted','inventory',inventoryMatch[1]),state=>{const user=getUser(state,ctx.user.id),before=user.inventory.length;user.inventory=user.inventory.filter(item=>item.id!==inventoryMatch[1]);if(user.inventory.length===before)throw err('Объект не найден',404,'NOT_FOUND');return {ok:true};});}

 if(method==='POST'&&pathname==='/assistant'){
	  const input=parse(schemas.assistant,ctx.data),state=await store.readState(),user=getUser(state,ctx.user.id),message=input.message,found=detectScenario(message,input.scenarioId??''),product=state.products.find(item=>message.toLowerCase().includes(item.name.toLowerCase()));let answer='',source='rules';
  if(process.env.OMA_LLM_ENDPOINT&&process.env.OMA_LLM_API_KEY){if(!process.env.OMA_LLM_ENDPOINT.startsWith('https://'))throw err('Адрес модели должен использовать HTTPS',500,'LLM_CONFIG_ERROR');try{const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),10_000);try{const response=await fetch(process.env.OMA_LLM_ENDPOINT,{method:'POST',headers:{'content-type':'application/json','authorization':'Bearer '+process.env.OMA_LLM_API_KEY},body:JSON.stringify({model:process.env.OMA_LLM_MODEL||'model',messages:[{role:'system',content:'Ты консультант OMA ONE. Отвечай по-русски кратко. Не выдумывай цены, остатки и правила безопасности.'},{role:'user',content:message}]}),signal:controller.signal});if(response.ok){const json=await response.json() as LlmResponse;answer=String(json.choices?.[0]?.message?.content||'').slice(0,2500);if(answer)source='external-provider';}}finally{clearTimeout(timer);}}catch{/* deterministic fallback */}}
  if(!answer){const lower=message.toLowerCase();if(product)answer=`В каталоге есть «${product.name}»: ${product.price} BYN/${product.unit}, остаток для города ${user.city} — ${product.stock[user.city]||0}.`;else if(/гарант|провер|совместим|опасн|ошибк/.test(lower))answer=`AntiFail поможет проверить проект «${found.title}», но для инженерной безопасности нужен специалист. ${found.warn}`;else if(/сосед|вместе|скид|доставк/.test(lower))answer=`SyncCity объединяет заявки в вашем городе (${user.city}).`;else if(/эконом|дешев|не покупать|остат/.test(lower))answer=`ZeroBuy учитывает то, что уже есть дома. В вашем профиле ${user.inventory.length} видов материалов.`;else answer=`Для задачи «${found.title}» могу предложить расчёт, варианты выполнения и проверку ограничений. ${found.warn}`;}
  await store.audit({actorUserId:user.id,action:'assistant.asked',resourceType:'assistant',correlationId:ctx.requestId,ip:ctx.ip,metadata:{source,scenarioId:found.id}});return {answer,source,scenarioId:found.id,disclaimer:source==='rules'?'Ответ составлен по версионированным правилам.':'Ответ внешней модели может содержать ошибки.'};
 }

 if(method==='POST'&&pathname==='/solve'){
  const input=parse(schemas.solve,ctx.data),calculationId=id('calc');return store.mutate(mutationMeta(ctx,'calculation.created','calculation',calculationId,{rulesVersion:RULES_VERSION}),state=>{const plan=computePlan(state,{...input,userId:ctx.user.id});plan.ruleVersion=RULES_VERSION;plan.calculationId=calculationId;const now=Date.now();state.calculations=state.calculations.filter(item=>Date.parse(item.expiresAt)>now);state.calculations.push({id:calculationId,userId:ctx.user.id,input,plan,rulesVersion:RULES_VERSION,createdAt:new Date(now).toISOString(),expiresAt:new Date(now+86_400_000).toISOString()});return {calculationId,plan};});
 }
 if(method==='POST'&&pathname==='/sequence/validate'){
	  const input=parse(schemas.sequence,ctx.data),state=await store.readState(),calculation=findCalculation(state,ctx,input.calculationId),canonical=calculation.plan.steps;if(input.stepIds.length!==canonical.length||input.stepIds.some(stepId=>!canonical.some(step=>step.id===stepId)))throw err('Состав этапов изменён',422,'VALIDATION_ERROR');const ordered: ProjectStep[]=input.stepIds.map(stepId=>pick(canonical,stepId));return {conflicts:validateSequence(ordered)};
 }
 if(method==='POST'&&pathname==='/projects'){
  const input=parse(schemas.calculationRef,ctx.data),projectId=id('project');return store.mutate(mutationMeta(ctx,'project.created','project',projectId),state=>{const user=getUser(state,ctx.user.id),calculation=findCalculation(state,ctx,input.calculationId),plan=calculation.plan,project={id:projectId,userId:user.id,title:escapeText(plan.title),scenarioId:plan.scenarioId,room:plan.room,area:plan.area,createdAt:new Date().toISOString(),status:'planned',budget:plan.budget,estimated:plan.estimated,ruleVersion:calculation.rulesVersion,plan,proof:null};state.projects.push(project);user.projectIds.push(project.id);return {project};});
 }
 const projectMatch=pathname.match(/^\/projects\/([^/]+)\/complete$/);
 if(method==='POST'&&projectMatch){const input=parse(schemas.projectComplete,ctx.data),object=input.image?await objectStore.putProof(input.image):null;try{return await store.mutate(mutationMeta(ctx,'project.completed','project',projectMatch[1],{hasImage:Boolean(object)}),state=>{const project=pick(state.projects,projectMatch[1]);if(project.userId!==ctx.user.id)throw err('Нет доступа',403,'FORBIDDEN');if(project.status==='completed')throw err('Проект уже завершён',409,'PROJECT_ALREADY_COMPLETED');if(!input.checklist.every(Boolean))throw err('Отметьте все пункты приёмки',422,'CHECKLIST_INCOMPLETE');project.status='completed';project.proof={checklist:input.checklist,note:escapeText(input.note),object,verified:'self',date:new Date().toISOString()};return {project};});}catch(error){if(object)await objectStore.remove(object).catch(()=>{});throw error;}}
 const proofImageMatch=pathname.match(/^\/projects\/([^/]+)\/proof-image$/);
 if(method==='GET'&&proofImageMatch){const state=await store.readState(),project=pick(state.projects,proofImageMatch[1]);if(project.userId!==ctx.user.id&&!hasRole(ctx.user,'operator','administrator'))throw err('Нет доступа',403,'FORBIDDEN');if(!project.proof?.object)throw err('Фотография не найдена',404,'NOT_FOUND');return {binary:await objectStore.get(project.proof.object)};}

 if(method==='POST'&&pathname==='/cart/items'){
  const input=parse(schemas.cartItem,ctx.data);return store.mutate(mutationMeta(ctx,'cart.item_added','cart',ctx.user.id,{productId:input.productId,quantity:input.quantity}),state=>{const user=getUser(state,ctx.user.id),product=pick(state.products,input.productId),item=user.cart.find(value=>value.productId===product.id);if(item){if(item.quantity+input.quantity>200)throw err('Количество превышает лимит',422,'QUANTITY_LIMIT');item.quantity+=input.quantity;}else user.cart.push({id:id('cart'),productId:product.id,quantity:input.quantity});return {cart:user.cart};});
 }
 const cartMatch=pathname.match(/^\/cart\/items\/([^/]+)$/);
 if(method==='DELETE'&&cartMatch){parse(schemas.empty,ctx.data);return store.mutate(mutationMeta(ctx,'cart.item_deleted','cart_item',cartMatch[1]),state=>{const user=getUser(state,ctx.user.id),before=user.cart.length;user.cart=user.cart.filter(item=>item.id!==cartMatch[1]);if(user.cart.length===before)throw err('Объект не найден',404,'NOT_FOUND');return {cart:user.cart};});}
 if(method==='POST'&&pathname==='/cart/import-plan'){
  const input=parse(schemas.calculationRef,ctx.data);return store.mutate(mutationMeta(ctx,'cart.plan_imported','cart',ctx.user.id,{calculationId:input.calculationId}),state=>{const user=getUser(state,ctx.user.id),calculation=findCalculation(state,ctx,input.calculationId);for(const planned of calculation.plan.items){if(!planned.purchase)continue;const product=pick(state.products,planned.productId),quantity=Number(planned.purchase);if(!Number.isInteger(quantity)||quantity<1||quantity>200)throw err('Недопустимое количество',422,'INVALID_QUANTITY');const current=user.cart.find(item=>item.productId===product.id);if(current){if(current.quantity+quantity>200)throw err('Количество превышает лимит',422,'QUANTITY_LIMIT');current.quantity+=quantity;}else user.cart.push({id:id('cart'),productId:product.id,quantity});}return {cart:user.cart};});
 }
 if(method==='POST'&&pathname==='/cart/reserve'){
	  parse(schemas.empty,ctx.data);const reservationId=id('reservation');return store.mutate(mutationMeta(ctx,'stock.reserved','reservation',reservationId),state=>{const user=getUser(state,ctx.user.id);if(!user.cart.length)throw err('Корзина пуста',422,'EMPTY_CART');expireReservations(state);for(const previous of state.reservations)if(previous.userId===user.id&&previous.status==='active')previous.status='replaced';const items=user.cart.map(cartItem=>{if(!Number.isInteger(cartItem.quantity)||cartItem.quantity<1||cartItem.quantity>200)throw err('Недопустимое количество',422,'INVALID_QUANTITY');const product=pick(state.products,cartItem.productId),available=(product.stock[user.city]||0)-reservedQuantity(state,product.id,user.city);if(available<cartItem.quantity)throw err(`Недостаточно товара для резервирования: ${product.name}`,409,'STOCK_CHANGED',true);return {productId:product.id,quantity:cartItem.quantity,quotedPrice:product.price};});const now=Date.now(),reservation: Reservation={id:reservationId,userId:user.id,city:user.city,items,status:'active',createdAt:new Date(now).toISOString(),expiresAt:new Date(now+10*60_000).toISOString()};state.reservations.push(reservation);return {reservation};});
 }
 const reservationMatch=pathname.match(/^\/reservations\/([^/]+)$/);
 if(method==='DELETE'&&reservationMatch){parse(schemas.empty,ctx.data);return store.mutate(mutationMeta(ctx,'stock.reservation_cancelled','reservation',reservationMatch[1]),state=>{const reservation=pick(state.reservations,reservationMatch[1]);if(reservation.userId!==ctx.user.id)throw err('Нет доступа',403,'FORBIDDEN');if(reservation.status==='active')reservation.status='cancelled';return {reservation};});}
 if(method==='POST'&&pathname==='/orders'){
  const input=parse(schemas.reservationRef,ctx.data),orderId=id('order');return store.mutate(mutationMeta(ctx,'order.created','order',orderId,{reservationId:input.reservationId}),state=>{const user=getUser(state,ctx.user.id);expireReservations(state);const reservation=pick(state.reservations,input.reservationId);if(reservation.userId!==user.id)throw err('Нет доступа',403,'FORBIDDEN');if(reservation.status!=='active')throw err('Резерв недействителен',409,'RESERVATION_INVALID',true);let sum=0;const items=reservation.items.map(line=>{const product=pick(state.products,line.productId),available=product.stock[user.city]||0;if(available<line.quantity)throw err(`Остаток изменился: ${product.name}`,409,'STOCK_CHANGED',true);sum+=product.price*line.quantity;return {productId:product.id,name:product.name,price:product.price,quantity:line.quantity,quotedPrice:line.quotedPrice};});const order={id:orderId,userId:user.id,reservationId:reservation.id,items,total:round(sum),city:user.city,status:'Демонстрационный заказ',createdAt:new Date().toISOString(),notice:'Не передан в ОМА. Оплата и доставка не выполняются.'};for(const item of items)pick(state.products,item.productId).stock[user.city]-=item.quantity;reservation.status='consumed';reservation.consumedAt=order.createdAt;state.orders.push(order);user.cart=[];user.orderIds.push(order.id);return {order};});
 }

 if(method==='POST'&&pathname==='/groups'){
  const input=parse(schemas.groupCreate,ctx.data),groupId=id('grp');return store.mutate(mutationMeta(ctx,'group.created','group',groupId),state=>{const user=getUser(state,ctx.user.id),group={id:groupId,title:escapeText(input.title),district:user.district||user.city,city:user.city,category:escapeText(input.category),participants:1,memberIds:[user.id],target:input.target,basePrice:input.basePrice,description:escapeText(input.description||''),date:escapeText(input.date||'')};state.groups.push(group);user.groupIds.push(group.id);return {group};});
 }
 const joinMatch=pathname.match(/^\/groups\/([^/]+)\/join$/);
 if(method==='POST'&&joinMatch){parse(schemas.empty,ctx.data);return store.mutate(mutationMeta(ctx,'group.joined','group',joinMatch[1]),state=>{const user=getUser(state,ctx.user.id),group=pick(state.groups,joinMatch[1]);if(group.city!==user.city)throw err('Выберите группу в вашем городе',422,'CITY_MISMATCH');if(group.memberIds.includes(user.id))throw err('Вы уже участвуете',409,'ALREADY_JOINED');group.memberIds.push(user.id);group.participants=group.memberIds.length;user.groupIds.push(group.id);return {group};});}
 const voteMatch=pathname.match(/^\/forge\/([^/]+)\/vote$/);
 if(method==='POST'&&voteMatch){parse(schemas.empty,ctx.data);return store.mutate(mutationMeta(ctx,'forge.voted','forge',voteMatch[1]),state=>{const user=getUser(state,ctx.user.id),forge=pick(state.forge,voteMatch[1]);if(forge.voters.includes(user.id))throw err('Вы уже проявили интерес',409,'ALREADY_VOTED');forge.voters.push(user.id);forge.interested++;user.forgeVotes.push(forge.id);return {forge:{...forge,priceNow:estimatedForgePrice(forge)}};});}
 const approveMatch=pathname.match(/^\/forge\/([^/]+)\/approve$/);
 if(method==='POST'&&approveMatch){parse(schemas.empty,ctx.data);requireRole(ctx.user,'manager','administrator');return store.mutate(mutationMeta(ctx,'forge.approval_changed','forge',approveMatch[1]),state=>{const forge=pick(state.forge,approveMatch[1]);forge.approved=!forge.approved;return {forge,disclaimer:'Демо-решение не меняет ассортимент ОМА.'};});}
 if(method==='POST'&&pathname==='/pulse/report'){
  const input=parse(schemas.pulseReport,ctx.data),reportId=id('report');return store.mutate(mutationMeta(ctx,'pulse.reported','pulse_report',reportId),state=>{const report={id:reportId,userId:ctx.user.id,category:escapeText(input.category),model:escapeText(input.model),symptom:escapeText(input.symptom),status:'Требует проверки',verified:false,createdAt:new Date().toISOString()};state.reports.push(report);return {report};});
 }
 const subscribeMatch=pathname.match(/^\/pulse\/([^/]+)\/subscribe$/);
 if(method==='POST'&&subscribeMatch){parse(schemas.empty,ctx.data);return store.mutate(mutationMeta(ctx,'pulse.subscription_changed','pulse',subscribeMatch[1]),state=>{const user=getUser(state,ctx.user.id);pick(state.pulse,subscribeMatch[1]);user.pulseSubscriptions=user.pulseSubscriptions||[];if(user.pulseSubscriptions.includes(subscribeMatch[1]))user.pulseSubscriptions=user.pulseSubscriptions.filter(value=>value!==subscribeMatch[1]);else user.pulseSubscriptions.push(subscribeMatch[1]);return {subscriptions:user.pulseSubscriptions};});}
 if(method==='POST'&&pathname==='/dna/match'){const input=parse(schemas.dnaMatch,ctx.data),state=await store.readState(),user=getUser(state,ctx.user.id);return {templates:state.templates.map(template=>({...template,match:similarity(template,user,input.room,input.area)})).sort((a,b)=>b.match-a.match)};}
 if(method==='POST'&&pathname==='/metrics'){const input=parse(schemas.metrics,ctx.data),state=await store.readState();return metrics(state,input);}
 if(method==='POST'&&pathname==='/analytics/events'){const input=parse(schemas.analytics,ctx.data);await store.pool.query('INSERT INTO product_events(user_id,event_name,properties) VALUES($1,$2,$3::jsonb)',[ctx.user.id,input.name,JSON.stringify(input.properties)]);return {accepted:true};}
 if(method==='GET'&&pathname==='/audit'){requireRole(ctx.user,'manager','administrator');const result=await store.pool.query('SELECT id,actor_user_id,action,resource_type,resource_id,correlation_id,metadata,created_at FROM audit_events ORDER BY id DESC LIMIT 100');return {events:result.rows};}
 throw err('Маршрут не найден',404,'NOT_FOUND');
}

function isRecord(value: unknown): value is Record<string, unknown>{return typeof value==='object'&&value!==null&&!Array.isArray(value);}

async function apiHandler(req: IncomingMessage,res: ServerResponse,url: URL){
 const requestId=correlationId(req);res.setHeader('x-correlation-id',requestId);
 try{
  if(!isAllowedOrigin(req))throw err('Источник запроса не разрешён',403,'ORIGIN_FORBIDDEN');
  const ip=requestIp(req),authPath=url.pathname.startsWith(API_PREFIX+'/auth/'),bucket=rateLimit(`${ip}:${authPath?'auth':'api'}`,authPath?{limit:20,windowMs:60_000}:{limit:240,windowMs:60_000});res.setHeader('x-ratelimit-remaining',String(bucket.remaining));if(!bucket.allowed)throw err('Слишком много запросов',429,'RATE_LIMITED',true);
  if(req.method==='OPTIONS'){res.statusCode=204;applySecurityHeaders(res,{api:true});res.end();return;}
  const data=isMutation(req.method)?await body(req):{},cookies=parseCookies(req.headers.cookie||''),sessionToken=cookies[SESSION_COOKIE]||'',session=await store.getSession(sessionToken);let user=null;if(session){const state=await store.readState();user=state.users.find(value=>value.id===session.userId)||null;}
  const pathname=url.pathname.slice(API_PREFIX.length)||'/',publicMutation=req.method==='POST'&&pathname==='/auth/demo';
  if(isMutation(req.method)&&!publicMutation&&(!session||!csrfMatches(store,session,req.headers['x-csrf-token'])))throw err('Неверный CSRF-токен',403,'CSRF_INVALID');
  const result=await route({method:req.method??'GET',pathname,data,url,cookies,requestId,ip,secure:secureCookies(req),session,sessionToken,user});
  if(isRecord(result)&&typeof result.redirect==='string')redirect(res,result.redirect,{cookies:Array.isArray(result.cookies)?result.cookies.filter((value): value is string=>typeof value==='string'):[]});
  else if(isRecord(result)&&isRecord(result.binary)&&Buffer.isBuffer(result.binary.body)&&typeof result.binary.mime==='string')sendBinary(res,{body:result.binary.body,mime:result.binary.mime});
  else if(isRecord(result)&&'payload' in result&&Array.isArray(result.cookies))send(res,200,result.payload,{cookies:result.cookies.filter((value): value is string=>typeof value==='string')});
  else send(res,200,result);
 }catch(error){sendError(res,error,requestId);}
}

const mimetypes: Record<string, string>={'.html':'text/html; charset=utf-8','.js':'application/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.webmanifest':'application/manifest+json'};
const server=http.createServer(async(req,res)=>{
 let url: URL;try{url=new URL(req.url??'/','http://localhost');}catch{res.writeHead(400);res.end();return;}
 if(url.pathname.startsWith(API_PREFIX+'/')||url.pathname===API_PREFIX){await apiHandler(req,res,url);return;}
 if(url.pathname.startsWith('/api/')){send(res,410,{error:{code:'API_VERSION_RETIRED',message:'Используйте /api/v1',correlationId:correlationId(req),retryable:false,details:[]}});return;}
 if(req.method!=='GET'&&req.method!=='HEAD'){applySecurityHeaders(res);res.writeHead(405);res.end();return;}
 const pathname=decodeURIComponent(url.pathname),normalized=path.resolve(staticDir,'.'+pathname);if(!normalized.startsWith(staticDir+path.sep)&&normalized!==staticDir){applySecurityHeaders(res);res.writeHead(403);res.end();return;}
 let filename=normalized;if(!fs.existsSync(filename)||fs.statSync(filename).isDirectory())filename=path.join(staticDir,'index.html');
 try{const content=await fs.promises.readFile(filename);applySecurityHeaders(res);res.writeHead(200,{'content-type':mimetypes[path.extname(filename)]||'application/octet-stream','cache-control':filename.endsWith('index.html')?'no-cache':'public, max-age=300'});res.end(req.method==='HEAD'?'':content);}catch{applySecurityHeaders(res);res.writeHead(404);res.end();}
});

server.listen(PORT,'0.0.0.0',()=>console.log(`OMA ONE: http://localhost:${PORT} (PostgreSQL, API v1)`));
async function shutdown(){server.close(async()=>{await store.close();process.exit(0);});setTimeout(()=>process.exit(1),5_000).unref();}
process.on('SIGTERM',shutdown);process.on('SIGINT',shutdown);
