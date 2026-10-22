import crypto from 'node:crypto';
import {createRemoteJWKSet,jwtVerify} from 'jose';

const hash=value=>crypto.createHash('sha256').update(String(value)).digest('hex');
const random=bytes=>crypto.randomBytes(bytes).toString('base64url');
const safeReturnTo=value=>typeof value==='string'&&value.startsWith('/')&&!value.startsWith('//')?value:'/';

export function oidcConfigured(){return Boolean(process.env.OMA_OIDC_ISSUER&&process.env.OMA_OIDC_CLIENT_ID&&process.env.OMA_OIDC_REDIRECT_URI);}

export function createOidc(){
 const issuer=String(process.env.OMA_OIDC_ISSUER||'').replace(/\/$/,'');
 const clientId=process.env.OMA_OIDC_CLIENT_ID||'';
 const clientSecret=process.env.OMA_OIDC_CLIENT_SECRET||'';
 const redirectUri=process.env.OMA_OIDC_REDIRECT_URI||'';
 const scopes=process.env.OMA_OIDC_SCOPES||'openid profile email';
 let cached=null;

 async function discovery(){
  if(!oidcConfigured())throw Object.assign(new Error('OIDC не настроен'),{status:503,code:'OIDC_NOT_CONFIGURED'});
  if(cached&&cached.expiresAt>Date.now())return cached.value;
  const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),8_000);
  try{
   const response=await fetch(`${issuer}/.well-known/openid-configuration`,{signal:controller.signal,headers:{accept:'application/json'}});
   if(!response.ok)throw new Error(`OIDC discovery: HTTP ${response.status}`);
   const value=await response.json();
   if(String(value.issuer||'').replace(/\/$/,'')!==issuer||!value.authorization_endpoint||!value.token_endpoint||!value.jwks_uri)throw new Error('OIDC discovery вернул неполную или несовпадающую конфигурацию');
   cached={value,expiresAt:Date.now()+60*60_000};
   return value;
  }finally{clearTimeout(timer);}
 }

 async function begin(pool,returnTo='/'){
  const metadata=await discovery(),state=random(32),nonce=random(32),verifier=random(48),challenge=crypto.createHash('sha256').update(verifier).digest('base64url');
  await pool.query('DELETE FROM oidc_login_attempts WHERE expires_at<=now()');
  await pool.query(`INSERT INTO oidc_login_attempts(state_hash,code_verifier,nonce,return_to,expires_at)
    VALUES($1,$2,$3,$4,now()+interval '10 minutes')`,[hash(state),verifier,nonce,safeReturnTo(returnTo)]);
  const url=new URL(metadata.authorization_endpoint);
  url.search=new URLSearchParams({response_type:'code',client_id:clientId,redirect_uri:redirectUri,scope:scopes,state,nonce,code_challenge:challenge,code_challenge_method:'S256'}).toString();
  return {url:url.toString(),state};
 }

 async function complete(pool,{code,state}){
  if(typeof code!=='string'||typeof state!=='string'||!code||!state)throw Object.assign(new Error('OIDC callback не содержит code/state'),{status:400,code:'OIDC_CALLBACK_INVALID'});
  const attemptResult=await pool.query(`DELETE FROM oidc_login_attempts WHERE state_hash=$1 AND expires_at>now()
    RETURNING code_verifier,nonce,return_to`,[hash(state)]);
  if(!attemptResult.rowCount)throw Object.assign(new Error('OIDC state недействителен или истёк'),{status:400,code:'OIDC_STATE_INVALID'});
  const attempt=attemptResult.rows[0],metadata=await discovery();
  const headers={'content-type':'application/x-www-form-urlencoded','accept':'application/json'};
  const tokenBody=new URLSearchParams({grant_type:'authorization_code',code,redirect_uri:redirectUri,client_id:clientId,code_verifier:attempt.code_verifier});
  if(clientSecret){
   if(process.env.OMA_OIDC_CLIENT_AUTH==='client_secret_post')tokenBody.set('client_secret',clientSecret);
   else headers.authorization='Basic '+Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  }
  const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),8_000);let token;
  try{
   const response=await fetch(metadata.token_endpoint,{method:'POST',headers,body:tokenBody,signal:controller.signal});
   token=await response.json().catch(()=>({}));
   if(!response.ok||!token.id_token)throw Object.assign(new Error('OIDC token exchange отклонён'),{status:401,code:'OIDC_TOKEN_REJECTED'});
  }finally{clearTimeout(timer);}
  const jwks=createRemoteJWKSet(new URL(metadata.jwks_uri));
  const {payload}=await jwtVerify(token.id_token,jwks,{issuer:metadata.issuer,audience:clientId,clockTolerance:5});
  if(payload.nonce!==attempt.nonce)throw Object.assign(new Error('OIDC nonce не совпадает'),{status:401,code:'OIDC_NONCE_INVALID'});
  if(typeof payload.sub!=='string'||!payload.sub)throw Object.assign(new Error('OIDC subject отсутствует'),{status:401,code:'OIDC_SUBJECT_INVALID'});
  return {claims:payload,issuer:metadata.issuer,returnTo:safeReturnTo(attempt.return_to)};
 }

 return {begin,complete};
}

export function oidcStateCookie(state,{secure=false}={}){return `oma_oidc_state=${encodeURIComponent(state)}; HttpOnly; Path=/api/v1/auth/oidc; SameSite=Lax; Max-Age=600${secure?'; Secure':''}`;}
export function clearOidcStateCookie({secure=false}={}){return `oma_oidc_state=; HttpOnly; Path=/api/v1/auth/oidc; SameSite=Lax; Max-Age=0${secure?'; Secure':''}`;}
