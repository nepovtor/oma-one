export type FinanceMode = 'DEMO' | 'SANDBOX' | 'LIVE';
export type Currency = 'BYN';
export type CardStatus = 'ACTIVE' | 'BLOCKED' | 'PREPARING';
export type TransactionStatus = 'PENDING' | 'AUTHORIZED' | 'SETTLED' | 'DECLINED' | 'REVERSED';
export type TransactionKind = 'PURCHASE' | 'TRANSFER' | 'SERVICE' | 'REFUND' | 'HOME_PROJECT' | 'TOP_UP';
export type PaymentMilestoneStatus = 'PLANNED' | 'MANUALLY_PAID' | 'CANCELLED';

export interface Money {minor: number; currency: Currency}
export interface BankAccount {
 id: string;
 providerAccountId: string;
 name: string;
 balance: Money;
 available: Money;
 source: FinanceMode;
}
export interface CardControls {online: boolean; contactless: boolean; cashWithdrawal: boolean; monthlyLimitMinor: number}
export interface BankCard {
 id: string;
 providerCardId: string;
 accountId: string;
 name: string;
 maskedPan: string;
 status: CardStatus;
 kind: 'VIRTUAL' | 'PHYSICAL';
 network: string | null;
 controls: CardControls;
 source: FinanceMode;
 synthetic: boolean;
}
export interface FinanceTransaction {
 id: string;
 providerTransactionId: string;
 accountId: string;
 occurredAt: string;
 amount: Money;
 direction: 'DEBIT' | 'CREDIT';
 kind: TransactionKind;
 category: string;
 counterparty: string;
 status: TransactionStatus;
 source: FinanceMode;
 projectId: string | null;
 synthetic: boolean;
}
export interface BudgetLine {
 id: string;
 kind: 'MATERIALS' | 'SERVICES' | 'DELIVERY' | 'EXTRA' | 'RESERVE';
 title: string;
 estimatedMinor: number;
 actualMinor: number | null;
 source: 'CART' | 'MANUAL' | 'ZEROBUY';
}
export interface FinancePlan {
 id: string;
 projectId: string;
 projectTitle: string;
 budgetMinor: number;
 lines: BudgetLine[];
 updatedAt: string;
}
export interface FinancePlanSummary {
 estimatedMinor: number;
 actualMinor: number;
 paidMinor: number;
 remainingMinor: number;
 overrunMinor: number;
}
export interface PaymentMilestone {
 id: string;
 projectId: string;
 title: string;
 amountMinor: number;
 date: string;
 stage: string;
 dependsOn: string[];
 status: PaymentMilestoneStatus;
 note: string;
 linkedTransactionId: string | null;
}
export interface SavingsGoal {
 id: string;
 name: string;
 targetMinor: number;
 savedMinor: number;
 targetDate: string;
 projectId: string | null;
 createdAt: string;
}
export interface FinancingInput {
 projectCostMinor: number;
 downPaymentMinor: number;
 termMonths: number;
 annualRateBasisPoints: number;
 feesMinor: number;
}
export interface FinancingSimulation extends FinancingInput {
 financedMinor: number;
 monthlyPaymentMinor: number;
 totalPaymentsMinor: number;
 overpaymentMinor: number;
 totalCostMinor: number;
}
export interface FinanceState {
 version: 1;
 mode: FinanceMode;
 account: BankAccount;
 cards: BankCard[];
 transactions: FinanceTransaction[];
 plans: FinancePlan[];
 milestones: PaymentMilestone[];
 goals: SavingsGoal[];
 lastSimulation: FinancingSimulation;
 updatedAt: string;
}
export interface TransferRequest {amountMinor: number; counterparty: string; note?: string}
export interface TransferResult {transaction: FinanceTransaction; account: BankAccount; notice: string}

const BYN: Currency='BYN';
const positiveInt=(value: number,name: string)=>{
 if(!Number.isSafeInteger(value)||value<0)throw new Error(`${name} must be a non-negative safe integer`);
 return value;
};
const iso=(value: string)=>new Date(value).toISOString();

export function money(minor: number): Money{return {minor:positiveInt(minor,'money'),currency:BYN};}

export function formatMoney(value: Money | number): string{
 const minor=typeof value==='number'?value:value.minor;
 return new Intl.NumberFormat('ru-BY',{style:'currency',currency:'BYN',minimumFractionDigits:2}).format(minor/100);
}

export function maskPan(lastFour: string): string{
 const digits=lastFour.replace(/\D/g,'').slice(-4);
 if(digits.length!==4)throw new Error('Only four display digits are allowed');
 return `•••• ${digits}`;
}

