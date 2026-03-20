"""
Outfit Recommendation Engine.

Given a user's wardrobe, occasion, and weather context, produces the best
scoring outfit combination.
"""

import random
import uuid
from datetime import date
from typing import List, Optional
from models.wardrobe import ClothingItem, Category
from models.recommendation import OutfitRecommendation, WeatherContext
from core.weather_client import WeatherData
from engine.rules import get_style_priority
from engine.scoring import score_combination

MAX_CANDIDATES = 50


class RecommendationEngine:
    """Rule-based outfit recommendation engine."""

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def generate_outfit(
        self,
        wardrobe: List[ClothingItem],
        occasion: str,
        weather: WeatherData,
        user_preferences: Optional[List[str]] = None,
    ) -> OutfitRecommendation:
        """
        Generate the best outfit from the user's wardrobe.

        Args:
            wardrobe:          Full list of the user's clothing items.
            occasion:          One of the supported occasion strings.
            weather:           Current weather data object.
            user_preferences:  Optional list of user style preferences (up to 2).

        Returns:
            OutfitRecommendation with the best scoring combination.

        Raises:
            ValueError: If any clothing category is missing from the wardrobe.
        """
        tops      = [i for i in wardrobe if self._category_value(i) == "top"]
        bottoms   = [i for i in wardrobe if self._category_value(i) == "bottom"]
        footwears = [i for i in wardrobe if self._category_value(i) == "footwear"]

        if not tops:
            raise ValueError("Wardrobe incomplete: no tops found. Please add at least one top.")
        if not bottoms:
            raise ValueError("Wardrobe incomplete: no bottoms found. Please add at least one bottom.")
        if not footwears:
            raise ValueError("Wardrobe incomplete: no footwear found. Please add at least one pair of footwear.")

        # Pre-filter: prefer items whose style matches the occasion
        tops      = self._ranked_by_occasion(tops, occasion)
        bottoms   = self._ranked_by_occasion(bottoms, occasion)
        footwears = self._ranked_by_occasion(footwears, occasion)

        # Build candidate combinations (up to MAX_CANDIDATES)
        candidates = self._sample_candidates(tops, bottoms, footwears)

        # Score every candidate
        scored: List[tuple] = []
        for top, bottom, footwear in candidates:
            sc, explanations = score_combination(top, bottom, footwear, occasion, weather)
            scored.append((sc, explanations, top, bottom, footwear))

        # Sort descending by score
        scored.sort(key=lambda x: x[0], reverse=True)

        best_score, best_exp, best_top, best_bottom, best_footwear = scored[0]

        weather_ctx = WeatherContext(
            city=weather.city,
            temperature_c=weather.temperature_c,
            condition=weather.condition,
            humidity=weather.humidity,
            wind_kph=weather.wind_kph,
        )

        style_notes = self.generate_style_notes(occasion, weather)

        return OutfitRecommendation(
            id=str(uuid.uuid4()),
            user_id=best_top.user_id,
            top=best_top,
            bottom=best_bottom,
            footwear=best_footwear,
            occasion=occasion,
            weather_context=weather_ctx,
            score=best_score,
            explanation=best_exp,
            style_notes=style_notes,
            date=date.today(),
            is_saved=False,
        )

    def generate_style_notes(self, occasion: str, weather: WeatherData) -> str:
        """Return a short, human-readable style tip for the occasion + weather."""
        tips = {
            "office": "Keep it polished — tuck in your top and opt for closed-toe shoes.",
            "casual": "Relax and express yourself. Comfort is the priority.",
            "party":  "Go bold! A statement piece elevates any party look.",
            "wedding":"Honour the occasion with elegant, well-fitted attire.",
            "date":   "Smart-casual strikes the perfect balance — put-together yet approachable.",
            "gym":    "Prioritise stretch and breathability over style today.",
            "travel": "Layer smart — comfort for the journey, style at the destination.",
        }
        base_tip = tips.get(occasion, "Dress for confidence and comfort.")

        weather_addendum = {
            "hot":   " Opt for light, breathable fabrics to stay cool.",
            "cold":  " Layer up — warmth is as important as style today.",
            "rainy": " Waterproof your look; avoid delicate fabrics.",
            "humid": " Choose breathable materials and avoid heavy layering.",
            "warm":  " Light colours will keep you feeling fresh.",
            "mild":  " Perfect weather — almost anything goes!",
        }
        suffix = weather_addendum.get(weather.condition, "")
        return base_tip + suffix

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _category_value(item: ClothingItem) -> str:
        return item.category if isinstance(item.category, str) else item.category.value

    @staticmethod
    def _style_value(item: ClothingItem) -> str:
        return item.style if isinstance(item.style, str) else item.style.value

    def _ranked_by_occasion(
        self, items: List[ClothingItem], occasion: str
    ) -> List[ClothingItem]:
        """Sort items so that styles preferred for this occasion come first."""
        priority = get_style_priority(occasion)
        priority_index = {s: i for i, s in enumerate(priority)}

        def _key(item: ClothingItem) -> int:
            return priority_index.get(self._style_value(item), len(priority))

        return sorted(items, key=_key)

    def _sample_candidates(
        self,
        tops: List[ClothingItem],
        bottoms: List[ClothingItem],
        footwears: List[ClothingItem],
    ) -> List[tuple]:
        """
        Generate up to MAX_CANDIDATES (top, bottom, footwear) triples.

        Strategy:
          - Take the top-N items from each category (preference-ordered).
          - Build the full Cartesian product if it fits within MAX_CANDIDATES,
            otherwise sample intelligently.
        """
        total = len(tops) * len(bottoms) * len(footwears)

        if total <= MAX_CANDIDATES:
            # Full product
            candidates = [
                (t, b, f) for t in tops for b in bottoms for f in footwears
            ]
        else:
            # Sample from the top-ranked items in each category
            n = max(1, int(MAX_CANDIDATES ** (1 / 3)) + 1)
            sampled_tops      = tops[:min(n * 2, len(tops))]
            sampled_bottoms   = bottoms[:min(n * 2, len(bottoms))]
            sampled_footwears = footwears[:min(n * 2, len(footwears))]

            all_combos = [
                (t, b, f)
                for t in sampled_tops
                for b in sampled_bottoms
                for f in sampled_footwears
            ]
            candidates = random.sample(all_combos, min(MAX_CANDIDATES, len(all_combos)))

        return candidates
