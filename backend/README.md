# AI Expense Tracker Backend

Node.js + Express + TypeScript backend API for the AI Expense Tracker app.

## Features

- **User Authentication**: JWT-based auth with refresh tokens
- **Expense Management**: CRUD operations with pagination, filtering, and summary
- **Budget Management**: Monthly budget tracking
- **User Settings**: Preferences and encrypted AI API key storage
- **Automation Rules**: Configurable automation triggers
- **Data Sync**: Pull, push, and full sync endpoints

## Tech Stack

- Node.js 20 + Express.js
- TypeScript
- Prisma ORM + MySQL
- JWT + bcrypt
- Zod validation
- Helmet + rate limiting

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your database credentials
```

### 3. Run Database Migrations

```bash
npx prisma migrate dev
```

### 4. Start Development Server

```bash
npm run dev
```

The API will be available at `http://localhost:3000`

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/register | Register new user |
| POST | /api/auth/login | Login user |
| POST | /api/auth/refresh | Refresh access token |
| POST | /api/auth/logout | Logout user |
| GET | /api/auth/me | Get current user |

### Expenses

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/expenses | List expenses (paginated) |
| POST | /api/expenses | Create expense |
| GET | /api/expenses/:id | Get expense by ID |
| PUT | /api/expenses/:id | Update expense |
| DELETE | /api/expenses/:id | Delete expense |
| GET | /api/expenses/summary | Get expense summary |

### Budgets

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/budgets | List all budgets |
| POST | /api/budgets | Create budget |
| GET | /api/budgets/current | Get current month budget |
| GET | /api/budgets/month/:month/:year | Get budget by month |
| PUT | /api/budgets/:id | Update budget |
| DELETE | /api/budgets/:id | Delete budget |

### Settings

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/settings | Get user settings |
| PUT | /api/settings | Update user settings |
| GET | /api/settings/ai-keys | Get AI API keys |
| PUT | /api/settings/ai-keys | Update AI API keys |

### Automation

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/automation | List automation rules |
| POST | /api/automation | Create rule |
| GET | /api/automation/:id | Get rule by ID |
| PUT | /api/automation/:id | Update rule |
| DELETE | /api/automation/:id | Delete rule |
| POST | /api/automation/:id/toggle | Toggle rule |

### Sync

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/sync/pull | Pull data from server |
| POST | /api/sync/push | Push data to server |
| POST | /api/sync/full | Full sync |
| GET | /api/sync/status | Get sync status |

## Docker

```bash
# Build and run with Docker Compose
docker-compose up -d

# The API will be available at http://localhost:3000
```

## Project Structure

```
backend/
├── src/
│   ├── config/         # Configuration files
│   ├── controllers/   # Route handlers
│   ├── middleware/    # Express middleware
│   ├── models/        # DTOs and schemas
│   ├── routes/        # API routes
│   ├── services/      # Business logic
│   ├── utils/         # Utility functions
│   └── index.ts       # App entry point
├── prisma/
│   └── schema.prisma  # Database schema
├── .env               # Environment variables
├── package.json
└── tsconfig.json
```

## License

MIT
