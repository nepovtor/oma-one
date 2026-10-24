import fs from 'node:fs/promises';
import path from 'node:path';
import {PROOF_VERSION,antiFail,dna,domino,economics,forge,proof,pulse,syncCity,zeroBuy} from '../proof-engine.js';
import {FIXTURES} from '../proof-fixtures.js';
const results={
 zerobuy:zeroBuy(structuredClone(FIXTURES.zerobuy)),
 antifail:antiFail(structuredClone(FIXTURES.antifail)),
 domino:domino(structuredClone(FIXTURES.domino)),
 synccity:syncCity(structuredClone(FIXTURES.synccity)),
 proof:proof(structuredClone(FIXTURES.proof)),
 dna:dna(structuredClone(FIXTURES.dna)),
 forge:forge(structuredClone(FIXTURES.forge)),
 pulse:pulse(structuredClone(FIXTURES.pulse)),
 economics:economics(structuredClone(FIXTURES.economics))
};
const lines=[
 '# OMA ONE — Воспроизводимый протокол выполнения',
 '',
 '> **Важно:** это доказательство работы *программных алгоритмов на синтетических данных*, НЕ доказательство спроса, безопасности конструкций, цен ОМА, экономии реальных покупателей, реальных заказов или готовности интеграции.',
 '',
 `Версия правил: \`${PROOF_VERSION}\`. Сгенерировано командой \`npm run evidence:report\`.`,
 '',
 '| Модуль | Наблюдаемый результат на базовом примере | Что пока НЕ доказано |',
 '|---|---|---|',
 `| ZeroBuy | Из корзины ${results.zerobuy.result.full} BYN осталось ${results.zerobuy.result.after} BYN, избежанная покупка ${results.zerobuy.result.savings} BYN | Что товар действительно есть дома и пригоден |`,
 `| AntiFail | Статус ${results.antifail.result.status}, блокирующих правил ${results.antifail.result.critical.length} | Техническая пригодность реального крепежа |`,
 `| Domino | Порядок ${results.domino.result.valid?'принят':'отклонён'}, нарушений ${results.domino.result.errors.length} | Полнота экспертной схемы работ |`,
 `| SyncCity | ${results.synccity.result.requestCount} совместимых заявок, условное снижение затрат ${results.synccity.result.savingsPerUser} BYN/участник | Реальные логистические тарифы и согласия |`,
 `| Proof | Статус ${results.proof.result.status}, публикация ${results.proof.result.canPublishToDNA?'да':'нет'}, хеш ${results.proof.result.digest.slice(0,12)}… | Подлинность и качество выполненной работы |`,
 `| DNA | Индекс сопоставления ${results.dna.result.best.score}/100 для ${results.dna.result.best.id}, условный материал ${results.dna.result.best.adaptedUnits} ед. | Реальная точность и применимость чужого проекта |`,
 `| FORGE | ${results.forge.result.clusters[0].interested} согласий на интерес, ориентир минимальной цены ${results.forge.result.minimumIndicativePrice} BYN | Реальные предзаказы, себестоимость, договоры |`,
 `| PULSE | ${results.pulse.result.signals[0].distinctVerifiedCases} независимых тестовых сообщения, автоматических уведомлений ${results.pulse.result.notificationsSent} | Фактический дефект, полнота данных и частота отказов |`,
 `| Economics | Вклад ${results.economics.result.contribution} BYN, ${results.economics.result.breakEvenOrders} заказов для покрытия условных ${FIXTURES.economics.fixedCost} BYN фиксированных расходов | Фактические маржа, CAC, SLA, комиссии ОМА |`,
 '',
 '## Как повторить',
 '',
 '```bash',
 'npm run test:proof',
 'npm run evidence',
 '# открыть http://localhost:8790/',
 'npm run evidence:report',
 '```',
 '',
 '## Условия приёмки',
 '',
 '1. Каждая функция выдаёт JSON с version, inputs, result и limits.',
 '2. Параметры интерфейса реально меняют результаты, без замены шаблонного текста.',
 '3. При конфликте AntiFail выдаёт BLOCKED, Domino отклоняет нарушенный граф.',
 '4. ZeroBuy не вычитает больше подтверждённого количества.',
 '5. SyncCity не обещает экономии при недостаточном числе заявок или отрицательной экономике.',
 '6. Proof отделяет самоотчёт от экспертной проверки, не публикует без согласия.',
 '7. DNA не называет непроверенный шаблон проверенным.',
 '8. FORGE не превращает голоса в заказы и автоматически не утверждает цену.',
 '9. PULSE не выдаёт случайный кластер за отзыв товара и не рассылает автоматические предупреждения.',
 '10. Экономика поддерживает отрицательный вклад и сценарий без точки окупаемости.',
 '',
 '## Реальное рыночное подтверждение — пока отсутствует',
 '',
 'Нельзя писать «доказали эффект для клиентов ОМА» до получения интервью, фактической телеметрии и пилотных заказов. Форма сбора ниже есть в `USER_VALIDATION_PROTOCOL.md`.',
 'Замените синтетические данные только после разрешения ОМА, юридической оценки и проверки источников.',
 '',
];
const report=lines.join('\n');
await Promise.all([
 fs.writeFile(path.join(process.cwd(),'EXECUTION_REPORT.md'),report),
 fs.writeFile(path.join(process.cwd(),'docs/evidence/EXECUTION_REPORT.md'),report),
 fs.writeFile(path.join(process.cwd(),'docs/evidence/OUTPUT_TRACES.json'),JSON.stringify({proofVersion:PROOF_VERSION,generatedFrom:'synthetic fixtures',modules:results},null,2)+'\n')
]);
console.log('Evidence report regenerated: 9 modules, 3 artifacts.');
