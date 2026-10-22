# iOS-обновление OMA ONE (2026-10-23)

**Автономная нативная SwiftUI-версия** получила обновлённые главную, каталог, карточку товара, корзину и путь «задача → смета → корзина». Все восемь интерактивных демо-модулей OMA ONE сохранены и запускаются без сервера. Подробности: [IOS_README.md](IOS_README.md). Приложение не является официальным продуктом ОМА; серверный движок/PWA ниже сохранён.

---

# OMA ONE

Неофициальный конкурсный прототип экосистемы домашних задач. SyncCity, OMA DNA, FORGE, PULSE, Proof с фотографиями, мастера и внешний AI представлены как демонстрационные или дополнительные сценарии. Разрешения, интеграции и доступ к официальным системам ОМА не подтверждены.

Каталог, цены, остатки, пользователи и финансовые показатели в локальном окружении остаются демонстрационными. Настоящие платежи и операции в системах ОМА не выполняются.

## Быстрый запуск

Требуются Node.js 20+ и Docker с Compose:

```bash
npm install
npm run db:up
export DATABASE_URL='postgresql://oma:oma@127.0.0.1:55432/oma_one'
npm start
```

Откройте <http://localhost:8787>. На macOS/Linux можно запустить `./RUN_MAC_LINUX.sh`, на Windows — `RUN_WINDOWS.cmd`. Если PostgreSQL уже работает отдельно, задайте собственный `DATABASE_URL`.

Команды:

```bash
npm test       # unit + интеграционный тест на изолированном PostgreSQL
npm run migrate
npm run reset  # восстановить seed и завершить активные сессии
npm run db:down
```

## Что реализовано в P1

- PostgreSQL, последовательные миграции и транзакции `SERIALIZABLE`.
- Версионированный `/api/v1`; старый `/api/*` отвечает `410 Gone`.
- Серверные сессии, CSRF, строгая проверка Origin, CSP/security headers и rate limiting.
- OIDC Authorization Code + PKCE, проверка ID Token по JWKS, одноразовые state/nonce и автоматическое создание профиля.
- RBAC: административное решение FORGE доступно только менеджеру/администратору.
- Идентичность только из сессии: произвольный `userId` в бизнес-запросах отвергается.
- Строгие Zod-схемы запросов, запрет отрицательных и чрезмерных количеств.
- Серверные расчёты с `calculationId`; клиент не может подменить смету при сохранении или импорте в корзину.
- Десятиминутное резервирование остатков и повторная проверка цены/наличия перед заказом.
- Append-only аудит с correlation ID; IP хранится только как HMAC-SHA-256.
- Proof-фотографии вынесены из БД в локальное или S3-совместимое объектное хранилище, проверяются MIME-сигнатура и размер.
- Клиентские API и состояние вынесены из монолитного `app.js` в отдельные ES-модули.

## Что реализовано в P2 — интерфейс

- Упрощена навигация: основные пользовательские сценарии отделены от экрана «Ещё» с расширенными модулями.
- Добавлены loading, empty, offline и error states, доступный dialog, управление фокусом, ARIA и режимы reduced motion/high contrast.
- Исправлено перекрытие мобильной навигации уведомлениями; интерфейс проверен в desktop и viewport 390×844.
- PWA получила PNG-иконки, installable manifest, offline service worker и URL/history-навигацию.
- Добавлена privacy-safe аналитика воронки и ошибок с серверным allowlist событий и свойств.

Подробный статус и оставшиеся проверки: [`docs/p2/README.md`](docs/p2/README.md).

## Production-конфигурация

Скопируйте перечень переменных из `.env.example`, но передавайте значения через менеджер секретов платформы. Не коммитьте `.env`.

Для production-входа:

```text
NODE_ENV=production
OMA_OIDC_ISSUER=https://identity.example.com
OMA_OIDC_CLIENT_ID=oma-one
OMA_OIDC_CLIENT_SECRET=...
OMA_OIDC_REDIRECT_URI=https://oma-one.example.com/api/v1/auth/oidc/callback
OMA_SECURE_COOKIES=1
```

