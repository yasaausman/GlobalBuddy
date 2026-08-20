from functools import lru_cache
from pathlib import Path

from pydantic import AliasChoices, Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Always resolve .env next to the backend package.
_BACKEND_DIR = Path(__file__).resolve().parents[1]
_REPO_DIR = _BACKEND_DIR.parent


class Settings(BaseSettings):
    """Application settings; at least one AI backend is required for plan/bridge."""

    model_config = SettingsConfigDict(
        env_file=_BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    graph_source: str = Field(default="markdown", description="markdown | neo4j")
    graph_data_dir: str = Field(default=str((_REPO_DIR / "data" / "graph").resolve()))

    # Optional legacy Neo4j adapter.
    neo4j_uri: str = Field(default="", description="Optional legacy Neo4j Aura bolt URI")
    neo4j_user: str = Field(
        default="",
        validation_alias=AliasChoices("NEO4J_USER", "NEO4J_USERNAME"),
    )
    neo4j_password: str = Field(default="")
    neo4j_database: str | None = Field(default=None)

    # Target Neon persistence/auth settings.
    database_url: str = Field(default="", description="Neon pooled Postgres connection string")
    database_url_unpooled: str = Field(default="", description="Neon direct connection string for migrations")
    neon_auth_url: str = Field(default="", description="Neon Auth URL")
    neon_auth_jwks_url: str = Field(default="", description="JWKS URL for Neon Auth JWT verification")
    neon_auth_issuer: str = Field(default="", description="Optional expected JWT issuer")
    neon_auth_audience: str = Field(default="", description="Optional expected JWT audience")
    auth_required: bool = Field(default=False, description="Require JWTs on protected API routes")

    # Legacy Stack Auth names remain accepted for older local .env files.
    stack_project_id: str = Field(default="", description="Legacy Stack Auth project id")
    stack_publishable_client_key: str = Field(default="", description="Legacy Stack Auth publishable key")
    stack_secret_server_key: str = Field(default="", description="Legacy Stack Auth server secret")
    stack_jwks_url: str = Field(default="", description="Legacy Stack Auth JWKS URL")

    # AI providers.
    ai_provider: str = Field(
        default="auto",
        description=(
            "auto | gemini | rocketride_sdk | rocketride_http | anthropic | groq; "
            "auto prefers Gemini when GEMINI_API_KEY is set"
        ),
    )
    gemini_api_key: str = Field(default="", description="Google AI Studio / Vertex-compatible Gemini API key")
    gemini_model: str = Field(default="gemini-2.0-flash", description="Gemini model id for generateContent")
    anthropic_api_key: str = Field(default="", description="Optional Anthropic fallback via httpx")

    rocketride_uri: str = Field(default="", description="RocketRide DAP base URI")
    rocketride_apikey: str = Field(default="", description="RocketRide API key for SDK/HTTP")
    rocketride_gemini_key: str = Field(
        default="",
        description="Gemini API key injected into ROCKETRIDE_GEMINI_KEY for default RocketRide pipelines",
    )
    rocketride_plan_pipeline: str = Field(
        default=str((_REPO_DIR / "pipelines" / "globaldost.plan.pipe").resolve()),
        description="Absolute or relative path to the RocketRide pipeline for /v1/plan/generate",
    )
    rocketride_bridge_pipeline: str = Field(
        default=str((_REPO_DIR / "pipelines" / "globaldost.bridge.pipe").resolve()),
        description="Absolute or relative path to the RocketRide pipeline for /v1/bridge/explain",
    )
    rocketride_http_completion_url: str = Field(
        default="",
        description="Legacy full HTTPS URL for RocketRide HTTP JSON inference",
    )

    ai_timeout_seconds: int = Field(default=30, description="Hard timeout for each AI provider call")
    groq_api_key: str = Field(default="", description="Groq API key for low-latency fallback")
    groq_model: str = Field(default="llama3-8b-8192", description="Groq model id")

    # Legacy Supabase fields are ignored by the target Neon stack but accepted
    # for older local .env files during migration.
    supabase_url: str = Field(default="", description="Legacy Supabase project URL")
    supabase_service_role_key: str = Field(default="", description="Legacy Supabase service role key")
    supabase_jwt_secret: str = Field(default="", description="Legacy Supabase JWT secret")

    upstash_redis_url: str = Field(default="", description="Upstash Redis REST URL")
    upstash_redis_token: str = Field(default="", description="Upstash Redis REST token")
    session_ttl_hours: int = Field(default=24, description="Profile/evidence session TTL in hours")
    resend_api_key: str = Field(default="", description="Resend API key for transactional email")

    linkedin_client_id: str = Field(default="")
    linkedin_client_secret: str = Field(default="")
    linkedin_redirect_uri: str = Field(default="http://localhost:8000/v1/auth/linkedin/callback")

    # -- Xano migration (M18+) -----------------------------------------------------
    # Once set, the sidecar requires X-Sidecar-Key on agent-only routes and a signed
    # stream token on /v1/chat/stream, instead of accepting unauthenticated calls.
    xano_base_url: str = Field(default="", description="Xano API group base URL")
    sidecar_shared_secret: str = Field(
        default="", description="Xano -> FastAPI sidecar shared secret (X-Sidecar-Key)"
    )

    cors_origins: str = Field(default="http://localhost:5173")

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: object) -> str:
        if isinstance(value, str):
            return value
        if isinstance(value, list):
            return ",".join(str(item).strip() for item in value if str(item).strip())
        return str(value)

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def graph_data_path(self) -> Path:
        raw = Path(self.graph_data_dir)
        if raw.is_absolute():
            return raw
        return (_BACKEND_DIR / raw).resolve()

    @property
    def neo4j_enabled(self) -> bool:
        return bool(self.neo4j_uri.strip() and self.neo4j_user.strip() and self.neo4j_password.strip())

    @property
    def postgres_enabled(self) -> bool:
        return bool(self.database_url.strip())

    @property
    def jwt_jwks_url(self) -> str:
        return self.neon_auth_jwks_url.strip() or self.stack_jwks_url.strip()

    @property
    def auth_enforced(self) -> bool:
        return bool(self.auth_required and self.jwt_jwks_url)

    @model_validator(mode="after")
    def require_llm_backend(self) -> "Settings":
        has_gemini = bool(self.gemini_api_key.strip())
        has_rr_sdk = bool(self.rocketride_uri.strip() and self.rocketride_apikey.strip())
        has_rr_http = bool(self.rocketride_http_completion_url.strip() and self.rocketride_apikey.strip())
        has_anthropic = bool(self.anthropic_api_key.strip())
        has_groq = bool(self.groq_api_key.strip())
        if not (has_gemini or has_rr_sdk or has_rr_http or has_anthropic or has_groq):
            raise ValueError(
                "Set GEMINI_API_KEY (recommended), or ROCKETRIDE_URI with ROCKETRIDE_APIKEY, "
                "or ROCKETRIDE_HTTP_COMPLETION_URL with ROCKETRIDE_APIKEY, GROQ_API_KEY, or ANTHROPIC_API_KEY "
                "for plan/bridge endpoints."
            )
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()


class Neo4jOnlySettings(BaseSettings):
    """Neo4j only; used by seed scripts so LLM keys are not required."""

    model_config = SettingsConfigDict(
        env_file=_BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    neo4j_uri: str = Field(..., min_length=1)
    neo4j_user: str = Field(
        ...,
        min_length=1,
        validation_alias=AliasChoices("NEO4J_USER", "NEO4J_USERNAME"),
    )
    neo4j_password: str = Field(..., min_length=1)


def get_neo4j_settings() -> Neo4jOnlySettings:
    return Neo4jOnlySettings()
