import datetime as dt
import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from auth import get_current_user
from database import get_db
from models import (
    User, WorkoutSession, WorkoutSet,
)
from schemas import (
    ExerciseInfo, PersonalRecord, TemplateSave, WorkoutSessionCreate,
    WorkoutSessionResponse, WorkoutSessionUpdate, WorkoutSetCreate,
    WorkoutSetResponse, WorkoutStats,
)
from services.gamification import check_achievements
from services.streak import update_streaks
from services.xp import calculate_workout_xp, apply_xp

router = APIRouter(prefix="/api/workouts", tags=["workouts"])

# A small built-in exercise library with muscle groups and equipment.
EXERCISE_LIBRARY = [
    {"name": "Barbell Back Squat", "category": "strength", "muscles": ["quads", "glutes", "core"], "equipment": ["barbell", "rack"]},
    {"name": "Deadlift", "category": "strength", "muscles": ["hamstrings", "glutes", "back"], "equipment": ["barbell"]},
    {"name": "Bench Press", "category": "strength", "muscles": ["chest", "triceps", "shoulders"], "equipment": ["barbell", "bench"]},
    {"name": "Overhead Press", "category": "strength", "muscles": ["shoulders", "triceps"], "equipment": ["barbell"]},
    {"name": "Barbell Row", "category": "strength", "muscles": ["back", "biceps"], "equipment": ["barbell"]},
    {"name": "Pull-up", "category": "strength", "muscles": ["back", "biceps"], "equipment": ["pull-up bar"]},
    {"name": "Push-up", "category": "calisthenics", "muscles": ["chest", "triceps", "core"], "equipment": ["bodyweight"]},
    {"name": "Dips", "category": "calisthenics", "muscles": ["chest", "triceps"], "equipment": ["parallel bars"]},
    {"name": "Squat", "category": "calisthenics", "muscles": ["quads", "glutes"], "equipment": ["bodyweight"]},
    {"name": "Lunge", "category": "legs", "muscles": ["quads", "glutes"], "equipment": ["bodyweight", "dumbbells"]},
    {"name": "Dumbbell Curl", "category": "strength", "muscles": ["biceps"], "equipment": ["dumbbells"]},
    {"name": "Dumbbell Shoulder Press", "category": "strength", "muscles": ["shoulders", "triceps"], "equipment": ["dumbbells"]},
    {"name": "Running", "category": "cardio", "muscles": ["legs", "heart"], "equipment": ["treadmill", "outdoors"]},
    {"name": "Cycling", "category": "cardio", "muscles": ["legs", "heart"], "equipment": ["bike"]},
    {"name": "Rowing", "category": "cardio", "muscles": ["back", "legs", "arms"], "equipment": ["rowing machine"]},
    {"name": "Jump Rope", "category": "cardio", "muscles": ["legs", "core"], "equipment": ["rope"]},
    {"name": "Plank", "category": "core", "muscles": ["core"], "equipment": ["bodyweight"]},
    {"name": "Hanging Leg Raise", "category": "core", "muscles": ["abs", "hip flexors"], "equipment": ["pull-up bar"]},
    {"name": "Hip Thrust", "category": "glutes", "muscles": ["glutes", "hamstrings"], "equipment": ["barbell", "bench"]},
    {"name": "Romanian Deadlift", "category": "strength", "muscles": ["hamstrings", "glutes"], "equipment": ["barbell", "dumbbells"]},
]


async def _get_owned_session(db: AsyncSession, user_id: str, session_id: str) -> WorkoutSession:
    result = await db.execute(
        select(WorkoutSession)
        .options(selectinload(WorkoutSession.sets))
        .where(
            WorkoutSession.id == session_id,
            WorkoutSession.user_id == user_id,
        )
    )
    session = result.scalar_one_or_none()
    if session is None:
        raise HTTPException(status_code=404, detail="Workout session not found")
    return session


def _compute_volume(sets) -> float:
    total = 0.0
    for s in sets:
        if s.weight_kg and s.reps:
            total += float(s.weight_kg) * int(s.reps)
    return round(total, 2)


