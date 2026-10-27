import test from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {mkdtempSync,rmSync} from 'node:fs';
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';

test('offline service model validates slot, duplicates, cancellation, and persistence',()=>{
 const folder=mkdtempSync(join(tmpdir(),'oma-service-'));
 try{
  const binary=join(folder,'service-checks');
  execFileSync('swiftc',['ios/OMAOne/ServiceRequestModel.swift','tests/service-request.swift','-o',binary],
               {cwd:process.cwd(),timeout:120_000});
  assert.match(execFileSync(binary,{encoding:'utf8',timeout:10_000}),/service model checks: PASS/);
 }finally{rmSync(folder,{recursive:true,force:true});}
});

test('service flow is local, visible in iOS, and never fakes real master booking',async()=>{
 const [ui,model,xcode]=await Promise.all([
  readFile('ios/OMAOne/ContentView.swift','utf8'),
  readFile('ios/OMAOne/ServiceRequestModel.swift','utf8'),
  readFile('ios/OMAOne.xcodeproj/project.pbxproj','utf8')
 ]);
 assert.match(ui,/private struct ServiceRequestScreen: View/);
 assert.match(ui,/func createServiceRequest\(projectID:/);
 assert.match(ui,/ServiceRequestScreen\(store:store,projectID:draft\.id\)/);
 assert.match(ui,/ServiceRequestScreen\(store:store,projectID:nil\)/);
 assert.match(ui,/store\.serviceLedger\.requests/);
 assert.match(ui,/service\.cancel|service\.cancel/);
 assert.match(model,/case savedLocally, cancelled/);
 assert.match(model,/case invalidDate, noteTooLong, duplicateActiveProject/);
 assert.match(model,/mutating func cancel\(id:/);
 assert.doesNotMatch(model,/URLSession|HTTPURL|https?:\/\/api\./);
 assert.match(xcode,/ServiceRequestModel\.swift in Sources/);
});
