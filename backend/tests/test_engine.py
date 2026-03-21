"""
Tests: Recommendation engine — rules, scoring, colour compatibility.
Pure unit tests, no network or DB required.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
os.environ.setdefault("JWT_SECRET_KEY", "test-secret-key-minimum-32-chars-ok")
os.environ.setdefault("MONGODB_URL", "mongodb://localhost:27017")
os.environ.setdefault("DEBUG", "true")

from datetime import datetime, timezone
import pytest

from engine.rules import (
    style_score_for_occasion,
    get_style_priority,
    get_weather_rules,
    colors_compatible,
    OCCASION_STYLE_PRIORITY,
    WEATHER_RULES,
)
from engine.scoring import score_combination
from models.wardrobe import ClothingItem, Category, Style
from core.weather_client import WeatherData


# ── Helpers ───────────────────────────────────────────────────────────────

def make_item(category, color, style, uid="user1", iid="i1"):
    return ClothingItem(
        id=iid, user_id=uid,
        category=category, color=color, style=style,
        image_url="https://example.com/img.jpg",
        cloudinary_public_id=f"styleai/wardrobe/{iid}",
        created_at=datetime.now(tz=timezone.utc),
    )

def mild_weather(city="Mumbai"):
    return WeatherData(city=city, temperature_c=24, condition="mild",
                       humidity=55, wind_kph=10, description="clear sky")


# ── Occasion style priority ───────────────────────────────────────────────

def test_all_occasions_have_priority_rules():
    for occ in ["office", "casual", "party", "wedding", "date", "gym", "travel"]:
        assert occ in OCCASION_STYLE_PRIORITY
        assert len(OCCASION_STYLE_PRIORITY[occ]) >= 1


def test_style_score_best_match_returns_1():
    score = style_score_for_occasion("formal", "office")
    assert score == 1.0


def test_style_score_second_match_less_than_first():
    first  = style_score_for_occasion("formal", "office")
    second = style_score_for_occasion("urban",  "office")
    assert first > second


def test_style_score_unknown_returns_low():
    score = style_score_for_occasion("ethnic", "gym")
    assert score <= 0.2


def test_style_score_unknown_occasion_fallback():
    score = style_score_for_occasion("casual", "picnic")
    assert score > 0  # falls back to casual priority


# ── Weather rules ─────────────────────────────────────────────────────────

def test_all_weather_conditions_have_rules():
    for cond in ["hot", "cold", "rainy", "mild", "warm", "humid"]:
        assert cond in WEATHER_RULES


def test_hot_weather_avoids_dark_colors():
    rules = get_weather_rules("hot")
    assert "black" in rules["avoid_colors"]
    assert rules["avoid_dark_colors"] is True


def test_rainy_weather_has_light_bottom_flag():
    rules = get_weather_rules("rainy")
    assert rules.get("avoid_light_bottom") is True


def test_cold_weather_restricts_sandals():
    rules = get_weather_rules("cold")
    assert "sandals" in rules["footwear_restrictions"]


def test_mild_weather_has_no_restrictions():
    rules = get_weather_rules("mild")
    assert rules["avoid_colors"] == []
    assert rules["footwear_restrictions"] == []


def test_unknown_condition_falls_back_to_mild():
    rules = get_weather_rules("tornado")
    mild  = get_weather_rules("mild")
    assert rules == mild


# ── Colour compatibility ──────────────────────────────────────────────────

@pytest.mark.parametrize("a,b,expected", [
    ("white", "navy",   True),
    ("black", "white",  True),
    ("navy",  "beige",  True),
    ("grey",  "pink",   True),
    ("white", "white",  True),   # same colour → monochrome ok
    ("red",   "green",  False),  # clash
    ("orange","purple", False),  # clash
])
def test_color_compatibility_matrix(a, b, expected):
    assert colors_compatible(a, b) == expected, f"{a}+{b} should be {expected}"


def test_color_compatibility_is_symmetric():
    assert colors_compatible("navy", "beige") == colors_compatible("beige", "navy")


def test_color_compatibility_case_insensitive():
    assert colors_compatible("White", "NAVY") == colors_compatible("white", "navy")


# ── Full outfit scoring ───────────────────────────────────────────────────

def test_score_returns_0_to_100():
    top      = make_item("top",      "white", "casual", iid="t1")
    bottom   = make_item("bottom",   "navy",  "casual", iid="b1")
    footwear = make_item("footwear", "white", "casual", iid="f1")
    score, explanations = score_combination(top, bottom, footwear, "casual", mild_weather())
    assert 0 <= score <= 100
    assert len(explanations) >= 1


def test_perfect_casual_outfit_scores_high():
    """White top + navy bottom + white shoes on a mild day for casual = high score."""
    top      = make_item("top",      "white", "casual", iid="t1")
    bottom   = make_item("bottom",   "navy",  "casual", iid="b1")
    footwear = make_item("footwear", "white", "casual", iid="f1")
    score, _ = score_combination(top, bottom, footwear, "casual", mild_weather())
    assert score >= 70, f"Expected >=70, got {score}"


def test_mismatched_style_outfit_scores_lower():
    """Ethnic top + formal bottom + casual shoes is an inconsistent combo."""
    top      = make_item("top",      "red",   "ethnic", iid="t2")
    bottom   = make_item("bottom",   "black", "formal", iid="b2")
    footwear = make_item("footwear", "white", "casual", iid="f2")
    score, _ = score_combination(top, bottom, footwear, "casual", mild_weather())
    assert score < 80


def test_hot_weather_penalises_black_top():
    top      = make_item("top",      "black", "casual", iid="t3")
    bottom   = make_item("bottom",   "navy",  "casual", iid="b3")
    footwear = make_item("footwear", "white", "casual", iid="f3")
    hot = WeatherData(city="Delhi", temperature_c=40, condition="hot",
                      humidity=30, wind_kph=5, description="sunny")
    score_hot, _ = score_combination(top, bottom, footwear, "casual", hot)

    mild = mild_weather()
    score_mild, _ = score_combination(top, bottom, footwear, "casual", mild)
    assert score_hot <= score_mild, "Black top should score worse in hot weather"


def test_formal_outfit_scores_well_for_office():
    top      = make_item("top",      "white", "formal", iid="t4")
    bottom   = make_item("bottom",   "black", "formal", iid="b4")
    footwear = make_item("footwear", "black", "formal", iid="f4")
    score, _ = score_combination(top, bottom, footwear, "office", mild_weather())
    assert score >= 75


def test_gym_outfit_with_ethnic_style_scores_low():
    top      = make_item("top",      "white", "ethnic", iid="t5")
    bottom   = make_item("bottom",   "white", "ethnic", iid="b5")
    footwear = make_item("footwear", "white", "ethnic", iid="f5")
    score, _ = score_combination(top, bottom, footwear, "gym", mild_weather())
    # Engine rewards colour harmony + style consistency even for a bad occasion fit.
    # Ethnic-only all-white outfit → occasion penalty pulls it below 75.
    assert score < 75, f"Ethnic outfit for gym should score below 75, got {score}"


def test_score_explanations_mention_occasion():
    top      = make_item("top",      "white", "casual", iid="t6")
    bottom   = make_item("bottom",   "navy",  "casual", iid="b6")
    footwear = make_item("footwear", "white", "casual", iid="f6")
    _, explanations = score_combination(top, bottom, footwear, "casual", mild_weather())
    full_text = " ".join(explanations).lower()
    assert "casual" in full_text


# ── User profile validation ───────────────────────────────────────────────

def test_onboarding_rejects_invalid_gender():
    from models.user import OnboardingData
    import pydantic
    with pytest.raises(pydantic.ValidationError):
        OnboardingData(
            gender="alien",
            age_range="25-34",
            city="Mumbai",
            style_preferences=["casual"],
        )


def test_onboarding_rejects_invalid_age_range():
    from models.user import OnboardingData
    import pydantic
    with pytest.raises(pydantic.ValidationError):
        OnboardingData(
            gender="male",
            age_range="0-5",
            city="Mumbai",
            style_preferences=["casual"],
        )


def test_onboarding_rejects_more_than_two_style_preferences():
    from models.user import OnboardingData
    import pydantic
    with pytest.raises(pydantic.ValidationError):
        OnboardingData(
            gender="male",
            age_range="25-34",
            city="Mumbai",
            style_preferences=["casual", "ethnic", "formal"],  # 3 → too many
        )


def test_onboarding_rejects_invalid_style():
    from models.user import OnboardingData
    import pydantic
    with pytest.raises(pydantic.ValidationError):
        OnboardingData(
            gender="female",
            age_range="18-24",
            city="Delhi",
            style_preferences=["hipster"],  # not in allowed set
        )


def test_onboarding_valid_data_passes():
    from models.user import OnboardingData
    data = OnboardingData(
        gender="female",
        age_range="25-34",
        city="Bangalore",
        style_preferences=["casual", "urban"],
    )
    assert data.gender == "female"
    assert data.city == "Bangalore"
