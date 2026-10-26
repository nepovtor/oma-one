import {applyDemoTransfer,createDemoFinanceState,financingSimulation,formatMoney,monthlySavingsNeeded,summarizePlan,validateMilestoneOrder} from '../finance-domain.js';
import type {BankCard,FinancePlan,FinanceState,FinanceTransaction,SavingsGoal,TransactionKind} from '../finance-domain.js';

let state:FinanceState;
let owner='demo1';
let screen='dashboard';
let transactionFilter:TransactionKind|null=null;
let revision=0;
const entities:Record<string,string>={'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'};
const esc=(value:unknown)=>String(value??'').replace(/[&<>"']/g,char=>entities[char]||char);
const storageKey=()=>`oma-finance-demo-v1:${owner}`;
const persist=()=>localStorage.setItem(storageKey(),JSON.stringify(state));
const date=(value:string)=>new Date(value).toLocaleDateString('ru-RU',{day:'numeric',month:'short',year:'numeric'});
const minorFromInput=(value:string)=>{
 const normalized=value.trim().replace(',','.');
 if(!/^\d+(\.\d{1,2})?$/.test(normalized))throw new Error('Введите сумму с точностью не более двух знаков');
 const [whole,fraction='']=normalized.split('.');
 const result=Number(whole)*100+Number(fraction.padEnd(2,'0'));
 if(!Number.isSafeInteger(result))throw new Error('Сумма слишком велика');
 return result;
};

export function loadFinanceState(userId:string){
 owner=userId;
 try{const raw=localStorage.getItem(storageKey());const parsed=raw?JSON.parse(raw):null;if(parsed?.version===1&&parsed?.mode==='DEMO'&&parsed?.account&&Array.isArray(parsed?.plans)){state=parsed;return;}}catch{}
 state=createDemoFinanceState();persist();
}

export function replaceFinanceState(next:FinanceState){if(next.mode!=='DEMO')throw new Error('PWA Stage 1 accepts only isolated DEMO state');state=next;persist();}
export function hydrateFinanceState(payload:{revision:number;state:FinanceState}){if(payload.state.mode!=='DEMO')throw new Error('PWA Stage 1 accepts only isolated DEMO state');revision=payload.revision;state=payload.state;persist();}
export function financeSavePayload(){return {revision,state};}
export function acceptFinanceSave(payload:{revision:number;state:FinanceState}){revision=payload.revision;replaceFinanceState(payload.state);}
export function currentFinanceState(){return state;}

export function syncFinanceMaterials(cartMinor:number){
 if(!state||!Number.isSafeInteger(cartMinor)||cartMinor<=0)return;
 const plan=state.plans.find(item=>item.projectId==='shelf-local'),line=plan?.lines.find(item=>item.kind==='MATERIALS');
 if(!plan||!line||line.estimatedMinor===cartMinor)return;
 line.estimatedMinor=cartMinor;line.source='ZEROBUY';line.title='Материалы из корзины после ZeroBuy';plan.updatedAt=new Date().toISOString();state.updatedAt=plan.updatedAt;persist();
}

const statusLabel=(status:string)=>({ACTIVE:'Активна',BLOCKED:'Заблокирована',PREPARING:'Готовится',PENDING:'Ожидает',AUTHORIZED:'Авторизована',SETTLED:'Завершена',DECLINED:'Отклонена',REVERSED:'Отменена'}[status]||status);
const navButton=(id:string,label:string)=>`<button class="finance-subnav-button ${screen===id?'active':''}" data-action="finance-nav" data-id="${id}">${label}</button>`;
const heading=(title:string,description:string)=>`<div class="finance-heading"><div><h1 tabindex="-1">${title}</h1><p>${description}</p></div><span class="finance-mode">${state.mode} · демонстрация</span></div>`;

export function pageFinance(materialMinor:number){
 syncFinanceMaterials(materialMinor);
 const pages:Record<string,()=>string>={dashboard, cards, history, budgets, milestones, simulation, goals};
 return `<section class="finance-shell" data-ui>${heading(screen==='dashboard'?'OMA Finance':({cards:'Мои карты',history:'История операций',budgets:'Бюджеты проектов',milestones:'План платежей',simulation:'Финансирование',goals:'Финансовые цели'}[screen]||'OMA Finance'),'Банковская демонстрация и финансовое управление жильём. Реальные деньги не используются.')}
 <nav class="finance-subnav" aria-label="Разделы OMA Finance">${navButton('dashboard','Обзор')}${navButton('cards','Карты')}${navButton('history','Операции')}${navButton('budgets','Бюджеты')}${navButton('milestones','Платежи')}${navButton('simulation','Калькулятор')}${navButton('goals','Цели')}</nav>
 ${(pages[screen]||dashboard)()}</section>`;
}

function dashboard(){const plan=state.plans[0],summary=summarizePlan(plan,state.milestones);return `
<div class="finance-dashboard">
 <section class="finance-account" aria-label="Синтетический банковский счёт"><div class="finance-account-top"><strong>${esc(state.account.name)}</strong><span>Демонстрация</span></div><div class="finance-balance">${formatMoney(state.account.balance)}</div><div class="finance-account-meta"><span>Доступно <b>${formatMoney(state.account.available)}</b></span><span>${esc(state.cards[0]?.maskedPan||'Карта не создана')} · ${statusLabel(state.cards[0]?.status||'')}</span></div><p>Синтетические данные. Счёт и карта не принимают и не хранят реальные деньги.</p></section>
 <div class="finance-actions"><button data-action="finance-nav" data-id="cards"><b>Мои карты</b><span>Управление DEMO</span></button><button data-action="finance-open-operation" data-id="transfer"><b>Перевести</b><span>Синтетическая запись</span></button><button data-action="finance-open-operation" data-id="topup"><b>Пополнить</b><span>Синтетическая запись</span></button><button data-action="finance-nav" data-id="history"><b>История</b><span>${state.transactions.length} операций</span></button></div>
 <div class="finance-grid-main">
  <section class="finance-panel"><div class="finance-panel-head"><div><h2>${esc(plan.projectTitle)}</h2><p>Домашний проект</p></div><button data-action="finance-nav" data-id="budgets">Открыть бюджет</button></div><div class="finance-plan-answer"><span>Остаток плана</span><strong>${formatMoney(summary.remainingMinor)}</strong></div><div class="finance-plan-track"><i style="width:${Math.min(100,Math.round(summary.actualMinor/Math.max(1,plan.budgetMinor)*100))}%"></i></div><div class="finance-plan-meta"><span>Смета ${formatMoney(summary.actualMinor)}</span><span>Лимит ${formatMoney(plan.budgetMinor)}</span></div></section>
  <section class="finance-panel"><div class="finance-panel-head"><div><h2>Планирование</h2><p>Без банковской заявки</p></div></div><div class="finance-tool-links"><button data-action="finance-nav" data-id="simulation"><b>${formatMoney(state.lastSimulation.monthlyPaymentMinor)}</b><span>Расчётный платёж</span></button><button data-action="finance-nav" data-id="goals"><b>${state.goals.length}</b><span>Личных целей</span></button><button data-action="finance-nav" data-id="milestones"><b>${state.milestones.filter(item=>item.status==='PLANNED').length}</b><span>Запланировано</span></button></div></section>
 </div>
 ${transactionList(state.transactions.slice(0,4),'Последние операции')}
 <p class="finance-disclaimer">Stage 1 · Неофициальный демонстрационный контур OMA ONE. LIVE заблокирован до договора, разрешений и технической проверки лицензированного финансового партнёра.</p>
</div>`;}

function cards(){return `<div class="finance-content-grid"><section class="finance-panel"><div class="finance-panel-head"><div><h2>Тестовые карты</h2><p>Все идентификаторы синтетические</p></div><button data-action="finance-card-create">Новая демо-карта</button></div>${state.cards.map(cardRow).join('')}</section><section class="finance-panel finance-aside"><h2>Физическая карта</h2><p>Функция готовится к подключению. Адрес доставки и паспортные сведения не собираются.</p><h3>Универсальные платежи</h3><p>Сеть, география, валюты, NFC и системный кошелёк сможет определить только будущий лицензированный эмитент.</p></section></div>`;}
function cardRow(card:BankCard){return `<article class="finance-card-row"><div><strong>${esc(card.name)}</strong><span>${esc(card.maskedPan)} · ${statusLabel(card.status)}</span><small>${card.kind} · ${card.source} · сеть не указана</small></div><div class="finance-card-controls"><label><input type="checkbox" data-action="finance-card-online" data-id="${card.id}" ${card.controls.online?'checked':''}> Онлайн</label><button data-action="finance-card-toggle" data-id="${card.id}">${card.status==='BLOCKED'?'Разблокировать':'Заблокировать'}</button></div><p>Не работает для настоящих покупок.</p></article>`;}

function transactionList(rows:FinanceTransaction[],title:string){return `<section class="finance-panel finance-transactions"><div class="finance-panel-head"><div><h2>${title}</h2><p>${rows.length?`${rows.length} синтетических записей`:'Нет записей для фильтра'}</p></div>${screen==='dashboard'?'<button data-action="finance-nav" data-id="history">Все операции</button>':''}</div>${rows.length?rows.map(transactionRow).join(''):'<div class="finance-empty">Измени фильтр или добавь DEMO-операцию.</div>'}</section>`;}
function transactionRow(item:FinanceTransaction){return `<article class="finance-transaction"><div><strong>${esc(item.counterparty)}</strong><span>${esc(item.category)} · ${date(item.occurredAt)}</span><small>${statusLabel(item.status)} · ${item.source} · ID ${esc(item.providerTransactionId.slice(0,22))}</small></div><b class="finance-amount">${item.direction==='CREDIT'?'+':'−'}${formatMoney(item.amount)}</b></article>`;}
function history(){const filters:[TransactionKind|null,string][]=[[null,'Все'],['PURCHASE','Покупки'],['TRANSFER','Переводы'],['SERVICE','Услуги'],['REFUND','Возвраты'],['HOME_PROJECT','Проекты']];const rows=transactionFilter?state.transactions.filter(item=>item.kind===transactionFilter):state.transactions;return `<div class="finance-filter-row">${filters.map(([value,label])=>`<button class="${transactionFilter===value?'active':''}" data-action="finance-filter" data-id="${value||'ALL'}">${label}</button>`).join('')}</div>${transactionList(rows,'Журнал операций')}`;}

function budgets(){return `<div class="finance-budget-list">${state.plans.map(planCard).join('')}<button class="finance-add" data-action="finance-plan-create">Создать бюджет</button></div>`;}
function planCard(plan:FinancePlan){const summary=summarizePlan(plan,state.milestones);return `<form class="finance-panel finance-budget" data-finance-plan="${plan.id}"><div class="finance-panel-head"><div><h2>${esc(plan.projectTitle)}</h2><p>Обновлено ${date(plan.updatedAt)}</p></div><label>Лимит <input name="budget" type="number" min="0" step="10" value="${plan.budgetMinor/100}"> BYN</label></div><div class="finance-budget-summary"><span>Предварительно <b>${formatMoney(summary.estimatedMinor)}</b></span><span>Текущие расходы <b>${formatMoney(summary.actualMinor)}</b></span><span class="${summary.overrunMinor?'negative':''}">${summary.overrunMinor?'Превышение':'Остаток'} <b>${formatMoney(summary.overrunMinor||summary.remainingMinor)}</b></span></div><div class="finance-lines">${plan.lines.map(line=>`<label><span><b>${esc(line.title)}</b><small>${line.source==='ZEROBUY'?'Корзина после ZeroBuy — повторно не вычитается':'Ручная оценка'}</small></span><input name="${line.id}" type="number" min="0" step="1" value="${line.estimatedMinor/100}" aria-label="${esc(line.title)}, BYN"></label>`).join('')}</div><button class="finance-primary" type="submit">Сохранить и пересчитать</button><p>Цены и расчёты демонстрационные. Фактический расход отмечает пользователь.</p></form>`;}

function milestones(){const check=validateMilestoneOrder(state.milestones);return `<section class="finance-panel"><div class="finance-panel-head"><div><h2>Этапы ремонта</h2><p>Domino: ${check.valid?'зависимости корректны':'есть конфликт'}</p></div></div>${!check.valid?`<div class="finance-error">${check.errors.map(esc).join('<br>')}</div>`:''}${state.milestones.map(item=>`<article class="finance-milestone"><div><strong>${esc(item.title)}</strong><span>${esc(item.stage)} · ${date(item.date)}</span><small>${esc(item.note)}</small></div><b>${formatMoney(item.amountMinor)}</b><select data-action="finance-milestone-status" data-id="${item.id}" aria-label="Статус ${esc(item.title)}"><option value="PLANNED" ${item.status==='PLANNED'?'selected':''}>Запланирован</option><option value="MANUALLY_PAID" ${item.status==='MANUALLY_PAID'?'selected':''}>Оплачен вручную</option><option value="CANCELLED" ${item.status==='CANCELLED'?'selected':''}>Отменён</option></select></article>`).join('')}<p class="finance-disclaimer">MANUALLY_PAID — отметка пользователя, не банковская операция. Proof не инициирует перевод мастеру.</p></section>`;}

function simulation(){const value=state.lastSimulation;return `<div class="finance-content-grid"><form id="finance-simulation-form" class="finance-panel"><div class="finance-panel-head"><div><h2>Параметры</h2><p>Все суммы в BYN</p></div></div><div class="finance-form-grid"><label>Стоимость проекта<input name="cost" type="number" min="0" step="1" value="${value.projectCostMinor/100}"></label><label>Первоначальный взнос<input name="down" type="number" min="0" step="1" value="${value.downPaymentMinor/100}"></label><label>Срок, месяцев<input name="term" type="number" min="1" max="600" value="${value.termMonths}"></label><label>Номинальная ставка, %<input name="rate" type="number" min="0" max="1000" step="0.01" value="${value.annualRateBasisPoints/100}"></label><label>Условные комиссии<input name="fees" type="number" min="0" step="1" value="${value.feesMinor/100}"></label></div><button class="finance-primary" type="submit">Пересчитать</button></form><section class="finance-panel finance-results"><h2>Расчёт</h2>${[['Сумма финансирования',value.financedMinor],['Ежемесячный платёж',value.monthlyPaymentMinor],['Сумма платежей',value.totalPaymentsMinor],['Переплата',value.overpaymentMinor],['Комиссии',value.feesMinor],['Суммарные расходы',value.totalCostMinor]].map(([label,minor])=>`<div><span>${label}</span><b>${formatMoney(Number(minor))}</b></div>`).join('')}<p>Не предложение банка, не скоринг и не одобрение кредита.</p></section></div>`;}

function goals(){return `<div class="finance-content-grid"><section class="finance-panel"><div class="finance-panel-head"><div><h2>Личные планы накопления</h2><p>Не банковские счета</p></div></div>${state.goals.map(goalRow).join('')}</section><form id="finance-goal-form" class="finance-panel finance-aside"><h2>Новая цель</h2><label>Название<input name="name" maxlength="80" required></label><label>Нужно, BYN<input name="target" type="number" min="1" step="1" required></label><label>Уже накоплено, BYN<input name="saved" type="number" min="0" step="1" value="0"></label><label>Дата достижения<input name="date" type="date" required></label><label>Проект<select name="project"><option value="">Без проекта</option>${state.plans.map(plan=>`<option value="${plan.projectId}">${esc(plan.projectTitle)}</option>`).join('')}</select></label><button class="finance-primary" type="submit">Сохранить личную цель</button></form></div>`;}
function goalRow(goal:SavingsGoal){const progress=Math.min(100,Math.round(goal.savedMinor/Math.max(1,goal.targetMinor)*100));return `<article class="finance-goal"><div><strong>${esc(goal.name)}</strong><span>${formatMoney(goal.savedMinor)} из ${formatMoney(goal.targetMinor)} · к ${date(goal.targetDate)}</span></div><b>${progress}%</b><div class="finance-plan-track"><i style="width:${progress}%"></i></div><p>Ориентир: ${formatMoney(monthlySavingsNeeded(goal))} в месяц</p><button data-action="finance-goal-add" data-id="${goal.id}">Добавить 50 BYN в план</button></article>`;}

function operationDialog(topUp:boolean){return `<form id="finance-operation-form" class="finance-operation"><input type="hidden" name="kind" value="${topUp?'TOP_UP':'TRANSFER'}"><p>Безопасная симуляция Stage 1: изменится только синтетический баланс и DEMO-журнал.</p><label>Сумма в BYN<input name="amount" type="text" inputmode="decimal" required placeholder="100,00"></label><label>${topUp?'Тестовый источник':'Тестовый получатель'}<input name="counterparty" maxlength="80" required></label><button class="finance-primary" type="submit">Добавить синтетическую операцию</button><small>Сообщение «Деньги переведены» не используется.</small></form>`;}

export function financeAction(name:string,id:string,element?:HTMLInputElement|HTMLSelectElement):{handled:boolean;message?:string}{
 if(!name.startsWith('finance-'))return {handled:false};
 if(name==='finance-nav'){screen=id;return {handled:true};}
 if(name==='finance-filter'){transactionFilter=id==='ALL'?null:id as TransactionKind;return {handled:true};}
 if(name==='finance-open-operation'){return {handled:true,message:`OPEN:${id}`};}
 if(name==='finance-card-create'){const suffix=String(Math.floor(Math.random()*10_000)).padStart(4,'0');const card:BankCard={...state.cards[0],id:`demo-card-${crypto.randomUUID()}`,providerCardId:`demo-token-${crypto.randomUUID()}`,maskedPan:`•••• ${suffix}`,controls:{...state.cards[0].controls,monthlyLimitMinor:150_000}};state.cards.push(card);persist();return {handled:true,message:'Создана тестовая запись карты. Она не работает для настоящих покупок.'};}
 if(name==='finance-card-toggle'){const card=state.cards.find(item=>item.id===id);if(card){card.status=card.status==='BLOCKED'?'ACTIVE':'BLOCKED';persist();}return {handled:true,message:'Статус изменён только в DEMO'};}
 if(name==='finance-card-online'){const card=state.cards.find(item=>item.id===id);if(card&&element instanceof HTMLInputElement){card.controls.online=element.checked;persist();}return {handled:true,message:'Настройка сохранена только в DEMO'};}
 if(name==='finance-plan-create'){const seed=createDemoFinanceState().plans[0],uid=crypto.randomUUID();state.plans.push({...seed,id:`plan-${uid}`,projectId:`local-${uid}`,projectTitle:'Новый домашний проект',budgetMinor:100_000,lines:seed.lines.map((line,index)=>({...line,id:`line-${uid}-${index}`,estimatedMinor:0,actualMinor:null,title:line.kind==='MATERIALS'?'Материалы':line.title})),updatedAt:new Date().toISOString()});persist();return {handled:true,message:'Новый бюджет создан'};}
 if(name==='finance-milestone-status'){const row=state.milestones.find(item=>item.id===id);if(row&&element){row.status=element.value as typeof row.status;persist();}return {handled:true,message:element?.value==='MANUALLY_PAID'?'Отмечено вручную. Банковская операция не создавалась.':'Статус этапа обновлён'};}
 if(name==='finance-goal-add'){const goal=state.goals.find(item=>item.id===id);if(goal){goal.savedMinor=Math.min(goal.targetMinor,goal.savedMinor+5_000);persist();}return {handled:true,message:'Личный план обновлён; банковский счёт не менялся'};}
 return {handled:true};
}

export function financeOperationModal(kind:string){return operationDialog(kind==='topup');}

export function financeSubmit(form:HTMLFormElement):{handled:boolean;message?:string}{
 const data=new FormData(form);
 if(form.id==='finance-operation-form'){const topUp=data.get('kind')==='TOP_UP';const result=applyDemoTransfer(state,{amountMinor:minorFromInput(String(data.get('amount')||'')),counterparty:String(data.get('counterparty')||'')},topUp?'TOP_UP':'TRANSFER');persist();return {handled:true,message:result.notice};}
 if(form.matches('[data-finance-plan]')){const plan=state.plans.find(item=>item.id===form.dataset.financePlan);if(!plan)return {handled:true,message:'Бюджет не найден'};plan.budgetMinor=minorFromInput(String(data.get('budget')||'0'));for(const line of plan.lines)line.estimatedMinor=minorFromInput(String(data.get(line.id)||'0'));plan.updatedAt=new Date().toISOString();persist();return {handled:true,message:'Бюджет сохранён и пересчитан'};}
 if(form.id==='finance-simulation-form'){state.lastSimulation=financingSimulation({projectCostMinor:minorFromInput(String(data.get('cost')||'0')),downPaymentMinor:minorFromInput(String(data.get('down')||'0')),termMonths:Number(data.get('term'))||1,annualRateBasisPoints:Math.round(Number(data.get('rate'))*100),feesMinor:minorFromInput(String(data.get('fees')||'0'))});persist();return {handled:true,message:'Расчёт сохранён. Это не кредитная заявка.'};}
 if(form.id==='finance-goal-form'){const goal:SavingsGoal={id:`goal-${crypto.randomUUID()}`,name:String(data.get('name')||'').trim().slice(0,80),targetMinor:minorFromInput(String(data.get('target')||'0')),savedMinor:minorFromInput(String(data.get('saved')||'0')),targetDate:new Date(`${data.get('date')}T12:00:00`).toISOString(),projectId:String(data.get('project')||'')||null,createdAt:new Date().toISOString()};if(!goal.name)throw new Error('Введите название цели');goal.savedMinor=Math.min(goal.savedMinor,goal.targetMinor);state.goals.push(goal);persist();return {handled:true,message:'Цель сохранена как личный план, не банковский счёт'};}
 return {handled:false};
}
