"""Xano -> FastAPI sidecar authentication (M18).

The sidecar holds no user data and is called two ways once Xano is live:

1. Server-to-server, from Xano function stacks (e.g. the future agent's
   ``check_policy``/``generate_form`` tool calls) -- verified with a static
   shared secret in the ``X-Sidecar-Key`` header.
2. Browser-to-sidecar, for the one route that must stream to the browser
   directly (``/v1/chat/stream``) -- Xano mints a short-lived signed token
   after checking the user's session, and the browser passes it along;
   the sidecar verifies the signature and expiry without needing a JWKS
   client or a user table of its own.

Both checks are a no-op while ``SIDECAR_SHARED_SECRET`` is unset, so the
existing Neon-Auth-protected app keeps working unchanged until the Xano
workspace exists and the secret is configured on both sides.
"""

from __future__ import annotations

import hashlib
import hmac
import time
from base64 import urlsafe_b64decode, urlsafe_b64encode
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.config import Settings

STREAM_TOKEN_TTL_SECONDS = 300

# Paths only ever called by Xano function stacks, never directly by a browser.
SIDECAR_ONLY_PREFIXES = ("/v1/agent",)

# The one route a browser calls on the sidecar directly; auth is a stream token,
# not the shared secret (the secret must never reach the browser).
STREAM_TOKEN_PREFIXES = ("/v1/chat/stream",)


def sidecar_auth_configured(settings: Settings) -> bool:
    return bool(settings.sidecar_shared_secret.strip())


def is_sidecar_only_path(path: str) -> bool:
    return any(path.startswith(prefix) for prefix in SIDECAR_ONLY_PREFIXES)


def is_stream_token_path(path: str) -> bool:
    return any(path.startswith(prefix) for prefix in STREAM_TOKEN_PREFIXES)


def verify_sidecar_key(header_value: str | None, settings: Settings) -> bool:
    """Constant-time comparison of the X-Sidecar-Key header against the shared secret."""
    if not header_value:
        return False
    return hmac.compare_digest(header_value.strip(), settings.sidecar_shared_secret.strip())


def _sign(payload: str, secret: str) -> str:
    digest = hmac.new(secret.encode("utf-8"), payload.encode("utf-8"), hashlib.sha256).digest()
    return urlsafe_b64encode(digest).decode("utf-8").rstrip("=")


def mint_stream_token(user_id: str, settings: Settings, *, ttl_seconds: int = STREAM_TOKEN_TTL_SECONDS) -> str:
    """Xano-side helper (kept here for parity/testing) -- production minting happens in Xano."""
    expires_at = int(time.time()) + ttl_seconds
    payload = f"{user_id}:{expires_at}"
    signature = _sign(payload, settings.sidecar_shared_secret)
    token_body = urlsafe_b64encode(payload.encode("utf-8")).decode("utf-8").rstrip("=")
    return f"{token_body}.{signature}"


def verify_stream_token(token: str, settings: Settings) -> str | None:
    """Returns the user_id if the token is validly signed and unexpired, else None."""
    try:
        token_body, signature = token.split(".", 1)
        padding = "=" * (-len(token_body) % 4)
        payload = urlsafe_b64decode(token_body + padding).decode("utf-8")
        user_id, expires_at_raw = payload.rsplit(":", 1)
        expires_at = int(expires_at_raw)
    except (ValueError, UnicodeDecodeError):
        return None

    expected_signature = _sign(payload, settings.sidecar_shared_secret)
    if not hmac.compare_digest(signature, expected_signature):
        return None
    if time.time() > expires_at:
        return None
    return user_id
