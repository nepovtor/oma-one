import test from 'node:test';
import assert from 'node:assert/strict';
import {applyDemoTransfer,createDemoFinanceState,financingSimulation,maskPan,monthlySavingsNeeded,summarizePlan,validateMilestoneOrder} from '../finance-domain.js';

test('money values and card display remain exact and masked',()=>{
 const state=createDemoFinanceState();
 assert.equal(state.account.balance.minor,1_248_630);
 assert.equal(state.cards[0].maskedPan,'•••• 2841');
 assert.equal(maskPan('12 34'),'•••• 1234');
 assert.throws(()=>maskPan('123'));
});

test('financing handles normal, zero-rate and full down-payment cases',()=>{
 const normal=financingSimulation({projectCostMinor:1_000_000,downPaymentMinor:200_000,termMonths:24,annualRateBasisPoints:1800,feesMinor:10_000});
 assert.equal(normal.financedMinor,800_000);
 assert.ok(normal.monthlyPaymentMinor>33_333);
 assert.equal(normal.totalCostMinor,normal.downPaymentMinor+normal.totalPaymentsMinor+normal.feesMinor);
 const zero=financingSimulation({projectCostMinor:120_000,downPaymentMinor:0,termMonths:12,annualRateBasisPoints:0,feesMinor:0});
 assert.equal(zero.monthlyPaymentMinor,10_000);
 assert.equal(zero.overpaymentMinor,0);
 const paid=financingSimulation({projectCostMinor:120_000,downPaymentMinor:120_000,termMonths:12,annualRateBasisPoints:2500,feesMinor:0});
 assert.equal(paid.financedMinor,0);assert.equal(paid.monthlyPaymentMinor,0);
});

test('project summary does not subtract ZeroBuy twice and exposes overrun',()=>{
 const state=createDemoFinanceState(),plan=state.plans[0];
 const summary=summarizePlan(plan,state.milestones);
 assert.equal(summary.estimatedMinor,39_700);
 assert.equal(summary.remainingMinor,15_300);
 plan.lines[1].actualMinor=60_000;
 const over=summarizePlan(plan,state.milestones);
 assert.equal(over.overrunMinor,26_700);
});

test('Domino-style milestone validation catches cycles and missing stages',()=>{
 const state=createDemoFinanceState();
 assert.equal(validateMilestoneOrder(state.milestones).valid,true);
 state.milestones[0].dependsOn=['ms-install'];
 assert.equal(validateMilestoneOrder(state.milestones).valid,false);
 state.milestones[0].dependsOn=['missing'];
 assert.match(validateMilestoneOrder(state.milestones).errors[0],/отсутствует/);
});

test('demo transfers mutate only synthetic state and never imply real movement',()=>{
 const state=createDemoFinanceState(),before=state.account.available.minor;
 const result=applyDemoTransfer(state,{amountMinor:12_345,counterparty:'Тестовый получатель'},'TRANSFER',new Date('2026-10-26T10:00:00Z'));
 assert.equal(state.account.available.minor,before-12_345);
 assert.equal(result.transaction.source,'DEMO');
 assert.match(result.notice,/Реальные деньги не перемещались/);
 assert.throws(()=>applyDemoTransfer({...state,mode:'LIVE'},{amountMinor:100,counterparty:'x'}));
});

test('savings calculation reaches target without negative contributions',()=>{
 const goal=createDemoFinanceState().goals[0];
 assert.equal(monthlySavingsNeeded(goal,new Date('2026-10-01T00:00:00Z')),83_572);
 goal.savedMinor=goal.targetMinor+1;
 assert.equal(monthlySavingsNeeded(goal,new Date('2026-10-01T00:00:00Z')),0);
});
