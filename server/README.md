# LOCKED IN — Backend Server

A complete, production-ready async backend for the **LOCKED IN** fitness & life
lock-in app. Built with **Python 3.12, FastAPI, SQLAlchemy (async) + SQLite
(aiosqlite)**, JWT auth, XP/gamification, streaks, habits, workouts, study,
social, competitions, and a timestamps-based sync protocol.

## Quick Start

```bash
cd server
python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

pip install -r requirements.txt
uvicorn main:app --reload
```

The API runs at `http://localhost:8000`, interactive docs at `http://localhost:8000/docs`.

## Seeded Data (auto on startup)

- Tables are created automatically on first boot.
- An initial admin invite code **`LOCKEDIN2026`** is seeded (max 10 uses).
- If the DB is empty, a default admin account is created:
  - email: `admin@lockedin.app`
  - password: `ChangeMe123!`
  - **Change these credentials immediately in production.**

The **first real signup** (via a valid invite code) automatically becomes an
admin too.

## Configuration (env vars)

| Variable | Default | Notes |
|---|---|---|
| `DATABASE_URL` | `sqlite+aiosqlite:///./locked_in.db` | SQLite async URL |
| `SECRET_KEY` | dev secret | **Set a strong secret in production** |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `10080` (7d) | |
| `REFRESH_TOKEN_EXPIRE_MINUTES` | `43200` (30d) | |
| `ADMIN_INVITE_CODE` | `LOCKEDIN2026` | Seeded invite code |

Copy `.env.example` to `.env` if you want to override — `config.py` reads it.

## Core Concepts

- **XP**: awarded for workouts (10–50), habits (5), study (10 per 30 min), and
  streak bonuses (streak_count × 2). All XP is multiplied by the user's
  **lock-in level**: `mini` ×1, `standard` ×2, `full` ×3.
- **Levels 1–100**: each level requires `level² × 100` XP to advance.
- **Creatine**: in-game currency (5–20 per activity) used for cosmetics,
  streak freezes, and XP boosts.
- **Streaks**: `daily_workout`, `daily_habits`, `daily_study`, `daily_all`.
  `daily_all` requires at least 1 habit **plus** 1 other activity. Streak freezes
  (max 2/month) pause decay.
- **Approval flow**: new users register as **pending**; an admin must approve
  them (except the first user / seeded admin who are auto-approved). Banned
  users are blocked from login and all authenticated actions.
- **Invite codes**: required for signup; single-use or multi-use with optional
  expiry, created by admins.

## API Overview

### Auth
- `POST /api/auth/signup` — email, username, password, invite_code (creates pending user)
- `POST /api/auth/login` — returns JWT + refresh + user
- `POST /api/auth/refresh` — rotate refresh token
- `GET  /api/auth/me` — current profile

### Admin (requires admin)
- `GET  /api/admin/pending-users`
- `POST /api/admin/approve/{user_id}`
- `POST /api/admin/ban/{user_id}`
- `GET  /api/admin/squad-stats`
- `POST /api/admin/invite-codes`, `GET /api/admin/invite-codes`

### User
- `GET/PUT /api/user/profile`
- `GET /api/user/stats`

### Workouts
- `POST/GET /api/workouts/sessions`, `GET/PUT/DELETE /api/workouts/sessions/{id}`
- `POST /api/workouts/sessions/{id}/sets`, `PUT/DELETE /api/workouts/sets/{id}`
- `POST/GET /api/workouts/templates`, `POST /api/workouts/templates/{id}/start`
- `GET /api/workouts/exercises`, `GET /api/workouts/stats`, `GET /api/workouts/prs`

### Habits
- `POST/GET /api/habits`, `PUT/DELETE /api/habits/{id}`
- `POST /api/habits/{id}/log`, `GET /api/habits/today`, `GET /api/habits/stats`

### Daily / Body / Streaks / XP
- `POST/GET /api/daily`, `GET /api/daily/today`, `GET /api/daily/history`
- `POST /api/body/log`, `GET /api/body/history`, `GET /api/body/stats`
- `GET /api/streaks`, `POST /api/streaks/check`
- `GET /api/xp`, `GET /api/xp/transactions`, `POST /api/xp/earn`

### Social
- `GET /api/squad/leaderboard`
- `POST /api/squad/friend-request/{user_id}`, `POST /api/squad/friend-accept/{friendship_id}`
- `GET /api/squad/friends`, `POST /api/squad/reaction`, `GET /api/squad/feed`

### Competitions
- `GET /api/competitions/active`, `POST /api/competitions/join/{id}`
- `GET /api/competitions/{id}/leaderboard`

### Study
- `POST /api/study/log`, `GET /api/study/history`, `GET /api/study/stats`
- `POST /api/study/pomodoro`, `POST /api/study/pomodoro/complete/{id}`

### Sync
- `POST /api/sync/push`, `POST /api/sync/pull`, `GET /api/sync/status`

## Auth

Send the access token as the `Authorization` header:
```
Authorization: Bearer <access_token>
```

Tokens are JWT (HS256). Refresh tokens are type-tagged and validated separately.
Expired / malformed tokens return `401`. Non-approved accounts return `403`.

## Sync Protocol

Clients batch local changes:

```json
POST /api/sync/push
{
  "client_timestamp": "2026-08-31T10:00:00",
  "changes": [
    {
      "table_name": "habits",
      "records": [
        {"id": "abc", "table": "habits", "data": {"name": "Drink water", "target_frequency": 8}, "timestamp": "2026-08-31T09:55:00"}
      ]
    }
  ]
}
```

The server performs **last-write-wins per field**, returns `changed` records plus
any `conflicts` detected when a record was edited concurrently on both ends, and
then echoes back everything changed since last sync via `pull` semantics.

Call `POST /api/sync/pull` with `{"since": "<iso timestamp>"}` to fetch changes
after a cutoff. `GET /api/sync/status` returns the last sync timestamp.

## Privacy

Each user's `privacy_settings` (JSON string) controls per-category visibility
(workout / study / etc.). The social feed respects these settings and only shows
public data from accepted friends and the user themself.

## File Structure

```
server/
├── main.py          FastAPI app, CORS, startup seeding
├── config.py        settings / env
├── database.py      async engine + session
├── models.py        all SQLAlchemy models
├── schemas.py       Pydantic v2 schemas
├── auth.py          JWT, password hashing, dependency injection
├── routes/          API route modules
├── services/        xp, streak, gamification, sync logic
├── requirements.txt
└── README.md
```

## Production Notes

- Set a real `SECRET_KEY` and a real admin password.
- SQLite is fine for a single small instance; swap `DATABASE_URL` to Postgres by
  changing the driver (e.g. `postgresql+asyncpg://...`) — the models are
  agnostic.
- CORS is currently `*` for dev. Restrict `CORS_ORIGINS` in production.
