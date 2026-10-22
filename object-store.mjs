import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {S3Client,PutObjectCommand,GetObjectCommand,DeleteObjectCommand} from '@aws-sdk/client-s3';

const root=path.dirname(fileURLToPath(import.meta.url));
const invalid=message=>Object.assign(new Error(message),{status:422,code:'INVALID_IMAGE'});

function decodeImage(dataUrl){
 const match=/^data:image\/(png|jpeg|webp);base64,([A-Za-z0-9+/=]+)$/.exec(dataUrl||'');
 if(!match)throw invalid('Неверный формат фотографии');
 const body=Buffer.from(match[2],'base64'),declared=match[1];
 if(!body.length||body.length>1_250_000)throw invalid('Фотография превышает допустимый размер');
 const detected=body[0]===0x89&&body.subarray(1,4).toString()==='PNG'?'png':body[0]===0xff&&body[1]===0xd8&&body[2]===0xff?'jpeg':body.subarray(0,4).toString()==='RIFF'&&body.subarray(8,12).toString()==='WEBP'?'webp':null;
 if(!detected||detected!==declared)throw invalid('Содержимое фотографии не соответствует MIME-типу');
 return {body,mime:`image/${detected}`,extension:detected==='jpeg'?'jpg':detected};
}

function safeKey(key){
 if(typeof key!=='string'||!/^proof\/[0-9]{4}\/[0-9]{2}\/[a-f0-9-]+\.(jpg|png|webp)$/.test(key))throw invalid('Недопустимый ключ объекта');
 return key;
}

export async function createObjectStore(){
 const bucket=process.env.OMA_OBJECT_BUCKET||'';
 const prefix=(process.env.OMA_OBJECT_PREFIX||'').replace(/^\/+|\/+$/g,'');
 const localRoot=path.resolve(process.env.OMA_OBJECT_DIR||path.join(root,'var','objects'));
 const s3=bucket?new S3Client({region:process.env.OMA_OBJECT_REGION||'us-east-1',endpoint:process.env.OMA_OBJECT_ENDPOINT||undefined,forcePathStyle:process.env.OMA_OBJECT_FORCE_PATH_STYLE==='1'}):null;
 if(!s3)await fs.mkdir(localRoot,{recursive:true});
 const storage=s3?'s3':'local';
 const fullKey=key=>prefix?`${prefix}/${key}`:key;

 async function putProof(dataUrl){
  const {body,mime,extension}=decodeImage(dataUrl),now=new Date(),key=`proof/${now.getUTCFullYear()}/${String(now.getUTCMonth()+1).padStart(2,'0')}/${crypto.randomUUID()}.${extension}`;
  if(s3)await s3.send(new PutObjectCommand({Bucket:bucket,Key:fullKey(key),Body:body,ContentType:mime,ServerSideEncryption:process.env.OMA_OBJECT_SSE||undefined,Metadata:{purpose:'proof'}}));
  else{
   const filename=path.join(localRoot,safeKey(key));
   await fs.mkdir(path.dirname(filename),{recursive:true});
   await fs.writeFile(filename,body,{flag:'wx',mode:0o600});
  }
  return {key,mime,size:body.length,storage};
 }

 async function get(object){
  const key=safeKey(object.key);
  if(s3){const result=await s3.send(new GetObjectCommand({Bucket:bucket,Key:fullKey(key)})),bytes=await result.Body.transformToByteArray();return {body:Buffer.from(bytes),mime:result.ContentType||object.mime};}
  return {body:await fs.readFile(path.join(localRoot,key)),mime:object.mime};
 }

 async function remove(object){
  if(!object?.key)return;
  const key=safeKey(object.key);
  if(s3)await s3.send(new DeleteObjectCommand({Bucket:bucket,Key:fullKey(key)}));
  else await fs.rm(path.join(localRoot,key),{force:true});
 }

 return {putProof,get,remove,storage};
}
