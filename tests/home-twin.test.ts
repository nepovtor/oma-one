import test from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {mkdtempSync,rmSync} from 'node:fs';
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';

test('HOME TWIN models the supplied 58.67 m² plan, migrates local progress, and derives shelf progress from Proof',()=>{
 const folder=mkdtempSync(join(tmpdir(),'oma-home-twin-'));
 try{
  const binary=join(folder,'home-twin-checks');
  execFileSync('swiftc',['ios/OMAOne/HomeTwinModel.swift','tests/home-twin.swift','-o',binary],{cwd:process.cwd(),timeout:120_000});
  assert.match(execFileSync(binary,{encoding:'utf8',timeout:10_000}),/home twin model passed/);
 }finally{rmSync(folder,{recursive:true,force:true});}
});

test('HOME TWIN uses bundled photorealistic room renders, with no fake expert Proof',async()=>{
 const [scene,model,ui,xcode]=await Promise.all([
  readFile('ios/OMAOne/HomeTwin3DView.swift','utf8'),
  readFile('ios/OMAOne/HomeTwinModel.swift','utf8'),
  readFile('ios/OMAOne/ContentView.swift','utf8'),
  readFile('ios/OMAOne.xcodeproj/project.pbxproj','utf8')
 ]);
 assert.doesNotMatch(scene,/import SceneKit/);
 assert.doesNotMatch(scene,/SceneView\(/);
 assert.doesNotMatch(scene,/SCNBox\(/);
 assert.match(scene,/TwinPhotoViewer\(/);
 assert.match(scene,/Image\(assetName\)/);
 assert.match(scene,/MagnificationGesture\(\)/);
 assert.match(scene,/ЛИЧНОЕ ФОТО · НА УСТРОЙСТВЕ/);
 assert.match(scene,/Picker\("Ракурс", selection: \$viewMode\)/);
 assert.match(scene,/viewMode == \.interior/);
 assert.match(scene,/План по изображению/);
 assert.match(scene,/PhotosPicker\(selection:/);
 assert.match(scene,/OMAHomeTwinPhotos/);
 assert.match(model,/func totalProgress\(shelf: TwinShelfEvidence\)/);
 assert.match(model,/static let widthMM = 6_070/);
 assert.match(model,/static let declaredAreaM2 = 58\.67/);
 for(const asset of ['TwinOverview','TwinLiving','TwinKitchen','TwinPrimaryBedroom','TwinFlexBedroom','TwinHallway','TwinBathroom','TwinWC']){
  assert.match(model+scene,new RegExp(asset));
 }
 assert.match(ui,/HomeTwin3DView\(shelfEvidence:store\.homeTwinShelfEvidence\)/);
 assert.match(ui,/var homeTwinShelfEvidence: TwinShelfEvidence/);
 assert.match(ui,/case "EVIDENCE_SUBMITTED": return \.photoSubmitted/);
 assert.match(ui,/case "SELF_REPORTED": return \.selfReported/);
 for(const name of ['HomeTwin3DView.swift','HomeTwinModel.swift']){
  assert.ok(xcode.includes(name+' in Sources'),name+' not part of native target');
 }
});
