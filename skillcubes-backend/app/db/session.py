"""Async SQLAlchemy engine, session factory, and FastAPI dependency."""

from collections.abc import AsyncGenerator

from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings


class Base(DeclarativeBase):
    """Declarative base for all ORM models."""


_engine_kwargs: dict = {"echo": False}  # keep SQL quiet; use app logging for debug
if settings.is_sqlite:
    _engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_async_engine(settings.database_url, **_engine_kwargs)

SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Yield a request-scoped async DB session (caller commits writes)."""
    async with SessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


async def init_db() -> None:
    """Create all tables and apply lightweight SQLite column migrations."""
    from app import models  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        if settings.is_sqlite:
            await _ensure_sqlite_user_columns(conn)


async def _ensure_sqlite_user_columns(conn) -> None:
    """Add freemium/streak columns to existing SQLite `users` tables."""
    result = await conn.execute(text("PRAGMA table_info(users)"))
    existing = {row[1] for row in result.fetchall()}
    alters = []
    if "is_premium" not in existing:
        alters.append(
            "ALTER TABLE users ADD COLUMN is_premium BOOLEAN NOT NULL DEFAULT 0"
        )
    if "streak_count" not in existing:
        alters.append(
            "ALTER TABLE users ADD COLUMN streak_count INTEGER NOT NULL DEFAULT 0"
        )
    if "last_test_date" not in existing:
        alters.append("ALTER TABLE users ADD COLUMN last_test_date DATETIME")
    if "streak_freeze_count" not in existing:
        alters.append(
            "ALTER TABLE users ADD COLUMN streak_freeze_count INTEGER NOT NULL DEFAULT 1"
        )
    for stmt in alters:
        await conn.execute(text(stmt))
