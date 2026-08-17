"""User progress, stats, radar chart, and premium toggle."""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models import Category, User, UserProgress
from app.schemas import (
    PremiumToggleOut,
    ProgressOut,
    ProgressUpsert,
    RadarAxis,
    RadarStatsOut,
    UserStats,
)

router = APIRouter(prefix="/user", tags=["user"])


@router.post("/progress", response_model=ProgressOut)
async def upsert_progress(
    payload: ProgressUpsert,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserProgress:
    """Save or update quiz progress and refresh streak counters."""
    category = (
        await db.execute(select(Category).where(Category.id == payload.category_id))
    ).scalar_one_or_none()
    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found",
        )

    result = await db.execute(
        select(UserProgress).where(
            UserProgress.user_id == current_user.id,
            UserProgress.category_id == payload.category_id,
        )
    )
    progress = result.scalar_one_or_none()

    if progress is None:
        progress = UserProgress(
            user_id=current_user.id,
            category_id=payload.category_id,
            completed_questions=payload.completed_questions,
            score=payload.score,
        )
        db.add(progress)
    else:
        progress.completed_questions = max(
            progress.completed_questions,
            payload.completed_questions,
        )
        progress.score = max(progress.score, payload.score)
        progress.updated_at = datetime.now(timezone.utc)

    _update_user_streak(current_user)
    await db.commit()
    await db.refresh(progress)
    return progress


@router.get("/stats", response_model=UserStats)
async def get_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserStats:
    """Overall user stats: scores, completed categories, streak."""
    rows = (
        await db.execute(
            select(UserProgress).where(UserProgress.user_id == current_user.id)
        )
    ).scalars().all()

    if not rows:
        return UserStats(
            total_games=0,
            total_categories_started=0,
            total_categories_completed=0,
            average_score=0.0,
            streak=current_user.streak_count,
            best_score=0,
            is_premium=current_user.is_premium,
            streak_freeze_count=current_user.streak_freeze_count,
            progress=[],
        )

    cats = (await db.execute(select(Category))).scalars().all()
    total_by_id = {c.id: c.total_questions for c in cats}

    completed_cats = sum(
        1
        for p in rows
        if p.completed_questions >= total_by_id.get(p.category_id, 20)
    )
    scores = [p.score for p in rows]
    average = sum(scores) / len(scores) if scores else 0.0

    return UserStats(
        total_games=len(rows),
        total_categories_started=len(rows),
        total_categories_completed=completed_cats,
        average_score=round(average, 1),
        streak=current_user.streak_count,
        best_score=max(scores) if scores else 0,
        is_premium=current_user.is_premium,
        streak_freeze_count=current_user.streak_freeze_count,
        progress=list(rows),
    )


@router.get("/radar-stats", response_model=RadarStatsOut)
async def radar_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> RadarStatsOut:
    """Percentage scores across all 6 cognitive categories (radar chart)."""
    cats = (
        await db.execute(select(Category).order_by(Category.id))
    ).scalars().all()
    progress_rows = (
        await db.execute(
            select(UserProgress).where(UserProgress.user_id == current_user.id)
        )
    ).scalars().all()
    by_cat = {p.category_id: p for p in progress_rows}

    axes: list[RadarAxis] = []
    for cat in cats:
        prog = by_cat.get(cat.id)
        if prog is None:
            pct = 0.0
        else:
            # Prefer explicit score (0–100); fall back to completion ratio.
            pct = float(prog.score)
            if pct <= 0 and cat.total_questions > 0:
                pct = (prog.completed_questions / cat.total_questions) * 100
        axes.append(
            RadarAxis(
                slug=cat.slug,
                title=cat.title,
                percentage=round(min(max(pct, 0.0), 100.0), 1),
            )
        )

    return RadarStatsOut(axes=axes, is_premium=current_user.is_premium)


@router.post("/toggle-premium", response_model=PremiumToggleOut)
async def toggle_premium(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PremiumToggleOut:
    """Dev helper: flip the current user's `is_premium` flag."""
    current_user.is_premium = not current_user.is_premium
    await db.commit()
    await db.refresh(current_user)
    state = "Premium" if current_user.is_premium else "Free"
    return PremiumToggleOut(
        id=current_user.id,
        email=current_user.email,
        is_premium=current_user.is_premium,
        message=f"Account is now {state}",
    )


def _update_user_streak(user: User) -> None:
    """Increment / freeze / reset streak based on calendar days."""
    now = datetime.now(timezone.utc)
    today = now.date()
    last = user.last_test_date
    if last is None:
        user.streak_count = 1
        user.last_test_date = now
        return

    last_day = (
        last.astimezone(timezone.utc).date()
        if last.tzinfo
        else last.replace(tzinfo=timezone.utc).date()
    )
    delta = (today - last_day).days
    if delta == 0:
        user.last_test_date = now
        return
    if delta == 1:
        user.streak_count = (user.streak_count or 0) + 1
        user.last_test_date = now
        return
    if delta == 2 and (user.streak_freeze_count or 0) > 0:
        # Missed one day — consume a freeze and keep the streak.
        user.streak_freeze_count -= 1
        user.streak_count = (user.streak_count or 0) + 1
        user.last_test_date = now
        return

    user.streak_count = 1
    user.last_test_date = now
