from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from models import (
    Achievement, DailyLog, HabitLog, Streak, StudyLog, User, WorkoutSession, XpBalance,
)


async def check_achievements(db: AsyncSession, user_id: str):
    """Evaluates a few milestone achievements and awards new ones if reached."""
    awarded = []

    # First workout
    wc = (await db.execute(
        select(func.count()).select_from(WorkoutSession).where(
            WorkoutSession.user_id == user_id,
            WorkoutSession.is_template.is_(False),
        )
    )).scalar() or 0
    if wc >= 1 and not await _has_badge(db, user_id, "First Workout"):
        awarded.append(await _grant_badge(db, user_id, "First Workout", "bronze", "body"))

    # 10 workouts
    if wc >= 10 and not await _has_badge(db, user_id, "Workout Machine"):
        awarded.append(await _grant_badge(db, user_id, "Workout Machine", "silver", "body"))

    # Habit completions
    hc = (await db.execute(
        select(func.count()).select_from(HabitLog).where(
            HabitLog.user_id == user_id,
            HabitLog.completed.is_(True),
        )
    )).scalar() or 0
    if hc >= 7 and not await _has_badge(db, user_id, "Consistent"):
        awarded.append(await _grant_badge(db, user_id, "Consistent", "bronze", "life"))

    # Study minutes
    sm = (await db.execute(
        select(func.coalesce(func.sum(StudyLog.duration_minutes), 0)).where(
            StudyLog.user_id == user_id
        )
    )).scalar() or 0
    if sm >= 300 and not await _has_badge(db, user_id, "Scholar"):
        awarded.append(await _grant_badge(db, user_id, "Scholar", "silver", "mind"))

    # Any 7-day streak
    for stype in ["daily_all", "daily_workout", "daily_habits"]:
        sres = await db.execute(
            select(Streak).where(
                Streak.user_id == user_id,
                Streak.streak_type == stype,
                Streak.current_count >= 7,
            )
        )
        if sres.scalar_one_or_none() and not await _has_badge(db, user_id, "On Fire"):
            awarded.append(await _grant_badge(db, user_id, "On Fire", "gold", "life"))
            break

    if awarded:
        await db.flush()
    return awarded


async def _has_badge(db: AsyncSession, user_id: str, badge_name: str) -> bool:
    result = await db.execute(
        select(Achievement).where(
            Achievement.user_id == user_id,
            Achievement.badge_name == badge_name,
        )
    )
    return result.scalar_one_or_none() is not None


async def _grant_badge(db, user_id, badge_name, tier, category) -> Achievement:
    badge = Achievement(
        user_id=user_id,
        badge_name=badge_name,
        badge_tier=tier,
        category=category,
        earned_at=datetime.utcnow(),
    )
    db.add(badge)
    return badge


async def get_leaderboard(db: AsyncSession, limit: int = 50) -> list[dict]:
    """Top users by total XP (aggregate, no private data)."""
    result = await db.execute(
        select(XpBalance, User.username, User.display_name, User.avatar_url)
        .join(User, User.id == XpBalance.user_id)
        .where(User.status == "approved")
        .order_by(XpBalance.total_xp.desc())
        .limit(limit)
    )
    rows = result.all()
    leaderboard = []
    for idx, (balance, username, display_name, avatar_url) in enumerate(rows):
        leaderboard.append({
            "rank": idx + 1,
            "user_id": balance.user_id,
            "username": username,
            "display_name": display_name,
            "total_xp": balance.total_xp,
            "level": balance.level,
            "avatar_url": avatar_url,
        })
    return leaderboard


async def recompute_competition_scores(db: AsyncSession, competition):
    """Recomputes a competition's entries based on the tracked stat and updates ranks."""
    from models import CompetitionEntry

    entries_res = await db.execute(
        select(CompetitionEntry).where(CompetitionEntry.competition_id == competition.id)
    )
    entries = entries_res.scalars().all()

    for entry in entries:
        score = 0.0
        stat = competition.stat_tracked or "xp"

        if stat == "workout_count":
            score = (await db.execute(
                select(func.count()).select_from(WorkoutSession).where(
                    WorkoutSession.user_id == entry.user_id,
                    WorkoutSession.is_template.is_(False),
                )
            )).scalar() or 0
        elif stat == "study_minutes":
            score = (await db.execute(
                select(func.coalesce(func.sum(StudyLog.duration_minutes), 0)).where(
                    StudyLog.user_id == entry.user_id
                )
            )).scalar() or 0
        elif stat == "habit_count":
            score = (await db.execute(
                select(func.count()).select_from(HabitLog).where(
                    HabitLog.user_id == entry.user_id,
                    HabitLog.completed.is_(True),
                )
            )).scalar() or 0
        elif stat == "weight_logged":
            score = (await db.execute(
                select(func.count()).select_from(DailyLog).where(
                    DailyLog.user_id == entry.user_id,
                    DailyLog.weight_kg.is_not(None),
                )
            )).scalar() or 0
        else:  # xp default
            bal = (await db.execute(
                select(XpBalance).where(XpBalance.user_id == entry.user_id)
            )).scalar_one_or_none()
            score = bal.total_xp if bal else 0

        entry.score = float(score)

    sorted_entries = sorted(entries, key=lambda e: e.score, reverse=True)
    for rank, e in enumerate(sorted_entries, start=1):
        e.rank = rank

    await db.flush()
    return sorted_entries
