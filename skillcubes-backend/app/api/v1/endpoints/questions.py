"""Question fetch endpoints with freemium teaser limits."""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.freemium import question_limit_for_user
from app.db.session import get_db
from app.models import Category, Question, User
from app.schemas import QuestionOut

router = APIRouter(prefix="/questions", tags=["questions"])


@router.get("", response_model=list[QuestionOut])
async def get_questions(
    category_id: int = Query(..., description="Category primary key"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Question]:
    """Fetch questions for a category (20 full / 2 teaser for locked free users)."""
    category = (
        await db.execute(select(Category).where(Category.id == category_id))
    ).scalar_one_or_none()
    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found",
        )

    limit = question_limit_for_user(
        is_premium=current_user.is_premium,
        category_slug=category.slug,
    )

    result = await db.execute(
        select(Question)
        .where(Question.category_id == category_id)
        .order_by(Question.id)
        .limit(limit)
    )
    return list(result.scalars().all())
