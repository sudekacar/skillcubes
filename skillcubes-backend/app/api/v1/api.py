"""Aggregate v1 API router."""

from fastapi import APIRouter

from app.api.v1.endpoints import ai, auth, categories, questions, user

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(categories.router)
api_router.include_router(questions.router)
api_router.include_router(user.router)
api_router.include_router(ai.router)
