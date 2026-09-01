from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models import Streak, User
from services.xp import apply_xp, get_today_activity_counts

MIN_ACTIVITIES_PER_DAY = 2  # at least 1 habit + 1 other activity


def _date_to_days(date_str: str) -> int:
    try:
        return datetime.strptime(date_str, "%Y-%m-%d").toordinal()
    except (ValueError, TypeError):
        return datetime.utcnow().toordinal()


def _days_to_date(days: int) -> str:
    return datetime.fromordinal(days).strftime("%Y-%m-%d")


def _today_str() -> str:
    return datetime.utcnow().strftime("%Y-%m-%d")


async def update_streaks(
    db: AsyncSession,
    user: User,
    today_str: str | None = None,
) -> dict[str, Streak]:
    """
    Checks whether the user logged any activity today and updates all streak rows.
    Returns a dict of streak_type -> updated Streak.
    """
    today = today_str or _today_str()
    counts = await get_today_activity_counts(db, user.id, today)

    # daily_all requires at least 1 habit + 1 other activity
    all_met = counts["habits"] >= 1 and counts["total_activities"] >= MIN_ACTIVITIES_PER_DAY

    conditions = {
        "daily_workout": counts["workouts"] >= 1,
        "daily_habits": counts["habits"] >= 1,
        "daily_study": counts["study"] >= 1,
        "daily_all": all_met,
    }

    today_days = _date_to_days(today)

    result = {}
    for stype in ["daily_workout", "daily_habits", "daily_study", "daily_all"]:
        sres = await db.execute(
            select(Streak).where(
                Streak.user_id == user.id,
                Streak.streak_type == stype,
            )
        )
        streak = sres.scalar_one_or_none()
        if streak is None:
            streak = Streak(user_id=user.id, streak_type=stype)
            db.add(streak)
            await db.flush()

        met = conditions[stype]
        last_days = _date_to_days(streak.last_active_date) if streak.last_active_date else None
        yesterday_days = today_days - 1

        if met:
            if last_days is None:
                # brand new streak
                streak.is_active = True
                streak.current_count = 1
                streak.last_active_date = today
            elif yesterday_days == today_days - 1 and last_days == yesterday_days:
                # consecutive day
                streak.current_count += 1
                streak.last_active_date = today
                streak.is_active = True
            elif last_days == today_days:
                # already logged today, no change
                pass
            else:
                # gap: streak broken, but allow freeze
                if streak.freeze_count > 0:
                    streak.freeze_count -= 1
                    streak.current_count += 1
                    streak.last_active_date = today
                    streak.is_active = True
                else:
                    streak.current_count = 1
                    streak.last_active_date = today
                    streak.is_active = True

            if streak.current_count > streak.longest_count:
                streak.longest_count = streak.current_count

            # Award streak bonus XP (streak_count * 2)
            if streak.current_count >= 2 and met:
                bonus = streak.current_count * 2
                await apply_xp(
                    db, user, bonus, "streak",
                    source_id=streak.id,
                    description=f"Day {streak.current_count} {stype} streak bonus",
                )
            else:
                # Apply streak bonus on day 1 too for consistency of "streak_count * 2"
                await apply_xp(
                    db, user, streak.current_count * 2, "streak",
                    source_id=streak.id,
                    description=f"Day {streak.current_count} {stype} streak",
                )
        else:
            # Not met today: check if streak decays
            if last_days is not None and last_days < today_days - 1:
                # missed at least a full day -> break (unless freeze)
                if streak.freeze_count > 0:
                    streak.freeze_count -= 1
                    streak.last_active_date = today
                else:
                    streak.is_active = False
                    streak.current_count = 0

        result[stype] = streak

    await db.flush()
    return result
