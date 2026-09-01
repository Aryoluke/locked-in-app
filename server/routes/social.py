import datetime as dt

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user
from database import get_db
from models import (
    BodyLog, DailyLog, HabitLog, Reaction, StudyLog, User, WorkoutSession,
    WorkoutSet, XpBalance,
)
from schemas import (
    FeedItem, FriendRequest, FriendshipResponse, LeaderboardEntry,
    ReactionCreate, ReactionResponse,
)
from services.gamification import get_leaderboard

router = APIRouter(prefix="/api/squad", tags=["social"])


@router.get("/leaderboard", response_model=list[LeaderboardEntry])
async def leaderboard(
    limit: int = 50, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    return await get_leaderboard(db, limit=min(limit, 100))


@router.post("/friend-request/{user_id}", status_code=201)
async def send_friend_request(
    user_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    from models import Friendship
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot friend yourself")
    target = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if target is None:
        raise HTTPException(status_code=404, detail="User not found")
    if target.status != "approved" and not target.is_admin:
        raise HTTPException(status_code=403, detail="Target user not approved")

    # Check for existing friendship (either direction)
    existing = await db.execute(
        select(Friendship).where(
            Friendship.user_id_1 == current_user.id, Friendship.user_id_2 == user_id
        )
    )
    reverse = await db.execute(
        select(Friendship).where(
            Friendship.user_id_1 == user_id, Friendship.user_id_2 == current_user.id
        )
    )
    if existing.scalar_one_or_none() or reverse.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Friendship already exists or is pending")

    friendship = Friendship(user_id_1=current_user.id, user_id_2=user_id, status="pending")
    db.add(friendship)
    await db.commit()
    return {"status": "pending", "friendship_id": friendship.id}


@router.post("/friend-accept/{friendship_id}")
async def accept_friend_request(
    friendship_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    from models import Friendship
    result = await db.execute(select(Friendship).where(Friendship.id == friendship_id))
    friendship = result.scalar_one_or_none()
    if friendship is None:
        raise HTTPException(status_code=404, detail="Friendship not found")
    # Only the recipient (user_id_2) can accept
    if friendship.user_id_2 != current_user.id:
        raise HTTPException(status_code=403, detail="Only the recipient can accept this request")
    friendship.status = "accepted"
    await db.commit()
    return {"status": "accepted"}


@router.get("/friends", response_model=list[FriendshipResponse])
async def list_friends(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    from models import Friendship
    result = await db.execute(
        select(Friendship).where(
            Friendship.user_id_1 == current_user.id,
            Friendship.status == "accepted",
        )
    )
    friendships_as_1 = result.scalars().all()

    result2 = await db.execute(
        select(Friendship).where(
            Friendship.user_id_2 == current_user.id,
            Friendship.status == "accepted",
        )
    )
    friendships_as_2 = result2.scalars().all()

    responses = []
    friend_ids = set()
    for f in friendships_as_1:
        friend_ids.add(f.user_id_2)
    for f in friendships_as_2:
        friend_ids.add(f.user_id_1)

    for fid in friend_ids:
        friend = (await db.execute(select(User).where(User.id == fid))).scalar_one_or_none()
        if friend is None:
            continue
        responses.append(FriendshipResponse(
            id="accepted",
            user_id_1=current_user.id,
            user_id_2=fid,
            status="accepted",
            friend_username=friend.username,
            friend_display_name=friend.display_name,
            friend_avatar_url=friend.avatar_url,
        ))
    return responses


@router.post("/reaction", response_model=ReactionResponse, status_code=201)
async def add_reaction(
    body: ReactionCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    if body.reaction_type not in ("fire", "laugh", "cheer", "pr"):
        raise HTTPException(status_code=400, detail="Invalid reaction type")
    if body.target_type not in ("workout", "habit", "study"):
        raise HTTPException(status_code=400, detail="Invalid target type")
    reaction = Reaction(
        user_id=current_user.id,
        target_type=body.target_type,
        target_id=body.target_id,
        reaction_type=body.reaction_type,
    )
    db.add(reaction)
    await db.commit()
    await db.refresh(reaction)
    # Attach username for convenience
    reaction.username = current_user.username
    return reaction


@router.get("/feed", response_model=list[FeedItem])
async def feed(
    limit: int = 30, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    # Gather recent activity from accepted friends + self
    from models import Friendship
    friend_ids = {current_user.id}
    res1 = await db.execute(
        select(Friendship).where(
            Friendship.user_id_1 == current_user.id, Friendship.status == "accepted"
        )
    )
    for f in res1.scalars().all():
        friend_ids.add(f.user_id_2)
    res2 = await db.execute(
        select(Friendship).where(
            Friendship.user_id_2 == current_user.id, Friendship.status == "accepted"
        )
    )
    for f in res2.scalars().all():
        friend_ids.add(f.user_id_1)

    items: list[FeedItem] = []

    # Workouts
    wres = await db.execute(
        select(WorkoutSession).where(
            WorkoutSession.user_id.in_(list(friend_ids)),
            WorkoutSession.is_template.is_(False),
        ).order_by(WorkoutSession.created_at.desc()).limit(limit)
    )
    for ws in wres.scalars().all():
        user = await _get_user(db, ws.user_id)
        if user and _privacy_allows(user, "workout"):
            items.append(FeedItem(
                type="workout", user_id=user.id, username=user.username,
                display_name=user.display_name, avatar_url=user.avatar_url,
                data={"session_id": ws.id, "name": ws.name, "workout_type": ws.workout_type,
                      "duration_minutes": ws.duration_minutes, "date": ws.date,
                      "xp": ws.xp_earned},
                created_at=ws.created_at,
            ))

    # Study
    sres = await db.execute(
        select(StudyLog).where(
            StudyLog.user_id.in_(list(friend_ids)),
        ).order_by(StudyLog.created_at.desc()).limit(limit)
    )
    for sl in sres.scalars().all():
        user = await _get_user(db, sl.user_id)
        if user and _privacy_allows(user, "study"):
            items.append(FeedItem(
                type="study", user_id=user.id, username=user.username,
                display_name=user.display_name, avatar_url=user.avatar_url,
                data={"study_id": sl.id, "subject": sl.subject, "topic": sl.topic,
                      "duration_minutes": sl.duration_minutes, "date": sl.date},
                created_at=sl.created_at,
            ))

    items.sort(key=lambda x: x.created_at or dt.datetime.min, reverse=True)
    items = items[:min(limit, 50)]

    # Attach reactions for each item (counts only)
    for item in items:
        target_id = item.data.get("session_id") or item.data.get("study_id") or ""
        rres = await db.execute(
            select(Reaction).where(
                Reaction.target_id == target_id,
            ).order_by(Reaction.created_at.desc()).limit(10)
        )
        reactions = []
        for r in rres.scalars().all():
            ru = await _get_user(db, r.user_id)
            reactions.append(ReactionResponse(
                id=r.id, user_id=r.user_id, target_type=r.target_type,
                target_id=r.target_id, reaction_type=r.reaction_type,
                created_at=r.created_at, username=ru.username if ru else None,
            ))
        item.reactions = reactions

    return items


async def _get_user(db: AsyncSession, user_id: str) -> User | None:
    return (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()


def _privacy_allows(user: User, category: str) -> bool:
    """Respects privacy_settings JSON. If no setting, defaults to public (visible)."""
    import json
    try:
        settings = json.loads(user.privacy_settings) if user.privacy_settings else {}
    except (ValueError, TypeError):
        settings = {}
    return settings.get(category, True)
