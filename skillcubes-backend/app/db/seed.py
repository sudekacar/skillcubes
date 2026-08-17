"""Seed default categories and 20 mock questions each.

Usage (from `skillcubes-backend/`):
    python -m app.db.seed
"""

from __future__ import annotations

import asyncio
import random
from typing import Any

from sqlalchemy import func, select

from app.db.session import SessionLocal, init_db
from app.models import Category, Question

CATEGORIES: list[dict[str, Any]] = [
    {
        "slug": "hizli-matematik",
        "title": "Hızlı Matematik",
        "description": "Zamana karşı denklemler (ücretsiz)",
        "icon_name": "calculate",
    },
    {
        "slug": "oruntu-yakalama",
        "title": "Örüntü Yakalama",
        "description": "Dizi ve matris mantığı (ücretsiz)",
        "icon_name": "grid_view",
    },
    {
        "slug": "funnel",
        "title": "Funnel Dönüşüm",
        "description": "Cut-e tarzı şekil dönüşümü",
        "icon_name": "filter_alt",
    },
    {
        "slug": "ratio",
        "title": "Oran & Karşılaştırma",
        "description": "Kesir ve terazi muhakemesi",
        "icon_name": "balance",
    },
    {
        "slug": "charts",
        "title": "Grafik Okuma",
        "description": "Hızlı istatistik yorumlama",
        "icon_name": "bar_chart",
    },
    {
        "slug": "go-nogo",
        "title": "Go / No-Go",
        "description": "Renk baskılama & Stroop",
        "icon_name": "touch_app",
    },
]

SHAPES = ["▲", "■", "●", "◆", "★", "✚"]


def _options_with_answer(answer: str, decoys: list[str]) -> tuple[list[str], int]:
    opts = list({answer, *decoys})
    while len(opts) < 4:
        opts.append(f"Seçenek {len(opts) + 1}")
    opts = opts[:4]
    random.shuffle(opts)
    return opts, opts.index(answer)


