import datetime as dt

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user
from database import get_db
from models import Habit, HabitLog, User
from schemas import (
    HabitCreate, HabitLogCreate, HabitLogResponse, HabitResponse, HabitStats,
    HabitUpdate, TodayHabit,
)
from services.gamification import check_achievements
from services.streak import update_streaks
from services.xp import apply_xp

router = APIRouter(prefix="/api/habits", tags=["habits"])


@router.post("", response_model=HabitResponse, status_code=201)
async def create_habit(
    body: HabitCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    habit = Habit(user_id=current_user.id, **body.model_dump())
    db.add(habit)
    await db.commit()
    await db.refresh(habit)
    return habit


@router.get("", response_model=list[HabitResponse])
async def list_habits(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Habit).where(Habit.user_id == current_user.id).order_by(Habit.order_index)
    )
    return result.scalars().all()


@router.put("/{habit_id}", response_model=HabitResponse)
async def update_habit(
    habit_id: str,
    body: HabitUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    habit = await _get_owned_habit(db, current_user.id, habit_id)
    for key, value in body.model_dump(exclude_unset=True).items():
        setattr(habit, key, value)
    await db.commit()
    await db.refresh(habit)
    return habit


@router.delete("/{habit_id}", status_code=204)
async def delete_habit(
    habit_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    habit = await _get_owned_habit(db, current_user.id, habit_id)
    await db.delete(habit)
    await db.commit()
    return None


@router.post("/{habit_id}/log", response_model=HabitLogResponse, status_code=201)
async def log_habit(
    habit_id: str,
    body: HabitLogCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    habit = await _get_owned_habit(db, current_user.id, habit_id)
    today = dt.date.today().isoformat()

    # Deduplicate: if already logged today, increment/update instead of a second row
    existing = await db.execute(
        select(HabitLog).where(
            HabitLog.habit_id == habit.id,
            HabitLog.user_id == current_user.id,
            HabitLog.date == today,
        )
    )
    log = existing.scalar_one_or_none()
    if log:
        log.completed = body.completed
        if body.value is not None:
            log.value = body.value
        if body.notes is not None:
            log.notes = body.notes
    else:
        log = HabitLog(
            habit_id=habit.id,
            user_id=current_user.id,
            date=today,
            completed=body.completed,
            value=body.value,
            notes=body.notes,
        )
        db.add(log)

    await db.flush()

    # Award XP on first completion today
    if body.completed:
        # Check if already awarded XP for this habit today (to avoid double-award)
        awarded = (await db.execute(
            select(HabitLog).where(
                HabitLog.habit_id == habit.id,
                HabitLog.user_id == current_user.id,
                HabitLog.date == today,
                HabitLog.id != log.id,
            )
        )).scalar_one_or_none()
        if awarded is None:
            await apply_xp(
                db, current_user, 5, "habit", source_id=log.id,
                description=f"Habit: {habit.name}",
            )
            await update_streaks(db, current_user, today)
            await check_achievements(db, current_user.id)

    await db.commit()
    await db.refresh(log)
    return log


@router.get("/today", response_model=list[TodayHabit])
async def habits_today(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    today = dt.date.today().isoformat()
    habits_res = await db.execute(
        select(Habit).where(Habit.user_id == current_user.id).order_by(Habit.order_index)
    )
    habits = habits_res.scalars().all()

    logs_res = await db.execute(
        select(HabitLog).where(HabitLog.user_id == current_user.id, HabitLog.date == today)
    )
    logs = {l.habit_id: l for l in logs_res.scalars().all()}

    result = []
    for h in habits:
        log = logs.get(h.id)
        result.append(TodayHabit(
            habit=h,
            logged_today=log is not None and log.completed,
            log=log,
        ))
    return result


@router.get("/stats", response_model=HabitStats)
async def habit_stats(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    total_habits = (await db.execute(
        select(func.count()).select_from(Habit).where(Habit.user_id == current_user.id)
    )).scalar() or 0
    active_habits = (await db.execute(
        select(func.count()).select_from(Habit).where(
            Habit.user_id == current_user.id, Habit.is_active.is_(True)
        )
    )).scalar() or 0
    total_completions = (await db.execute(
        select(func.count()).select_from(HabitLog).where(
            HabitLog.user_id == current_user.id, HabitLog.completed.is_(True)
        )
    )).scalar() or 0

    # today's completion rate
    today = dt.date.today().isoformat()
    today_logs = (await db.execute(
        select(func.count()).select_from(HabitLog).where(
            HabitLog.user_id == current_user.id,
            HabitLog.date == today,
            HabitLog.completed.is_(True),
        )
    )).scalar() or 0
    today_rate = round((today_logs / active_habits) * 100, 2) if active_habits else 0.0

    best_streak = 0
    # Crude best streak from distinct completion dates per habit
    habits_res = await db.execute(
        select(Habit.id).where(Habit.user_id == current_user.id)
    )
    for (hid,) in habits_res.all():
        dates_res = await db.execute(
            select(HabitLog.date).where(
                HabitLog.habit_id == hid,
                HabitLog.completed.is_(True),
            ).distinct()
        )
        dates = sorted(d.date for d in dates_res.all())
        run = 1
        for i in range(1, len(dates)):
            if (dt.date.fromisoformat(dates[i]) - dt.date.fromisoformat(dates[i - 1])).days == 1:
                run += 1
                best_streak = max(best_streak, run)
            else:
                run = 1
        if dates:
            best_streak = max(best_streak, 1)

    return HabitStats(
        total_habits=total_habits,
        active_habits=active_habits,
        total_completions=total_completions,
        today_completion_rate=today_rate,
        best_streak=best_streak,
    )


async def _get_owned_habit(db: AsyncSession, user_id: str, habit_id: str) -> Habit:
    result = await db.execute(
        select(Habit).where(Habit.id == habit_id, Habit.user_id == user_id)
    )
    habit = result.scalar_one_or_none()
    if habit is None:
        raise HTTPException(status_code=404, detail="Habit not found")
    return habit
