import {createStore} from '../db.mjs';

const store=await createStore();
await store.reset();
await store.close();
console.log('Демонстрационные данные PostgreSQL восстановлены; активные сессии завершены');
