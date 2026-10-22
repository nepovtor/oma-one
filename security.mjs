import crypto from 'node:crypto';

export const SESSION_COOKIE='oma_session';
export const CSRF_COOKIE='oma_csrf';

export function parseCookies(header=''){
 return Object.fromEntries(header.split(';').map(part=>part.trim()).filter(Boolean).map(part=>{const at=part.indexOf('=');return at<0?[part,'']:[part.slice(0,at),decodeURIComponent(part.slice(at+1))];}));
}

export function sessionCookies(session,{secure=false}={}){
 const flags=`Path=/; SameSite=Strict; Max-Age=${session.expiresIn}${secure?'; Secure':''}`;
 return [
  `${SESSION_COOKIE}=${encodeURIComponent(session.token)}; HttpOnly; ${flags}`,
  `${CSRF_COOKIE}=${encodeURIComponent(session.csrf)}; ${flags}`
 ];
}

export function clearSessionCookies({secure=false}={}){
 const flags=`Path=/; SameSite=Strict; Max-Age=0${secure?'; Secure':''}`;
 return [`${SESSION_COOKIE}=; HttpOnly; ${flags}`,`${CSRF_COOKIE}=; ${flags}`];
}

export function applySecurityHeaders(res,{api=false}={}){
 res.setHeader('x-content-type-options','nosniff');
 res.setHeader('x-frame-options','DENY');
 res.setHeader('referrer-policy','no-referrer');
 res.setHeader('permissions-policy','camera=(), microphone=(), geolocation=(), payment=()');
 res.setHeader('cross-origin-opener-policy','same-origin');
 res.setHeader('cross-origin-resource-policy','same-origin');
 res.setHeader('content-security-policy',"default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'; worker-src 'self'");
 if(api)res.setHeader('cache-control','no-store');
}

export function requestIp(req){
 if(process.env.OMA_TRUST_PROXY==='1'){
  const forwarded=String(req.headers['x-forwarded-for']||'').split(',')[0].trim();
  if(forwarded)return forwarded;
 }
 return req.socket.remoteAddress||'';
}

export function isAllowedOrigin(req){
 const origin=req.headers.origin;
 if(!origin)return true;
 const expected=`${req.socket.encrypted?'https':'http'}://${req.headers.host}`;
 const allowed=new Set(String(process.env.OMA_ALLOWED_ORIGINS||'').split(',').map(x=>x.trim()).filter(Boolean));
 return origin===expected||allowed.has(origin);
}

export function createRateLimiter(){
 const buckets=new Map();
 return function check(key,{limit=120,windowMs=60_000}={}){
  const now=Date.now();let bucket=buckets.get(key);
  if(!bucket||bucket.resetAt<=now){bucket={count:0,resetAt:now+windowMs};buckets.set(key,bucket);}
  bucket.count++;
  if(buckets.size>10_000)for(const [name,value] of buckets)if(value.resetAt<=now)buckets.delete(name);
  return {allowed:bucket.count<=limit,remaining:Math.max(0,limit-bucket.count),resetAt:bucket.resetAt};
 };
}

export function correlationId(req){
 const value=String(req.headers['x-correlation-id']||'');
 return /^[a-zA-Z0-9._-]{8,100}$/.test(value)?value:crypto.randomUUID();
}

export function csrfMatches(store,session,provided){
 if(!provided||!session)return false;
 const actual=Buffer.from(store.hash(provided));
 const expected=Buffer.from(session.csrfHash);
 return actual.length===expected.length&&crypto.timingSafeEqual(actual,expected);
}
