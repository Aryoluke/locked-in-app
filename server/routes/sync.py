import datetime as dt
import json
from typing import Any

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from auth import get_current_user
from database import get_db
from models import User
from schemas import SyncPullRequest, SyncPushRequest, SyncResponse, SyncRecord
from services.sync import apply_push_changes, pull_changes_since

router = APIRouter(prefix="/api/sync", tags=["sync"])


def _group_records(records: list[dict]) -> list[SyncRecord]:
    """Group a flat list of {"table", "id", "data"} into SyncRecord groups by table."""
    by_table: dict[str, list[dict]] = {}
    for rec in records:
        table = rec.get("table") or "unknown"
        rec_data = dict(rec.get("data", {}))
        rec_data["id"] = rec.get("id")
        rec_data["timestamp"] = rec.get("timestamp")
        # Map service-level 'data' payload into the record shape the client expects
        by_table.setdefault(table, []).append(rec_data)
    return [
        SyncRecord(table_name=table, records=rows) for table, rows in by_table.items()
    ]


@router.post("/push", response_model=SyncResponse)
async def sync_push(
    body: SyncPushRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Normalize client changes into the flat record list the service expects.
    records: list[dict[str, Any]] = []
    for group in body.changes:
        table_name = group.table_name
        for rec in group.records:
            # Each record may carry its own id/data/timestamp
            if "id" in rec and "data" not in rec:
                # record is raw field dict with an id inside
                rec_id = rec.get("id")
                payload = {k: v for k, v in rec.items() if k != "id" and k != "timestamp"}
                records.append({
                    "table": table_name,
                    "id": rec_id,
                    "data": payload,
                    "timestamp": rec.get("timestamp"),
                })
            else:
                records.append({
                    "table": table_name,
                    "id": rec.get("id"),
                    "data": rec.get("data", rec),
                    "timestamp": rec.get("timestamp"),
                })

    result = await apply_push_changes(db, current_user.id, records, body.client_timestamp)
    total_xp_earned = 0.0

    # Small XP award for syncing is intentionally skipped; only real activities earn XP.

    await db.commit()

    # Return relevant pull after push
    server_ts = dt.datetime.utcnow().isoformat()
    pulled = await pull_changes_since(db, current_user.id, None)

    return SyncResponse(
        server_timestamp=server_ts,
        changes=_group_records(pulled),
        conflicts=result["conflicts"],
    )


@router.post("/pull", response_model=SyncResponse)
async def sync_pull(
    body: SyncPullRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    changed = await pull_changes_since(db, current_user.id, body.since)
    return SyncResponse(
        server_timestamp=dt.datetime.utcnow().isoformat(),
        changes=_group_records(changed),
        conflicts=[],
    )


@router.get("/status")
async def sync_status(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    if current_user.last_synced_at is None:
        return {"last_synced_at": None}
    return {"last_synced_at": current_user.last_synced_at.isoformat()}
