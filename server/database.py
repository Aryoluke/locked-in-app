from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from config import settings

# Render's managed Postgres connection strings come back as postgres://... which
# SQLAlchemy treats as the sync dialect. Normalize to the async driver.
_db_url = settings.DATABASE_URL
if _db_url.startswith("postgres://"):
    _db_url = _db_url.replace("postgres://", "postgresql+asyncpg://", 1)

engine = create_async_engine(_db_url, echo=False)
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
    async with engine.begin() as conn:
        from models import (  # noqa: F401
            Achievement, BodyLog, Competition, CompetitionEntry, CompetitionWar,
            DailyLog, Friendship, Habit, HabitLog, InviteCode, PomodoroSession,
            Reaction, SleepLog, Streak, StudyLog, SupplementLog, User,
            WorkoutSession, WorkoutSet, XpBalance, XpTransaction,
        )
        await conn.run_sync(Base.metadata.create_all)
