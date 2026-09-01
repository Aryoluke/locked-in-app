# LOCKED IN 🔒

A private, invite-only fitness + life lock-in app for you and your squad (2–10 users). **Male-only, fully free forever, self-hosted on your own server.** One account, one streak, one XP balance, one progress history — synced across every device.

> **Private by design.** No ads, no trackers, no analytics, no third party ever sees your data. Your own server is the single source of truth; every device is a full offline-first client.

---

## One codebase → three platforms

Built with **Flutter** — the same Dart code compiles to all three:

| Platform | Output | How |
|----------|--------|-----|
| Android | `.apk` | `flutter build apk` |
| Windows | `.exe` | `flutter build windows` |
| iPhone / any browser | HTML web app | `flutter build web` |

Everyone shares the **same account, profile, streak, XP and history** across all devices. Log a workout on your phone, it's on your laptop instantly. Full bidirectional sync (last-write-wins per field), works offline everywhere, syncs when back online.

---

## Project structure

```
locked-in/
├── server/          # FastAPI + SQLite backend (self-hosted)
│   ├── main.py          # App entry, CORS, seeding
│   ├── models.py        # SQLAlchemy models (21 tables)
│   ├── schemas.py       # Pydantic request/response schemas
│   ├── auth.py          # JWT + bcrypt
│   ├── routes/          # auth, admin, user, workouts, habits, daily,
│   │                    # body, streaks, social, competitions, study, sync
│   └── services/        # XP, streak, gamification, sync (LWW conflict)
├── app/             # Flutter app (Android / Windows / iOS web)
│   └── lib/
│       ├── main.dart       # SQLite init + provider wiring
│       ├── app.dart        # Theme + 5-tab shell (Home/Train/Mind/Life/Squad)
│       ├── config/         # theme, constants, routes
│       ├── models/         # 12 data models
│       ├── services/       # api, auth, sync (offline-first), local db, notifications, xp
│       ├── providers/      # 10 ChangeNotifier providers
│       ├── screens/        # 26 screens
│       └── widgets/        # 10 core widgets
└── scripts/         # deployment + build automation
```

---

## Quick start (development)

### 1. Start the server

```powershell
cd server
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
.\.venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

- Interactive API docs: http://localhost:8000/docs
- On first boot it seeds the admin invite code: **`LOCKEDIN2026`**
- It also seeds a default admin: `admin@lockedin.app` / `ChangeMe123!` — **change these immediately.**

### 2. Run the Flutter app

```powershell
cd app
flutter create .          # generates platform/android, ios, web, windows scaffolding
flutter pub get
flutter run               # pick your device (Android / Windows / Chrome)
```

Point the app at your server under **Settings → Server URL** (default `http://localhost:8000`).

---

## The admin flow (invite-only, everyone must be approved)

1. Admin creates invite codes (or uses the seeded `LOCKEDIN2026`).
2. A friend signs up with **email + password + invite code** → their account is created as `pending`.
3. Admin approves them under the Admin panel → only then can they log in.
4. Admin can also ban users, send squad announcements, and see only **aggregate** stats — never private data.

---

## Deployment (self-hosted)

Your server can run on a spare PC or a Raspberry Pi-class device.

### Option A — Private tailnet (recommended, zero public exposure)

Use **Tailscale** (or WireGuard) so only your devices can reach the server:
1. Install Tailscale on the server and on every squad member's phone/laptop.
2. Run the server bound to `0.0.0.0:8000`.
3. In the app set Server URL to `http://<tailscale-ip>:8000` (or use the MagicDNS name).

The AI coach + sync work from **any network** — home, school, gym, mobile data — because Tailscale creates a private mesh. No port forwarding, no public IP.

### Option B — Public HTTPS (Caddy reverse proxy)

```caddyfile
lockedin.example.com {
    reverse_proxy 127.0.0.1:8000
}
```
- Caddy auto-provisions a valid HTTPS cert.
- Protect with basic auth if you want an extra layer before the app's own login.

### Backup

`scripts/backup.ps1` copies the SQLite DB to a dated file. Run it daily with Task Scheduler / cron:
```powershell
.\scripts\backup.ps1
```

---

## Building installers

See `scripts/build-android.ps1`, `scripts/build-windows.ps1`, `scripts/build-web.ps1`.
Or build from the `app/` folder manually:

```powershell
cd app
flutter build apk --release          # Android
flutter build windows --release      # Windows EXE
flutter build web --release          # iPhone web app (host the build/web folder)
```

---

## Server security notes (read before going live)

1. **Change the seeded admin credentials** and the default `SECRET_KEY` in your `.env` (copy `.env.example` → `.env`).
2. Body photos and private logs are **device-encrypted and never uploaded** — mark them private in the app and they stay on-device only.
3. Rate limiting is on auth endpoints; enable HTTPS before exposing publicly.
4. All passwords are bcrypt-hashed; sessions use JWT (7-day access / 30-day refresh).

---

## The pillars built into this MVP

This is **Phase 1 & 2** of the build plan. The full spec spans 7 phases; this repo implements the foundation that everything else plugs into.

- **Body (Train):** workout logging (gym / calisthenics / cardio / sports), exercise **variations** (each with its own PRs), supersets, auto rest timer, templates, exercise library, PRs, 1RM, XP on every set.
- **Mind:** study logging, Pomodoro (25/5), mood/energy/motivation 3-tap check-ins, subjects + streaks.
- **Life:** daily habits hub (skin, nutrition, water, supplements, cold shower…), each feeding the same streak/XP system.
- **Gamification:** daily & multi-activity streaks with streak freezes, XP + levels (Iron→Steel→Titan), **Creatine** in-game currency, habit combos, daily quests.
- **Squad:** leaderboard, friend streaks, activity feed, reactions, competitions.
- **Onboarding:** body type (Sleeper/Bulk/Hybrid), goal physique, height/weight/age/DOB, activity level, dietary preference, allergies, equipment, lifestyle, skin profile, lock-in level (Mini/Standard/Full).

---

## Roadmap (remaining phases)

- **Phase 3:** full gamification depth — duels, raids, arcs, badge tiers, shop, trophy room.
- **Phase 4:** nutrition (meal plans, barcode scanner, meal-photo AI), recovery (HRV, muscle map), life habits full depth.
- **Phase 5:** body scan (MediaPipe on-device), growth science, photo timeline, muscle/fatigue map.
- **Phase 6:** AI coach (local Ollama → Gemini → Groq → OpenRouter → Cloudflare RAG), form check (MediaPipe), learn-why notes, Duolingo-style lessons.
- **Phase 7:** music/Strava/NFC, TikTok-style squad feed, voice logging, sport-specific comps, manly hacks vault, arcs, power features, polish.

Each phase is non-destructive — it layers on top of this foundation.
