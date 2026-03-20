"""
Outfit recommendation rule sets.

Defines:
  - OCCASION_STYLE_PRIORITY  — ordered list of preferred styles per occasion
  - WEATHER_RULES            — constraints / flags per weather condition
  - COLOR_COMPATIBILITY      — compatible color pairings matrix
"""

from typing import Dict, List


# ---------------------------------------------------------------------------
# Occasion → Style priority
# Index 0 is most preferred. Lower index = higher preference weight.
# ---------------------------------------------------------------------------
OCCASION_STYLE_PRIORITY: Dict[str, List[str]] = {
    "office":  ["formal", "urban", "casual"],
    "casual":  ["casual", "urban"],
    "party":   ["urban", "casual", "formal"],
    "wedding": ["ethnic", "formal"],
    "date":    ["casual", "urban"],
    "gym":     ["casual"],
    "travel":  ["casual", "urban"],
}

# Default to casual if unknown occasion is supplied
DEFAULT_OCCASION = "casual"


def get_style_priority(occasion: str) -> List[str]:
    """Return ordered style list for an occasion (falls back to casual)."""
    return OCCASION_STYLE_PRIORITY.get(occasion, OCCASION_STYLE_PRIORITY[DEFAULT_OCCASION])


def style_score_for_occasion(style: str, occasion: str) -> float:
    """
    Return a 0-1 score for how well a style matches an occasion.
    First place → 1.0, second → 0.65, third → 0.35, not listed → 0.1
    """
    priority = get_style_priority(occasion)
    score_map = {s: max(1.0 - i * 0.35, 0.1) for i, s in enumerate(priority)}
    return score_map.get(style, 0.1)


# ---------------------------------------------------------------------------
# Weather rules
# Each condition maps to a dict of flags used by the scoring / filtering layer.
# ---------------------------------------------------------------------------
WEATHER_RULES: Dict[str, Dict] = {
    "hot": {
        "prefer_light_colors": True,
        "avoid_dark_colors": True,
        "avoid_heavy_styles": ["formal"],
        "preferred_colors": ["white", "beige", "light_blue", "grey", "pink", "yellow"],
        "avoid_colors": ["black", "navy", "dark_brown"],
        "footwear_restrictions": [],
        "description": "Hot weather — light colours and breathable fabrics recommended.",
    },
    "cold": {
        "prefer_light_colors": False,
        "avoid_dark_colors": False,
        "avoid_heavy_styles": [],
        "preferred_colors": ["black", "navy", "grey", "brown", "dark_green"],
        "avoid_colors": [],
        "footwear_restrictions": ["sandals", "flip_flops", "slippers"],
        "description": "Cold weather — warm tones and covered footwear recommended.",
    },
    "rainy": {
        "prefer_light_colors": False,
        "avoid_dark_colors": False,
        "avoid_heavy_styles": [],
        "preferred_colors": ["black", "navy", "grey", "dark_green"],
        "avoid_colors": ["white", "beige", "light_blue"],   # stain-prone for bottoms
        "footwear_restrictions": ["sandals", "open_toe", "canvas"],
        "avoid_light_bottom": True,
        "description": "Rainy weather — darker bottoms and covered footwear recommended.",
    },
    "mild": {
        "prefer_light_colors": False,
        "avoid_dark_colors": False,
        "avoid_heavy_styles": [],
        "preferred_colors": [],
        "avoid_colors": [],
        "footwear_restrictions": [],
        "description": "Mild weather — no restrictions, any outfit works.",
    },
    "warm": {
        "prefer_light_colors": True,
        "avoid_dark_colors": False,
        "avoid_heavy_styles": [],
        "preferred_colors": ["white", "beige", "light_blue", "grey", "pink"],
        "avoid_colors": [],
        "footwear_restrictions": [],
        "description": "Warm weather — lighter colours preferred.",
    },
    "humid": {
        "prefer_light_colors": True,
        "avoid_dark_colors": True,
        "avoid_heavy_styles": ["formal"],
        "preferred_colors": ["white", "beige", "light_blue", "grey"],
        "avoid_colors": ["black", "navy"],
        "footwear_restrictions": [],
        "description": "Humid weather — breathable light fabrics recommended.",
    },
}


def get_weather_rules(condition: str) -> Dict:
    """Return weather rules for a condition (falls back to mild)."""
    return WEATHER_RULES.get(condition, WEATHER_RULES["mild"])


# ---------------------------------------------------------------------------
# Color compatibility matrix
# Maps a color to the list of colors it pairs well with.
# "any" means it is a neutral and goes with everything.
# ---------------------------------------------------------------------------
COLOR_COMPATIBILITY: Dict[str, List[str]] = {
    "white":       ["navy", "black", "grey", "beige", "brown", "blue", "green", "red", "pink", "any"],
    "black":       ["white", "grey", "beige", "red", "pink", "gold", "silver", "any"],
    "navy":        ["white", "beige", "grey", "light_blue", "gold", "silver"],
    "grey":        ["white", "black", "navy", "blue", "pink", "any"],
    "beige":       ["white", "navy", "brown", "olive", "black", "grey"],
    "brown":       ["white", "beige", "olive", "cream", "navy", "tan"],
    "blue":        ["white", "grey", "beige", "navy", "light_blue", "denim"],
    "light_blue":  ["white", "navy", "grey", "beige", "denim"],
    "denim":       ["white", "black", "grey", "beige", "red", "pink", "light_blue"],
    "red":         ["white", "black", "grey", "navy", "denim"],
    "pink":        ["white", "grey", "black", "navy", "beige"],
    "green":       ["white", "beige", "brown", "olive", "navy", "grey"],
    "olive":       ["white", "beige", "brown", "denim", "khaki"],
    "yellow":      ["white", "navy", "grey", "black", "denim"],
    "orange":      ["white", "navy", "black", "denim", "grey"],
    "purple":      ["white", "grey", "black", "beige"],
    "cream":       ["brown", "navy", "olive", "beige", "black"],
    "gold":        ["black", "navy", "white", "brown"],
    "silver":      ["black", "white", "grey", "navy"],
    "tan":         ["brown", "white", "navy", "beige", "olive"],
    "khaki":       ["white", "navy", "olive", "brown", "beige"],
    "any":         [],   # universal neutral — compatible with everything
}

# Normalise all color names to lowercase for comparison
COLOR_COMPATIBILITY = {k.lower(): [v.lower() for v in vals] for k, vals in COLOR_COMPATIBILITY.items()}


def colors_compatible(color_a: str, color_b: str) -> bool:
    """Return True if color_a and color_b are considered a compatible pair."""
    a = color_a.lower().strip()
    b = color_b.lower().strip()

    if a == b:
        return True  # Same color (monochrome) is acceptable

    # Either is a universal neutral
    if "any" in COLOR_COMPATIBILITY.get(a, []) or "any" in COLOR_COMPATIBILITY.get(b, []):
        return True

    compatible_with_a = COLOR_COMPATIBILITY.get(a, [])
    compatible_with_b = COLOR_COMPATIBILITY.get(b, [])

    return b in compatible_with_a or a in compatible_with_b
