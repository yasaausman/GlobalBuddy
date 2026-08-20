from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
import logging
import time

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

from app.auth import bearer_token_from_header, is_public_api_path, verify_jwt_token
from app.config import get_settings
from app.db.neo4j_client import Neo4jClient
from app.db.postgres import PostgresDatabase
from app.sidecar_auth import (
    is_sidecar_only_path,
    is_stream_token_path,
    sidecar_auth_configured,
    verify_sidecar_key,
    verify_stream_token,
)
from app.routers import (
    auth,
    bridge,
    chat,
    documents,
    feed,
    graph,
    mentor,
    notifications,
    plan,
    pre_arrival,
    profile,
    progress,
    social,
)
from app.services.markdown_graph import MarkdownGraphService

_telemetry_logger = logging.getLogger("app.telemetry")
_TELEMETRY_ROUTES = {"/v1/plan/generate", "/v1/bridge/explain", "/v1/chat/message", "/v1/chat/stream"}


class _RequestTelemetryMiddleware(BaseHTTPMiddleware):
    """Log method, path, status, and elapsed_ms for AI-heavy routes."""

    async def dispatch(self, request: Request, call_next: object) -> Response:
        if request.url.path not in _TELEMETRY_ROUTES:
            return await call_next(request)
        t0 = time.perf_counter()
        try:
            response: Response = await call_next(request)
            elapsed_ms = int((time.perf_counter() - t0) * 1000)
            _telemetry_logger.info(
                "request method=%s path=%s status=%d elapsed_ms=%d",
                request.method, request.url.path, response.status_code, elapsed_ms,
            )
            return response
        except Exception as exc:
            elapsed_ms = int((time.perf_counter() - t0) * 1000)
            _telemetry_logger.warning(
                "request method=%s path=%s error=%s elapsed_ms=%d",
                request.method, request.url.path, type(exc).__name__, elapsed_ms,
            )
            raise


class _AuthMiddleware(BaseHTTPMiddleware):
    """Attach optional JWT principal and enforce protected API routes when configured."""

    async def dispatch(self, request: Request, call_next: object) -> Response:
        settings = get_settings()
        token = bearer_token_from_header(request.headers.get("Authorization"))
        if token and settings.jwt_jwks_url:
            try:
                request.state.user = verify_jwt_token(token, settings)
            except HTTPException as exc:
                return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})

        if settings.auth_enforced and not is_public_api_path(request.url.path):
            if not getattr(request.state, "user", None):
                return JSONResponse(status_code=401, content={"detail": "Authentication required."})

        return await call_next(request)


