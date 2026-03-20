import logging
from datetime import date, datetime, timezone
from typing import Optional
from bson import ObjectId
from fastapi import HTTPException, status
from core.database import get_recommendations_collection
from core.redis_client import cache_get, cache_set, RECOMMENDATION_TTL
from models.user import UserDocument
from models.wardrobe import ClothingItem
from models.recommendation import OutfitRecommendation, WeatherContext
from services.wardrobe_service import get_user_wardrobe
from services.weather_service import get_weather_for_city
from engine.recommendation_engine import RecommendationEngine

logger = logging.getLogger(__name__)

_engine = RecommendationEngine()


# ---------------------------------------------------------------------------
# Serialisation helpers
# ---------------------------------------------------------------------------

def _item_to_dict(item: ClothingItem) -> dict:
    return {
        "id": item.id,
        "user_id": item.user_id,
        "category": item.category if isinstance(item.category, str) else item.category.value,
        "color": item.color,
        "style": item.style if isinstance(item.style, str) else item.style.value,
        "image_url": item.image_url,
        "cloudinary_public_id": item.cloudinary_public_id,
        "created_at": item.created_at.isoformat(),
    }


def _rec_to_dict(rec: OutfitRecommendation) -> dict:
    return {
        "id": rec.id,
        "user_id": rec.user_id,
        "top": _item_to_dict(rec.top),
        "bottom": _item_to_dict(rec.bottom),
        "footwear": _item_to_dict(rec.footwear),
        "occasion": rec.occasion,
        "weather_context": {
            "city": rec.weather_context.city,
            "temperature_c": rec.weather_context.temperature_c,
            "condition": rec.weather_context.condition,
            "humidity": rec.weather_context.humidity,
            "wind_kph": rec.weather_context.wind_kph,
        },
        "score": rec.score,
        "explanation": rec.explanation,
        "style_notes": rec.style_notes,
        "date": rec.date.isoformat(),
        "is_saved": rec.is_saved,
        "created_at": rec.created_at.isoformat(),
    }


def _dict_to_rec(data: dict) -> OutfitRecommendation:
    """Re-hydrate an OutfitRecommendation from a cached/stored dict."""
    for key in ("top", "bottom", "footwear"):
        data[key]["created_at"] = datetime.fromisoformat(data[key]["created_at"])
    data["date"] = date.fromisoformat(data["date"])
    data["created_at"] = datetime.fromisoformat(data["created_at"])
    data["weather_context"] = WeatherContext(**data["weather_context"])

    for key in ("top", "bottom", "footwear"):
        data[key] = ClothingItem(**data[key])

    return OutfitRecommendation(**data)


# ---------------------------------------------------------------------------
# Persistence helpers
# ---------------------------------------------------------------------------

async def _persist_recommendation(rec: OutfitRecommendation) -> None:
    """Save recommendation document to MongoDB."""
    col = get_recommendations_collection()
    doc = _rec_to_dict(rec)
    # Use the recommendation's own UUID as _id for easy retrieval
    doc["_id"] = doc.pop("id")
    try:
        await col.insert_one(doc)
    except Exception as e:
        logger.warning("Failed to persist recommendation %s: %s", rec.id, e)


# ---------------------------------------------------------------------------
# Public service functions
# ---------------------------------------------------------------------------

async def get_recommendation_by_id(rec_id: str) -> Optional[OutfitRecommendation]:
    """
    Fetch a single recommendation by its ID.
    Returns None if not found.
    """
    col = get_recommendations_collection()
    doc = await col.find_one({"_id": rec_id})
    if doc is None:
        return None
    doc["id"] = doc.pop("_id")
    try:
        return _dict_to_rec(doc)
    except Exception as e:
        logger.warning("Failed to deserialise recommendation %s: %s", rec_id, e)
        return None


async def get_today_recommendation(user: UserDocument) -> OutfitRecommendation:
    """
    Return today's outfit recommendation for the user.

    Check Redis first; on miss: generate, cache, and persist.
    """
    today_str = date.today().isoformat()
    cache_key = f"rec:{user.id}:{today_str}"

    cached = await cache_get(cache_key)
    if cached:
        logger.debug("Recommendation cache hit for user %s", user.id)
        return _dict_to_rec(cached)

    logger.debug("Recommendation cache miss for user %s — generating", user.id)

    wardrobe = await get_user_wardrobe(user.id)

    city = user.city or "Mumbai"
    weather = await get_weather_for_city(city)

    try:
        rec = _engine.generate_outfit(
            wardrobe=wardrobe,
            occasion="casual",
            weather=weather,
            user_preferences=user.style_preferences,
        )
        rec.user_id = user.id
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        )

    rec_dict = _rec_to_dict(rec)
    await cache_set(cache_key, rec_dict, ttl=RECOMMENDATION_TTL)
    await _persist_recommendation(rec)

    return rec


async def get_custom_recommendation(
    user: UserDocument,
    occasion: str,
    use_weather: bool,
) -> OutfitRecommendation:
    """
    Generate a fresh recommendation for a specific occasion.
    Never cached — always runs the engine.
    """
    wardrobe = await get_user_wardrobe(user.id)

    if use_weather:
        city = user.city or "Mumbai"
        weather = await get_weather_for_city(city)
    else:
        from core.weather_client import WeatherData
        weather = WeatherData(
            city=user.city or "Unknown",
            temperature_c=25.0,
            condition="mild",
            humidity=60,
            wind_kph=10.0,
            description="clear sky",
        )

    try:
        rec = _engine.generate_outfit(
            wardrobe=wardrobe,
            occasion=occasion,
            weather=weather,
            user_preferences=user.style_preferences,
        )
        rec.user_id = user.id
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        )

    await _persist_recommendation(rec)
    return rec


async def save_recommendation(user_id: str, rec_id: str) -> bool:
    """
    Toggle the is_saved flag on a recommendation to True.
    Returns True on success, raises 404 if not found.
    """
    col = get_recommendations_collection()
    result = await col.update_one(
        {"_id": rec_id, "user_id": user_id},
        {"$set": {"is_saved": True}},
    )
    if result.matched_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recommendation not found",
        )
    return True


async def get_saved_recommendations(
    user_id: str,
    limit: int = 20,
    offset: int = 0,
) -> list[OutfitRecommendation]:
    """Return saved/favourite recommendations for the user, with pagination."""
    col = get_recommendations_collection()
    cursor = (
        col.find({"user_id": user_id, "is_saved": True})
        .sort("created_at", -1)
        .skip(offset)
        .limit(limit)
    )
    results: list[OutfitRecommendation] = []
    async for doc in cursor:
        doc["id"] = doc.pop("_id")
        try:
            results.append(_dict_to_rec(doc))
        except Exception as e:
            logger.warning("Failed to deserialise recommendation %s: %s", doc.get("id"), e)
    return results
