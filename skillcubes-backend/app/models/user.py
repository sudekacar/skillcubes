"""User ORM model."""

from datetime import datetime, timezone
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Boolean, DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base

if TYPE_CHECKING:
    from app.models.user_progress import UserProgress


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        default=_utcnow,
    )

    # Freemium + streak engine
    is_premium: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    streak_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    last_test_date: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        default=None,
    )
    streak_freeze_count: Mapped[int] = mapped_column(Integer, nullable=False, default=1)

    progress: Mapped[list["UserProgress"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )
