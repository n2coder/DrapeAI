"""
Outfit Recommendation Engine — AI-enhanced.

Pipeline:
  1. Filter wardrobe into tops / bottoms / footwear
  2. Pre-rank by occasion style priority (rule-based)
  3. Build candidate combinations (up to MAX_CANDIDATES)
  4. Score every candidate with the rule-based scorer
  5. Take the top-5 rule-scored candidates to the LLM scorer (GPT-4o)
  6. LLM picks the best, returns score + explanation + style tip
  7. Fall back to rule-based #1 if LLM is unavailable
"""

import random
import uuid
from datetime import date
from typing import List, Optional, Tuple
from models.wardrobe import ClothingItem, Category
from models.recommendation import OutfitRecommendation, WeatherContext
from core.weather_client import WeatherData
from engine.rules import get_style_priority
from engine.scoring import score_combination
from engine.llm_scorer import llm_score_candidates

MAX_CANDIDATES = 50
LLM_TOP_N = 5   # How many rule-scored finalists to send to the LLM


class RecommendationEngine:
    """AI-enhanced outfit recommendation engine (rule-based pre-filter + GPT-4o final pick)."""

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def generate_outfit(
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
            user_preferences:  Optional list of user style preferences.

        Returns:
            OutfitRecommendation with AI-selected best combination.

        Raises:
            ValueError: If any required clothing category is missing.
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

        # Step 1 — pre-rank by occasion
        tops      = self._ranked_by_occasion(tops, occasion)
        bottoms   = self._ranked_by_occasion(bottoms, occasion)
        footwears = self._ranked_by_occasion(footwears, occasion)

        # Step 2 — build candidate pool
        candidates = self._sample_candidates(tops, bottoms, footwears)

        # Step 3 — rule-based scoring of all candidates
        scored: List[tuple] = []
        for top, bottom, footwear in candidates:
            sc, explanations = score_combination(top, bottom, footwear, occasion, weather)
            scored.append((sc, explanations, top, bottom, footwear))

        scored.sort(key=lambda x: x[0], reverse=True)

        # Step 4 — send top-N finalists to GPT-4o for intelligent final ranking
        finalists: List[Tuple[ClothingItem, ClothingItem, ClothingItem]] = [
            (s[2], s[3], s[4]) for s in scored[:LLM_TOP_N]
        ]

        llm_result = await llm_score_candidates(finalists, occasion, weather)

        if llm_result:
            best_idx   = llm_result["best_index"]
            best_score = float(llm_result.get("score", scored[best_idx][0]))
            best_top, best_bottom, best_footwear = finalists[best_idx]

            # Build rich AI explanation
            parts = []
            if llm_result.get("explanation"):
                parts.append(llm_result["explanation"])
            if llm_result.get("color_note"):
                parts.append(llm_result["color_note"])
            best_explanations = parts if parts else scored[best_idx][1]

            style_notes = llm_result.get("style_tip") or self.generate_style_notes(occasion, weather)
            engine_used = "gpt-4o-mini"
        else:
            # Graceful fallback to rule-based #1
            best_score, best_explanations, best_top, best_bottom, best_footwear = scored[0]
            style_notes = self.generate_style_notes(occasion, weather)
            engine_used = "rule-based"

        weather_ctx = WeatherContext(
            city=weather.city,
            temperature_c=weather.temperature_c,
            condition=weather.condition,
            humidity=weather.humidity,
            wind_kph=weather.wind_kph,
        )

        return OutfitRecommendation(
            id=str(uuid.uuid4()),
            user_id=best_top.user_id,
            top=best_top,
            bottom=best_bottom,
            footwear=best_footwear,
            occasion=occasion,
            weather_context=weather_ctx,
            score=best_score,
            explanation=best_explanations,
            style_notes=f"[{engine_used}] {style_notes}",
            date=date.today(),
            is_saved=False,
        )

    def generate_style_notes(self, occasion: str, weather: WeatherData) -> str:
        tips = {
            "office":  "Keep it polished — tuck in your top and opt for closed-toe shoes.",
            "casual":  "Relax and express yourself. Comfort is the priority.",
            "party":   "Go bold! A statement piece elevates any party look.",
            "wedding": "Honour the occasion with elegant, well-fitted attire.",
            "date":    "Smart-casual strikes the perfect balance — put-together yet approachable.",
            "gym":     "Prioritise stretch and breathability over style today.",
            "travel":  "Layer smart — comfort for the journey, style at the destination.",
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
        return base_tip + weather_addendum.get(weather.condition, "")

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _category_value(item: ClothingItem) -> str:
        return item.category if isinstance(item.category, str) else item.category.value

    @staticmethod
    def _style_value(item: ClothingItem) -> str:
        return item.style if isinstance(item.style, str) else item.style.value

    def _ranked_by_occasion(self, items: List[ClothingItem], occasion: str) -> List[ClothingItem]:
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
        total = len(tops) * len(bottoms) * len(footwears)
        if total <= MAX_CANDIDATES:
            return [(t, b, f) for t in tops for b in bottoms for f in footwears]

        n = max(1, int(MAX_CANDIDATES ** (1 / 3)) + 1)
        st = tops[:min(n * 2, len(tops))]
        sb = bottoms[:min(n * 2, len(bottoms))]
        sf = footwears[:min(n * 2, len(footwears))]
        all_combos = [(t, b, f) for t in st for b in sb for f in sf]
        return random.sample(all_combos, min(MAX_CANDIDATES, len(all_combos)))
