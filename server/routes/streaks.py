import datetime as dt

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user
from database import get_db
from models import Streak, User, XpBalance, XpTransaction
from schemas import (
    StreakResponse, XpBalanceResponse, XpEarnRequest, XpTransactionResponse,
)
from services.streak import update_streaks
from services.xp import apply_xp

router = APIRouter(tags=["streaks-xp"])

streaks_router = APIRouter(prefix="/api/streaks", tags=["streaks"])
xp_router = APIRouter(prefix="/api/xp", tags=["xp"])


@streaks_router.get("", response_model=list[StreakResponse])
async def get_streaks(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    from services.xp import ensure_streaks_exist
    await ensure_streaks_exist(db, current_user.id)
    await db.commit()
    result = await db.execute(select(Streak).where(Streak.user_id == current_user.id))
    return result.scalars().all()


@streaks_router.post("/check", response_model=list[StreakResponse])
async def check_streaks(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    from services.xp import ensure_streaks_exist
    await ensure_streaks_exist(db, current_user.id)
    await update_streaks(db, current_user, dt.date.today().isoformat())
    await db.commit()
    result = await db.execute(select(Streak).where(Streak.user_id == current_user.id))
    return result.scalars().all()


@xp_router.get("", response_model=XpBalanceResponse)
async def get_xp_balance(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    from services.xp import get_or_create_xp_balance, xp_for_level, level_from_xp
    balance = await get_or_create_xp_balance(db, current_user.id)
    xp_to_next = xp_for_level(balance.level)
    return XpBalanceResponse(
        total_xp=balance.total_xp,
        level=balance.level,
        creatine_currency=balance.creatine_currency,
        xp_to_next_level=xp_to_next,
    )


@xp_router.get("/transactions", response_model=list[XpTransactionResponse])
async def get_transactions(
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(XpTransaction)
        .where(XpTransaction.user_id == current_user.id)
        .order_by(XpTransaction.created_at.desc())
        .limit(min(limit, 500))
    )
    return result.scalars().all()


@xp_router.post("/earn", response_model=XpTransactionResponse)
async def earn_xp(
    body: XpEarnRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Internal awards go through apply_xp so lock-in multiplier applies.
    # Pass multiplier 1 (apply_xp applies its own multiplier) for internal calls.
    amount = await apply_xp(
        db, current_user, body.amount, body.source,
        source_id=body.source_id, description=body.description,
    )
    await db.commit()
    # Return the created transaction
    result = await db.execute(
        select(XpTransaction)
        .where(XpTransaction.user_id == current_user.id)
        .order_by(XpTransaction.created_at.desc())
        .limit(1)
    )
    return result.scalar_one()
