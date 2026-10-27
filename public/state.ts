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
 userId:localStorage.getItem('oma-demo-user')||'demo1',view:'home',data:null,plan:null,calculationId:null,scenario:'faucet',catalogQuery:'',catalogCategory:'Все',filter:'all',planMode:'hybrid',sequenceConflicts:null,selectedProject:null,selectedDna:null,metrics:null,modal:null,shelfDraft:null,shelfStep:0,busy:false,online:navigator.onLine,chatOpen:false,chatTyping:false,
 vibeStage:localStorage.getItem('oma-vibe-stage-v1')||'home',vibeStyle:localStorage.getItem('oma-vibe-style-v1')||'Soft Loft',vibeOwned:localStorage.getItem('oma-vibe-owned-v1')==='true',vibeSaved:localStorage.getItem('oma-vibe-saved-v1')==='true',
 chatMessages:[{role:'assistant',text:'Привет! Я помощник OMA ONE. Расскажи, что хочешь сделать дома — подскажу, с чего начать. Сейчас я работаю на проверяемых правилах демо-приложения.'}]
};
