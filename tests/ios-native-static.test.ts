import test from 'node:test';

import assert from 'node:assert/strict';
import {readFile,readdir} from 'node:fs/promises';
import {join} from 'node:path';
const root = new URL(`file://${process.cwd()}/`);
const read = (name: string) => readFile(new URL(name,root),'utf8');
test('native iOS shell includes six OMA sections and eight OMA ONE modules',async()=>{
 const src=await read('ios/OMAOne/ContentView.swift');
 for(const tab of ['home','catalog','cart','finance','favorites','profile'])assert.ok(src.includes(`.${tab}`),tab);
 for(const feature of ['zerobuy','antifail','domino','synccity','proof','dna','forge','pulse'])assert.match(src,new RegExp(`case \\.${feature}`));
 for(const screen of ['HomeScreen','CatalogScreen','CartScreen','FavoritesScreen','ProfileScreen','ONEHub','PlannerScreen','FeatureScreen'])assert.ok(src.includes(`struct ${screen}`),screen);
});
test('native OMA Finance is an explicit synthetic demo with persistent interactive screens',async()=>{
 const [view,models]=await Promise.all([read('ios/OMAOne/FinanceView.swift'),read('ios/OMAOne/FinanceModels.swift')]);
 for(const screen of ['FinanceRootView','FinanceDashboardView','FinanceCardsView','FinanceHistoryView','FinancePlansView','FinanceMilestonesView','FinanceSimulationView','FinanceGoalsView'])assert.match(view,new RegExp(`struct ${screen}`),screen);
 assert.match(view,/не принимают и не хранят реальные деньги/);
 assert.doesNotMatch(view,/Деньги переведены/);
 assert.match(models,/UserDefaults/);
 assert.match(models,/Реальные деньги не перемещались/);
 assert.ok(models.includes('source: .demo'));
 assert.doesNotMatch(view+models,/\b(?:PAN|CVV|CVC|PIN)\b/);
});
test('native feedback is visual, confirms cart additions, and has no haptics',async()=>{
 const src=await read('ios/OMAOne/ContentView.swift');
 assert.match(src,/struct OmaPressButtonStyle/);
 assert.match(src,/accessibilityReduceMotion/);
 assert.match(src,/struct AddToCartButton/);
 assert.match(src,/showingAdded \? "Добавлено"/);
 assert.match(src,/kitAdded \? "Комплект добавлен"/);
 assert.doesNotMatch(src,/UI(?:Impact|Selection|Notification)FeedbackGenerator|AudioServicesPlaySystemSound/);
});
test('native SyncCity, DNA, FORGE and PULSE screens feed their current inputs to the shared engine',async()=>{
 const src=await read('ios/OMAOne/ContentView.swift');
 for(const marker of ['let count = store.joinedSyncCity ? 5 : 4','"area":roomArea','let count = store.votedForge ? 4 : 3','0..<pulseConfirmedReports'])assert.ok(src.includes(marker),marker);
 assert.doesNotMatch(src,/default: return nil \/\/ Explicit synthetic fixture/);
});
test('iOS native demo does not require an unavailable fixed Mac hostname',async()=>{
 const swift=await read('ios/OMAOne/WebApp.swift');
 const plist=await read('ios/OMAOne/Info.plist');
 assert.ok(!swift.includes('MacBook-Pro-Nepovtor'));
 assert.ok(!plist.includes('MacBook-Pro-Nepovtor'));
 assert.match(swift,/struct ServerPreview/);
});
test('reference catalog assets and promo banners exist in Xcode asset catalog',async()=>{
 const dir=new URL('ios/OMAOne/Assets.xcassets/',root);
 const all=await readdir(dir);
 for(let i=1;i<=16;i++)assert.ok(all.includes(`Category${String(i).padStart(2,'0')}.imageset`));
 for(const name of ['PromoLight','PromoTools','PromoLinen','PromoFoam','PromoPaint','OMALogoReference'])assert.ok(all.includes(`${name}.imageset`));
});

test('saving an unchanged completed shelf preserves Proof, while changed inputs revoke it',async()=>{
 const src=await read('ios/OMAOne/ContentView.swift');
 const begin=src.indexOf('func saveShelf(_ draft: ShelfProjectData, amount: Double)');
 const end=src.indexOf('func complete(_ id:',begin);
 assert.ok(begin>=0&&end>begin);
 const save=src.slice(begin,end);
 assert.match(save,/previous\?\.updatedAt = copy\.updatedAt/);
 assert.match(save,/let inputsChanged = previous != copy/);
 assert.match(save,/if inputsChanged \{\s*projects\[index\]\.completed = false\s*projects\[index\]\.proofStatus = nil/);
 assert.doesNotMatch(save,/projects\[index\]\.completed = false\s*\}/);
});
