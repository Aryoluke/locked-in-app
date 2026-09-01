from typing import Any

import datetime as dt

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models import (
    User, WorkoutSession, WorkoutSet, Habit, HabitLog, DailyLog, BodyLog,
    SleepLog, SupplementLog, StudyLog, PomodoroSession, Competition,
    CompetitionEntry, CompetitionWar, Friendship, Reaction, InviteCode,
    Achievement, Streak, XpBalance, XpTransaction,
)

# Maps each public table name to its model and which field carries the
# user's ownership/foreign-key link so we can scope sync to the caller.
TABLE_MODELS = {
    "workout_sessions": (WorkoutSession, "user_id"),
    "workout_sets": (WorkoutSet, None),  # scoped through session
    "habits": (Habit, "user_id"),
    "habit_logs": (HabitLog, "user_id"),
    "daily_logs": (DailyLog, "user_id"),
    "body_logs": (BodyLog, "user_id"),
    "sleep_logs": (SleepLog, "user_id"),
    "supplement_logs": (SupplementLog, "user_id"),
    "study_logs": (StudyLog, "user_id"),
    "pomodoro_sessions": (PomodoroSession, "user_id"),
    "streaks": (Streak, "user_id"),
    "xp_transactions": (XpTransaction, "user_id"),
}

# Tables that are read-only/shared and ignored for push, but can be pulled.
READONLY_TABLES = {
    "achievements": Achievement,
    "competitions": Competition,
    "competition_entries": CompetitionEntry,
    "competition_wars": CompetitionWar,
    "friendships": Friendship,
    "reactions": Reaction,
    "invite_codes": InviteCode,
    "users": User,
}

# Attribute names that should be treated as dates for last-write-wins ordering.
DATE_FIELDS = {"created_at", "updated_at", "last_synced_at"}


def _serialize_model(obj: Any) -> dict:
    data = {}
    for col in obj.__table__.columns:
        value = getattr(obj, col.name)
        if hasattr(value, "isoformat"):
            value = value.isoformat()
        data[col.name] = value
    return data


def _cell_eq(model, attr, incoming, current):
    """Compares incoming client value against current DB value to detect conflicts."""
    try:
        col = getattr(model, attr)
    except AttributeError:
        return True
    if col.type.python_type in (float, int):
        try:
            return abs(float(incoming or 0) - float(current or 0)) < 1e-9
        except (ValueError, TypeError):
            return False
    if str(incoming) == str(current):
        return True
    return False


