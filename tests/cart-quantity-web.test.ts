import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import {schemas} from '../validation.js';
test('quantity range and strict payload',()=>{for(const q of [1,2,200])assert.equal(schemas.cartQuantity.safeParse({quantity:q}).success,true);for(const q of [0,-1,201,1.5,'2',null])assert.equal(schemas.cartQuantity.safeParse({quantity:q}).success,false);});
test('cart PATCH and distinct delete contracts',async()=>{const [server,app]=await Promise.all([fs.readFile('server.ts','utf8'),fs.readFile('public/app.ts','utf8')]);assert.match(server,/method==='PATCH'&&cartMatch/);assert.match(server,/user\.cart\.find\(value=>value\.id===cartMatch\[1\]\)/);assert.match(server,/method==='DELETE'&&cartMatch/);assert.match(app,/data-cart-qty/);assert.match(app,/qty-step/);assert.match(app,/remove-shelf-cart/);});
