import datetime as dt

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user
from database import get_db
from models import Competition, CompetitionEntry, CompetitionWar, User
from schemas import CompetitionEntryResponse, CompetitionResponse
from services.gamification import recompute_competition_scores

router = APIRouter(prefix="/api/competitions", tags=["competitions"])


def _parse_date(d: str) -> dt.date | None:
    try:
        return dt.date.fromisoformat(d)
    except (ValueError, TypeError):
        return None


@router.get("/active", response_model=list[CompetitionResponse])
async def active_competitions(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Competition).where(Competition.is_active.is_(True)).order_by(Competition.created_at.desc())
    )
    comps = result.scalars().all()
    responses = []
    today = dt.date.today()
    for c in comps:
        start, end = _parse_date(c.start_date), _parse_date(c.end_date)
        # Only include those within active window (or no end date)
        if end and end < today:
            continue
        count = (await db.execute(
            select(CompetitionEntry).where(CompetitionEntry.competition_id == c.id)
        )).scalars().all()
        responses.append(CompetitionResponse(
            id=c.id,
            title=c.title,
            description=c.description,
            competition_type=c.competition_type,
            stat_tracked=c.stat_tracked,
            start_date=c.start_date,
            end_date=c.end_date,
            is_active=c.is_active,
            created_at=c.created_at,
            participant_count=len(count),
        ))
    return responses


@router.post("/join/{competition_id}", response_model=CompetitionEntryResponse)
async def join_competition(
    competition_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comp = (await db.execute(select(Competition).where(Competition.id == competition_id))).scalar_one_or_none()
    if comp is None:
        raise HTTPException(status_code=404, detail="Competition not found")
    if not comp.is_active:
        raise HTTPException(status_code=400, detail="Competition not active")

    existing = (await db.execute(
        select(CompetitionEntry).where(
            CompetitionEntry.competition_id == competition_id,
            CompetitionEntry.user_id == current_user.id,
        )
    )).scalar_one_or_none()
    if existing:
        return existing

    entry = CompetitionEntry(
        competition_id=competition_id,
        user_id=current_user.id,
        score=0,
        joined_at=dt.datetime.utcnow(),
    )
    db.add(entry)
    await db.commit()
    await db.refresh(entry)
    return entry


@router.get("/{competition_id}/leaderboard", response_model=list[CompetitionEntryResponse])
async def competition_leaderboard(
    competition_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comp = (await db.execute(select(Competition).where(Competition.id == competition_id))).scalar_one_or_none()
    if comp is None:
        raise HTTPException(status_code=404, detail="Competition not found")

    entries = await recompute_competition_scores(db, comp)
    await db.commit()

    responses = []
    for e in entries:
        user = (await db.execute(select(User).where(User.id == e.user_id))).scalar_one_or_none()
        responses.append(CompetitionEntryResponse(
            id=e.id,
            competition_id=e.competition_id,
            user_id=e.user_id,
            score=e.score,
            rank=e.rank,
            joined_at=e.joined_at,
            username=user.username if user else None,
        ))
    return responses
