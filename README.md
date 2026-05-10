# TradeFlow

TradeFlow is a DBMS project for a stock trading platform. It includes a single-page React frontend, a Python Flask API, and a relational database design that supports users, companies, admins, orders, trades, wallets, portfolios, audit logs, and stock price history.

## Features

- User login with JWT-based authentication
- Role-based access for `USER`, `COMPANY`, and `ADMIN`
- Stock browsing with price history charts
- Buy and sell order flow with wallet and portfolio updates
- Wallet deposit, withdrawal, and transaction history
- Portfolio summary with invested value, current value, and profit/loss
- Company dashboard for listed companies
- Company announcements and financial results
- Admin panel for users, companies, stocks, wallets, orders, and audit logs
- SQLite local mode for quick testing
- PostgreSQL/Supabase mode for full DBMS deployment

## Tech Stack

- Frontend: React from CDN, Chart.js, plain HTML/CSS/JavaScript
- Backend: Python, Flask, Flask-CORS, PyJWT
- Database: SQLite for local development, PostgreSQL/Supabase for deployment
- DBMS concepts: tables, views, triggers, stored functions, indexes, constraints, and role-based access

## Project Structure

```text
tradeflow_v4_complete/
├── backend/                 # Flask API and local SQLite initializer
│   ├── middleware/          # JWT auth middleware
│   ├── routes/              # API route modules
│   ├── db.py                # PostgreSQL/SQLite database adapter
│   ├── init_db.py           # Local SQLite schema and seed data
│   ├── server.py            # Backend entry point
│   ├── requirements.txt     # Python dependencies
│   └── .env.example         # Example environment variables
├── frontend/
│   └── index.html           # React single-page application
├── database/
│   ├── schema.sql           # Main PostgreSQL/Supabase schema
│   └── backup/
│       └── backup.tar       # Full PostgreSQL backup archive
├── study/                   # Report, presentation, viva, and learning files
│   ├── database-notes/
│   ├── diagrams/
│   ├── ppt/
│   ├── project_explanation.txt
│   └── Tradeflow DBMS Final Project Report.pdf
├── .gitignore
└── README.md
```

## Getting Started

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd tradeflow_v4_complete
```

### 2. Set Up the Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python server.py
```

The backend runs at:

```text
http://localhost:4000
```

Health check:

```text
http://localhost:4000/api/health
```

### 3. Open the Frontend

Open this file in your browser:

```text
frontend/index.html
```

The frontend expects the backend API at:

```text
http://localhost:4000/api
```

## Database Setup

### Local SQLite Mode

For local testing, leave `DATABASE_URL` empty in `backend/.env`. When you start the backend, `init_db.py` creates and seeds a local SQLite database automatically.

### PostgreSQL/Supabase Mode

To use Supabase or PostgreSQL:

1. Create a PostgreSQL/Supabase project.
2. Run `database/schema.sql` in your SQL editor.
3. Set `DATABASE_URL` in `backend/.env`.
4. Restart the backend.

Main schema file:

```text
database/schema.sql
```

This file combines the project schema, v4 company-role updates, dashboard fixes, and admin reporting views.

### Restore From Backup

The full database backup is stored at:

```text
database/backup/backup.tar
```

Use it only when you want to restore the complete PostgreSQL database dump, including data. A typical restore command is:

```bash
pg_restore --clean --if-exists --dbname "<your-postgres-connection-string>" database/backup/backup.tar
```

For normal setup, prefer `database/schema.sql` because it is cleaner and easier to review.

## Demo Credentials

| Role | Email | Password |
| --- | --- | --- |
| User | demo@tradeflow.in | password |
| Admin | admin@tradeflow.in | password |
| Company | company@tradeflow.in | password |

## Main API Routes

| Area | Routes |
| --- | --- |
| Auth | `/api/auth/*` |
| Stocks | `/api/stocks/*` |
| Orders | `/api/orders/*` |
| Portfolio | `/api/portfolio/*` |
| Wallet | `/api/wallet/*` |
| Admin | `/api/admin/*` |
| Company | `/api/company/*` |

## Study Material

The `study/` folder contains supporting files for presentation, viva, and project explanation:

- Final DBMS project report
- PPT guide and detailed presentation plan
- Complete project explanation
- Table relationship notes
- Views and roles notes
- Integrity constraint notes
- Relational diagram HTML

## GitHub Notes

The repository is prepared so local-only files are ignored:

- `backend/.env`
- local SQLite database files such as `backend/tradeflow.db`
- Python cache folders such as `__pycache__/`
- virtual environments

Before pushing, run:

```bash
git status
git add .
git commit -m "Organize TradeFlow project structure"
git push
```

## Project Summary

TradeFlow demonstrates how a trading application can be designed around strong database concepts. The backend exposes role-protected REST APIs, the frontend provides role-specific dashboards, and the database layer handles core entities such as users, wallets, orders, trades, portfolios, stock history, company data, and audit logs.