def _generate_questions(slug: str, category_id: int, n: int = 20) -> list[Question]:
    questions: list[Question] = []
    rng = random.Random(hash(slug) & 0xFFFFFFFF)

    for i in range(n):
        if slug == "funnel":
            inputs = [SHAPES[rng.randint(0, len(SHAPES) - 1)] for _ in range(4)]
            order = list(range(4))
            rng.shuffle(order)
            rule = "-".join(str(x + 1) for x in order)
            answer = "".join(inputs[j] for j in order)
            decoys = []
            for _ in range(3):
                d = inputs[:]
                rng.shuffle(d)
                decoys.append("".join(d))
            options, correct = _options_with_answer(answer, decoys)
            text = f"Girdi: {' '.join(inputs)}\nKural: {rule}\nDoğru çıktı hangisi?"
            explanation = "Kural, girdi sembollerinin pozisyon sırasını belirtir."

        elif slug == "oruntu-yakalama":
            start = rng.randint(1, 12)
            step = rng.randint(2, 6)
            seq = [start + j * step for j in range(4)]
            answer = str(start + 4 * step)
            decoys = [str(int(answer) + rng.randint(-6, 6)) for _ in range(3)]
            options, correct = _options_with_answer(answer, decoys)
            text = f"{', '.join(map(str, seq))}, ?"
            explanation = f"Aritmetik dizi; ortak fark = {step}."

        elif slug == "hizli-matematik":
            a, b, c = rng.randint(5, 20), rng.randint(5, 20), rng.randint(2, 12)
            kind = i % 3
            if kind == 0:
                answer_n = a + b - c
                text = f"{a} + {b} − {c} = ?"
            elif kind == 1:
                answer_n = a * b
                text = f"{a} × {b} = ?"
            else:
                product = a * b * c
                missing = rng.randint(10, 40)
                answer_n = missing
                text = f"({a} × {b} × {c}) − ? = {product - missing}"
            answer = str(answer_n)
            decoys = [str(answer_n + rng.randint(-8, 8)) for _ in range(3)]
            options, correct = _options_with_answer(answer, decoys)
            explanation = "İşlem önceliğine göre hesaplayın."

        elif slug == "ratio":
            a, b = rng.randint(2, 9), rng.randint(2, 9)
            c, d = rng.randint(2, 9), rng.randint(2, 9)
            left, right = a / b, c / d
            answer = f"{a}/{b}" if left >= right else f"{c}/{d}"
            decoys = [f"{a}/{b}", f"{c}/{d}", f"{a + 1}/{b}", f"{a}/{b + 1}"]
            options, correct = _options_with_answer(answer, decoys)
            text = f"Hangisi daha büyük?\n{a}/{b}  vs  {c}/{d}"
            explanation = "Kesirleri karşılaştırın (çapraz çarpım veya ondalık)."

        elif slug == "charts":
            values = [rng.randint(2, 10) for _ in range(4)]
            labels = ["A", "B", "C", "D"]
            max_i = values.index(max(values))
            answer = labels[max_i]
            options, correct = _options_with_answer(answer, labels)
            text = (
                "Çubuk değerleri: "
                + ", ".join(f"{labels[j]}={values[j]}" for j in range(4))
                + "\nEn yüksek hangisi?"
            )
            explanation = f"En yüksek değer {values[max_i]} ({answer})."

        else:  # go-nogo and any other
            bank = [
                (
                    "Kural: Yeşil/Mavi/Sarıya dokun, Kırmızıya dokunma. "
                    "Kırmızı yanınca ne yapmalısın?",
                    ["Dokunma", "Hemen dokun", "Çift dokun", "Uzun bas"],
                    0,
                    "No-Go uyarısında tepki verilmez.",
                ),
                (
                    "Stroop: Kelime 'Mavi' ama renk kırmızı. Karar neye göre?",
                    ["Renk", "Kelime", "Ses", "Boyut"],
                    0,
                    "Stroop modunda görünen renge göre karar verilir.",
                ),
                (
                    "Go uyarısı (yeşil) geldiğinde doğru tepki nedir?",
                    ["Hızlı dokunuş", "Bekle", "Kaydır", "Hiçbir şey"],
                    0,
                    "Go sinyallerinde hızlı ve doğru dokunuş beklenir.",
                ),
                (
                    "Yanlış alarm (false alarm) ne demektir?",
                    [
                        "No-Go'ya dokunmak",
                        "Go'yu kaçırmak",
                        "Doğru dokunuş",
                        "Zaman aşımı yok",
                    ],
                    0,
                    "No-Go'ya dokunmak false alarm'dır.",
                ),
            ]
            prompt, opts_src, correct_src, explanation = bank[i % len(bank)]
            options = opts_src[:]
            rng.shuffle(options)
            correct = options.index(opts_src[correct_src])
            text = prompt

        questions.append(
            Question(
                category_id=category_id,
                question_text=text,
                options=options,
                correct_option_index=correct,
                explanation=explanation,
            )
        )
    return questions


async def seed(*, force: bool = False) -> None:
    """Populate categories + 20 questions each if empty (or if force=True)."""
    await init_db()
    async with SessionLocal() as db:
        count = (
            await db.execute(select(func.count()).select_from(Category))
        ).scalar_one()
        if count and not force:
            print(f"Seed skipped — {count} categories already exist.")
            return

        if force and count:
            # Simple wipe for reseed in development
            for model in (Question, Category):
                rows = (await db.execute(select(model))).scalars().all()
                for row in rows:
                    await db.delete(row)
            await db.commit()

        for meta in CATEGORIES:
            category = Category(
                slug=meta["slug"],
                title=meta["title"],
                description=meta["description"],
                total_questions=20,
                icon_name=meta["icon_name"],
            )
            db.add(category)
            await db.flush()
            db.add_all(_generate_questions(meta["slug"], category.id, 20))

        await db.commit()
        print(f"Seeded {len(CATEGORIES)} categories × 20 questions.")


def main() -> None:
    asyncio.run(seed())


if __name__ == "__main__":
    main()
