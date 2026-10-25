import {dna, forge, pulse, syncCity} from './proof-engine.js';
import type {AppState, DnaTemplate, ForgeItem, Group, Product, User} from './types.js';

export function syncCityDecision(group: Group,user?: User){
 const existingCount=Math.max(1,group.participants,group.memberIds.length);
 const requests=Array.from({length:existingCount},(_,index)=>({
  id:`participant-${index+1}`,city:group.city,zone:group.district,slot:group.date,service:group.category
 }));
 if(user)requests.push({id:'candidate',city:user.city,zone:user.district,slot:group.date,service:group.category});
 return syncCity({
  requests,selectedId:user?'candidate':'participant-1',sharedTripCost:group.basePrice,
  individualTripCost:group.basePrice,minGroup:group.target
 });
}

export function dnaDecision(templates: DnaTemplate[],user: User,room: string,area: number){
 return dna({
  homeType:user.homeType,room,area,qtyPerM2:1.1,
  templates:templates.map(template=>({
   id:template.id,homeType:template.homeType,room:template.room,area:template.area,
   inspection:template.verified?'professional':'self'
  }))
 });
}

export function dnaTemplates(templates: DnaTemplate[],user: User,room: string,area: number){
 const decision=dnaDecision(templates,user,room,area),byId=new Map(decision.result.templates.map(item=>[item.id,item]));
 return {decision,templates:templates.map(template=>{
  const result=byId.get(template.id);
  return {...template,match:result?.score||0,candidate:result?.eligible||false,adaptedUnits:result?.adaptedUnits??null,matchReason:result?.reason||''};
 }).sort((a,b)=>b.match-a.match)};
}

export function forgeDecision(item: ForgeItem,products: Product[]){
 const recordedVoters=[...new Set(item.voters)],baseline=Math.max(0,item.interested-recordedVoters.length);
 const projects=[
  ...Array.from({length:baseline},(_,index)=>({id:`synthetic-${index+1}`,userId:`synthetic-${index+1}`,problem:item.id,homeType:item.category,optIn:true})),
  ...recordedVoters.map(userId=>({id:`vote-${userId}`,userId,problem:item.id,homeType:item.category,optIn:true}))
 ];
 const prices=new Map(products.map(product=>[product.id,product.price]));
 return forge({projects,skuCosts:item.productIds.map(id=>({id,cost:prices.get(id)||0})),interestThreshold:item.threshold,minGrossMargin:.15,assemblyCost:0});
}

export function pulseDecision(state: AppState){
 return pulse({
  reports:state.reports.map(report=>({userId:report.userId,model:report.model,verifiedByExpert:report.verified})),
  cohortSize:state.users.length,minCases:3,minCohort:30,expertApproved:false,reviewerId:null
 });
}
