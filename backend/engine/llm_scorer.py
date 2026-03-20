"""
Option B — LLM Outfit Reasoning.

Takes the top-N outfit candidates from the rule-based engine and asks
GPT-4o to reason about them like a professional fashion stylist.

Returns the best outfit index + an AI-generated score, explanation,
and style notes. Falls back to rule-based results if OpenAI is unavailable.
"""

import json
import logging
from typing import List, Optional, Tuple

from models.wardrobe import ClothingItem
from core.weather_client import WeatherData
from core.openai_client import get_openai_client

logger = logging.getLogger(__name__)

_SYSTEM_PROMPT = """You are an expert fashion stylist AI. You will be given a list of outfit candidates
(each is a combination of top, bottom, and footwear) along with the occasion and current weather.

Your job is to:
1. Pick the BEST outfit for the occasion and weather
2. Give it a score from 0–100 reflecting how well it fits
3. Write 2–3 sentences explaining why it works
4. Add a short, actionable style tip

For each clothing item you will receive:
- category (top/bottom/footwear)
- color
- style tag (casual/formal/urban/ethnic)
- fabric_type, pattern, formality_level, fit_type (from AI vision — may be null)

Consider:
- Color harmony and coordination
- Style consistency (do the pieces work together aesthetically?)
- Occasion appropriateness (is this formal enough? too formal?)
- Weather suitability (fabric/color for temperature and conditions)
- Overall visual balance and modern fashion sensibility

Return ONLY a raw JSON object with this exact structure:
{
  "best_index": <integer, 0-based index of best outfit from the candidates list>,
  "score": <integer 0-100>,
  "explanation": "<2-3 sentence explanation of why this outfit works>",
  "style_tip": "<one actionable styling tip, e.g. accessory suggestion, tuck recommendation>",
  "color_note": "<brief note on the color story of this outfit>"
}
"""


def _item_summary(item: ClothingItem) -> dict:
    """Compact representation of a clothing item for the LLM prompt."""
    ai = item.ai_attributes or {}
    return {
        "category": item.category if isinstance(item.category, str) else item.category.value,
        "color": item.color,
        "style": item.style if isinstance(item.style, str) else item.style.value,
        "fabric": ai.get("fabric_type"),
        "pattern": ai.get("pattern"),
        "formality": ai.get("formality_level"),
        "fit": ai.get("fit_type"),
        "ai_color": ai.get("detected_color"),  # Vision-detected color may be more precise
    }


async def llm_score_candidates(
    candidates: List[Tuple[ClothingItem, ClothingItem, ClothingItem]],
    occasion: str,
    weather: WeatherData,
) -> Optional[dict]:
    """
    Ask GPT-4o to rank outfit candidates and pick the best one.

    Args:
        candidates: List of (top, bottom, footwear) tuples — max 5 recommended.
        occasion:   The target occasion string.
        weather:    Current weather data.

    Returns:
        Dict with keys: best_index, score, explanation, style_tip, color_note
        Returns None if OpenAI is unavailable or the call fails.
    """
    client = get_openai_client()
    if client is None:
        return None

    # Build the candidate descriptions for the prompt
    candidate_list = []
    for i, (top, bottom, footwear) in enumerate(candidates):
        candidate_list.append({
            "index": i,
            "top": _item_summary(top),
            "bottom": _item_summary(bottom),
            "footwear": _item_summary(footwear),
        })

    user_message = {
        "occasion": occasion,
        "weather": {
            "condition": weather.condition,
            "temperature_c": weather.temperature_c,
            "description": weather.description,
        },
        "candidates": candidate_list,
    }

    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=500,
            temperature=0.3,
            messages=[
                {"role": "system", "content": _SYSTEM_PROMPT},
                {"role": "user", "content": json.dumps(user_message)},
            ],
        )

        raw = response.choices[0].message.content.strip()

        # Strip markdown fences if present
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]

        result = json.loads(raw)

        # Validate best_index is in range
        if not (0 <= result.get("best_index", -1) < len(candidates)):
            result["best_index"] = 0

        logger.info(
            "LLM scorer picked candidate %d with score %s",
            result["best_index"],
            result.get("score"),
        )
        return result

    except json.JSONDecodeError as e:
        logger.warning("LLM scorer returned invalid JSON: %s", e)
        return None
    except Exception as e:
        logger.warning("LLM scoring failed: %s", e)
        return None