Демо-вход автоматически отключён при `NODE_ENV=production`, если явно не задано `OMA_DEMO_AUTH=1`. Для публичного пилота не включайте эту переменную.

Для Proof-фотографий задайте `OMA_OBJECT_BUCKET`, регион и при необходимости S3 endpoint. Без bucket используется закрытая локальная папка `var/objects`, пригодная только для разработки.

Внешний AI подключается только на сервере через `OMA_LLM_ENDPOINT`, `OMA_LLM_API_KEY`, `OMA_LLM_MODEL`. Ключ никогда не передаётся браузеру; при недоступности провайдера используется детерминированный ответ.

## Архитектура

```text
PWA: app.js + api.js + state.js + analytics.js
                │
             /api/v1
                │
Node HTTP API ──┼── OIDC / sessions / RBAC / CSRF
                ├── Decision Engine + versioned calculations
                ├── reservations + orders + audit
                ├── PostgreSQL migrations and state
                └── local/S3-compatible Proof object store
```

Основные файлы:

- `server.mjs` — HTTP/API и маршрутизация.
- `db.mjs`, `db/migrations/` — PostgreSQL, транзакции, миграции, аудит и сессии.
- `oidc.mjs`, `security.mjs`, `validation.mjs` — вход и защитные контуры.
- `object-store.mjs` — локальное/S3-хранилище Proof.
- `engine.mjs`, `seed.mjs` — расчётные правила и тестовые данные.
- `public/` — PWA-клиент.
- `tests/` — unit и интеграционные проверки.
- `docs/p0/` — принятые рамки пилота, роли, SLA, API-запрос и риски.

## API v1

После входа все изменяющие запросы требуют cookie-сессию и заголовок `X-CSRF-Token`, совпадающий с cookie `oma_csrf`.

| Метод | Путь | Назначение |
|---|---|---|
| GET | `/api/v1/health` | Состояние сервиса |
| GET | `/api/v1/auth/config` | Доступные способы входа |
| GET | `/api/v1/auth/oidc/start` | Начать OIDC-вход |
| GET | `/api/v1/bootstrap` | Данные активного профиля |
| POST | `/api/v1/solve` | Серверный расчёт |
| POST | `/api/v1/projects` | Сохранить расчёт по `calculationId` |
| POST | `/api/v1/cart/import-plan` | Импортировать проверенный расчёт |
| POST | `/api/v1/cart/reserve` | Зарезервировать остатки |
| POST | `/api/v1/orders` | Создать заказ по `reservationId` |
| POST | `/api/v1/analytics/events` | Записать разрешённое продуктовое событие |
| GET | `/api/v1/audit` | Аудит для менеджера/администратора |

Полный текущий контракт зафиксирован схемами в `validation.mjs` и интеграционным тестом `tests/api.test.mjs`.

## Ограничения пилота

Пока не подключены реальные API ОМА для каталога, оплаты, доставки, возвратов и мастеров. OIDC и S3 готовы к конфигурации, но требуют реквизитов среды. Полная нормализация доменных сущностей, модерация DNA/FORGE/PULSE, антивирусная проверка файлов, observability, нагрузочные тесты, независимый security review и CI/CD остаются следующими P1-шагами.

---

## Новый проверяемый контур: OMA ONE Evidence Lab

Для хакатона добавлена отдельная лаборатория с динамическими сценариями всех восьми модулей и расчётом экономики **на синтетических данных**. Не требует PostgreSQL или AI-ключа:

```bash
npm run test:proof
npm run evidence
# http://localhost:8790
```

Подробнее: `docs/evidence/START_HERE.md`, `docs/evidence/EXECUTION_REPORT.md`, `docs/evidence/USER_VALIDATION_PROTOCOL.md`.

**Прозрачность:** это доказательство работоспособности демо-алгоритмов, а не доказательство рыночной эффективности или производственной готовности. Основной backend с PostgreSQL остаётся отдельной частью проекта, полной iOS-сборки без Xcode нет. Показ прототипа не означает интеграции с настоящим приложением ОМА.
