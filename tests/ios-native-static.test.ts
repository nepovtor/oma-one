import test from 'node:test';

import assert from 'node:assert/strict';
import {readFile,readdir} from 'node:fs/promises';
import {join} from 'node:path';
const root = new URL(`file://${process.cwd()}/`);
const read = (name: string) => readFile(new URL(name,root),'utf8');
test('native iOS shell includes five original OMA sections and eight OMA ONE modules',async()=>{
 const src=await read('ios/OMAOne/ContentView.swift');
 for(const tab of ['home','catalog','cart','favorites','profile'])assert.match(src,new RegExp(`\\.${tab}\\b`));
 for(const feature of ['zerobuy','antifail','domino','synccity','proof','dna','forge','pulse'])assert.match(src,new RegExp(`case \\.${feature}`));
 for(const screen of ['HomeScreen','CatalogScreen','CartScreen','FavoritesScreen','ProfileScreen','ONEHub','PlannerScreen','FeatureScreen'])assert.ok(src.includes(`struct ${screen}`),screen);
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