async def apply_push_changes(
    db: AsyncSession, user_id: str, changes: list[dict], client_timestamp: str | None = None
) -> dict:
    """
    Last-write-wins per field merge. Accepts a list of raw records like:
      [{"id": "...", "table": "habits", "data": {...}, "timestamp": "..."}, ...]
    Detects conflicts when a same record was edited on both ends recently.
    Returns {"changed": [...], "conflicts": [...]}.
    """
    applied = []
    conflicts = []

    for record in changes:
        table = record.get("table")
        record_id = record.get("id")
        data = record.get("data", {})
        incoming_ts = record.get("timestamp")

        if table not in TABLE_MODELS:
            continue  # ignore unknown tables
        model, owner_field = TABLE_MODELS[table]

        # Build a mapping of field name -> (incoming, timestamp) for LWW
        existing = None
        if record_id:
            result = await db.execute(select(model).where(model.id == record_id))
            existing = result.scalar_one_or_none()

        if existing is None:
            # Create new record (only for user-owned tables)
            if owner_field is None:
                conflicts.append({
                    "id": record_id,
                    "table": table,
                    "reason": "orphan_set_without_session",
                })
                continue
            try:
                coerced = dict(data)
                # Coerce ISO strings for DateTime columns into datetime objects so
                # SQLite/SQLAlchemy can insert them (client sends ISO strings).
                for col in model.__table__.columns:
                    key = col.name
                    if key in coerced and coerced[key] is not None:
                        value = coerced[key]
                        if col.type.python_type is dt.datetime and isinstance(value, str):
                            from datetime import datetime
                            try:
                                coerced[key] = datetime.fromisoformat(value)
                            except ValueError:
                                pass
                new_obj = model(**coerced)
                setattr(new_obj, owner_field, user_id)
                if new_obj.id is None:
                    new_obj.id = data.get("id") or _new_id()
                db.add(new_obj)
                applied.append({"id": str(new_obj.id), "table": table, "status": "created"})
            except Exception:
                conflicts.append({"id": record_id, "table": table, "reason": "create_failed"})
        else:
            # Existing record: LWW per field
            conflict_detected = False
            for attr, value in data.items():
                if not hasattr(model, attr):
                    continue
                current_value = getattr(existing, attr)
                if not _cell_eq(model, attr, value, current_value):
                    # Real conflict only if the record was edited server-side recently too.
                    # Compare on updated_at when available.
                    server_ts = getattr(existing, "updated_at", None)
                    if server_ts and incoming_ts:
                        try:
                            from datetime import datetime
                            inc_dt = datetime.fromisoformat(incoming_ts)
                            if abs((server_ts - inc_dt.replace(tzinfo=None)).total_seconds()) < 300:
                                conflict_detected = True
                        except (ValueError, TypeError):
                            pass
                    # Coerce ISO datetime strings to datetime for DateTime columns.
                    _val = value
                    col = getattr(model, attr, None)
                    if col is not None:
                        coltype = getattr(col, "type", None)
                        coltype_pt = getattr(coltype, "python_type", None)
                        if coltype_pt is dt.datetime and isinstance(_val, str):
                            from datetime import datetime
                            try:
                                _val = datetime.fromisoformat(_val)
                            except ValueError:
                                pass
                    setattr(existing, attr, _val)
            applied.append({"id": str(existing.id), "table": table, "status": "merged"})
            if conflict_detected:
                conflicts.append({
                    "id": str(existing.id),
                    "table": table,
                    "reason": "concurrent_edit",
                    "server_values": _serialize_model(existing),
                })

    await db.flush()
    return {"changed": applied, "conflicts": conflicts}


async def pull_changes_since(
    db: AsyncSession, user_id: str, since: str | None = None
) -> list[dict]:
    """
    Returns all user-owned rows changed after `since` (ISO timestamp), plus rolled-up
    shared tables that changed (competitions, etc.). For simplicity, shared/read-only
    tables are returned in full when requested so the client stays in sync.
    """
    from datetime import datetime

    changed_records = []
    cutoff = _to_dt(since)

    for table, (model, owner_field) in TABLE_MODELS.items():
        if owner_field is None:
            continue
        result = await db.execute(select(model).where(getattr(model, owner_field) == user_id))
        for obj in result.scalars().all():
            ts = _latest_ts(obj)
            if cutoff is None or ts is None or ts >= cutoff:
                record = _serialize_model(obj)
                changed_records.append({"table": table, "id": record.get("id"), "data": record})

    # Include workouts' sets too (scoped through parent session ownership)
    session_ids = []
    sres = await db.execute(
        select(WorkoutSession.id).where(WorkoutSession.user_id == user_id)
    )
    session_ids = [r[0] for r in sres.all()]
    if session_ids:
        sres2 = await db.execute(
            select(WorkoutSet).where(WorkoutSet.session_id.in_(session_ids))
        )
        for obj in sres2.scalars().all():
            record = _serialize_model(obj)
            changed_records.append({"table": "workout_sets", "id": record.get("id"), "data": record})

    return changed_records


def _latest_ts(obj: Any):
    ts = getattr(obj, "updated_at", None)
    if ts is None:
        ts = getattr(obj, "created_at", None)
    return ts


def _to_dt(iso: str | None):
    from datetime import datetime
    if not iso:
        return None
    try:
        return datetime.fromisoformat(iso)
    except (ValueError, TypeError):
        return None


def _new_id() -> str:
    import uuid
    return str(uuid.uuid4())
