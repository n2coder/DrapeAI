"""
Outfit scoring module.

`score_combination` evaluates a top + bottom + footwear triple against an
occasion and current weather, returning a 0-100 score and human-readable
explanations.
"""

from typing import Tuple, List
from models.wardrobe import ClothingItem
from core.weather_client import WeatherData
from engine.rules import (
    style_score_for_occasion,
    get_weather_rules,
    colors_compatible,
)

# ---------------------------------------------------------------------------
# Scoring weights (must sum to 1.0)
# ---------------------------------------------------------------------------
WEIGHT_OCCASION_FIT    = 0.35
WEIGHT_COLOR_HARMONY   = 0.30
WEIGHT_STYLE_CONSIST   = 0.25
WEIGHT_WEATHER_APPROP  = 0.10


def _occasion_fit_score(
    top: ClothingItem,
    bottom: ClothingItem,
    footwear: ClothingItem,
    occasion: str,
) -> Tuple[float, List[str]]:
    """Score 0-1 based on how well each piece's style suits the occasion."""
    top_s    = style_score_for_occasion(top.style if isinstance(top.style, str) else top.style.value, occasion)
    bottom_s = style_score_for_occasion(bottom.style if isinstance(bottom.style, str) else bottom.style.value, occasion)
    foot_s   = style_score_for_occasion(footwear.style if isinstance(footwear.style, str) else footwear.style.value, occasion)

    avg = (top_s + bottom_s + foot_s) / 3.0
    explanations: List[str] = []

    if avg >= 0.75:
        explanations.append(f"All pieces are well-suited for a {occasion} occasion.")
    elif avg >= 0.5:
        explanations.append(f"This outfit is a good match for {occasion}.")
    else:
        explanations.append(f"Some pieces may not be ideal for {occasion}, but the look can still work.")

    return avg, explanations


def _color_harmony_score(
    top: ClothingItem,
    bottom: ClothingItem,
    footwear: ClothingItem,
) -> Tuple[float, List[str]]:
    """Score 0-1 based on color compatibility between the three pieces."""
    top_color     = top.color.lower().strip()
    bottom_color  = bottom.color.lower().strip()
    foot_color    = footwear.color.lower().strip()

    tb_ok  = colors_compatible(top_color, bottom_color)
    tf_ok  = colors_compatible(top_color, foot_color)
    bf_ok  = colors_compatible(bottom_color, foot_color)

    matches = sum([tb_ok, tf_ok, bf_ok])
    score   = matches / 3.0

    explanations: List[str] = []
    if matches == 3:
        explanations.append(
            f"Great color harmony: {top_color}, {bottom_color}, and {foot_color} complement each other."
        )
    elif matches == 2:
        explanations.append("Good color pairing with minor tonal contrast.")
    else:
        explanations.append("Colours may clash — consider mixing in a neutral.")

    return score, explanations


def _style_consistency_score(
    top: ClothingItem,
    bottom: ClothingItem,
    footwear: ClothingItem,
) -> Tuple[float, List[str]]:
    """Score 0-1 based on how consistently styled the three pieces are."""
    styles = [
        top.style if isinstance(top.style, str) else top.style.value,
        bottom.style if isinstance(bottom.style, str) else bottom.style.value,
        footwear.style if isinstance(footwear.style, str) else footwear.style.value,
    ]
    unique_styles = set(styles)

    if len(unique_styles) == 1:
        score = 1.0
        explanation = f"Perfectly consistent {styles[0]} style throughout."
    elif len(unique_styles) == 2:
        score = 0.6
        explanation = "Lightly mixed aesthetic — creates an interesting contrast."
    else:
        score = 0.25
        explanation = "Mixed styles — may look eclectic; ensure it fits the vibe."

    return score, [explanation]


def _weather_appropriateness_score(
    top: ClothingItem,
    bottom: ClothingItem,
    footwear: ClothingItem,
    weather: WeatherData,
) -> Tuple[float, List[str]]:
    """Score 0-1 based on how well the outfit suits the current weather."""
    rules = get_weather_rules(weather.condition)
    penalties = 0
    explanations: List[str] = []

    top_color     = top.color.lower().strip()
    bottom_color  = bottom.color.lower().strip()
    foot_color    = footwear.color.lower().strip()

    avoid_colors: list = rules.get("avoid_colors", [])
    preferred_colors: list = rules.get("preferred_colors", [])
    footwear_restrictions: list = rules.get("footwear_restrictions", [])

    # Check avoided colors (top + bottom)
    if top_color in avoid_colors:
        penalties += 1
        explanations.append(
            f"A {top_color} top may be uncomfortable in {weather.condition} weather."
        )
    if bottom_color in avoid_colors:
        penalties += 1
    if rules.get("avoid_light_bottom") and bottom_color in ["white", "beige", "light_blue", "cream"]:
        penalties += 1
        explanations.append("Light-coloured bottoms are a risky choice in rainy conditions.")

    # Check footwear restrictions
    foot_style_val = footwear.style if isinstance(footwear.style, str) else footwear.style.value
    foot_color_lower = foot_color
    if any(r in foot_color_lower or r in foot_style_val for r in footwear_restrictions):
        penalties += 1
        explanations.append(
            f"Consider covered footwear for {weather.condition} weather."
        )

    # Bonus for preferred colors
    bonus = 0
    if top_color in preferred_colors or bottom_color in preferred_colors:
        bonus = 1
        explanations.append(f"Color choice suits {weather.condition} weather well.")

    raw = max(0, 3 - penalties + bonus)
    score = min(raw / 3.0, 1.0)

    if not explanations:
        explanations.append(f"Outfit is weather-appropriate for {weather.condition} conditions.")

    return score, explanations


def score_combination(
    top: ClothingItem,
    bottom: ClothingItem,
    footwear: ClothingItem,
    occasion: str,
    weather: WeatherData,
) -> Tuple[float, List[str]]:
    """
    Score an outfit combination.

    Returns:
        (score: float 0-100, explanations: list[str])
    """
    occ_score,   occ_exp   = _occasion_fit_score(top, bottom, footwear, occasion)
    color_score, color_exp = _color_harmony_score(top, bottom, footwear)
    style_score, style_exp = _style_consistency_score(top, bottom, footwear)
    wthr_score,  wthr_exp  = _weather_appropriateness_score(top, bottom, footwear, weather)

    weighted = (
        occ_score   * WEIGHT_OCCASION_FIT
        + color_score * WEIGHT_COLOR_HARMONY
        + style_score * WEIGHT_STYLE_CONSIST
        + wthr_score  * WEIGHT_WEATHER_APPROP
    )

    final_score = round(weighted * 100, 2)

    all_explanations: List[str] = []
    all_explanations.extend(occ_exp)
    all_explanations.extend(color_exp)
    all_explanations.extend(style_exp)
    all_explanations.extend(wthr_exp)

    return final_score, all_explanations
