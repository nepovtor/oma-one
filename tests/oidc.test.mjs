import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {once} from 'node:events';
import {generateKeyPair,exportJWK,SignJWT} from 'jose';
import {startPostgres} from './postgres.mjs';
import {createStore} from '../db.mjs';
import {createOidc} from '../oidc.mjs';

test('OIDC Code + PKCE validates issuer, audience, nonce and one-time state',async t=>{
 const database=await startPostgres();
 const store=await createStore({connectionString:database.connectionString});
 const {privateKey,publicKey}=await generateKeyPair('RS256');
 const jwk=await exportJWK(publicKey);jwk.kid='test-key';jwk.alg='RS256';jwk.use='sig';
 let expectedNonce='';
 const provider=http.createServer(async(req,res)=>{
  const origin=`http://127.0.0.1:${provider.address().port}`;
  if(req.url==='/.well-known/openid-configuration')return void end({issuer:origin,authorization_endpoint:origin+'/authorize',token_endpoint:origin+'/token',jwks_uri:origin+'/jwks'});
  if(req.url==='/jwks')return void end({keys:[jwk]});
  if(req.url==='/token'){
   const token=await new SignJWT({sub:'oidc-user',name:'OIDC User',email:'user@example.test',roles:['manager'],nonce:expectedNonce}).setProtectedHeader({alg:'RS256',kid:'test-key'}).setIssuer(origin).setAudience('oma-one-test').setIssuedAt().setExpirationTime('5m').sign(privateKey);
   return void end({access_token:'test',token_type:'Bearer',expires_in:300,id_token:token});
  }
  res.writeHead(404);res.end();
  function end(value){res.writeHead(200,{'content-type':'application/json'});res.end(JSON.stringify(value));}
 });
 provider.listen(0,'127.0.0.1');await once(provider,'listening');
 const issuer=`http://127.0.0.1:${provider.address().port}`;
 Object.assign(process.env,{OMA_OIDC_ISSUER:issuer,OMA_OIDC_CLIENT_ID:'oma-one-test',OMA_OIDC_CLIENT_SECRET:'secret',OMA_OIDC_REDIRECT_URI:'http://127.0.0.1/callback'});
 t.after(async()=>{delete process.env.OMA_OIDC_ISSUER;delete process.env.OMA_OIDC_CLIENT_ID;delete process.env.OMA_OIDC_CLIENT_SECRET;delete process.env.OMA_OIDC_REDIRECT_URI;provider.close();await once(provider,'close');await store.close();await database.stop();});

 const oidc=createOidc(),started=await oidc.begin(store.pool,'/profile');
 const authorization=new URL(started.url);
 expectedNonce=authorization.searchParams.get('nonce');
 assert.equal(authorization.searchParams.get('code_challenge_method'),'S256');
 assert.equal(authorization.searchParams.get('state'),started.state);
 const completed=await oidc.complete(store.pool,{code:'authorization-code',state:started.state});
 assert.equal(completed.claims.sub,'oidc-user');
 assert.equal(completed.claims.aud,'oma-one-test');
 assert.equal(completed.returnTo,'/profile');
 await assert.rejects(()=>oidc.complete(store.pool,{code:'replay',state:started.state}),error=>error.code==='OIDC_STATE_INVALID');
});