export function summarizePlan(plan: FinancePlan,milestones: PaymentMilestone[]=[]): FinancePlanSummary{
 const estimatedMinor=plan.lines.reduce((sum,line)=>sum+positiveInt(line.estimatedMinor,'estimatedMinor'),0);
 const actualMinor=plan.lines.reduce((sum,line)=>sum+(line.actualMinor===null?line.estimatedMinor:positiveInt(line.actualMinor,'actualMinor')),0);
 const paidMinor=milestones.filter(item=>item.projectId===plan.projectId&&item.status==='MANUALLY_PAID')
  .reduce((sum,item)=>sum+positiveInt(item.amountMinor,'amountMinor'),0);
 return {
  estimatedMinor,
  actualMinor,
  paidMinor,
  remainingMinor:Math.max(0,plan.budgetMinor-actualMinor),
  overrunMinor:Math.max(0,actualMinor-plan.budgetMinor)
 };
}

export function financingSimulation(input: FinancingInput): FinancingSimulation{
 const projectCostMinor=positiveInt(input.projectCostMinor,'projectCostMinor');
 const downPaymentMinor=Math.min(projectCostMinor,positiveInt(input.downPaymentMinor,'downPaymentMinor'));
 const feesMinor=positiveInt(input.feesMinor,'feesMinor');
 const termMonths=Math.min(600,Math.max(1,Math.trunc(input.termMonths)||1));
 const annualRateBasisPoints=Math.min(100_000,positiveInt(input.annualRateBasisPoints,'annualRateBasisPoints'));
 const financedMinor=projectCostMinor-downPaymentMinor;
 const monthlyRate=annualRateBasisPoints/10_000/12;
 const rawMonthly=financedMinor===0?0:monthlyRate===0
  ?financedMinor/termMonths
  :financedMinor*(monthlyRate*Math.pow(1+monthlyRate,termMonths))/(Math.pow(1+monthlyRate,termMonths)-1);
 const monthlyPaymentMinor=Math.round(rawMonthly);
 const totalPaymentsMinor=monthlyPaymentMinor*termMonths;
 return {
  projectCostMinor,downPaymentMinor,termMonths,annualRateBasisPoints,feesMinor,financedMinor,monthlyPaymentMinor,
  totalPaymentsMinor,
  overpaymentMinor:Math.max(0,totalPaymentsMinor-financedMinor),
  totalCostMinor:downPaymentMinor+totalPaymentsMinor+feesMinor
 };
}

export function monthlySavingsNeeded(goal: SavingsGoal,now=new Date()): number{
 const remaining=Math.max(0,positiveInt(goal.targetMinor,'targetMinor')-positiveInt(goal.savedMinor,'savedMinor'));
 const target=new Date(goal.targetDate);
 if(!Number.isFinite(target.getTime())||target<=now)return remaining;
 const months=Math.max(1,(target.getUTCFullYear()-now.getUTCFullYear())*12+target.getUTCMonth()-now.getUTCMonth());
 return Math.ceil(remaining/months);
}

export function validateMilestoneOrder(items: PaymentMilestone[]): {valid: boolean; errors: string[]}{
 const byId=new Map(items.map(item=>[item.id,item]));
 const errors:string[]=[];
 const visiting=new Set<string>(),visited=new Set<string>();
 const visit=(id: string)=>{
  if(visiting.has(id)){errors.push(`Цикл этапов: ${id}`);return;}
  if(visited.has(id))return;
  const item=byId.get(id);if(!item){errors.push(`Неизвестный этап: ${id}`);return;}
  visiting.add(id);
  for(const dependency of item.dependsOn){if(!byId.has(dependency))errors.push(`Для ${id} отсутствует зависимость ${dependency}`);else visit(dependency);}
  visiting.delete(id);visited.add(id);
 };
 for(const item of items)visit(item.id);
 return {valid:errors.length===0,errors:[...new Set(errors)]};
}