@router.post("/sessions", response_model=WorkoutSessionResponse, status_code=201)
async def create_session(
    body: WorkoutSessionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = WorkoutSession(
        user_id=current_user.id,
        date=body.date,
        duration_minutes=body.duration_minutes,
        workout_type=body.workout_type,
        name=body.name,
        notes=body.notes,
        total_volume_kg=body.total_volume_kg,
        estimated_calories=body.estimated_calories,
    )
    if body.sets:
        for i, set_data in enumerate(body.sets, start=1):
            session.sets.append(WorkoutSet(session_id=session.id, **set_data.model_dump()))
    else:
        session.total_volume_kg = 0

    if session.total_volume_kg is None:
        session.total_volume_kg = _compute_volume(session.sets)

    db.add(session)
    await db.flush()

    # XP awarding
    if not session.is_template:
        xp = calculate_workout_xp(session.duration_minutes or 0, session.total_volume_kg or 0)
        session.xp_earned = await apply_xp(
            db, current_user, xp, "workout", source_id=session.id,
            description=f"Workout: {session.name or session.workout_type or 'session'}",
        )
        await update_streaks(db, current_user, session.date)
        await check_achievements(db, current_user.id)

    await db.commit()
    return await _get_owned_session(db, current_user.id, session.id)


@router.get("/sessions", response_model=list[WorkoutSessionResponse])
async def list_sessions(
    start_date: str | None = None,
    end_date: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(WorkoutSession).options(selectinload(WorkoutSession.sets)).where(
        WorkoutSession.user_id == current_user.id,
        WorkoutSession.is_template.is_(False),
    )
    if start_date:
        query = query.where(WorkoutSession.date >= start_date)
    if end_date:
        query = query.where(WorkoutSession.date <= end_date)
    query = query.order_by(WorkoutSession.date.desc())
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/sessions/{session_id}", response_model=WorkoutSessionResponse)
async def get_session(
    session_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    return await _get_owned_session(db, current_user.id, session_id)


@router.put("/sessions/{session_id}", response_model=WorkoutSessionResponse)
async def update_session(
    session_id: str,
    body: WorkoutSessionUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = await _get_owned_session(db, current_user.id, session_id)
    updates = body.model_dump(exclude_unset=True)
    for key, value in updates.items():
        setattr(session, key, value)
    session.updated_at = dt.datetime.utcnow()
    await db.commit()
    return await _get_owned_session(db, current_user.id, session.id)


@router.delete("/sessions/{session_id}", status_code=204)
async def delete_session(
    session_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    session = await _get_owned_session(db, current_user.id, session_id)
    await db.delete(session)
    await db.commit()
    return None


@router.post("/sessions/{session_id}/sets", response_model=WorkoutSetResponse, status_code=201)
async def add_set(
    session_id: str,
    body: WorkoutSetCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = await _get_owned_session(db, current_user.id, session_id)
    new_set = WorkoutSet(session_id=session.id, **body.model_dump())
    db.add(new_set)
    # Recompute session volume
    await db.flush()
    all_sets = await db.execute(select(WorkoutSet).where(WorkoutSet.session_id == session.id))
    session.total_volume_kg = _compute_volume(all_sets.scalars().all())
    session.updated_at = dt.datetime.utcnow()
    await db.commit()
    await db.refresh(new_set)
    return new_set


async def _get_owned_set(db: AsyncSession, user_id: str, set_id: str) -> WorkoutSet:
    result = await db.execute(
        select(WorkoutSet)
        .join(WorkoutSession, WorkoutSession.id == WorkoutSet.session_id)
        .where(WorkoutSet.id == set_id, WorkoutSession.user_id == user_id)
    )
    ws = result.scalar_one_or_none()
    if ws is None:
        raise HTTPException(status_code=404, detail="Set not found")
    return ws


@router.put("/sets/{set_id}", response_model=WorkoutSetResponse)
async def update_set(
    set_id: str,
    body: WorkoutSetCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ws = await _get_owned_set(db, current_user.id, set_id)
    for key, value in body.model_dump(exclude_unset=True).items():
        if key == "exercise_name" and not value:
            continue
        setattr(ws, key, value)
    await db.commit()
    await db.refresh(ws)
    return ws


@router.delete("/sets/{set_id}", status_code=204)
async def delete_set(
    set_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    ws = await _get_owned_set(db, current_user.id, set_id)
    await db.delete(ws)
    await db.commit()
    return None


@router.post("/templates", response_model=WorkoutSessionResponse, status_code=201)
async def save_template(
    body: TemplateSave,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    source = await _get_owned_session(db, current_user.id, body.session_id)
    # Build a template copy (sets copied over)
    template = WorkoutSession(
        user_id=current_user.id,
        date=dt.date.today().isoformat(),
        duration_minutes=source.duration_minutes,
        workout_type=source.workout_type,
        name=body.template_name,
        notes=source.notes,
        total_volume_kg=source.total_volume_kg,
        estimated_calories=source.estimated_calories,
        is_template=True,
        template_name=body.template_name,
    )
    for s in source.sets:
        template.sets.append(WorkoutSet(
            exercise_name=s.exercise_name,
            exercise_variation=s.exercise_variation,
            set_number=s.set_number,
            reps=s.reps,
            weight_kg=s.weight_kg,
            rest_seconds=s.rest_seconds,
            is_warmup=s.is_warmup,
            is_dropset=s.is_dropset,
            is_superset=s.is_superset,
            superset_group=s.superset_group,
            notes=s.notes,
            rpe=s.rpe,
            completed=s.completed,
        ))
    db.add(template)
    await db.commit()
    return await _get_owned_session(db, current_user.id, template.id)


@router.get("/templates", response_model=list[WorkoutSessionResponse])
async def list_templates(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(WorkoutSession).options(selectinload(WorkoutSession.sets)).where(
            WorkoutSession.user_id == current_user.id,
            WorkoutSession.is_template.is_(True),
        ).order_by(WorkoutSession.created_at.desc())
    )
    return result.scalars().all()


@router.post("/templates/{template_id}/start", response_model=WorkoutSessionResponse, status_code=201)
async def start_from_template(
    template_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    template = await _get_owned_session(db, current_user.id, template_id)
    if not template.is_template:
        raise HTTPException(status_code=400, detail="Session is not a template")

    session = WorkoutSession(
        user_id=current_user.id,
        date=dt.date.today().isoformat(),
        duration_minutes=None,
        workout_type=template.workout_type,
        name=template.name or template.template_name,
        notes=template.notes,
        total_volume_kg=0,
        estimated_calories=template.estimated_calories,
        is_template=False,
    )
    for s in template.sets:
        session.sets.append(WorkoutSet(
            exercise_name=s.exercise_name,
            exercise_variation=s.exercise_variation,
            set_number=s.set_number,
            reps=s.reps,
            weight_kg=s.weight_kg,
            rest_seconds=s.rest_seconds,
            is_warmup=s.is_warmup,
            is_dropset=s.is_dropset,
            is_superset=s.is_superset,
            superset_group=s.superset_group,
            notes=s.notes,
            rpe=s.rpe,
            completed=s.completed,
        ))
    db.add(session)
    await db.commit()
    return await _get_owned_session(db, current_user.id, session.id)


@router.get("/exercises", response_model=list[ExerciseInfo])
async def exercise_library():
    return EXERCISE_LIBRARY


@router.get("/stats", response_model=WorkoutStats)
async def workout_stats(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(WorkoutSession).where(
            WorkoutSession.user_id == current_user.id,
            WorkoutSession.is_template.is_(False),
        )
    )
    sessions = result.scalars().all()

    total_volume = sum(s.total_volume_kg or 0 for s in sessions)
    total_duration = sum(s.duration_minutes or 0 for s in sessions)

    today = dt.date.today()
    week_start = (today - dt.timedelta(days=today.weekday())).isoformat()
    month_start = today.replace(day=1).isoformat()
    sessions_week = sum(1 for s in sessions if s.date >= week_start)
    sessions_month = sum(1 for s in sessions if s.date >= month_start)

    # frequency per week over last 4 weeks
    four_weeks_ago = today - dt.timedelta(weeks=4)
    recent = [s for s in sessions if s.date >= four_weeks_ago.isoformat()]
    frequency = round(len(recent) / 4.0, 2)

    return WorkoutStats(
        total_sessions=len(sessions),
        total_volume_kg=round(total_volume, 2),
        total_duration_minutes=total_duration,
        average_duration_minutes=round(total_duration / len(sessions), 2) if sessions else 0,
        sessions_this_week=sessions_week,
        sessions_this_month=sessions_month,
        workout_frequency_per_week=frequency,
    )


@router.get("/prs", response_model=list[PersonalRecord])
async def personal_records(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(WorkoutSet)
        .join(WorkoutSession, WorkoutSession.id == WorkoutSet.session_id)
        .where(
            WorkoutSession.user_id == current_user.id,
            WorkoutSession.is_template.is_(False),
            WorkoutSet.completed.is_(True),
            WorkoutSet.is_warmup.is_(False),
        )
    )
    sets = result.scalars().all()

    records: dict[str, dict] = {}
    for s in sets:
        exercise = s.exercise_name
        rec = records.setdefault(exercise, {
            "exercise_name": exercise,
            "best_weight_kg": None,
            "best_reps": None,
            "best_volume": None,
            "date": None,
        })
        weight = s.weight_kg or 0
        if weight > (rec["best_weight_kg"] or 0):
            rec["best_weight_kg"] = weight
            rec["date"] = s.session.date
        if s.reps and s.reps > (rec["best_reps"] or 0):
            rec["best_reps"] = s.reps
        if weight and s.reps:
            vol = weight * s.reps
            if vol > (rec["best_volume"] or 0):
                rec["best_volume"] = vol
                if rec["date"] is None:
                    rec["date"] = s.session.date

    return list(records.values())
