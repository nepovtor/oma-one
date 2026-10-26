import {applyDemoTransfer,createDemoFinanceState} from './finance-domain.js';
import type {BankAccount,BankCard,CardControls,FinanceState,FinanceTransaction,Money,TransferRequest,TransferResult} from './finance-domain.js';

export interface CardRequest {accountId:string;kind:'VIRTUAL'}
export interface CardRequestResult {card:BankCard;notice:string}
export interface TransactionQuery {accountId?:string;cursor?:string;limit?:number}
export interface TransactionPage {items:FinanceTransaction[];nextCursor:string|null}
export type TransferStatus='PENDING'|'AUTHORIZED'|'SETTLED'|'DECLINED'|'REVERSED';

export interface BankingProvider {
 readonly mode:'DEMO'|'SANDBOX'|'LIVE';
 getAccounts():Promise<BankAccount[]>;
 getBalance(accountId:string):Promise<Money>;
 getCards():Promise<BankCard[]>;
 requestVirtualCard(input:CardRequest):Promise<CardRequestResult>;
 getTransactions(query:TransactionQuery):Promise<TransactionPage>;
 createTransfer(input:TransferRequest,idempotencyKey:string):Promise<TransferResult>;
 getTransferStatus(transferId:string):Promise<TransferStatus>;
 updateCardControls(cardId:string,controls:CardControls):Promise<void>;
}

export class DemoBankingProvider implements BankingProvider {
 readonly mode='DEMO' as const;
 readonly state:FinanceState;
 private readonly idempotency=new Map<string,TransferResult>();
 constructor(state=createDemoFinanceState()){if(state.mode!=='DEMO')throw new Error('Demo provider accepts only DEMO state');this.state=structuredClone(state);}
 async getAccounts(){return [structuredClone(this.state.account)];}
 async getBalance(accountId:string){if(accountId!==this.state.account.id)throw new Error('Account not found');return structuredClone(this.state.account.available);}
 async getCards(){return structuredClone(this.state.cards);}
 async requestVirtualCard(input:CardRequest){if(input.accountId!==this.state.account.id)throw new Error('Account not found');const suffix=String(Math.floor(Math.random()*10_000)).padStart(4,'0'),id=`demo-card-${crypto.randomUUID()}`,card:BankCard={...structuredClone(this.state.cards[0]),id,providerCardId:`demo-token-${crypto.randomUUID()}`,maskedPan:`•••• ${suffix}`,synthetic:true,source:'DEMO'};this.state.cards.push(card);return {card:structuredClone(card),notice:'Создана только синтетическая запись карты.'};}
 async getTransactions(query:TransactionQuery){const limit=Math.min(100,Math.max(1,query.limit||50)),items=this.state.transactions.filter(item=>!query.accountId||item.accountId===query.accountId).slice(0,limit);return {items:structuredClone(items),nextCursor:null};}
 async createTransfer(input:TransferRequest,idempotencyKey:string){if(!/^[A-Za-z0-9_-]{8,100}$/.test(idempotencyKey))throw new Error('Invalid idempotency key');const previous=this.idempotency.get(idempotencyKey);if(previous)return structuredClone(previous);const result=applyDemoTransfer(this.state,input,'TRANSFER');this.idempotency.set(idempotencyKey,structuredClone(result));return result;}
 async getTransferStatus(transferId:string){const item=this.state.transactions.find(transaction=>transaction.id===transferId);if(!item)throw new Error('Transfer not found');return item.status;}
 async updateCardControls(cardId:string,controls:CardControls){const card=this.state.cards.find(item=>item.id===cardId);if(!card)throw new Error('Card not found');card.controls=structuredClone(controls);}
}

export interface SandboxProviderConfig {baseUrl:string;accessToken:()=>Promise<string>}
export class SandboxBankingProvider implements BankingProvider {
 readonly mode='SANDBOX' as const;
 constructor(private readonly config:SandboxProviderConfig){if(!config.baseUrl.startsWith('https://'))throw new Error('Sandbox provider requires an official HTTPS endpoint');}
 private unavailable():never{throw new Error('Official partner Sandbox contract is not configured');}
 async getAccounts():Promise<BankAccount[]>{return this.unavailable();}
 async getBalance(_accountId:string):Promise<Money>{return this.unavailable();}
 async getCards():Promise<BankCard[]>{return this.unavailable();}
 async requestVirtualCard(_input:CardRequest):Promise<CardRequestResult>{return this.unavailable();}
 async getTransactions(_query:TransactionQuery):Promise<TransactionPage>{return this.unavailable();}
 async createTransfer(_input:TransferRequest,_idempotencyKey:string):Promise<TransferResult>{return this.unavailable();}
 async getTransferStatus(_transferId:string):Promise<TransferStatus>{return this.unavailable();}
 async updateCardControls(_cardId:string,_controls:CardControls):Promise<void>{return this.unavailable();}
}

export class LiveBankingProvider implements BankingProvider {
 readonly mode='LIVE' as const;
 constructor(){throw new Error('LIVE_LOCKED: requires a licensed partner, contracts, regulatory approval, independent security review and a separately reviewed activation change');}
 async getAccounts():Promise<BankAccount[]>{throw new Error('LIVE_LOCKED');}
 async getBalance(_accountId:string):Promise<Money>{throw new Error('LIVE_LOCKED');}
 async getCards():Promise<BankCard[]>{throw new Error('LIVE_LOCKED');}
 async requestVirtualCard(_input:CardRequest):Promise<CardRequestResult>{throw new Error('LIVE_LOCKED');}
 async getTransactions(_query:TransactionQuery):Promise<TransactionPage>{throw new Error('LIVE_LOCKED');}
 async createTransfer(_input:TransferRequest,_idempotencyKey:string):Promise<TransferResult>{throw new Error('LIVE_LOCKED');}
 async getTransferStatus(_transferId:string):Promise<TransferStatus>{throw new Error('LIVE_LOCKED');}
 async updateCardControls(_cardId:string,_controls:CardControls):Promise<void>{throw new Error('LIVE_LOCKED');}
}

export function configuredBankingMode(env:NodeJS.ProcessEnv=process.env):'DEMO'|'SANDBOX'{
 const requested=String(env.OMA_BANKING_MODE||'DEMO').toUpperCase();
 if(requested==='LIVE')throw new Error('LIVE_LOCKED: an environment variable cannot activate real-money operations');
 if(requested==='SANDBOX')return 'SANDBOX';
 if(requested!=='DEMO')throw new Error('Unknown banking mode');
 return 'DEMO';
}
