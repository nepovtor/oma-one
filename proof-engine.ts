// OMA ONE - deterministic, auditable, DEMO-ONLY decision prototypes (TypeScript source).
// Each function is independent of a generative model and external services.
import {createHash} from 'node:crypto';

export const PROOF_VERSION='2026-10-25-evidence.3';
export interface ProofOutcome<Input = unknown, Result = unknown> {
 module: string;
 version: string;
 what: string;
 inputs: Input;
 result: Result;
 explanation: string;
 limits: string[];
 stats: Record<string, unknown>;
 source: string;
}

export interface ZeroBuyRequirement {id: string; name?: string; qty: number; unitPrice: number}
export interface ZeroBuyInventory {id: string; qty: number}
export interface ZeroBuyInput {requirements?: ZeroBuyRequirement[]; inventory?: ZeroBuyInventory[]}
export interface AntiFailInput {surface?: string; fastener?: string; loadKg?: number; verifiedWiring?: boolean}
export interface DominoStep {id: string; name?: string; after?: string[]}
export interface DominoInput {order?: string[]; steps?: DominoStep[]}
export interface SyncRequest {id: string; city: string; zone: string; slot: string; service: string}
export interface SyncCityInput {requests?: SyncRequest[]; selectedId?: string; sharedTripCost?: number; individualTripCost?: number; minGroup?: number}
export interface SyncCityResult {eligible: boolean; requestCount: number; matchIds: string[]; individualTotal: number; combinedTotal: number | null; savingsPerUser: number; reason: string}
export interface ProofStep {code: string; done: boolean}
export interface ProofInspector {id: string; approved: boolean}
export interface ProofInput {projectId?: string; steps?: ProofStep[]; photoHashes?: string[]; inspector?: ProofInspector | null; ownerConsent?: boolean}
export type ProofStatus = 'IN_PROGRESS' | 'SELF_REPORTED' | 'EVIDENCE_SUBMITTED' | 'EXPERT_VERIFIED';
export interface ProofState {
 status: ProofStatus;
 checklistComplete: boolean;
 evidenceSubmitted: boolean;
 expertVerified: boolean;
 canPublishToDNA: boolean;
 photoCount: number;
 inspectorId: string | null;
}
export interface DnaTemplate {id: string; homeType: string; room: string; area: number; inspection?: string}
export interface DnaInput {templates?: DnaTemplate[]; homeType?: string; room?: string; area?: number; qtyPerM2?: number}
export interface ForgeProject {id: string; userId?: string; problem: string; homeType: string; optIn: boolean}
export interface ForgeCost {id: string; cost: number}
export interface ForgeInput {projects?: ForgeProject[]; skuCosts?: ForgeCost[]; interestThreshold?: number; minGrossMargin?: number; assemblyCost?: number}
export interface PulseReport {userId: string; model: string; verifiedByExpert: boolean}
export interface PulseInput {reports?: PulseReport[]; cohortSize?: number; minCases?: number; minCohort?: number; expertApproved?: boolean; reviewerId?: string | null}
export interface EconomicsInput {basket?: number; margin?: number; service?: number; commission?: number; fulfillment?: number; acquisition?: number; support?: number; returns?: number; fixedCost?: number}

const number = (v: unknown,min: number,max: number,def: number): number => { const n=Number(v);return Number.isFinite(n)?Math.min(max,Math.max(min,n)):def; };
const money = (x: number): number => Math.round((x+Number.EPSILON)*100)/100;
const assertArray = <T>(v: T[] | unknown): T[]=>Array.isArray(v)?v as T[]:[];
const idText = (x: unknown): string => String(x ?? '').slice(0,100);
const outcome = <Input, Result>(code: string,what: string,inputs: Input,result: Result,explanation: string,limits: string[]=[],stats: Record<string, unknown>={}): ProofOutcome<Input, Result>=>({module:code,version:PROOF_VERSION,what,inputs,result,explanation,limits,stats,source:'Synthetic fixtures or user-entered inputs; deterministic demo rules, never verified OMA operations'});

