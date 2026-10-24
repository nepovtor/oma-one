export interface ClientError extends Error {status?: number; code?: string; correlationId?: string}

function cookie(name: string){return document.cookie.split(';').map(value=>value.trim()).find(value=>value.startsWith(name+'='))?.slice(name.length+1)||'';}


export async function api<Result = any>(endpoint: string,method='GET',data?: unknown): Promise<Result>{
 const config: RequestInit={method,credentials:'same-origin',headers:{accept:'application/json'}};
 if(method!=='GET'){
  const headers=config.headers as Record<string, string>;headers['content-type']='application/json';
  const csrf=cookie('oma_csrf');
  if(csrf)headers['x-csrf-token']=decodeURIComponent(csrf);
  config.body=JSON.stringify(data||{});
 }
 let response;
 try{response=await fetch('/api/v1'+endpoint,config);}catch{
  const error: ClientError=new Error('Нет связи с сервером. Проверьте подключение и попробуйте снова.');
  error.code='NETWORK_ERROR';
  throw error;
 }
 let json;
 try{json=await response.json();}catch{throw new Error('Нет ответа от сервера');}
 if(!response.ok){
  const error: ClientError=new Error(json.error?.message||'Ошибка сервера');
  error.status=response.status;
  error.code=json.error?.code;
  error.correlationId=json.error?.correlationId;
  throw error;
 }
 return json as Result;
}
