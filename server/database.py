import asyncio
import logging

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from config import settings

log = logging.getLogger("lockedin.db")

# Render's managed Postgres connection strings come back as postgres://... which
# SQLAlchemy treats as the sync dialect. Normalize to the async driver.
_db_url = settings.DATABASE_URL
if _db_url.startswith("postgres://"):
    _db_url = _db_url.replace("postgres://", "postgresql+asyncpg://", 1)

engine = create_async_engine(
    _db_url,
    echo=False,
    # asyncpg does not accept libpq-style sslmode in the URL. For Render's
    # Postgres (which requires TLS), pass ssl via connect_args instead.
    connect_args={"ssl": "require"} if _db_url.startswith("postgresql+asyncpg://") else {},
)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    """Create all tables with retry logic for cloud databases that may not be
    ready when the app first connects (e.g. Render free Postgres cold start)."""
    max_retries = 5
    for attempt in range(1, max_retries + 1):
        try:
            async with engine.begin() as conn:
                from models import (  # noqa: F401
                    Achievement, BodyLog, Competition, CompetitionEntry, CompetitionWar,
                    DailyLog, Friendship, Habit, HabitLog, InviteCode, PomodoroSession,
                    Reaction, SleepLog, Streak, StudyLog, SupplementLog, User,
                    WorkoutSession, WorkoutSet, XpBalance, XpTransaction,
                )
                await conn.run_sync(Base.metadata.create_all)
            log.info("[DB] Tables created successfully (attempt %d)", attempt)
            return
        except Exception as e:
            log.warning("[DB] Attempt %d/%d failed: %s", attempt, max_retries, e)
            if attempt < max_retries:
                await asyncio.sleep(3 * attempt)
            else:
                log.error("[DB] All %d attempts failed — last error: %s", max_retries, e)
                raise
