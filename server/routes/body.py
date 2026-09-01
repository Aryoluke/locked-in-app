import datetime as dt

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user
from database import get_db
from models import BodyLog, User
from schemas import BodyLogCreate, BodyLogResponse, BodyStats

router = APIRouter(prefix="/api/body", tags=["body"])


@router.post("/log", response_model=BodyLogResponse, status_code=201)
async def create_body_log(
    body: BodyLogCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    existing = await db.execute(
        select(BodyLog).where(BodyLog.user_id == current_user.id, BodyLog.date == body.date)
    )
    log = existing.scalar_one_or_none()
    if log:
        for key, value in body.model_dump(exclude_unset=True).items():
            if key == "date":
                continue
            setattr(log, key, value)
    else:
        log = BodyLog(user_id=current_user.id, **body.model_dump())
        db.add(log)
    await db.commit()
    await db.refresh(log)
    return log


@router.get("/history", response_model=list[BodyLogResponse])
async def body_history(
    start_date: str | None = None,
    end_date: str | None = None,
    limit: int = 200,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(BodyLog).where(BodyLog.user_id == current_user.id)
    if start_date:
        query = query.where(BodyLog.date >= start_date)
    if end_date:
        query = query.where(BodyLog.date <= end_date)
    query = query.order_by(BodyLog.date.desc()).limit(min(limit, 1000))
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/stats", response_model=BodyStats)
async def body_stats(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(BodyLog).where(BodyLog.user_id == current_user.id).order_by(BodyLog.date.desc())
    )
    logs = result.scalars().all()
    if not logs:
        return BodyStats(total_logs=0)

    latest = logs[0]
    cutoff_30d = (dt.date.today() - dt.timedelta(days=30)).isoformat()
    older = [l for l in logs if l.date < cutoff_30d]
    comparison = older[0] if older else None  # earliest entry more than 30d old

    weight_change = None
    if comparison and comparison.weight_kg and latest.weight_kg:
        weight_change = round(latest.weight_kg - comparison.weight_kg, 2)
    bf_change = None
    if comparison and comparison.body_fat_pct and latest.body_fat_pct:
        bf_change = round(latest.body_fat_pct - comparison.body_fat_pct, 2)

    return BodyStats(
        latest_weight=latest.weight_kg,
        weight_change_30d=weight_change,
        latest_body_fat=latest.body_fat_pct,
        body_fat_change_30d=bf_change,
        total_logs=len(logs),
    )
