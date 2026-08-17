"""Application settings loaded from environment / `.env`."""

from functools import lru_cache
from typing import List, Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Central configuration for SkillCubes API."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    app_name: str = "SkillCubes API"
    app_env: str = "development"
    debug: bool = True
    api_v1_prefix: str = "/api/v1"

    # JWT
    secret_key: str = Field(
        default="change-me-to-a-long-random-secret-key",
        min_length=16,
    )
    access_token_expire_minutes: int = 60
    algorithm: str = "HS256"

    # Database — SQLite by default, PostgreSQL via DATABASE_URL
    database_url: str = "sqlite+aiosqlite:///./skillcubes.db"

    # Gemini / SkillCubes AI Agent
    gemini_api_key: Optional[str] = None
    gemini_model: str = "gemini-2.0-flash"

    # CORS for Flutter local development
    cors_origins: List[str] = Field(default_factory=lambda: ["*"])

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith("sqlite")

    @property
    def has_gemini(self) -> bool:
        return bool(self.gemini_api_key and self.gemini_api_key.strip())


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
