import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';

const root=process.cwd();
const read=(name:string)=>fs.readFile(path.join(root,name),'utf8');

test('OMA web screens use the supplied mark, no ONE display name, and functional links',async()=>{
 const [html,app,css,manifestText,sw,build,proof]=await Promise.all([
  read('public/index.html'),read('public/app.ts'),read('public/oma-brand.css'),
  read('public/manifest.webmanifest'),read('public/sw.ts'),
  read('scripts/copy-static.ts'),read('proof.html')
 ]);
 const manifest=JSON.parse(manifestText);
 assert.equal(manifest.short_name,'ОМА');
 assert.equal(manifest.theme_color,'#302b7b');
 assert.match(html,/oma-brand\.css/);
 assert.match(html,/\/icons\/oma-logo\.jpg/);
 assert.match(html,/class="skip-link"/);
 assert.match(html,/aria-live="polite"/);
 assert.doesNotMatch(html+app+proof,/OMA ONE/);
 assert.match(app,/class="home-intro oma-home-intro"/);
 assert.match(app,/data-action="start-shelf"/);
 assert.match(app,/data-view="planner"/);
 assert.match(app,/data-view="cart"/);
 assert.match(app,/data-view="profile"/);
 assert.match(app,/aria-current="page"/);
 assert.match(app,/src="\/icons\/oma-logo\.jpg"/);
 assert.match(css,/--brand-cyan:#[0-9a-f]{6}/);
 assert.match(css,/\.home-copy\.oma-hero/);
 assert.match(css,/max-width:480px/);
 assert.match(css,/prefers-reduced-motion/);
 assert.match(css,/prefers-contrast:more/);
 assert.match(build,/public\/oma-brand\.css/);
 assert.match(sw,/\/oma-brand\.css/);
 assert.match(sw,/\/icons\/oma-logo\.jpg/);
 const [nativeLogo,webLogo]=await Promise.all([
  fs.readFile(path.join(root,'ios/OMAOne/Assets.xcassets/OMALogoReference.imageset/OMALogoReference.jpg')),
  fs.readFile(path.join(root,'public/icons/oma-logo.jpg'))
 ]);
 assert.deepEqual(webLogo,nativeLogo,'Web must use the same original OMA mark as iOS');
 // Reject placeholders or the previous house icon. PNG files must be the
 // expected size so iOS/PWA use real assets instead of browser fallbacks.
 for(const [file,size] of [
  ['public/icons/icon-192.png',192],
  ['public/icons/icon-512.png',512],
  ['public/icons/apple-touch-icon.png',180],
  ['ios/OMAOne/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png',1024]
 ] as const){
  const png=await fs.readFile(path.join(root,file));
  assert.equal(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
  assert.equal(png.readUInt32BE(16),size,file+' width');
  assert.equal(png.readUInt32BE(20),size,file+' height');
  assert.ok(png.length>350,file+' is unexpectedly small');
 }

});

test('OMA iOS navigation and 3D remain linked after branding',async()=>{
 const [ui,twin,plist,xcode]=await Promise.all([
  read('ios/OMAOne/ContentView.swift'),
  read('ios/OMAOne/HomeTwin3DView.swift'),
  read('ios/OMAOne/Info.plist'),
  read('ios/OMAOne.xcodeproj/project.pbxproj')
 ]);
 assert.match(plist,/<key>CFBundleDisplayName<\/key>\s*<string>ОМА · Дом<\/string>/);
 assert.match(ui,/Image\("OMALogoReference"\)/);
 assert.match(ui,/МОЯ КВАРТИРА · 3D/);
 assert.match(ui,/startShelf = true/);
 assert.match(ui,/startTwin = true/);
 assert.match(ui,/HomeTwin3DView\(shelfEvidence:/);
 assert.match(twin,/SceneView\(/);
 assert.match(xcode,/HomeTwin3DView\.swift in Sources/);
 assert.doesNotMatch(ui+twin+plist,/OMA ONE/);
 for(const v of ['home','catalog','cart','favorites','profile'])
  assert.match(ui,new RegExp('case \\.'+v+'\\b'));
 for(const mechanism of ['zerobuy','antifail','domino','synccity','proof','dna','forge','pulse'])
  assert.match(ui,new RegExp('case \\.'+mechanism+'\\b'));
});
