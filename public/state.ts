export type Dynamic = any;

export interface ClientState {
 [key: string]: Dynamic;
 userId: string;
 view: string;
 data: Dynamic;
 plan: Dynamic;
 modal: Dynamic;
 shelfDraft: Dynamic;
}

export const S: ClientState={
 userId:localStorage.getItem('oma-demo-user')||'demo1',view:'home',data:null,plan:null,calculationId:null,scenario:'faucet',catalogQuery:'',catalogCategory:'Все',filter:'all',planMode:'hybrid',sequenceConflicts:null,selectedProject:null,selectedDna:null,metrics:null,modal:null,shelfDraft:null,busy:false,online:navigator.onLine,chatOpen:false,chatTyping:false,
 chatMessages:[{role:'assistant',text:'Привет! Я помощник OMA ONE. Расскажи, что хочешь сделать дома — подскажу, с чего начать. Сейчас я работаю на проверяемых правилах демо-приложения.'}]
};
