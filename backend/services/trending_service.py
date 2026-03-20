"""
Trending Outfit Combos Service.

Pipeline:
  1. Ask GPT-4o-mini for trending outfit style combos that work with the user's
     available wardrobe colors / styles.
  2. For each trending combo, fetch 2-3 free reference images from Pexels.
  3. Return a list of TrendingCombo dicts to include in recommendation responses.

Each TrendingCombo:
  {
    "title":            str,
    "description":      str,
    "wardrobe_match":   str,   # which wardrobe items match this trend
    "tags":             [str],
    "reference_images": [str], # Pexels image URLs
  }
"""

import json
import logging
from typing import Optional

import httpx

from core.config import settings
from core.openai_client import get_openai_client
from models.wardrobe import ClothingItem

logger = logging.getLogger(__name__)

PEXELS_SEARCH_URL = "https://api.pexels.com/v1/search"
MAX_COMBOS = 3
PEXELS_IMAGES_PER_COMBO = 2


# ── GPT-4o trend analysis ─────────────────────────────────────────────────────

_TREND_PROMPT = """You are a fashion trend analyst with deep knowledge of current global style trends.
Given the user's wardrobe summary and occasion, suggest {n} trending outfit combo styles
that can be assembled (fully or partially) from their existing wardrobe.

Return ONLY a raw JSON array (no markdown):
[
  {{
    "title": "<short trend name, e.g. 'Coastal Grandpa'>",
    "description": "<2-sentence description of the trend and why it works>",
    "wardrobe_match": "<which of their items can be used for this look, e.g. 'white top + navy trousers + white sneakers'>",
    "tags": ["<tag1>", "<tag2>", "<tag3>"],
    "pexels_query": "<3-5 word search phrase for Pexels, e.g. 'coastal grandpa fashion street style'>"
  }}
]"""


async def _ask_llm_for_trends(
    wardrobe_summary: str,
    occasion: str,
    weather_condition: str,
) -> list[dict]:
    client = get_openai_client()
    if client is None:
        return []

    try:
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=800,
            temperature=0.7,
            messages=[
                {
                    "role": "system",
                    "content": _TREND_PROMPT.format(n=MAX_COMBOS),
                },
                {
                    "role": "user",
                    "content": (
                        f"Occasion: {occasion}\n"
                        f"Weather: {weather_condition}\n"
                        f"Wardrobe summary:\n{wardrobe_summary}"
                    ),
                },
            ],
        )
        raw = resp.choices[0].message.content.strip()
        if raw.startswith("```"):
            raw = raw.split("```")[1].lstrip("json").strip()
        combos = json.loads(raw)
        return combos if isinstance(combos, list) else []
    except Exception as e:
        logger.warning("Trending LLM call failed: %s", e)
        return []


# ── Pexels image fetcher ──────────────────────────────────────────────────────

async def _fetch_pexels_images(query: str, count: int = PEXELS_IMAGES_PER_COMBO) -> list[str]:
    """Search Pexels and return a list of medium-sized image URLs."""
    api_key = settings.pexels_api_key
    if not api_key:
        return []

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.get(
                PEXELS_SEARCH_URL,
                params={"query": query, "per_page": count, "orientation": "portrait"},
                headers={"Authorization": api_key},
            )
            resp.raise_for_status()
            photos = resp.json().get("photos", [])
            return [p["src"]["medium"] for p in photos if "src" in p]
    except Exception as e:
        logger.warning("Pexels fetch failed for query '%s': %s", query, e)
        return []


# ── Wardrobe summariser ───────────────────────────────────────────────────────

def _summarise_wardrobe(wardrobe: list[ClothingItem]) -> str:
    """
    Build a compact text summary of the wardrobe for the LLM prompt.
    Groups items by category and lists color + style.
    """
    by_cat: dict[str, list[str]] = {"top": [], "bottom": [], "footwear": []}
    for item in wardrobe:
        cat = item.category if isinstance(item.category, str) else item.category.value
        style = item.style if isinstance(item.style, str) else item.style.value
        if cat in by_cat:
            by_cat[cat].append(f"{item.color} {style}")

    lines = []
    for cat, items in by_cat.items():
        if items:
            lines.append(f"{cat.capitalize()}s: {', '.join(items)}")
    return "\n".join(lines) if lines else "No items in wardrobe"


# ── Main entry point ──────────────────────────────────────────────────────────

async def get_trending_combos(
    wardrobe: list[ClothingItem],
    occasion: str,
    weather_condition: str,
) -> list[dict]:
    """
    Generate trending outfit combo suggestions with Pexels reference images.

    Returns a list of dicts:
      title, description, wardrobe_match, tags, reference_images
    """
    if not wardrobe:
        return []

    summary = _summarise_wardrobe(wardrobe)
    combos = await _ask_llm_for_trends(summary, occasion, weather_condition)

    if not combos:
        return []

    # Enrich each combo with Pexels reference images
    results = []
    for combo in combos[:MAX_COMBOS]:
        query = combo.get("pexels_query", combo.get("title", "fashion outfit"))
        images = await _fetch_pexels_images(query)
        results.append(
            {
                "title": combo.get("title", ""),
                "description": combo.get("description", ""),
                "wardrobe_match": combo.get("wardrobe_match", ""),
                "tags": combo.get("tags", []),
                "reference_images": images,
            }
        )

    logger.info("Generated %d trending combos for occasion=%s", len(results), occasion)
    return results
