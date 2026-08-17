# SkillCubes Backend

Production-oriented **FastAPI** API for the SkillCubes Flutter app.

## Features

- JWT auth (`/auth/register`, `/auth/login`, `/auth/me`)
- Freemium: 2 free categories (`hizli-matematik`, `oruntu-yakalama`); other 4 return **2 questions** for non-premium
- Categories with per-user completion + lock flags (`/categories`)
- Questions (`/questions?category_id=`) — 20 for free/premium-unlocked cats
- Progress + streak (`/user/progress`, `/user/stats`)
- Cognitive radar (`/user/radar-stats`) — 6-axis percentages
- Gemini `CognitiveCoachAgent` (`/ai/analyze`) — Turkish summary + premium-gated detailed report
- Dev premium toggle (`/user/toggle-premium`)
- SQLite by default, PostgreSQL via `DATABASE_URL`
- Seed script with 6 cognitive categories × 20 questions

## Quick start

```bash
cd skillcubes-backend

# 1) Virtual environment
python -m venv .venv

# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# macOS / Linux
# source .venv/bin/activate

# 2) Install dependencies
pip install -r requirements.txt

# 3) Environment
copy .env.example .env   # Windows
# cp .env.example .env   # macOS / Linux
# Set GEMINI_API_KEY in .env for live AI analysis (fallback works without it)

# 4) Create tables + seed mock questions
python -m app.db.seed

# 5) Run API — MUST bind 0.0.0.0 so the Android emulator (10.0.2.2) can connect.
# Default uvicorn host is 127.0.0.1 only, which causes Connection refused from Pixel emulators.
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or:
python -m app.main
```

Open interactive docs: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

Health check: [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)

Confirm the process is listening on IPv4 all interfaces (Windows):

```powershell
netstat -ano | findstr :8000
```

You should see `0.0.0.0:8000` (not only `127.0.0.1:8000`).

## Flutter / emulator tips

- Android emulator (Pixel 7 vb.) → `http://10.0.2.2:8000/api/v1` (`ApiService.hostOrigin`)
- iOS simulator / desktop / web → `http://127.0.0.1:8000/api/v1`
- Physical device → PC'nin LAN IP'si, örn. `http://192.168.x.x:8000/api/v1`

`Connection refused` (errno 111) emulator'de: backend kapalıdır veya `--host 0.0.0.0` olmadan açılmıştır. `port = 54466` istemcinin geçici kaynak portudur; hedef port URI'deki `8000`'dir.

CORS is open (`*`) in `.env.example` for local development.

## API overview

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/auth/register` | No | Create user, return JWT |
| POST | `/api/v1/auth/login` | No | JSON login `{email,password}` |
| POST | `/api/v1/auth/login/form` | No | OAuth2 form (Swagger) |
| GET | `/api/v1/auth/me` | Yes | Current user |
| GET | `/api/v1/categories` | Yes | Categories + completion / `is_free` / `is_locked` / `question_limit` |
| GET | `/api/v1/questions?category_id=` | Yes | 20 qs (free cats / premium); **2 qs** if locked |
| POST | `/api/v1/user/progress` | Yes | Upsert progress + streak |
| GET | `/api/v1/user/stats` | Yes | Aggregate stats / streak |
| GET | `/api/v1/user/radar-stats` | Yes | 6-category radar percentages |
| POST | `/api/v1/user/toggle-premium` | Yes | Dev: flip `is_premium` |
| POST | `/api/v1/ai/analyze` | Yes | CognitiveCoachAgent feedback (TR) |

Authorize in Swagger with: `Bearer <access_token>`.

### Freemium rules

| Slug | Free tier |
|------|-----------|
| `hizli-matematik`, `oruntu-yakalama` | Full 20 questions |
| `funnel`, `ratio`, `charts`, `go-nogo` | First **2** questions only |

Premium users (`is_premium=true`) get all 20 in every category and full AI `detailed_report`.

### AI analyze body

```json
{
  "category_slug": "hizli-matematik",
  "score": 14,
  "total_questions": 20,
  "response_times": [1.2, 0.9, 2.1]
}
```

Response includes `summary`, `detailed_report`, `recommended_category`, `is_premium_locked`.

## PostgreSQL

Set in `.env`:

```env
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/skillcubes
```

Then run seed + uvicorn as above.

## Project layout

```
skillcubes-backend/
  app/
    api/v1/endpoints/   # auth, categories, questions, user, ai
    core/               # config, security, freemium
    db/                 # session, seed
    models/             # SQLAlchemy ORM
    schemas/            # Pydantic DTOs
    services/           # CognitiveCoachAgent (Gemini)
    main.py
  requirements.txt
  .env.example
```