export function createDemoFinanceState(now='2026-10-26T09:00:00.000Z'): FinanceState{
 const account:BankAccount={id:'demo-account-1',providerAccountId:'demo-provider-account-001',name:'Основной демо-счёт',balance:money(1_248_630),available:money(1_218_630),source:'DEMO'};
 const cards:BankCard[]=[{id:'demo-card-1',providerCardId:'demo-card-token-2841',accountId:account.id,name:'OMA Finance Virtual',maskedPan:maskPan('2841'),status:'ACTIVE',kind:'VIRTUAL',network:null,controls:{online:true,contactless:false,cashWithdrawal:false,monthlyLimitMinor:300_000},source:'DEMO',synthetic:true}];
 const transaction=(id:string,occurredAt:string,minor:number,direction:'DEBIT'|'CREDIT',kind:TransactionKind,category:string,counterparty:string,status:TransactionStatus='SETTLED',projectId:string|null=null):FinanceTransaction=>({id,providerTransactionId:`demo-partner-${id}`,accountId:account.id,occurredAt:iso(occurredAt),amount:money(minor),direction,kind,category,counterparty,status,source:'DEMO',projectId,synthetic:true});
 const transactions=[
  transaction('tx-1','2026-10-25T15:42:00+03:00',8_950,'DEBIT','PURCHASE','Кафе','Кофейня у парка · синтетический пример'),
  transaction('tx-2','2026-10-24T18:20:00+03:00',3_400,'DEBIT','PURCHASE','Транспорт','Городской транспорт · синтетический пример','AUTHORIZED'),
  transaction('tx-3','2026-10-23T12:10:00+03:00',28_600,'DEBIT','HOME_PROJECT','Материалы','Материалы для полки · демо', 'SETTLED','shelf-local'),
  transaction('tx-4','2026-10-22T09:05:00+03:00',150_000,'CREDIT','TOP_UP','Пополнение','Демо-пополнение'),
  transaction('tx-5','2026-10-20T17:30:00+03:00',6_800,'CREDIT','REFUND','Возврат','Возврат магазина · синтетический пример','REVERSED')
 ];
 const plans:FinancePlan[]=[{id:'plan-shelf',projectId:'shelf-local',projectTitle:'Повесить полку',budgetMinor:55_000,updatedAt:iso(now),lines:[
  {id:'line-materials',kind:'MATERIALS',title:'Материалы после ZeroBuy',estimatedMinor:11_200,actualMinor:null,source:'ZEROBUY'},
  {id:'line-services',kind:'SERVICES',title:'Работа мастера',estimatedMinor:18_000,actualMinor:null,source:'MANUAL'},
  {id:'line-delivery',kind:'DELIVERY',title:'Доставка',estimatedMinor:2_500,actualMinor:null,source:'MANUAL'},
  {id:'line-extra',kind:'EXTRA',title:'Дополнительные расходы',estimatedMinor:3_000,actualMinor:null,source:'MANUAL'},
  {id:'line-reserve',kind:'RESERVE',title:'Резерв',estimatedMinor:5_000,actualMinor:null,source:'MANUAL'}
 ]}];
 const milestones:PaymentMilestone[]=[
  {id:'ms-materials',projectId:'shelf-local',title:'Купить материалы',amountMinor:11_200,date:'2026-11-02',stage:'Подготовка',dependsOn:[],status:'PLANNED',note:'Сумма после ZeroBuy',linkedTransactionId:null},
  {id:'ms-install',projectId:'shelf-local',title:'Монтаж полки',amountMinor:18_000,date:'2026-11-05',stage:'Монтаж',dependsOn:['ms-materials'],status:'PLANNED',note:'Ручная стоимость мастера',linkedTransactionId:null}
 ];
 const goals:SavingsGoal[]=[{id:'goal-bathroom',name:'Обновление ванной',targetMinor:800_000,savedMinor:215_000,targetDate:'2027-05-01',projectId:null,createdAt:iso(now)}];
 return {version:1,mode:'DEMO',account,cards,transactions,plans,milestones,goals,lastSimulation:financingSimulation({projectCostMinor:550_000,downPaymentMinor:150_000,termMonths:24,annualRateBasisPoints:1800,feesMinor:12_000}),updatedAt:iso(now)};
}

export function applyDemoTransfer(state: FinanceState,input: TransferRequest,kind:'TRANSFER'|'TOP_UP'='TRANSFER',now=new Date()): TransferResult{
 if(state.mode!=='DEMO')throw new Error('Demo mutation is isolated from Sandbox and Live');
 const amountMinor=positiveInt(input.amountMinor,'amountMinor');
 if(amountMinor<100)throw new Error('Минимальная демо-сумма — 1 BYN');
 if(kind==='TRANSFER'&&amountMinor>state.account.available.minor)throw new Error('Недостаточно синтетического остатка');
 const direction=kind==='TOP_UP'?'CREDIT':'DEBIT';
 const id=`demo-${kind.toLowerCase()}-${now.getTime()}`;
 const transaction:FinanceTransaction={id,providerTransactionId:`demo-local-${id}`,accountId:state.account.id,occurredAt:now.toISOString(),amount:money(amountMinor),direction,kind,category:kind==='TOP_UP'?'Пополнение':'Переводы',counterparty:input.counterparty.trim().slice(0,80)||'Демо-получатель',status:'SETTLED',source:'DEMO',projectId:null,synthetic:true};
 const delta=direction==='CREDIT'?amountMinor:-amountMinor;
 state.account={...state.account,balance:money(state.account.balance.minor+delta),available:money(state.account.available.minor+delta)};
 state.transactions=[transaction,...state.transactions];state.updatedAt=now.toISOString();
 return {transaction,account:state.account,notice:'Синтетическая операция добавлена только в демонстрационный журнал. Реальные деньги не перемещались.'};
}
