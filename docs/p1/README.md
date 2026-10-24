# P1: технический baseline production-пилота

Статус: 22.10.2026. Все расширенные модули считаются разрешёнными для пилота, но реальные интеграции включаются только после выдачи контрактов и реквизитов среды.

## Реализовано

| Контур | Реализация | Проверка |
|---|---|---|
| Данные | PostgreSQL, миграции, seed без JSON-файла | интеграционный запуск на чистой временной БД |
| Конкурентность | `SERIALIZABLE`, блокировка состояния, резерв на 10 минут | два параллельных резерва не превышают остаток |
| Вход | OIDC Code + PKCE, JWKS, state/nonce, серверные сессии | конфигурационный контракт; нужен тестовый IdP |
| Доступ | роли client/master/operator/manager/administrator | клиенту запрещено решение FORGE и чужой Proof |
| API | `/api/v1`, Zod request validation, correlation ID | старый API возвращает `410` |
| Расчёты | серверный `calculationId`, версия правил | план нельзя прислать обратно в изменённом виде |
| Web security | CSRF, Origin policy, CSP, headers, rate limits | негативные API-тесты |
| Аудит | append-only PostgreSQL table | проверка событий заказа и FORGE |
| Proof | локальное/S3 object storage, magic-byte/size checks | загрузка и закрытая выдача владельцу |

## Порядок включения production

1. Выдать PostgreSQL и S3-совместимое хранилище с backup/retention policy.
2. Зарегистрировать OIDC client и callback; роли выдавать только утверждённой группой IdP.
3. Передать секреты через secret manager, включить HTTPS и `OMA_SECURE_COOKIES=1`.
4. Подключить staging-контракты каталога, остатков, корзины, заказов и мастеров.
5. Прогнать contract/E2E, нагрузочный и security-тесты.
6. Включить аудит/метрики/алерты и проверить восстановление из backup.
7. Запустить ограниченный rollout по feature flags.

## Оставшиеся P1-блокеры

- реальные контракты ОМА и тестовые среды;
- полная нормализация доменных сущностей вместо единого JSONB состояния;
- response-схемы и генерируемая OpenAPI-спецификация;
- модерация UGC/DNA/FORGE/PULSE и антивирусный скан Proof;
- каталог/расписание/заказы мастеров, платежи, доставка, возвраты;
- secret manager, observability, backup restore drill, CI/CD;
- contract/E2E, load test и независимый penetration test;
- дальнейшее разбиение экранов `public/app.ts`.
