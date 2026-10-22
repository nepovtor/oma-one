import test from 'node:test';
import assert from 'node:assert/strict';
import {seed} from '../seed.mjs';
import {computePlan,validateSequence,detectScenario,similarity,metrics,estimatedForgePrice} from '../engine.mjs';

test('ZeroBuy subtracts owned materials from purchase quantities',()=>{
 const d=seed();const plan=computePlan(d,{userId:'demo1',scenarioId:'faucet',budget:200,area:1,mode:'hybrid'});
 const tape=plan.items.find(x=>x.productId==='p03');
 assert.equal(tape.owned,1);assert.equal(tape.purchase,0);assert.ok(plan.saved>=6.9);
 assert.ok(plan.estimated>0);
});
test('AntiFail flags incompatible material decision',()=>{
 const d=seed(),p=computePlan(d,{userId:'demo1',scenarioId:'shelf',wrongMaterial:true});
 assert.ok(p.warnings.some(w=>w.level==='critical'&&w.title.includes('Неверный')));
});
test('regional availability is checked rather than invented',()=>{
 const d=seed();const p=computePlan(d,{userId:'demo1',scenarioId:'bath',area:100});
 assert.ok(p.warnings.some(w=>w.title==='Ограниченный остаток'));
});
test('Domino detects invalid graph ordering',()=>{
 const d=seed(),p=computePlan(d,{userId:'demo1',scenarioId:'bath'});
 assert.deepEqual(validateSequence(p.steps),[]);
 const rev=[...p.steps].reverse();assert.ok(validateSequence(rev).length>0);
});
test('scenario detection prefers subject keywords',()=>{
 assert.equal(detectScenario('Мне нужна новая полка для гостиной').id,'shelf');
 assert.equal(detectScenario('Хочу подготовить дачу и теплицу').id,'garden');
});
test('DNA similarity matches known object more closely',()=>{
 const d=seed();const user=d.users[0],tpl=d.templates[0];
 assert.ok(similarity(tpl,user,'Прихожая',3.2)>similarity(tpl,{...user,homeType:'Частный дом'},'Ванная',30));
});
test('FORGE models falling unit price as volume grows',()=>{
 const d=seed(),f=d.forge[0],base=estimatedForgePrice(f);
 f.interested=120;assert.ok(estimatedForgePrice(f)<base);
});
test('economics is parameterized and honest about negative contribution',()=>{
 const d=seed();const m=metrics(d,{margin:0,commission:0,cost:50});
 assert.ok(m.contribution<0);assert.equal(m.breakEvenOrders,null);
});
