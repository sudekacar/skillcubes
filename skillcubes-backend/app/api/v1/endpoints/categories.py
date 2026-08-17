"""Category listing with per-user completion and freemium flags."""

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.freemium import is_free_category, question_limit_for_user
from app.db.session import get_db
from app.models import Category, User, UserProgress
from app.schemas import CategoryOut

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
async def list_categories(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[CategoryOut]:
    """List all categories with the current user's completion counts."""
    cats = (await db.execute(select(Category).order_by(Category.id))).scalars().all()
    progress_rows = (
        await db.execute(
            select(UserProgress).where(UserProgress.user_id == current_user.id)
        )
    ).scalars().all()
    progress_map = {p.category_id: p for p in progress_rows}

    return [
        CategoryOut(
            id=c.id,
            slug=c.slug,
            title=c.title,
            description=c.description,
            total_questions=c.total_questions,
            icon_name=c.icon_name,
            completed_questions=progress_map[c.id].completed_questions
            if c.id in progress_map
            else 0,
            score=progress_map[c.id].score if c.id in progress_map else 0,
            is_free=is_free_category(c.slug),
            is_locked=(
                not current_user.is_premium and not is_free_category(c.slug)
            ),
            question_limit=question_limit_for_user(
                is_premium=current_user.is_premium,
                category_slug=c.slug,
            ),
        )
        for c in cats
    ]
