## Быстрый старт

### 1. Запуск бэкенда и базы данных (Docker)

```bash
docker compose up --build
```

Эта команда запускает:

- **PostgreSQL** на порту `5432`
- **GraphQL API бэкенд** на порту `4000` (с автоматическими миграциями и заполнением тестовыми данными)

Открыть GraphQL Playground: http://localhost:4000/graphql

### 2. Запуск веб-клиента

```bash
cd web
npm install
npm run dev
```

Открыть в браузере: http://localhost:3000

### 3. Запуск мобильного приложения Flutter

```bash
cd mobile
flutter pub get
flutter run -t lib/main_mobile.dart
```

### 4. Запуск десктопного приложения Flutter

```bash
cd mobile
flutter pub get
flutter run -t lib/main_desktop.dart -d windows
```

## Обзор API

### Запросы (Queries)

- `hotels` — Получить список всех отелей с комнатами
- `hotel(id)` — Получить информацию об отеле по ID
- `room(id)` — Получить детали конкретной комнаты
- `rooms(hotelId)` — Получить список комнат для конкретного отеля
- `bookings(roomId)` — Получить список бронирований для комнаты
- `checkAvailability(input)` — Проверить доступность комнаты на заданные даты

### Мутации (Mutations)

- `createBooking(input)` — Создать бронирование (со встроенной защитой от наложения дат)
- `cancelBooking(input)` — Отменить бронирование

### Пример запроса

```graphql
query {
  hotels {
    id
    name
    rooms {
      id
      number
      type
      pricePerNight
    }
  }
}
```

## Тестовые данные (Seed Data)

При запуске автоматически создаются следующие данные:

- **2 отеля**: Grand Palace Hotel и Cozy Inn
- **6 комнат**: Типы Standard, Deluxe, Suite
- **5 бронирований**: Включая пересекающиеся бронирования для демонстрации обработки конфликтов

## Защита от наложения бронирований

Реализована двухуровневая защита:

1. **На уровне приложения** — Prisma делает запрос для проверки пересекающихся ПОДТВЕРЖДЕННЫХ (CONFIRMED) бронирований перед выполнением `INSERT`.
2. **На уровне базы данных** — Ограничение PostgreSQL `EXCLUDE USING gist` предотвращает состояние гонки (race conditions).

## Архитектурные решения и компромиссы

Согласно требованиям, в проекте были приняты следующие решения:

**1. Бэкенд и СУБД:**

- **GraphQL API:** Выбран для избежания проблемы Over-fetching/Under-fetching. Клиенты (React и Flutter) запрашивают ровно те данные, которые им нужны для рендеринга конкретных экранов.
- **Решение проблемы N+1:** Внедрен Facebook `DataLoader` на уровне GraphQL Context. Запросы к связям (например отель -> комнаты) батчатся, снижая нагрузку на PostgreSQL.
- **Транзакционность (ACID):** Процесс создания бронирования обернут в `Prisma.$transaction`. Валидация доступности и сама вставка происходят атомарно.
- **Компромисс (Кэширование):** В текущей версии не используется Redis. Для масштабирования `checkAvailability` под высокой нагрузкой (тысячи RPS) потребовалось бы кэширование, но ради упрощения инфраструктуры запросы пока идут напрямую в PostgreSQL.

**2. Клиентские приложения (Flutter & React):**

- **Clean Architecture (Flutter):** Код жестко разделен на слои (Data, Domain, Presentation). Использован паттерн `Result<T>` для функциональной обработки ошибок.
- **Кодогенерация GraphQL**: На клиенте React (Apollo) используется кодогенерация типов на основе схемы бэкенда для обеспечения Type Safety от базы данных до UI. Во Flutter используется классический клиент graphql_flutter с типизацией сущностей в слое Domain. Можно перевести GraphQL слой приложения на Ferry (он изначально построен вокруг строгой генерации типов, кэширования и изолятов).
- **Компромисс (State Management):** В React в качестве единого источника истины используется кэш Apollo Client вместо Redux или Zustand.

## Структура проекта

```
IZI/
├── backend/           # Node.js + Apollo GraphQL + Prisma
│   ├── prisma/        # Схема БД, миграции, скрипт заполнения (seed)
│   ├── src/
│   │   ├── schema/    # GraphQL схемы (typeDefs) и резолверы
│   │   ├── services/  # Бизнес-логика
│   │   └── utils/     # Ошибки, валидация, логирование
│   └── Dockerfile
├── mobile/            # Flutter (Мобилки + Windows Desktop)
│   └── lib/
│       ├── core/      # Внедрение зависимостей (DI), тема, GraphQL клиент, ошибки
│       ├── domain/    # Сущности, интерфейсы репозиториев
│       ├── data/      # GraphQL запросы, реализации репозиториев
│       └── presentation/
│           ├── mobile/    # 3 экрана: Отели → Комнаты → Детали комнаты
│           └── desktop/   # 2 экрана: Дашборд, Детали комнаты
├── web/               # React + TypeScript + Apollo Client
│   └── src/
│       ├── api/       # Apollo клиент, GraphQL запросы
│       ├── pages/     # Экраны Hotels, HotelDetail, RoomDetail
│       └── types/     # TypeScript типы
├── docker-compose.yml
└── README.md
```

## Запуск тестов

```bash
cd backend
npm test
```

## Бэкенд без Docker

```bash
# Сначала запустить локальный PostgreSQL, затем:
cd backend
npx prisma migrate dev
npx prisma db seed
npm run dev
```
