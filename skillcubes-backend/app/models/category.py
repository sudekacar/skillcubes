"""Category ORM model."""

from typing import TYPE_CHECKING

from sqlalchemy import Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base

if TYPE_CHECKING:
    from app.models.question import Question
    from app.models.user_progress import UserProgress


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(128), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False, default="")
    total_questions: Mapped[int] = mapped_column(Integer, nullable=False, default=20)
    icon_name: Mapped[str] = mapped_column(String(64), nullable=False, default="quiz")

    questions: Mapped[list["Question"]] = relationship(
        back_populates="category",
        cascade="all, delete-orphan",
    )
    progress: Mapped[list["UserProgress"]] = relationship(back_populates="category")
