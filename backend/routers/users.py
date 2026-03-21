import logging
import re
from fastapi import APIRouter, HTTPException, Query, Depends
from bson import ObjectId
from core.database import get_users_collection
from core.dependencies import CurrentUser
from core.gdpr import delete_user_data, export_user_data
from core.weather_client import get_weather
from models.user import OnboardingData, UserResponse, UserUpdate
from utils.response import success, error

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/users", tags=["Users"])


def _strip_html(value: str) -> str:
    """Remove HTML tags from a string to prevent XSS injection."""
    return re.sub(r"<[^>]+>", "", value)


@router.get("/weather", summary="Get weather for a city")
async def get_weather_for_city(
    current_user: CurrentUser,
    city: str = Query(..., description="City name"),
):
    """Fetch current weather for the given city via OpenWeatherMap."""
    try:
        weather = await get_weather(city)
        return success(data={
            "temperature": weather.temperature_c,
            "description": weather.description,
            "icon": "01d",
            "cityName": weather.city,
            "feelsLike": weather.temperature_c,
            "humidity": weather.humidity,
            "windSpeed": weather.wind_kph,
            "condition": weather.condition,
        }, message="Weather fetched")
    except Exception as exc:
        logger.warning("Weather fetch failed for city %s: %s", city, exc)
        return error(message=f"Could not fetch weather for '{city}'", status_code=404)


@router.get("/profile", summary="Get current user profile")
async def get_profile(current_user: CurrentUser):
    """Return the authenticated user's profile."""
    return success(
        data=UserResponse.from_document(current_user).model_dump(mode="json"),
        message="Profile retrieved",
    )


@router.post("/onboarding", summary="Submit onboarding data")
async def complete_onboarding(body: OnboardingData, current_user: CurrentUser):
    """
    Save the user's gender, age range, city, and style preferences collected
    during the onboarding flow. Marks onboarding_complete = True.
    """
    col = get_users_collection()
    oid = ObjectId(current_user.id)

    update_fields = {
        "gender": body.gender,
        "age_range": body.age_range,
        "city": body.city,
        "style_preferences": body.style_preferences,
        "onboarding_complete": True,
    }

    await col.update_one({"_id": oid}, {"$set": update_fields})

    # Re-fetch updated document
    raw = await col.find_one({"_id": oid})
    raw["id"] = str(raw.pop("_id"))
    from models.user import UserDocument
    updated_user = UserDocument(**raw)

    logger.info("Onboarding completed for user %s", current_user.id)
    return success(
        data=UserResponse.from_document(updated_user).model_dump(mode="json"),
        message="Onboarding completed successfully",
    )


@router.put("/profile", summary="Update user profile")
async def update_profile(body: UserUpdate, current_user: CurrentUser):
    """
    Update mutable profile fields (name, city).
    Only provided (non-null) fields will be updated.
    """
    col = get_users_collection()
    oid = ObjectId(current_user.id)

    update_fields: dict = {}
    if body.name is not None:
        name = _strip_html(body.name.strip())
        if len(name) > 100:
            return error(message="Name must not exceed 100 characters", status_code=400)
        update_fields["name"] = name
    if body.city is not None:
        city = _strip_html(body.city.strip())
        if len(city) > 100:
            return error(message="City must not exceed 100 characters", status_code=400)
        update_fields["city"] = city

    if not update_fields:
        return error(message="No fields to update provided", status_code=400)

    await col.update_one({"_id": oid}, {"$set": update_fields})

    raw = await col.find_one({"_id": oid})
    raw["id"] = str(raw.pop("_id"))
    from models.user import UserDocument
    updated_user = UserDocument(**raw)

    # Log only user ID — never log name or phone
    logger.info("Profile updated for user %s: fields=%s", current_user.id, list(update_fields.keys()))
    return success(
        data=UserResponse.from_document(updated_user).model_dump(mode="json"),
        message="Profile updated successfully",
    )


@router.delete("/me", summary="Delete account and all associated data (GDPR)")
async def delete_account(current_user: CurrentUser):
    """
    Permanently delete the authenticated user's account and all associated data.
    This satisfies the GDPR right to erasure (Article 17).
    """
    try:
        summary = await delete_user_data(current_user.id)
    except Exception as exc:
        logger.error("Failed to delete data for user %s: %s", current_user.id, exc)
        return error(message="Failed to delete account data", status_code=500)

    logger.info("Account deleted for user %s", current_user.id)
    return success(data=summary, message="Account and all associated data deleted successfully")


@router.get("/me/export", summary="Export all personal data (GDPR)")
async def export_data(current_user: CurrentUser):
    """
    Export all personal data held for the authenticated user.
    This satisfies the GDPR right of access (Article 15).
    """
    try:
        data = await export_user_data(current_user.id)
    except Exception as exc:
        logger.error("Failed to export data for user %s: %s", current_user.id, exc)
        return error(message="Failed to export account data", status_code=500)

    return success(data=data, message="Personal data export")