export function zeroBuy({requirements=[],inventory=[]}: ZeroBuyInput={}){
 const known=new Map<string, number>();for(const i of assertArray<ZeroBuyInventory>(inventory)){const k=idText(i.id);const q=number(i.qty,0,10000,0); known.set(k,(known.get(k)||0)+q);}
 const items=assertArray<ZeroBuyRequirement>(requirements).map(r=>{const id=idText(r.id),required=number(r.qty,0,10000,0),owned=Math.min(required,known.get(id)||0),unitPrice=number(r.unitPrice,0,1e6,0);known.set(id,Math.max(0,(known.get(id)||0)-owned));return {id,name:idText(r.name||id),required,owned,toBuy:required-owned,unitPrice,saved:money(owned*unitPrice),pay:money((required-owned)*unitPrice)};});
 const full=money(items.reduce((a,b)=>a+b.required*b.unitPrice,0)),after=money(items.reduce((a,b)=>a+b.pay,0));
 return outcome('ZeroBuy','Verified subtraction and no double-counting',{requirements,inventory},{items,full,after,savings:money(full-after)},'Owned items are subtracted once, never below zero; savings refer to avoided demo purchase, not net lifetime savings.',['Inventory is self-reported and does not prove suitability or condition.'],{items:items.length});
}
const compatibility: Record<string, string[]>={concrete:['concrete-anchor'],drywall:['drywall-anchor'],wood:['wood-screw']};
export function antiFail({surface='concrete',fastener='concrete-anchor',loadKg=8,verifiedWiring=false}: AntiFailInput={}){
 const risk=[],critical=[];
 if(!compatibility[surface])risk.push('Unknown wall substrate: an installer must identify it.');
 else if(!compatibility[surface].includes(fastener))critical.push(`Fastener ${fastener} is not mapped as compatible with ${surface}.`);
 const load=number(loadKg,0,1000,8);
 if(load>15)risk.push('Load above demo threshold 15 kg: professional check required.');
 if(!verifiedWiring)risk.push('Hidden pipes/wiring not checked. Do not drill before checking.');
 const status=critical.length?'BLOCKED':risk.length?'REVIEW':'PRELIMINARY_PASS';
 return outcome('AntiFail','Compatibility + safety gate',{surface,fastener,loadKg:load,verifiedWiring},{status,canAutoApprove:false,critical,risk,suggestedFasteners:compatibility[surface]||[]},'Rule engine never certifies a safe installation, even for a preliminary pass.',['Illustrative compatibility map only; load limits, wall thickness and manufacturer documentation require specialist review.']);
}
const bathroomSteps: DominoStep[]=[{id:'inspect',name:'Survey',after:[]},{id:'pipes',name:'Pipes',after:['inspect']},{id:'waterproof',name:'Waterproofing',after:['pipes']},{id:'tiles',name:'Tiling',after:['waterproof']},{id:'finish',name:'Finish and inspect',after:['tiles']}];
export function domino({order=['inspect','pipes','waterproof','tiles','finish'],steps=bathroomSteps}: DominoInput={}){
	 const ids=assertArray<DominoStep>(steps).map(s=>s.id),orderIds=assertArray<string>(order).map(idText),errors: string[]=[];
 if(new Set(ids).size!==ids.length)errors.push('Duplicate step IDs in graph.');
 if(new Set(orderIds).size!==orderIds.length||orderIds.length!==ids.length||ids.some(id=>!orderIds.includes(id)))errors.push('Order must contain each project step exactly once.');
 const pos=new Map(orderIds.map((s,i)=>[s,i]));
	 for(const s of steps)for(const pre of s.after||[]){const prerequisitePosition=pos.get(pre),stepPosition=pos.get(s.id);if(!ids.includes(pre))errors.push(`Unknown dependency: ${pre}`);else if(prerequisitePosition!==undefined&&stepPosition!==undefined&&prerequisitePosition>stepPosition)errors.push(`${s.id} requires ${pre} first.`);}
 const suggested: string[]=[],pending=new Map<string, DominoStep>(steps.map(s=>[s.id,s]));
 while(pending.size){const ready=[...pending.values()].filter(s=>(s.after||[]).every(dep=>suggested.includes(dep))).sort((a,b)=>ids.indexOf(a.id)-ids.indexOf(b.id));if(!ready.length){errors.push('Cyclic dependency graph.');break;}for(const s of ready){suggested.push(s.id);pending.delete(s.id);}}
 return outcome('Domino','Topological dependency validation',{order:orderIds,steps},{valid:errors.length===0,errors,suggested},'An invalid order is rejected; the solver returns a topological order if the dependency graph is acyclic.',['Dependency graph must be approved by a construction specialist; times/costs are not inferred.']);
}
export function syncCity({requests=[],selectedId='r1',sharedTripCost=48,individualTripCost=24,minGroup=3}: SyncCityInput={}): ProofOutcome<{selectedId: string; sharedTripCost?: number; individualTripCost?: number; minGroup?: number; requests?: SyncRequest[]}, SyncCityResult>{
 const list=assertArray<SyncRequest>(requests),selected=list.find(x=>x.id===selectedId);
	 if(!selected)return outcome('SyncCity','Privacy-preserving logistics match',{requests,selectedId},{eligible:false,requestCount:0,matchIds:[],individualTotal:0,combinedTotal:null,savingsPerUser:0,reason:'Request not found'},'No match means no discount.');
 const matches=list.filter(x=>x.city===selected.city&&x.zone===selected.zone&&x.slot===selected.slot&&x.service===selected.service&&x.id!==selectedId);
 const members=matches.length+1,threshold=number(minGroup,2,20,3),single=number(individualTripCost,0,2000,24),shared=number(sharedTripCost,0,2000,48);
 const eligible=members>=threshold&&shared<members*single;
 const savingsPerUser=eligible?money(single-shared/members):0;
 return outcome('SyncCity','Delivery/service bundling by zone and slot',{selectedId,sharedTripCost:shared,individualTripCost:single,minGroup:threshold},{eligible,requestCount:members,matchIds:matches.map(x=>x.id),individualTotal:money(members*single),combinedTotal:eligible?shared:null,savingsPerUser,reason:eligible?'Synthetic candidate group: partner quote still required.':'Threshold or business case not met.'},'User identity and full addresses are excluded from match output; no real booking or guaranteed price.',['No real partner pricing or participant consent exists; coordinator must validate operational feasibility.']);
}
export function evaluateProofState({steps=[],photoHashes=[],inspector=null,ownerConsent=false}: ProofInput={}): ProofState{
 const checklist=assertArray<ProofStep>(steps),photos=assertArray<string>(photoHashes).filter(x=>/^[a-f0-9]{64}$/.test(String(x))).map(String);
 const checklistComplete=checklist.length>0&&checklist.every(x=>x.done===true),evidenceSubmitted=checklistComplete&&photos.length>0;
 const inspectorId=typeof inspector?.id==='string'&&inspector.id.trim()?idText(inspector.id):null;
 const expertVerified=evidenceSubmitted&&inspector?.approved===true&&inspectorId!==null;
 const status: ProofStatus=expertVerified?'EXPERT_VERIFIED':evidenceSubmitted?'EVIDENCE_SUBMITTED':checklistComplete?'SELF_REPORTED':'IN_PROGRESS';
 return {status,checklistComplete,evidenceSubmitted,expertVerified,canPublishToDNA:expertVerified&&ownerConsent,photoCount:photos.length,inspectorId:expertVerified?inspectorId:null};
}
export function proof({projectId='demo-p1',steps=[],photoHashes=[],inspector=null,ownerConsent=false}: ProofInput={}){
 const checklist=assertArray<ProofStep>(steps),photos=assertArray<string>(photoHashes).filter(x=>/^[a-f0-9]{64}$/.test(String(x))).map(String);
 const state=evaluateProofState({steps:checklist,photoHashes:photos,inspector,ownerConsent});
 const attestation={projectId:idText(projectId),checklist:checklist.map(x=>({code:idText(x.code),done:x.done===true})),photoHashes:photos,inspector:state.inspectorId,status:state.status};
 const digest=createHash('sha256').update(JSON.stringify(attestation)).digest('hex');
 return outcome('Proof','Traceable evidence record, not automatic certification',{projectId,steps,photoHashesCount:photos.length,inspector:state.inspectorId,ownerConsent},{...state,digest,completed:state.checklistComplete},'Hash identifies this exact record; user self-report and submitted evidence are NEVER labelled professionally inspected.',['A digest is not proof that a photo is genuine. Real uploads require metadata stripping, privacy consent and independent inspection.']);
}

