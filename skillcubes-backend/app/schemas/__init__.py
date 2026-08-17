"""Pydantic request/response schemas."""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field


# ── Auth ─────────────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    full_name: str = Field(default="", max_length=255)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    full_name: str
    created_at: datetime
    is_premium: bool = False
    streak_count: int = 0
    last_test_date: Optional[datetime] = None
    streak_freeze_count: int = 1


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    sub: Optional[str] = None


# ── Categories ────────────────────────────────────────────────────────────────

class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    slug: str
    title: str
    description: str
    total_questions: int
    icon_name: str
    completed_questions: int = 0
    score: int = 0
    is_free: bool = False
    is_locked: bool = False
    question_limit: int = 20


# ── Questions ─────────────────────────────────────────────────────────────────

class QuestionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    category_id: int
    question_text: str
    options: List[str]
    correct_option_index: int
    explanation: str


# ── Progress / Stats ──────────────────────────────────────────────────────────

class ProgressUpsert(BaseModel):
    category_id: int
    completed_questions: int = Field(ge=0, le=20)
    score: int = Field(ge=0, le=100)


class ProgressOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    category_id: int
    completed_questions: int
    score: int
    updated_at: datetime


class UserStats(BaseModel):
    total_games: int
    total_categories_started: int
    total_categories_completed: int
    average_score: float
    streak: int
    best_score: int
    is_premium: bool = False
    streak_freeze_count: int = 0
    progress: List[ProgressOut] = Field(default_factory=list)


class RadarAxis(BaseModel):
    slug: str
    title: str
    percentage: float


class RadarStatsOut(BaseModel):
    axes: List[RadarAxis]
    is_premium: bool


class PremiumToggleOut(BaseModel):
    id: int
    email: EmailStr
    is_premium: bool
    message: str


# ── AI Agent ──────────────────────────────────────────────────────────────────

class AnalyzeRequest(BaseModel):
    category_slug: str
    score: int = Field(ge=0)
    total_questions: int = Field(ge=1, le=20)
    response_times: List[float] = Field(default_factory=list)


class AnalyzeResponse(BaseModel):
    summary: str
    detailed_report: str
    recommended_category: str
    is_premium_locked: bool = False


class ChatTurn(BaseModel):
    role: str = Field(pattern="^(user|assistant)$")
    content: str = Field(min_length=1, max_length=2000)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    history: List[ChatTurn] = Field(default_factory=list)


class ChatResponse(BaseModel):
    reply: str
    coach: str = "Emma"
