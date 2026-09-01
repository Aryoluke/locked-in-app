import datetime as dt
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from database import async_session, init_db
from models import InviteCode, User, XpBalance
from auth import hash_password

from routes import (
    admin, auth, body, competitions, daily, habits, social, streaks, study,
    sync, user, workouts,
)


async def _seed_initial_data():
    """Creates all tables and seeds the initial admin invite code / first admin."""
    await init_db()

    async with async_session() as db:
        from sqlalchemy import select

        # Seed the initial admin invite code if missing & not expired
        existing = (
            await db.execute(
                select(InviteCode).where(InviteCode.code == settings.ADMIN_INVITE_CODE)
            )
        ).scalar_one_or_none()
        if existing is None:
            db.add(InviteCode(
                id=str(uuid.uuid4()),
                code=settings.ADMIN_INVITE_CODE,
                created_by="system",
                max_uses=10,
                current_uses=0,
                is_active=True,
                created_at=dt.datetime.utcnow(),
            ))
        await db.commit()

        # Seed an initial admin user when the DB is completely empty so the
        # server is usable out of the box. The first signup still auto-becomes
        # admin, but this guarantees a ready login path.
        user_count = (await db.execute(select(User))).scalars().all()
        if not user_count:
            default_email = "admin@lockedin.app"
            admin_user = User(
                id=str(uuid.uuid4()),
                email=default_email,
                username="admin",
                display_name="Admin",
                password_hash=hash_password("ChangeMe123!"),
                invite_code_used=settings.ADMIN_INVITE_CODE,
                is_admin=True,
                status="approved",
                lock_in_level="full",
                created_at=dt.datetime.utcnow(),
                updated_at=dt.datetime.utcnow(),
            )
            db.add(admin_user)
            await db.flush()
            db.add(XpBalance(user_id=admin_user.id, total_xp=0, level=1, creatine_currency=0))
            await db.commit()
            print(f"[LOCKED IN] Seeded admin user: {default_email} / ChangeMe123! (change it!)")


@asynccontextmanager
async def lifespan(app: FastAPI):
    await _seed_initial_data()
    yield


app = FastAPI(
    title="LOCKED IN API",
    description="Fitness/life lock-in backend. XP, streaks, habits, workouts, study and social.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=False,  # '*' origins can't use credentials
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {"service": "LOCKED IN", "status": "running", "docs": "/docs"}


@app.get("/health")
async def health():
    return {"status": "ok", "time": dt.datetime.utcnow().isoformat()}


# Routers
app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(user.router)
app.include_router(workouts.router)
app.include_router(habits.router)
app.include_router(daily.router)
app.include_router(body.router)
app.include_router(streaks.streaks_router)
app.include_router(streaks.xp_router)
app.include_router(social.router)
app.include_router(competitions.router)
app.include_router(study.router)
app.include_router(sync.router)


if __name__ == "__main__":
    import uvicorn
    port = int(__import__("os").getenv("PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=not settings.PRODUCTION)
