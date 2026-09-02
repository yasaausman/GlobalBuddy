"""Cultural & city discovery feed (M12).

Combines static Markdown graph items (guides, events, food, tips) with any
published Neon `content_items`, filtered by city and category. Browsing is
public; saving requires auth and is stored in `saved_content`.
"""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query, Request
from pydantic import BaseModel, Field

from app.auth import get_optional_principal, require_principal
from app.db import repositories

router = APIRouter(prefix="/v1/feed", tags=["feed"])

FEED_TYPES = {"guide", "event", "food", "tip"}


class FeedItem(BaseModel):
    id: str
    source: str
    type: str
    title: str
    body: str = ""
    city: str = ""
    tags: list[str] = Field(default_factory=list)
    maps_query: str = ""
    maps_link: str = ""
    saved: bool = False


class FeedResponse(BaseModel):
    items: list[FeedItem]
    next_offset: int | None = None


class SaveRequest(BaseModel):
    content_id: str = Field(min_length=1)
    content_source: str = "markdown"


def _graph_feed(request: Request, city: str, category: str, tags: list[str]) -> list[dict]:
    graph_service = getattr(request.app.state, "graph_service", None)
    if getattr(graph_service, "source", "") != "markdown":
        return []
    rows = graph_service.feed_items(city=city or None, tags=tags or None)
    if category:
        rows = [row for row in rows if row["type"] == category]
    return rows


async def _neon_feed(request: Request, city: str, category: str) -> list[dict]:
    db = getattr(request.app.state, "db", None)
    if db is None or not db.enabled:
        return []
    rows = await repositories.list_content_items(db, city=city, content_type=category)
    return [
        {
            "id": str(row["id"]),
            "source": "neon",
            "type": str(row["type"]),
            "title": str(row["title"]),
            "body": str(row.get("body") or ""),
            "city": str(row.get("city") or ""),
            "tags": list(row.get("tags") or []),
            "maps_query": "",
            "maps_link": "",
        }
        for row in rows
    ]


async def _saved_ids(request: Request) -> set[str]:
    principal = get_optional_principal(request)
    db = getattr(request.app.state, "db", None)
    if principal is None or db is None or not db.enabled:
        return set()
    profile = await repositories.get_or_create_profile_from_claims(db, principal.claims)
    rows = await repositories.list_saved_content(db, user_id=str(profile["id"]))
    return {str(row["content_id"]) for row in rows}


@router.get("", response_model=FeedResponse)
async def get_feed(
    request: Request,
    city: str = Query(default="Chicago"),
    category: str = Query(default=""),
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=12, ge=1, le=50),
    tags: str = Query(default=""),
) -> FeedResponse:
    if category and category not in FEED_TYPES:
        raise HTTPException(status_code=422, detail="Unknown feed category.")

    tag_list = [t.strip() for t in tags.split(",") if t.strip()]
    rows = _graph_feed(request, city, category, tag_list) + await _neon_feed(request, city, category)
    saved = await _saved_ids(request)

    window = rows[offset : offset + limit]
    next_offset = offset + limit if offset + limit < len(rows) else None
    items = [FeedItem(**row, saved=row["id"] in saved) for row in window]
    return FeedResponse(items=items, next_offset=next_offset)


@router.post("/save", status_code=204)
async def save_item(payload: SaveRequest, request: Request):
    principal = require_principal(request)
    db = getattr(request.app.state, "db", None)
    if db is None or not db.enabled:
        raise HTTPException(status_code=503, detail="Postgres persistence is not configured.")
    profile = await repositories.get_or_create_profile_from_claims(db, principal.claims)
    await repositories.add_saved_content(
        db,
        user_id=str(profile["id"]),
        content_id=payload.content_id,
        content_source=payload.content_source,
    )


@router.delete("/save/{content_id}", status_code=204)
async def unsave_item(content_id: str, request: Request, content_source: str = Query(default="markdown")):
    principal = require_principal(request)
    db = getattr(request.app.state, "db", None)
    if db is None or not db.enabled:
        raise HTTPException(status_code=503, detail="Postgres persistence is not configured.")
    profile = await repositories.get_or_create_profile_from_claims(db, principal.claims)
    await repositories.remove_saved_content(
        db,
        user_id=str(profile["id"]),
        content_id=content_id,
        content_source=content_source,
    )


@router.get("/saved", response_model=FeedResponse)
async def get_saved(request: Request) -> FeedResponse:
    principal = require_principal(request)
    db = getattr(request.app.state, "db", None)
    if db is None or not db.enabled:
        raise HTTPException(status_code=503, detail="Postgres persistence is not configured.")
    profile = await repositories.get_or_create_profile_from_claims(db, principal.claims)
    saved_rows = await repositories.list_saved_content(db, user_id=str(profile["id"]))
    saved_ids = {str(row["content_id"]) for row in saved_rows}

    # Resolve saved ids against the full feed corpus (all cities + Neon content).
    graph_service = getattr(request.app.state, "graph_service", None)
    corpus: list[dict] = []
    if getattr(graph_service, "source", "") == "markdown":
        corpus.extend(graph_service.feed_items())
    corpus.extend(await _neon_feed(request, "", ""))

    items = [FeedItem(**row, saved=True) for row in corpus if row["id"] in saved_ids]
    return FeedResponse(items=items, next_offset=None)