export const SHELF_STEPS: DominoStep[]=[
 {id:'inspect',name:'Осмотреть стену и её состояние',after:[]},
 {id:'utilities',name:'Проверить скрытые коммуникации',after:['inspect']},
 {id:'load',name:'Уточнить вес и допустимую нагрузку',after:['inspect']},
 {id:'fastener',name:'Сверить крепёж с инструкцией',after:['utilities','load']},
 {id:'mount',name:'Выполнить монтаж',after:['fastener']},
 {id:'final',name:'Проверить результат',after:['mount']}
];
export type ShelfReadiness='incomplete'|'blocked'|'review'|'candidate';
export interface ShelfCatalogProduct {id: string; name?: string; unitPrice: number}
export interface ShelfDecisionInput {
 projectId?: string;
 surface?: string;
 fastener?: string;
 shelfWeightKg?: number;
 plannedLoadKg?: number;
 wallInspected?: boolean;
 verifiedWiring?: boolean;
 manufacturerInstructionsChecked?: boolean;
 products?: ShelfCatalogProduct[];
 inventory?: ZeroBuyInventory[];
 completedStepIds?: string[];
 photoHashes?: string[];
}
const shelfFastenerProduct: Record<string,string>={'concrete-anchor':'p08','drywall-anchor':'p09'};
const uniqueShelfStepIds=(value: unknown): string[]=>{
 const allowed=new Set(SHELF_STEPS.map(step=>step.id));
 return [...new Set(assertArray<unknown>(value as unknown[]).map(idText).filter(id=>allowed.has(id)))];
};
export function canCompleteShelfStep(completedStepIds: string[],stepId: string): boolean{
 const completed=uniqueShelfStepIds(completedStepIds),step=SHELF_STEPS.find(item=>item.id===stepId);
 return Boolean(step&&(step.after||[]).every(dependency=>completed.includes(dependency)));
}
export function toggleShelfStep(completedStepIds: string[],stepId: string): string[]{
 let completed=uniqueShelfStepIds(completedStepIds);
 if(completed.includes(stepId)){
  const blocked=new Set<string>([stepId]);let changed=true;
  while(changed){changed=false;for(const step of SHELF_STEPS)if((step.after||[]).some(dependency=>blocked.has(dependency))&&!blocked.has(step.id)){blocked.add(step.id);changed=true;}}
  completed=completed.filter(id=>!blocked.has(id));
 }else if(canCompleteShelfStep(completed,stepId))completed=[...completed,stepId];
 return completed;
}
export function shelfDecision(input: ShelfDecisionInput={}){
 const surface=idText(input.surface||'unknown'),fastener=idText(input.fastener||'unknown');
 const shelfWeightKg=number(input.shelfWeightKg,0,1000,0),plannedLoadKg=number(input.plannedLoadKg,0,1000,0),totalLoadKg=money(shelfWeightKg+plannedLoadKg);
 const safety=antiFail({surface,fastener,loadKg:totalLoadKg,verifiedWiring:input.verifiedWiring===true}).result;
 const completeInputs=surface!=='unknown'&&shelfWeightKg>0&&plannedLoadKg>0&&fastener!=='unknown';
 const fastenerProductId=shelfFastenerProduct[fastener];let readiness: ShelfReadiness='incomplete';
 if(completeInputs){
  if(safety.status==='BLOCKED')readiness='blocked';
  else if(safety.status==='PRELIMINARY_PASS'&&input.wallInspected===true&&input.manufacturerInstructionsChecked===true&&Boolean(fastenerProductId))readiness='candidate';
  else readiness='review';
 }
 const candidateProductIds=readiness==='candidate'?['p07',fastenerProductId,'p25'].filter((id): id is string=>Boolean(id)):[];
 const catalog=new Map(assertArray<ShelfCatalogProduct>(input.products).map(product=>[idText(product.id),product]));
 const requirements=candidateProductIds.map(id=>{const product=catalog.get(id);return {id,name:idText(product?.name||id),qty:1,unitPrice:number(product?.unitPrice,0,1e6,0)};});
 const basket=zeroBuy({requirements,inventory:assertArray<ZeroBuyInventory>(input.inventory)}).result;
 const completedStepIds=uniqueShelfStepIds(input.completedStepIds),order=[...completedStepIds,...SHELF_STEPS.map(step=>step.id).filter(id=>!completedStepIds.includes(id))];
 const sequence=domino({order,steps:SHELF_STEPS}).result;
 const proofState=evaluateProofState({
  projectId:input.projectId,
  steps:SHELF_STEPS.map(step=>({code:step.id,done:sequence.valid&&completedStepIds.includes(step.id)})),
  photoHashes:input.photoHashes
 });
 return outcome('Shelf','AntiFail + ZeroBuy + Domino + Proof contract',{projectId:idText(input.projectId||'local-shelf'),surface,fastener,shelfWeightKg,plannedLoadKg,wallInspected:input.wallInspected===true,verifiedWiring:input.verifiedWiring===true,manufacturerInstructionsChecked:input.manufacturerInstructionsChecked===true,products:assertArray<ShelfCatalogProduct>(input.products),inventory:assertArray<ZeroBuyInventory>(input.inventory),completedStepIds,photoHashesCount:proofState.photoCount},{readiness,totalLoadKg,candidateProductIds,antiFail:safety,zeroBuy:basket,domino:sequence,proof:proofState},'One canonical shelf decision composes the four evidence mechanisms for every client.',['Synthetic compatibility and catalog inputs do not certify a real installation.']);
}
export function dna({templates=[],homeType='panel',room='bath',area=4,qtyPerM2=1.1}: DnaInput={}){
 const a=number(area,0.5,200,4),q=number(qtyPerM2,1,2,1.1);
 const ranked=assertArray<DnaTemplate>(templates).map(t=>{const type=t.homeType===homeType,place=t.room===room,delta=Math.abs(number(t.area,0,200,0)-a)/a,score=Math.max(0,Math.round((type?35:0)+(place?35:0)+Math.max(0,30-50*delta)));
 const sampleVerified=t.inspection==='professional',candidate=score>=70&&sampleVerified;
 return {id:t.id,score,eligible:candidate,verification:t.inspection||'none',referenceArea:t.area,adaptedUnits:place?Math.ceil(a*q):null,reason:candidate?'Matches type, room, and professionally inspected template.':'Review required: similarity does not certify compatibility.'}; }).sort((x,y)=>y.score-x.score);
 return outcome('DNA','Ranking and room-specific adaptation',{homeType,room,area:a,qtyPerM2:q},{templates:ranked,best:ranked[0]||null},'Similarity score is a DEMO ranking, not a calibrated probability or proof of engineering compatibility.',['A real match needs dimensions, plumbing, structure, material specs, consent and moderation.'],{considered:ranked.length});
}
export function forge({projects=[],skuCosts=[],interestThreshold=4,minGrossMargin=.15,assemblyCost=30}: ForgeInput={}){
 const paid=assertArray<ForgeProject>(projects).filter(p=>p.optIn===true),counts: Record<string, number>={},unique=new Set<string>();for(const p of paid){const k=idText(p.problem)+'|'+idText(p.homeType),participant=idText(p.userId||p.id);const scoped=k+'|'+participant;if(!participant||unique.has(scoped))continue;unique.add(scoped);counts[k]=(counts[k]||0)+1;}
 const clusters=Object.entries(counts).map(([key,n])=>({key,interested:n,threshold:interestThreshold,canPropose:n>=interestThreshold})).sort((a,b)=>b.interested-a.interested);
 const netCost=money(assertArray<ForgeCost>(skuCosts).reduce((n,x)=>n+number(x.cost,0,1e6,0),0)+number(assemblyCost,0,1e6,30));const minPrice=money(netCost/(1-number(minGrossMargin,0,.9,.15)));
 return outcome('FORGE','New kit opportunity, backed by opt-in demand',{projects,interestThreshold,skuCosts,assemblyCost},{clusters,netCost,minimumIndicativePrice:minPrice,status:'PROPOSAL_ONLY',mayPublishPrice:false},'Interest is NOT an order; kit remains a proposal until buyer, category owner and supplier verify economics.',['Gross margin excludes returns, shrinkage, marketing and overhead; all data and costs synthetic.']);
}
export function pulse({reports=[],cohortSize=120,minCases=3,minCohort=30,expertApproved=false,reviewerId=null}: PulseInput={}){
 const valid=assertArray<PulseReport>(reports).filter(r=>r.verifiedByExpert===true && r.model && r.userId),byModel: Record<string, Set<string>>={};for(const r of valid){const key=idText(r.model),set=byModel[key]||new Set<string>();set.add(idText(r.userId));byModel[key]=set;}
 const cohort=number(cohortSize,0,1e7,120),signals=Object.entries(byModel).map(([model,users])=>{const cases=users.size,qualified=cases>=minCases&&cohort>=minCohort&&cases<=cohort;return {model,distinctVerifiedCases:cases,cohortSize:cohort,observedRate:cohort?money(cases/cohort*100):null,qualifiedForManualReview:qualified,mayNotifyExternally:qualified&&expertApproved&&typeof reviewerId==='string'&&reviewerId.length>0};}).sort((a,b)=>b.distinctVerifiedCases-a.distinctVerifiedCases);
 return outcome('PULSE','Verified independent incidents + review gate',{reportsCount:reports.length,cohortSize:cohort,minCases,minCohort,expertApproved,reviewerId:reviewerId||null},{signals,notificationsSent:0},'An incident cluster is only a hypothesis. No customer notification is sent in the demo; a professional must authorize a real outreach.',['Selection and reporting biases; population denominator not independently validated. This is not a product-recall or safety finding.']);
}
export function economics({basket=300,margin=.2,service=140,commission=.12,fulfillment=35,acquisition=15,support=7,returns=5,fixedCost=3000}: EconomicsInput={}){
 const b=number(basket,0,1e6,300),m=number(margin,0,1,.2),s=number(service,0,1e6,140),c=number(commission,0,1,.12);
 const costs=number(fulfillment,0,1e6,35)+number(acquisition,0,1e6,15)+number(support,0,1e6,7)+number(returns,0,1e6,5);const contribution=money(b*m+s*c-costs);
 return outcome('Economics','Auditable unit economics and break-even',{basket:b,margin:m,service:s,commission:c,fulfillment,acquisition,support,returns,fixedCost},{grossProfit:money(b*m),commissionRevenue:money(s*c),variableCosts:money(costs),contribution,breakEvenOrders:contribution>0?Math.ceil(number(fixedCost,0,1e9,3000)/contribution):null,profitablePerOrder:contribution>0},'Every number is an explicit editable assumption, not a financial metric supplied by OMA.',['Excludes taxes, financing, capacity, refund tail risk and supplier contractual terms.']);
}
export const RUNNERS={zerobuy:zeroBuy,antifail:antiFail,domino,synccity:syncCity,proof,dna,forge,pulse,economics};
export type ProofModuleId = keyof typeof RUNNERS;
