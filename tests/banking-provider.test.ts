import test from 'node:test';
import assert from 'node:assert/strict';
import {configuredBankingMode,DemoBankingProvider,LiveBankingProvider,SandboxBankingProvider} from '../banking-provider.js';

test('Demo provider is isolated and idempotent',async()=>{
 const provider=new DemoBankingProvider(),before=(await provider.getAccounts())[0].available.minor;
 const first=await provider.createTransfer({amountMinor:10_000,counterparty:'Синтетический получатель'},'demo-key-0001');
 const repeated=await provider.createTransfer({amountMinor:10_000,counterparty:'Синтетический получатель'},'demo-key-0001');
 assert.equal(first.transaction.id,repeated.transaction.id);
 assert.equal((await provider.getAccounts())[0].available.minor,before-10_000);
 assert.equal(first.transaction.source,'DEMO');
 assert.match(first.notice,/Реальные деньги не перемещались/);
});

test('Sandbox requires an explicit official HTTPS endpoint and remains an adapter stub',async()=>{
 assert.throws(()=>new SandboxBankingProvider({baseUrl:'http://example.test',accessToken:async()=>''}),/HTTPS/);
 const provider=new SandboxBankingProvider({baseUrl:'https://sandbox.partner.invalid',accessToken:async()=>'test'});
 await assert.rejects(()=>provider.getAccounts(),/not configured/);
});

test('LIVE cannot be activated by environment variables or direct construction',()=>{
 assert.equal(configuredBankingMode({}),'DEMO');
 assert.equal(configuredBankingMode({OMA_BANKING_MODE:'SANDBOX'}),'SANDBOX');
 assert.throws(()=>configuredBankingMode({OMA_BANKING_MODE:'LIVE'}),/LIVE_LOCKED/);
 assert.throws(()=>new LiveBankingProvider(),/LIVE_LOCKED/);
});
