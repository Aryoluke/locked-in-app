from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_admin
from database import get_db
from models import (
    HabitLog, InviteCode, StudyLog, User, WorkoutSession, XpBalance,
)
from schemas import (
    AdminInviteCodeCreate, AdminSquadStats, InviteCodeResponse, UserResponse,
)

router = APIRouter(prefix="/api/admin", tags=["admin"])


@router.get("/pending-users", response_model=list[UserResponse])
async def list_pending_users(
    db: AsyncSession = Depends(get_db), admin: User = Depends(get_current_admin)
):
    result = await db.execute(
        select(User).where(User.status == "pending").order_by(User.created_at.desc())
    )
    return result.scalars().all()


@router.post("/approve/{user_id}", response_model=UserResponse)
async def approve_user(
    user_id: str, db: AsyncSession = Depends(get_db), admin: User = Depends(get_current_admin)
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user.status = "approved"
    user.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/ban/{user_id}", response_model=UserResponse)
async def ban_user(
    user_id: str, db: AsyncSession = Depends(get_db), admin: User = Depends(get_current_admin)
):
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Cannot ban yourself")
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user.status = "banned"
    user.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(user)
    return user


@router.get("/squad-stats", response_model=AdminSquadStats)
async def squad_stats(
    db: AsyncSession = Depends(get_db), admin: User = Depends(get_current_admin)
):
    total_users = (await db.execute(select(func.count()).select_from(User))).scalar() or 0
    approved_users = (await db.execute(
        select(func.count()).select_from(User).where(User.status == "approved")
    )).scalar() or 0
    pending_users = (await db.execute(
        select(func.count()).select_from(User).where(User.status == "pending")
    )).scalar() or 0
    total_workouts = (await db.execute(
        select(func.count()).select_from(WorkoutSession).where(WorkoutSession.is_template.is_(False))
    )).scalar() or 0
    total_habits = (await db.execute(
        select(func.count()).select_from(HabitLog).where(HabitLog.completed.is_(True))
    )).scalar() or 0
    total_study = (await db.execute(
        select(func.coalesce(func.sum(StudyLog.duration_minutes), 0))
    )).scalar() or 0

    xp_result = await db.execute(select(func.avg(XpBalance.total_xp), func.avg(XpBalance.level)))
    avg_xp, avg_level = xp_result.one()
    avg_xp = round(avg_xp or 0, 2)
    avg_level = round(avg_level or 0, 2)

    return AdminSquadStats(
        total_users=total_users,
        approved_users=approved_users,
        pending_users=pending_users,
        total_workouts=total_workouts,
        total_habits_completed=total_habits,
        total_study_minutes=total_study,
        avg_xp=avg_xp,
        avg_level=avg_level,
    )


@router.post("/invite-codes", response_model=InviteCodeResponse)
async def create_invite_code(
    body: AdminInviteCodeCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    import uuid
    code = body.code or (await _generate_code(db))
    # Prevent duplicate active codes
    existing = await db.execute(select(InviteCode).where(InviteCode.code == code))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Invite code already exists")

    expires_at = None
    if body.expires_at:
        try:
            expires_at = datetime.fromisoformat(body.expires_at)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid expires_at format")

    invite = InviteCode(
        id=str(uuid.uuid4()),
        code=code,
        created_by=admin.id,
        max_uses=body.max_uses or 1,
        current_uses=0,
        is_active=True,
        expires_at=expires_at,
    )
    db.add(invite)
    await db.commit()
    await db.refresh(invite)
    return invite


@router.get("/invite-codes", response_model=list[InviteCodeResponse])
async def list_invite_codes(
    db: AsyncSession = Depends(get_db), admin: User = Depends(get_current_admin)
):
    result = await db.execute(select(InviteCode).order_by(InviteCode.created_at.desc()))
    return result.scalars().all()


async def _generate_code(db: AsyncSession) -> str:
    import random
    import string
    for _ in range(20):
        code = "LOCKEDIN" + "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
        existing = await db.execute(select(InviteCode).where(InviteCode.code == code))
        if existing.scalar_one_or_none() is None:
            return code
    return "LOCKEDIN" + str(int(datetime.utcnow().timestamp()))
