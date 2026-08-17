"""Freemium category rules for SkillCubes."""

# Fully unlocked for free users (20 questions).
FREE_CATEGORY_SLUGS: frozenset[str] = frozenset(
    {
        "hizli-matematik",
        "oruntu-yakalama",
    }
)

# Premium-locked categories still return a 2-question teaser for free users.
PREMIUM_TEASER_QUESTION_LIMIT = 2
FULL_QUESTION_LIMIT = 20


def is_free_category(slug: str) -> bool:
    return slug in FREE_CATEGORY_SLUGS


def question_limit_for_user(*, is_premium: bool, category_slug: str) -> int:
    """Return how many questions a user may fetch for a category."""
    if is_premium or is_free_category(category_slug):
        return FULL_QUESTION_LIMIT
    return PREMIUM_TEASER_QUESTION_LIMIT
