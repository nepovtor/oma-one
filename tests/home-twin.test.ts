import test from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {mkdtempSync,rmSync} from 'node:fs';
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';

test('HOME TWIN model persists rooms, caps edits, and derives shelf progress from Proof',()=>{
 const folder=mkdtempSync(join(tmpdir(),'oma-home-twin-'));
 try{
  const binary=join(folder,'home-twin-checks');
  execFileSync('swiftc',['ios/OMAOne/HomeTwinModel.swift','tests/home-twin.swift','-o',binary],{cwd:process.cwd(),timeout:40_000});
  assert.match(execFileSync(binary,{encoding:'utf8',timeout:10_000}),/home twin model passed/);
 }finally{rmSync(folder,{recursive:true,force:true});}
});

test('HOME TWIN is a real native SceneKit apartment, with no fake expert Proof',async()=>{
 const [scene,model,ui,xcode]=await Promise.all([
  readFile('ios/OMAOne/HomeTwin3DView.swift','utf8'),
  readFile('ios/OMAOne/HomeTwinModel.swift','utf8'),
  readFile('ios/OMAOne/ContentView.swift','utf8'),
  readFile('ios/OMAOne.xcodeproj/project.pbxproj','utf8')
 ]);
 assert.match(scene,/import SceneKit/);
 assert.match(scene,/SceneView\(/);
 assert.match(scene,/SCNScene\(\)/);
 assert.match(scene,/SCNBox\(/);
 assert.match(scene,/\.allowsCameraControl/);
 assert.match(scene,/goalPreview: showGoal/);
 assert.match(scene,/shelfShown: apartment\.shelfRoomID == room\.id && shelf\.isRecorded/);
 assert.match(scene,/PhotosPicker\(selection:/);
 assert.match(scene,/OMAHomeTwinPhotos/);
 assert.match(model,/func totalProgress\(shelf: TwinShelfEvidence\)/);
 assert.match(ui,/HomeTwin3DView\(shelfEvidence:store\.homeTwinShelfEvidence\)/);
 assert.match(ui,/var homeTwinShelfEvidence: TwinShelfEvidence/);
 assert.match(ui,/case "EVIDENCE_SUBMITTED": return \.photoSubmitted/);
 assert.match(ui,/case "SELF_REPORTED": return \.selfReported/);
 for(const name of ['HomeTwin3DView.swift','HomeTwinModel.swift']){
  assert.ok(xcode.includes(name+' in Sources'),name+' not part of native target');
 }
});
