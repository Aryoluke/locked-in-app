import datetime as dt

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user
from database import get_db
from models import DailyLog, User
from schemas import DailyLogCreate, DailyLogResponse

router = APIRouter(prefix="/api/daily", tags=["daily"])


@router.post("", response_model=DailyLogResponse, status_code=201)
async def create_daily_log(
    body: DailyLogCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Upsert by (user, date)
    existing = await db.execute(
        select(DailyLog).where(
            DailyLog.user_id == current_user.id, DailyLog.date == body.date
        )
    )
    log = existing.scalar_one_or_none()

    if log:
        for key, value in body.model_dump(exclude_unset=True).items():
            if key == "date":
                continue
            setattr(log, key, value)
        log.updated_at = dt.datetime.utcnow()
    else:
        log = DailyLog(user_id=current_user.id, **body.model_dump())
        db.add(log)

    await db.commit()
    await db.refresh(log)
    return log


@router.get("/today", response_model=DailyLogResponse | None)
async def daily_today(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    today = dt.date.today().isoformat()
    result = await db.execute(
        select(DailyLog).where(DailyLog.user_id == current_user.id, DailyLog.date == today)
    )
    return result.scalar_one_or_none()


@router.get("/history", response_model=list[DailyLogResponse])
async def daily_history(
    start_date: str | None = None,
    end_date: str | None = None,
    limit: int = 90,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(DailyLog).where(DailyLog.user_id == current_user.id)
    if start_date:
        query = query.where(DailyLog.date >= start_date)
    if end_date:
        query = query.where(DailyLog.date <= end_date)
    query = query.order_by(DailyLog.date.desc()).limit(min(limit, 365))
    result = await db.execute(query)
    return result.scalars().all()
