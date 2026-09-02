"""In-app notifications (M14).

Notifications are created by server-side triggers (currently the social router,
when a logged-in user sends a connection/intro request) and read here. Bodies
are polled by the frontend bell.
"""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel

from app.auth import require_principal
from app.db import repositories

router = APIRouter(prefix="/v1/notifications", tags=["notifications"])


class NotificationItem(BaseModel):
    id: str
    type: str
    title: str
    body: str
    read: bool
    created_at: str


class NotificationList(BaseModel):
    items: list[NotificationItem]
    unread: int


def _require_db(request: Request):
    db = getattr(request.app.state, "db", None)
    if db is None or not db.enabled:
        raise HTTPException(status_code=503, detail="Postgres persistence is not configured.")
    return db


def _item(row: dict) -> NotificationItem:
    return NotificationItem(
        id=str(row["id"]),
        type=str(row["type"]),
        title=str(row["title"]),
        body=str(row.get("body") or ""),
        read=bool(row["read"]),
        created_at=row["created_at"].isoformat(),
    )


@router.get("", response_model=NotificationList)
async def list_notifications(request: Request) -> NotificationList:
    principal = require_principal(request)
    db = _require_db(request)
    profile = await repositories.get_or_create_profile_from_claims(db, principal.claims)
    user_id = str(profile["id"])
    rows = await repositories.list_notifications(db, user_id=user_id)
    unread = await repositories.count_unread_notifications(db, user_id=user_id)
    return NotificationList(items=[_item(r) for r in rows], unread=unread)


@router.post("/{notification_id}/read", status_code=204)
async def mark_read(notification_id: str, request: Request):
    principal = require_principal(request)
    db = _require_db(request)
    profile = await repositories.get_or_create_profile_from_claims(db, principal.claims)
    await repositories.mark_notification_read(db, user_id=str(profile["id"]), notification_id=notification_id)


@router.post("/read-all", status_code=204)
async def mark_all_read(request: Request):
    principal = require_principal(request)
    db = _require_db(request)
    profile = await repositories.get_or_create_profile_from_claims(db, principal.claims)
    await repositories.mark_all_notifications_read(db, user_id=str(profile["id"]))
