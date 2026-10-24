import {createStore} from '../db.js';

const store=await createStore();
await store.close();
console.log('Миграции PostgreSQL применены');
