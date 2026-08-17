"""Emma — SkillCubes personal cognitive coach (Gemini-powered)."""

from __future__ import annotations

import json
import re
from typing import Any, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.freemium import FREE_CATEGORY_SLUGS, is_free_category
from app.models import Category, User, UserProgress

EMMA_NAME = "Emma"

EMMA_GREETING = (
    "Merhaba, ben Emma! Bugünkü zihinsel performansını analiz etmeye hazırım. "
    "Ne çalışmak istersin?"
)

EMMA_SYSTEM = (
    "Sen Emma'sın — SkillCubes'un kişisel bilişsel koçu. "
    "Türkçe konuş; tonun samimi, profesyonel ve motive edici olsun. "
    "Kendini Emma olarak tanıt; asla jenerik 'AI koç' deme. "
    "Kısa, net ve uygulanabilir tavsiyeler ver."
)

PREMIUM_UPSELL = (
    "🔒 Emma'nın detaylı koçluk raporu Premium üyeler içindir. "
    "Odak düşüşleri, hız–doğruluk dengesi ve kişiselleştirilmiş "
    "antrenman planını görmek için Premium'a geç."
)


class CognitiveCoachAgent:
    """Emma — SkillCubes cognitive coach powered by Google Gemini."""

    def __init__(self, api_key: Optional[str] = None, model: Optional[str] = None):
        self.api_key = (api_key if api_key is not None else settings.gemini_api_key) or ""
        self.model = model or settings.gemini_model
        self._client = None
        if self.api_key.strip():
            try:
                from google import genai

                self._client = genai.Client(api_key=self.api_key.strip())
            except Exception:
                self._client = None

    async def analyze_performance(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        category_slug: str,
        score: int,
        total_questions: int,
        response_times: list[float],
    ) -> dict[str, Any]:
        """Return structured Turkish cognitive feedback for a finished test."""
        user = (
            await db.execute(select(User).where(User.id == user_id))
        ).scalar_one_or_none()
        if user is None:
            raise ValueError("User not found")

        history = await self._load_history(db, user_id)
        avg_ms = (
            sum(response_times) / len(response_times) if response_times else 0.0
        )

        if self._client is not None:
            payload = await self._call_gemini(
                user=user,
                category_slug=category_slug,
                score=score,
                total_questions=total_questions,
                avg_ms=avg_ms,
                response_times=response_times,
                history=history,
            )
        else:
            payload = self._fallback_analysis(
                category_slug=category_slug,
                score=score,
                total_questions=total_questions,
                avg_ms=avg_ms,
                history=history,
            )

        if not user.is_premium:
            payload["detailed_report"] = PREMIUM_UPSELL
            payload["is_premium_locked"] = True
        else:
            payload["is_premium_locked"] = False

        payload.setdefault("recommended_category", self._recommend(history, category_slug))
        return payload

    async def _load_history(self, db: AsyncSession, user_id: int) -> list[dict[str, Any]]:
        rows = (
            await db.execute(
                select(UserProgress, Category)
                .join(Category, Category.id == UserProgress.category_id)
                .where(UserProgress.user_id == user_id)
                .order_by(UserProgress.updated_at.desc())
            )
        ).all()
        return [
            {
                "slug": cat.slug,
                "title": cat.title,
                "score": prog.score,
                "completed_questions": prog.completed_questions,
                "updated_at": prog.updated_at.isoformat() if prog.updated_at else None,
            }
            for prog, cat in rows
        ]

    async def _call_gemini(
        self,
        *,
        user: User,
        category_slug: str,
        score: int,
        total_questions: int,
        avg_ms: float,
        response_times: list[float],
        history: list[dict[str, Any]],
    ) -> dict[str, Any]:
        prompt = f"""
{EMMA_SYSTEM}
Bir antrenman oturumunu analiz et. Sadece geçerli JSON döndür (markdown yok). Şema:
{{
  "summary": "Emma olarak 1–2 cümlelik vurucu analiz (kendini Emma diye tanıt)",
  "detailed_report": "Emma'nın koçluk tavsiyeleri: odak düşüşleri, hız vs doğruluk, sonraki adım",
  "recommended_category": "slug (ör. hizli-matematik, oruntu-yakalama, funnel, ratio, charts, go-nogo)"
}}

Kullanıcı: {user.full_name} | premium={user.is_premium} | streak={user.streak_count}
Kategori: {category_slug}
Skor: {score}/{total_questions} ({(score / max(total_questions, 1)) * 100:.0f}%)
Ort. tepki: {avg_ms:.0f} ms
Tepki süreleri (ms): {response_times[:40]}
Geçmiş performans: {json.dumps(history[:12], ensure_ascii=False)}
""".strip()

        try:
            response = self._client.models.generate_content(
                model=self.model,
                contents=prompt,
            )
            text = getattr(response, "text", None) or str(response)
            return self._parse_json(text, category_slug=category_slug, history=history)
        except Exception:
            return self._fallback_analysis(
                category_slug=category_slug,
                score=score,
                total_questions=total_questions,
                avg_ms=avg_ms,
                history=history,
            )

    def _parse_json(
        self,
        text: str,
        *,
        category_slug: str,
        history: list[dict[str, Any]],
    ) -> dict[str, Any]:
        cleaned = text.strip()
        fence = re.search(r"```(?:json)?\s*([\s\S]*?)```", cleaned)
        if fence:
            cleaned = fence.group(1).strip()
        try:
            data = json.loads(cleaned)
        except json.JSONDecodeError:
            return {
                "summary": cleaned[:220] if cleaned else "Analiz tamamlandı.",
                "detailed_report": cleaned or "Detaylı rapor üretilemedi.",
                "recommended_category": self._recommend(history, category_slug),
            }
        return {
            "summary": str(data.get("summary", "Analiz tamamlandı.")),
            "detailed_report": str(data.get("detailed_report", "")),
            "recommended_category": str(
                data.get("recommended_category")
                or self._recommend(history, category_slug)
            ),
        }

    def _fallback_analysis(
        self,
        *,
        category_slug: str,
        score: int,
        total_questions: int,
        avg_ms: float,
        history: list[dict[str, Any]],
    ) -> dict[str, Any]:
        pct = (score / max(total_questions, 1)) * 100
        if pct >= 80:
            summary = (
                f"Ben Emma — {category_slug} oturumunda güçlü bir performans gördüm "
                f"(%{pct:.0f}). Doğruluk yüksek; temposunu koru!"
            )
        elif pct >= 50:
            summary = (
                f"Ben Emma — %{pct:.0f} skor ile dengeli bir oturum çıkardın. "
                "Hız ile doğruluk arasında ince ayar zamanı."
            )
        else:
            summary = (
                f"Ben Emma — %{pct:.0f} skor, odak dalgalanması belirgin. "
                "Kısa tekrar setleriyle ritmi birlikte toparlayalım."
            )

        speed_note = (
            "Tepki sürelerin hızlı; acele hatalara dikkat."
            if avg_ms and avg_ms < 1800
            else "Tempo biraz yavaş; karar hızını artırmaya odaklan."
            if avg_ms
            else "Tepki süresi verisi sınırlı."
        )
        detailed = (
            f"Emma olarak bakıyorum: doğruluk %{pct:.0f} "
            f"({score}/{total_questions}). Ortalama tepki {avg_ms:.0f} ms. "
            f"{speed_note} Ortadaki sorularda odak düşüşü tipik; kısa molalar "
            "ve kategori tekrarı bilişsel dayanıklılığı güçlendirir."
        )
        return {
            "summary": summary,
            "detailed_report": detailed,
            "recommended_category": self._recommend(history, category_slug),
        }

    def _recommend(self, history: list[dict[str, Any]], current_slug: str) -> str:
        scores = {h["slug"]: h["score"] for h in history}
        # Prefer weakest category; otherwise a free one for freemium onboarding.
        all_slugs = [
            "hizli-matematik",
            "oruntu-yakalama",
            "funnel",
            "ratio",
            "charts",
            "go-nogo",
        ]
        ranked = sorted(
            all_slugs,
            key=lambda s: (scores.get(s, 0), 0 if is_free_category(s) else 1),
        )
        for slug in ranked:
            if slug != current_slug:
                return slug
        return next(iter(FREE_CATEGORY_SLUGS))

    async def chat(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        message: str,
        history: list[dict[str, str]] | None = None,
    ) -> str:
        """Conversational reply as Emma (Turkish, motivational)."""
        user = (
            await db.execute(select(User).where(User.id == user_id))
        ).scalar_one_or_none()
        if user is None:
            raise ValueError("User not found")

        progress = await self._load_history(db, user_id)
        trimmed = (message or "").strip()
        if not trimmed:
            return EMMA_GREETING

        if self._client is None:
            return self._fallback_chat(trimmed, user.full_name)

        transcript = ""
        for turn in (history or [])[-8]:
            role = "Kullanıcı" if turn.get("role") == "user" else "Emma"
            content = (turn.get("content") or "").strip()
            if content:
                transcript += f"{role}: {content}\n"

        prompt = f"""
{EMMA_SYSTEM}
Kullanıcı sohbete başladı. İlk mesajında şu selamlamayı kullanabilirsin (tekrarlardan kaçın):
"{EMMA_GREETING}"

Kullanıcı: {user.full_name} | premium={user.is_premium} | streak={user.streak_count}
Son performans: {json.dumps(progress[:8], ensure_ascii=False)}

Sohbet geçmişi:
{transcript or "(yeni sohbet)"}
Kullanıcı: {trimmed}

Sadece Emma'nın Türkçe yanıtını yaz. JSON yok, markdown yok.
Antrenman önerirken kategori slug'larını Türkçe isimle anlat
(Hızlı Matematik, Örüntü Yakalama, Funnel, Oran, Grafikler, Go/No-Go).
""".strip()

        try:
            response = self._client.models.generate_content(
                model=self.model,
                contents=prompt,
            )
            text = (getattr(response, "text", None) or str(response)).strip()
            return text or EMMA_GREETING
        except Exception:
            return self._fallback_chat(trimmed, user.full_name)

    def _fallback_chat(self, message: str, name: str) -> str:
        lowered = message.lower()
        who = name.split()[0] if name else "dostum"
        if any(k in lowered for k in ("selam", "merhaba", "hey", "hi")):
            return EMMA_GREETING
        if any(k in lowered for k in ("matematik", "hız", "refleks", "tap")):
            return (
                f"{who}, ben Emma — refleks ve hız için Hızlı Matematik / Speed Tap "
                "harika bir 3 dakikalık set. Hazırsan başlayalım!"
            )
        if any(k in lowered for k in ("örüntü", "hafıza", "memory", "grid")):
            return (
                "Ben Emma. Mekânsal hafızanı Örüntü Yakalama ile ısıtalım — "
                "deseni 2 saniye ezberle, sonra doğru hücrelere dokun."
            )
        if any(k in lowered for k in ("odak", "focus", "swipe", "dikkat")):
            return (
                "Odak için Swipe Focus / Go-No-Go öneririm. Yeşil sağa, mavi sola; "
                "kırmızıları yok say. Ben Emma, yanında olacağım."
            )
        return (
            f"Ben Emma, kişisel bilişsel koçunum. {who}, bugün refleks, hafıza "
            "veya odak çalışabiliriz — hangisini seçersen antrenmanı birlikte "
            "planlarız."
        )
