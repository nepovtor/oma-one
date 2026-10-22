import {createStore} from '../db.mjs';

const store=await createStore();
await store.close();
console.log('Миграции PostgreSQL применены');
