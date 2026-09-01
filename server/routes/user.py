from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user
from database import get_db
from models import (
    HabitLog, Streak, StudyLog, User, WorkoutSession, XpBalance,
)
from schemas import ProfileUpdate, UserResponse, UserStatsResponse

router = APIRouter(prefix="/api/user", tags=["user"])


@router.get("/profile", response_model=UserResponse)
async def get_profile(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    return current_user


@router.put("/profile", response_model=UserResponse)
async def update_profile(
    body: ProfileUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    updates = body.model_dump(exclude_unset=True)
    if "lock_in_level" in updates and updates["lock_in_level"] not in ("mini", "standard", "full"):
        raise HTTPException(status_code=400, detail="lock_in_level must be mini/standard/full")
    if "body_type" in updates and updates["body_type"] not in (None, "sleeper", "bulk", "hybrid"):
        raise HTTPException(status_code=400, detail="body_type must be sleeper/bulk/hybrid")

    for key, value in updates.items():
        setattr(current_user, key, value)
    current_user.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.get("/stats", response_model=UserStatsResponse)
async def get_stats(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    balance_result = await db.execute(select(XpBalance).where(XpBalance.user_id == current_user.id))
    balance = balance_result.scalar_one_or_none()

    # streaks
    streak_result = await db.execute(select(Streak).where(Streak.user_id == current_user.id))
    streaks = {}
    for s in streak_result.scalars().all():
        streaks[s.streak_type] = s.current_count

    total_workouts = (await db.execute(
        select(func.count()).select_from(WorkoutSession).where(
            WorkoutSession.user_id == current_user.id,
            WorkoutSession.is_template.is_(False),
        )
    )).scalar() or 0
    total_habits = (await db.execute(
        select(func.count()).select_from(HabitLog).where(
            HabitLog.user_id == current_user.id,
            HabitLog.completed.is_(True),
        )
    )).scalar() or 0
    total_study = (await db.execute(
        select(func.coalesce(func.sum(StudyLog.duration_minutes), 0)).where(
            StudyLog.user_id == current_user.id
        )
    )).scalar() or 0

    return UserStatsResponse(
        total_xp=balance.total_xp if balance else 0,
        level=balance.level if balance else 1,
        creatine_currency=balance.creatine_currency if balance else 0,
        streaks=streaks,
        total_workouts=total_workouts,
        total_habits_completed=total_habits,
        total_study_minutes=total_study,
    )
