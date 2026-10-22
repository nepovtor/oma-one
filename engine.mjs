import {scenarios} from './seed.mjs';
export const round = n => Math.round((Number(n)||0)*100)/100;
export const escapeText = x => String(x ?? '').trim().slice(0,4000);
export const safeNum = (n,lo,hi,def)=> {const v=Number(n);return Number.isFinite(v) ? Math.max(lo,Math.min(hi,v)) : def;};
export function detectScenario(task='',requestedId='') {
 if (requestedId) { const found=scenarios.find(s=>s.id===requestedId); if(found) return found; }
 const text=String(task).toLowerCase();
 let result=null,best=0;
 for(const s of scenarios){const score=s.keywords.filter(k=>text.includes(k)).length;if(score>best){best=score;result=s;}}
 return result||scenarios[0];
}
export function computePlan(db,{userId,task,scenarioId,budget,area,mode='hybrid',wrongMaterial=false,discountMode=false,stockCity}){
 const user=db.users.find(u=>u.id===userId); if(!user) throw new Error('Профиль не найден');
 const scenario=detectScenario(task,scenarioId);
 const size=safeNum(area,.5,120,scenario.area);
 const targetBudget=safeNum(budget,50,150000,scenario.defaultBudget);
 const scale=['bath','balcony','garden'].includes(scenario.id)?size/scenario.area:1;
 const factor=q=>Math.max(1,Math.ceil(q*scale));
 const homeItems=user.inventory||[];
 const city=stockCity||user.city;
 const items=scenario.requirements.map(([productId,q])=>{
  const product=db.products.find(p=>p.id===productId);
  const needed=factor(q);
  const owned=Math.min(needed,homeItems.filter(x=>x.productId===productId).reduce((n,x)=>n+x.qty,0));
  const purchase=needed-owned;
  return {productId,name:product.name,emoji:product.emoji,unit:product.unit,price:product.price,needed,owned,purchase,subtotal:round(purchase*product.price),stock:product.stock[city]??0,available:(product.stock[city]??0)>=purchase};
 });
 const flagged=!!wrongMaterial;
 let warnings=[];
 if(scenario.id==='shelf'&&wrongMaterial) warnings.push({level:'critical',title:'Неверный крепёж для основания',detail:'Выбрано несоответствие типа стены и крепежа. Проверьте основание, допустимую нагрузку и подберите крепёж заново.'});
 else if(wrongMaterial) warnings.push({level:'critical',title:'Материал не подтверждён',detail:'Пользователь отметил сомнение в совместимости. Требуется сверить свойства с документацией производителя и условиями работ.'});
 warnings.push({level:'info',title:'Требуется техническая проверка',detail:scenario.warn});
 for(const i of items.filter(x=>!x.available)) warnings.push({level:'warning',title:'Ограниченный остаток',detail:`В городе ${city} товара «${i.name}» недостаточно для рассчитанного количества. Уточните альтернативы.`});
 const materials=round(items.reduce((acc,i)=>acc+i.subtotal,0));
 const tool=db.products.find(x=>x.id===scenario.tool);
 const ownsTool=homeItems.some(x=>x.productId===scenario.tool&&x.qty>0);
 const rental=ownsTool?0:scenario.id==='faucet'?18:scenario.id==='shelf'?35:scenario.id==='garden'?20:45;
 const service=round(scenario.service*(scale>1?1+0.5*(scale-1):1));
 const options=[
  {id:'diy',title:'Сделаю самостоятельно',materials,rental,service:0,total:round(materials+rental),note:'Только для работ, которые допустимо и безопасно выполнять самостоятельно'},
  {id:'hybrid',title:'Комбинированный вариант',materials,rental:round(rental/2),service:round(service*.62),total:round(materials+rental/2+service*.62),note:'Часть задач выполняет специалист'},
  {id:'pro',title:'С мастером',materials,rental:0,service,total:round(materials+service),note:'Ориентировочная стоимость без реального предложения подрядчика'}
 ];
 const selected=options.find(o=>o.id===mode)||options[1];
 const saved=round(items.reduce((acc,i)=>acc+i.owned*i.price,0));
 const steps=scenario.steps.map((s,i)=>({...s,order:i+1}));
 const deficit=round(selected.total-targetBudget);
 const alternatives=[];
 if(deficit>0) alternatives.push(`Бюджет превышен на ${deficit.toLocaleString('ru-RU')} BYN. Сравните варианты работ и пересмотрите объём проекта.`);
 if(saved>0) alternatives.push(`ZeroBuy: использованы домашние запасы, предварительная экономия ${saved.toLocaleString('ru-RU')} BYN.`);
 if(items.some(i=>!i.available)) alternatives.push('Некоторых товаров не хватает в выбранном городе. Перед заказом обновите наличие.');
 if(!alternatives.length) alternatives.push('Предварительный расчёт укладывается в бюджет. Стоимости услуг требуют подтверждения.');
 return {id:`preview-${Date.now()}`,scenarioId:scenario.id,title:scenario.title,subtitle:scenario.subtitle,emoji:scenario.emoji,task:escapeText(task)||scenario.title,room:scenario.room,area:size,budget:targetBudget,mode:selected.id,city,items,options,selected,estimated:selected.total,materials,service,rental,saved,steps,warnings,alternatives,flagged,scale:round(scale),createdAt:new Date().toISOString(),disclaimer:'Демонстрационный расчёт. Цены, наличие и услуги не являются офертой. Проверяйте совместимость и безопасность работ.'};
}
export function validateSequence(steps){
 const order=Object.fromEntries(steps.map((s,i)=>[s.id,i]));
 const conflicts=[];
 for(const s of steps) for(const prerequisite of (s.after||[])) if(order[prerequisite]>=order[s.id]) conflicts.push({step:s.title,after:steps.find(x=>x.id===prerequisite)?.title||prerequisite});
 return conflicts;
}
export function similarity(template,user,room,area){
 let score=25;
 if(template.homeType===user.homeType)score+=30;
 if(template.room===room)score+=25;
 const a=Number(area);
 if(Number.isFinite(a)&&a>0)score+=Math.max(0,20-Math.min(20,Math.round(Math.abs(template.area-a)*5)));
 return Math.max(0,Math.min(100,score));
}
export function estimatedForgePrice(f){const n=f.interested;return round(f.unitPrice*(n>=100?.8:n>=f.threshold?.9:1));}
export function metrics({orders,projects,groups,forge}, assumptions={}){
 const margin=safeNum(assumptions.margin,0,80,20)/100;
 const commission=safeNum(assumptions.commission,0,50,12)/100;
 const cost=safeNum(assumptions.cost,0,5000,35);
 const aov=safeNum(assumptions.aov,50,10000,300);
 const avgService=safeNum(assumptions.avgService,0,10000,140);
 const expected=round(aov*margin+avgService*commission-cost);
 return {orders:orders.length,projects:projects.length,groups:groups.length,forge:forge.length,margin,commission,cost,aov,avgService,contribution:expected,breakEvenOrders:expected>0?Math.ceil(3000/expected):null};
}
