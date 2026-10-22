import {api} from './api.js';

export function track(name,properties={}){
 if(!navigator.onLine)return;
 const safe=Object.fromEntries(Object.entries(properties).filter(([,value])=>['string','boolean'].includes(typeof value)));
 const send=()=>api('/analytics/events','POST',{name,properties:safe}).catch(()=>{});
 if('requestIdleCallback' in window)window.requestIdleCallback(send,{timeout:1500});else setTimeout(send,0);
}

export function trackError(error,view){track('error_shown',{view,code:error?.code||'CLIENT_ERROR'});}
