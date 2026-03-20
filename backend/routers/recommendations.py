import logging
from fastapi import APIRouter, HTTPException, Query
from core.dependencies import CurrentUser
from models.recommendation import RecommendationRequest, RecommendationResponse
from services.recommendation_service import (
    get_today_recommendation,
    get_custom_recommendation,
    save_recommendation,
    get_saved_recommendations,
    get_recommendation_by_id,
)
from utils.response import success, error
from utils.validators import validate_occasion

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


@router.get("/today", summary="Get today's outfit recommendation")
async def today_recommendation(current_user: CurrentUser):
    """
    Return today's outfit recommendation for the authenticated user.
    Result is cached in Redis for RECOMMENDATION_TTL seconds (1 hour).
    Uses the user's saved city and a casual occasion by default.
    """
    if not current_user.onboarding_complete:
        return error(
            message="Please complete onboarding before requesting recommendations.",
            status_code=400,
        )

    try:
        rec = await get_today_recommendation(current_user)
    except HTTPException as exc:
        return error(message=exc.detail, status_code=exc.status_code)

    return success(
        data=RecommendationResponse.from_recommendation(rec).model_dump(mode="json"),
        message="Today's outfit recommendation",
    )


@router.post("/custom", summary="Get a custom outfit recommendation")
async def custom_recommendation(body: RecommendationRequest, current_user: CurrentUser):
    """
    Generate a fresh outfit recommendation for a specific occasion.
    Custom recommendations are never cached — always freshly computed.
    """
    if not current_user.onboarding_complete:
        return error(
            message="Please complete onboarding before requesting recommendations.",
            status_code=400,
        )

    occasion = body.occasion or "casual"
    try:
        validate_occasion(occasion)
    except HTTPException as exc:
        return error(message=exc.detail, status_code=exc.status_code)

    try:
        rec = await get_custom_recommendation(
            user=current_user,
            occasion=occasion,
            use_weather=body.use_current_weather,
        )
    except HTTPException as exc:
        return error(message=exc.detail, status_code=exc.status_code)

    return success(
        data=RecommendationResponse.from_recommendation(rec).model_dump(mode="json"),
        message=f"Custom outfit recommendation for '{occasion}'",
    )


@router.post("/{rec_id}/save", summary="Save / favourite a recommendation")
async def save_rec(rec_id: str, current_user: CurrentUser):
    """Mark a recommendation as saved (favourite)."""
    # Verify the recommendation belongs to the current user before saving
    existing = await get_recommendation_by_id(rec_id)
    if existing is None:
        return error(message="Recommendation not found", status_code=404)
    if existing.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorised to save this recommendation")

    try:
        await save_recommendation(user_id=current_user.id, rec_id=rec_id)
    except HTTPException as exc:
        return error(message=exc.detail, status_code=exc.status_code)

    return success(data={"rec_id": rec_id, "is_saved": True}, message="Recommendation saved")


@router.get("/saved", summary="Get saved / favourite recommendations")
async def saved_recommendations(
    current_user: CurrentUser,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """Return saved recommendations the user has marked as saved, with pagination."""
    recs = await get_saved_recommendations(
        user_id=current_user.id,
        limit=limit,
        offset=offset,
    )
    return success(
        data=[RecommendationResponse.from_recommendation(r).model_dump(mode="json") for r in recs],
        message=f"Retrieved {len(recs)} saved recommendation(s)",
    )
