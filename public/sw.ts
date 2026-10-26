const CACHE='oma-one-v8';
const PRODUCT_IMAGES=Array.from({length:28},(_,index)=>`/products/ProductP${String(index+1).padStart(2,'0')}.jpg`);
const SHELL=['/','/index.html','/app.js','/api.js','/analytics.js','/state.js','/shelf.js','/finance.js','/finance-domain.js','/evidence-engine.js','/styles.css','/manifest.webmanifest','/icons/icon.svg','/icons/icon-192.png','/icons/icon-512.png','/icons/apple-touch-icon.png',...PRODUCT_IMAGES];
const worker=globalThis as unknown as ServiceWorkerGlobalScope;
worker.addEventListener('install',(event: ExtendableEvent)=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(SHELL)).then(()=>worker.skipWaiting())));
worker.addEventListener('activate',(event: ExtendableEvent)=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key!==CACHE).map(key=>caches.delete(key)))).then(()=>worker.clients.claim())));
worker.addEventListener('fetch',(event: FetchEvent)=>{const request=event.request;const url=new URL(request.url);if(request.method!=='GET'||url.origin!==worker.location.origin||url.pathname.startsWith('/api/'))return;event.respondWith(fetch(request).then(async response=>{if(response.ok){await caches.open(CACHE).then(cache=>cache.put(request,response.clone())).catch(()=>{});}return response;}).catch(()=>caches.match(request).then(cached=>cached||caches.match('/')).then(cached=>cached??Response.error())));});