class _SidecarKeyMiddleware(BaseHTTPMiddleware):
    """Authenticate Xano -> sidecar calls once M18's Xano workspace is live.

    A no-op while ``SIDECAR_SHARED_SECRET`` is unset, so today's Neon-Auth-protected
    app is unaffected. Once set: agent-only paths require the exact shared secret in
    ``X-Sidecar-Key``; the browser-facing stream route accepts a short-lived signed
    token instead, since the shared secret itself must never reach the browser.
    """

    async def dispatch(self, request: Request, call_next: object) -> Response:
        settings = get_settings()
        if not sidecar_auth_configured(settings):
            return await call_next(request)

        path = request.url.path
        if is_sidecar_only_path(path):
            if not verify_sidecar_key(request.headers.get("X-Sidecar-Key"), settings):
                return JSONResponse(status_code=401, content={"detail": "Invalid or missing sidecar key."})
        elif is_stream_token_path(path):
            stream_token = request.query_params.get("stream_token", "")
            user_id = verify_stream_token(stream_token, settings) if stream_token else None
            if user_id is None:
                return JSONResponse(status_code=401, content={"detail": "Invalid or expired stream token."})
            request.state.sidecar_user_id = user_id

        return await call_next(request)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    graph_service = None
    if settings.graph_source.lower() == "markdown":
        graph_service = MarkdownGraphService(settings.graph_data_path)
    app.state.graph_service = graph_service

    neo4j: Neo4jClient | None = None
    if settings.graph_source.lower() == "neo4j" and settings.neo4j_enabled:
        neo4j = Neo4jClient(
            uri=settings.neo4j_uri,
            user=settings.neo4j_user,
            password=settings.neo4j_password,
        )
        await neo4j.connect()
    app.state.neo4j_client = neo4j
    db = PostgresDatabase(settings)
    await db.connect()
    app.state.db = db
    yield
    await db.close()
    if neo4j is not None:
        await neo4j.close()


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="Globalदोस्त API", version="0.1.0", lifespan=lifespan)

    # Regex covers localhost / 127.0.0.1 / [::1] with any port (browser Origin must match for CORS).
    _local_origin_regex = r"https?://(localhost|127\.0\.0\.1|\[::1\])(:\d+)?"
    app.add_middleware(_RequestTelemetryMiddleware)
    app.add_middleware(_SidecarKeyMiddleware)
    app.add_middleware(_AuthMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_origin_regex=_local_origin_regex,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(auth.router)
    app.include_router(chat.router)
    app.include_router(documents.router)
    app.include_router(progress.router)
    app.include_router(social.router)
    app.include_router(mentor.router)
    app.include_router(notifications.router)
    app.include_router(feed.router)
    app.include_router(pre_arrival.router)
    app.include_router(profile.router)
    app.include_router(plan.router)
    app.include_router(bridge.router)
    app.include_router(graph.router)

    @app.get("/health", tags=["system"])
    def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/health/providers", tags=["system"])
    async def health_providers() -> dict:
        """Lightweight ping of each configured AI provider — checks reachability, not generation."""
        settings = get_settings()
        results: dict[str, dict] = {}

        async with httpx.AsyncClient(timeout=5.0) as client:
            # Gemini — list models endpoint (fast, no token consumption)
            if settings.gemini_api_key.strip():
                t0 = time.perf_counter()
                try:
                    r = await client.get(
                        "https://generativelanguage.googleapis.com/v1beta/models",
                        params={"key": settings.gemini_api_key},
                    )
                    latency_ms = int((time.perf_counter() - t0) * 1000)
                    results["gemini"] = {"status": "ok" if r.status_code == 200 else "error", "latency_ms": latency_ms, "http_status": r.status_code}
                except Exception as exc:
                    results["gemini"] = {"status": "timeout", "latency_ms": int((time.perf_counter() - t0) * 1000), "error": str(exc)}
            else:
                results["gemini"] = {"status": "not_configured"}

            # Groq — list models endpoint
            if settings.groq_api_key.strip():
                t0 = time.perf_counter()
                try:
                    r = await client.get(
                        "https://api.groq.com/openai/v1/models",
                        headers={"Authorization": f"Bearer {settings.groq_api_key}"},
                    )
                    latency_ms = int((time.perf_counter() - t0) * 1000)
                    results["groq"] = {"status": "ok" if r.status_code == 200 else "error", "latency_ms": latency_ms, "http_status": r.status_code}
                except Exception as exc:
                    results["groq"] = {"status": "timeout", "latency_ms": int((time.perf_counter() - t0) * 1000), "error": str(exc)}
            else:
                results["groq"] = {"status": "not_configured"}

            # Anthropic — simple models endpoint
            if settings.anthropic_api_key.strip():
                t0 = time.perf_counter()
                try:
                    r = await client.get(
                        "https://api.anthropic.com/v1/models",
                        headers={"x-api-key": settings.anthropic_api_key, "anthropic-version": "2023-06-01"},
                    )
                    latency_ms = int((time.perf_counter() - t0) * 1000)
                    results["anthropic"] = {"status": "ok" if r.status_code == 200 else "error", "latency_ms": latency_ms, "http_status": r.status_code}
                except Exception as exc:
                    results["anthropic"] = {"status": "timeout", "latency_ms": int((time.perf_counter() - t0) * 1000), "error": str(exc)}
            else:
                results["anthropic"] = {"status": "not_configured"}

        return {"providers": results}

    @app.get("/health/graph", tags=["system"])
    async def health_graph(request: Request) -> dict:
        graph_service = request.app.state.graph_service
        if graph_service is None:
            return {
                "status": "disabled",
                "source": get_settings().graph_source,
                "node_count": 0,
                "edge_count": 0,
                "validation_errors": [],
            }
        return graph_service.health()

    @app.get("/health/db", tags=["system"])
    async def health_db(request: Request) -> dict:
        db = request.app.state.db
        if not db.enabled:
            return {"status": "not_configured"}
        ok = await db.ping()
        return {"status": "ok" if ok else "error"}

    @app.get("/health/neo4j", tags=["system"])
    async def health_neo4j(request: Request) -> dict[str, str | int | None]:
        """Legacy DB probe kept during the Markdown graph migration."""
        neo4j = request.app.state.neo4j_client
        if neo4j is None:
            return {
                "status": "disabled",
                "node_count": 0,
                "seed_command": None,
            }
        rows = await neo4j.query("MATCH (n) RETURN count(n) AS c", {})
        count = int(rows[0]["c"]) if rows else 0
        return {
            "status": "ok",
            "node_count": count,
            "seed_command": (
                "cd backend && source .venv/bin/activate && python -m app.db.seed_data"
                if count == 0
                else None
            ),
        }

    return app


app = create_app()
