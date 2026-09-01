import datetime as dt

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user
from database import get_db
from models import PomodoroSession, StudyLog, User
from schemas import (
    PomodoroCreate, PomodoroResponse, StudyLogCreate, StudyLogResponse, StudyStats,
)
from services.gamification import check_achievements
from services.streak import update_streaks
from services.xp import apply_xp, calculate_study_xp

router = APIRouter(prefix="/api/study", tags=["study"])


@router.post("/log", response_model=StudyLogResponse, status_code=201)
async def log_study(
    body: StudyLogCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    date = body.date or dt.date.today().isoformat()
    log = StudyLog(
        user_id=current_user.id,
        subject=body.subject,
        topic=body.topic,
        duration_minutes=body.duration_minutes,
        notes=body.notes,
        date=date,
    )
    db.add(log)
    await db.flush()

    if body.duration_minutes:
        xp = calculate_study_xp(body.duration_minutes)
        await apply_xp(
            db, current_user, xp, "study", source_id=log.id,
            description=f"Study: {body.subject or 'session'}",
        )
        await update_streaks(db, current_user, date)
        await check_achievements(db, current_user.id)

    await db.commit()
    await db.refresh(log)
    return log


@router.get("/history", response_model=list[StudyLogResponse])
async def study_history(
    start_date: str | None = None,
    end_date: str | None = None,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(StudyLog).where(StudyLog.user_id == current_user.id)
    if start_date:
        query = query.where(StudyLog.date >= start_date)
    if end_date:
        query = query.where(StudyLog.date <= end_date)
    query = query.order_by(StudyLog.created_at.desc()).limit(min(limit, 500))
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/stats", response_model=StudyStats)
async def study_stats(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(StudyLog).where(StudyLog.user_id == current_user.id))
    logs = result.scalars().all()

    total_minutes = sum(l.duration_minutes or 0 for l in logs)
    today = dt.date.today()
    week_start = (today - dt.timedelta(days=today.weekday())).isoformat()
    month_start = today.replace(day=1).isoformat()
    sessions_week = sum(1 for l in logs if (l.date or "") >= week_start)
    sessions_month = sum(1 for l in logs if (l.date or "") >= month_start)

    subjects: dict[str, int] = {}
    for l in logs:
        key = l.subject or "General"
        subjects[key] = subjects.get(key, 0) + (l.duration_minutes or 0)

    return StudyStats(
        total_sessions=len(logs),
        total_minutes=total_minutes,
        total_hours=round(total_minutes / 60, 2),
        sessions_this_week=sessions_week,
        sessions_this_month=sessions_month,
        subjects=subjects,
    )


@router.post("/pomodoro", response_model=PomodoroResponse, status_code=201)
async def start_pomodoro(
    body: PomodoroCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    pomodoro = PomodoroSession(
        user_id=current_user.id,
        subject=body.subject,
        duration_minutes=body.duration_minutes,
        completed=False,
    )
    db.add(pomodoro)
    await db.commit()
    await db.refresh(pomodoro)
    return pomodoro


@router.post("/pomodoro/complete/{pomodoro_id}", response_model=PomodoroResponse)
async def complete_pomodoro(
    pomodoro_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(PomodoroSession).where(
            PomodoroSession.id == pomodoro_id,
            PomodoroSession.user_id == current_user.id,
        )
    )
    pomodoro = result.scalar_one_or_none()
    from fastapi import HTTPException
    if pomodoro is None:
        raise HTTPException(status_code=404, detail="Pomodoro not found")
    if pomodoro.completed:
        return pomodoro

    pomodoro.completed = True
    # Award study XP based on pomodoro duration
    xp = calculate_study_xp(pomodoro.duration_minutes or 25)
    await apply_xp(
        db, current_user, xp, "study", source_id=pomodoro.id,
        description=f"Pomodoro: {pomodoro.subject or 'Focus session'}",
    )
    today = dt.date.today().isoformat()
    await update_streaks(db, current_user, today)
    await check_achievements(db, current_user.id)

    await db.commit()
    await db.refresh(pomodoro)
    return pomodoro
