import math
import uuid
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models import Streak, User, WorkoutSession, StudyLog, HabitLog, XpBalance, XpTransaction

LOCK_IN_MULTIPLIERS = {"mini": 1.0, "standard": 2.0, "full": 3.0}


def xp_for_level(level: int) -> float:
    """XP required to go from `level` to `level + 1`."""
    return level * level * 100


def level_from_xp(total_xp: float) -> int:
    level = 1
    cumulative = 0.0
    while level < 100:
        needed = xp_for_level(level)
        if cumulative + total_xp < needed:
            break
        cumulative = 0.0
        total_xp -= needed
        level += 1
    return min(level, 100)


def calculate_workout_xp(duration_minutes: int = 0, total_volume_kg: float = 0) -> float:
    xp = 10.0
    if duration_minutes:
        xp += min(duration_minutes * 0.5, 25.0)
    if total_volume_kg:
        xp += min(total_volume_kg / 1000.0, 15.0)
    return round(min(xp, 50.0), 2)


def calculate_study_xp(duration_minutes: int) -> float:
    return round((duration_minutes / 30.0) * 10.0, 2)


async def get_or_create_xp_balance(db: AsyncSession, user_id: str) -> XpBalance:
    result = await db.execute(select(XpBalance).where(XpBalance.user_id == user_id))
    balance = result.scalar_one_or_none()
    if balance is None:
        balance = XpBalance(user_id=user_id, total_xp=0, level=1, creatine_currency=0)
        db.add(balance)
        await db.flush()
    return balance


def create_transaction(
    db: AsyncSession,
    user_id: str,
    amount: float,
    source: str,
    source_id: str | None = None,
    description: str | None = None,
    multiplier: float = 1.0,
) -> XpTransaction:
    tx = XpTransaction(
        id=str(uuid.uuid4()),
        user_id=user_id,
        amount=amount,
        source=source,
        source_id=source_id,
        description=description,
        multiplier=multiplier,
    )
    db.add(tx)
    return tx


async def _user_lock_in_multiplier(db: AsyncSession, user: User) -> float:
    return LOCK_IN_MULTIPLIERS.get(user.lock_in_level or "standard", 2.0)


async def apply_xp(
    db: AsyncSession,
    user: User,
    base_amount: float,
    source: str,
    source_id: str | None = None,
    description: str | None = None,
) -> float:
    """
    Applies XP accounting for the user's lock-in multiplier, updates the balance,
    and credits creatine currency. Returns the final awarded XP.
    """
    multiplier = await _user_lock_in_multiplier(db, user)
    final_amount = round(base_amount * multiplier, 2)

    balance = await get_or_create_xp_balance(db, user.id)
    balance.total_xp += final_amount
    balance.creatine_currency += round(5 + (base_amount % 15), 2)  # 5-20 creatine
    balance.level = level_from_xp(balance.total_xp)
    balance.updated_at = datetime.utcnow()

    create_transaction(
        db, user.id, final_amount, source, source_id, description, multiplier
    )
    return final_amount


async def get_today_activity_counts(
    db: AsyncSession, user_id: str, date_str: str
) -> dict[str, int]:
    """Counts of workouts, habit logs, and study logs for a given day."""
    workout_count = 0
    result = await db.execute(
        select(WorkoutSession).where(
            WorkoutSession.user_id == user_id,
            WorkoutSession.date == date_str,
            WorkoutSession.is_template.is_(False),
        )
    )
    workout_count = len(result.scalars().all())

    habit_count = 0
    hres = await db.execute(
        select(HabitLog).where(
            HabitLog.user_id == user_id,
            HabitLog.date == date_str,
            HabitLog.completed.is_(True),
        )
    )
    habit_count = len(hres.scalars().all())

    study_count = 0
    sres = await db.execute(
        select(StudyLog).where(
            StudyLog.user_id == user_id,
            StudyLog.date == date_str,
        )
    )
    study_count = len(sres.scalars().all())

    return {
        "workouts": workout_count,
        "habits": habit_count,
        "study": study_count,
        "total_activities": workout_count + habit_count + study_count,
    }


async def ensure_streaks_exist(db: AsyncSession, user_id: str):
    """Creates the three streak rows for a user if missing."""
    for stype in ["daily_workout", "daily_habits", "daily_study", "daily_all"]:
        result = await db.execute(
            select(Streak).where(
                Streak.user_id == user_id,
                Streak.streak_type == stype,
            )
        )
        if result.scalar_one_or_none() is None:
            db.add(Streak(user_id=user_id, streak_type=stype))
    await db.flush()
