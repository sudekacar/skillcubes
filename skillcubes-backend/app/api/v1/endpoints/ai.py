"""SkillCubes AI Agent endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models import User
from app.schemas import AnalyzeRequest, AnalyzeResponse, ChatRequest, ChatResponse
from app.services.ai_agent import CognitiveCoachAgent

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_performance(
    payload: AnalyzeRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AnalyzeResponse:
    """Run Emma's CognitiveCoachAgent on a completed test."""
    agent = CognitiveCoachAgent()
    try:
        result = await agent.analyze_performance(
            db,
            user_id=current_user.id,
            category_slug=payload.category_slug,
            score=payload.score,
            total_questions=payload.total_questions,
            response_times=payload.response_times,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        ) from exc

    return AnalyzeResponse(
        summary=result["summary"],
        detailed_report=result["detailed_report"],
        recommended_category=result["recommended_category"],
        is_premium_locked=bool(result.get("is_premium_locked", False)),
    )


@router.post("/chat", response_model=ChatResponse)
async def chat_with_emma(
    payload: ChatRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ChatResponse:
    """Conversational reply from Emma, the personal cognitive coach."""
    agent = CognitiveCoachAgent()
    try:
        reply = await agent.chat(
            db,
            user_id=current_user.id,
            message=payload.message,
            history=[t.model_dump() for t in payload.history],
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        ) from exc

    return ChatResponse(reply=reply, coach="Emma")
