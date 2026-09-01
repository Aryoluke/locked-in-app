from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import (
    create_access_token, create_refresh_token, decode_token, get_current_user,
    hash_password, verify_password,
)
from database import get_db
from models import InviteCode, User, XpBalance
from schemas import (
    LoginRequest, RefreshRequest, SignupRequest, TokenResponse, UserResponse,
)

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/signup", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def signup(body: SignupRequest, db: AsyncSession = Depends(get_db)):
    # Validate invite code
    code_result = await db.execute(
        select(InviteCode).where(InviteCode.code == body.invite_code)
    )
    invite = code_result.scalar_one_or_none()
    if invite is None or not invite.is_active:
        raise HTTPException(status_code=400, detail="Invalid or inactive invite code")
    if invite.current_uses >= invite.max_uses:
        raise HTTPException(status_code=400, detail="Invite code has reached its max uses")
    if invite.expires_at and invite.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Invite code has expired")
    if invite.used_by and invite.used_by != User.__tablename__:
        pass  # single-use codes track used_by

    # Check duplicate email / username
    existing = await db.execute(select(User).where(User.email == body.email.lower().strip()))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")
    existing_u = await db.execute(select(User).where(User.username == body.username.strip()))
    if existing_u.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Username already taken")

    # First ever user auto-becomes admin
    user_count = (await db.execute(select(func.count()).select_from(User))).scalar() or 0
    is_admin = user_count == 0
    is_approved = is_admin  # first admin is auto-approved

    user = User(
        email=body.email.lower().strip(),
        username=body.username.strip(),
        display_name=body.display_name or body.username.strip(),
        password_hash=hash_password(body.password),
        invite_code_used=body.invite_code,
        is_admin=is_admin,
        status="approved" if is_approved else "pending",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    db.add(user)

    # Consume the invite code
    invite.current_uses += 1
    if invite.max_uses == 1:
        invite.used_by = user.id
        invite.is_active = False

    await db.flush()

    # Seed XP balance for the new user
    balance = XpBalance(user_id=user.id, total_xp=0, level=1, creatine_currency=0)
    db.add(balance)

    await db.commit()
    await db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(User.email == body.email.lower().strip())
    )
    user = result.scalar_one_or_none()
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    if user.status == "banned":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account banned",
        )
    if user.status != "approved" and not user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account pending approval. Please wait for an admin to approve your account.",
        )

    access = create_access_token(user.id, {"username": user.username})
    refresh = create_refresh_token(user.id)

    await db.commit()
    return TokenResponse(
        access_token=access, refresh_token=refresh, user=user
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    subject = decode_token(body.refresh_token, "refresh")
    result = await db.execute(
        select(User).where(User.id == subject)
    )
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    if user.status != "approved" and not user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account not approved",
        )
    access = create_access_token(user.id, {"username": user.username})
    new_refresh = create_refresh_token(user.id)
    return TokenResponse(access_token=access, refresh_token=new_refresh, user=user)


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
