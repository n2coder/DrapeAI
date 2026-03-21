import logging
from typing import Optional
from fastapi import APIRouter, Query, HTTPException, status
from core.dependencies import CurrentUser
from models.wardrobe import ClothingItemAddRequest, ClothingItemUpdate, ClothingItemResponse
from services.wardrobe_service import (
    get_user_wardrobe,
    add_clothing_item_from_url,
    update_clothing_item,
    delete_clothing_item,
    get_wardrobe_item_by_id,
)
from utils.response import success, error

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/wardrobe", tags=["Wardrobe"])


@router.post("/add", summary="Add a clothing item to wardrobe")
async def add_item(
    body: ClothingItemAddRequest,
    current_user: CurrentUser,
):
    """
    Add a clothing item using a Cloudinary URL (Flutter uploads the image
    directly to Cloudinary and sends the resulting URL here).
    """
    item = await add_clothing_item_from_url(
        user_id=current_user.id,
        image_url=body.image_url,
        category=body.category,
        color=body.color,
        style=body.style,
        brand=body.brand,
        notes=body.notes,
    )

    logger.info("Item added: %s (user=%s)", item.id, current_user.id)
    return success(
        data=ClothingItemResponse.from_item(item).model_dump(mode="json"),
        message="Clothing item added to wardrobe",
        status_code=201,
    )


@router.get("/list", summary="List wardrobe items")
async def list_items(
    current_user: CurrentUser,
    category: Optional[str] = None,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    """
    Return clothing items in the user's wardrobe with pagination.
    Optionally filter by category (top | bottom | footwear).
    """
    if category and category not in {c.value for c in Category}:
        return error(
            message=f"Invalid category '{category}'. Allowed: top, bottom, footwear",
            status_code=400,
        )

    items = await get_user_wardrobe(
        user_id=current_user.id,
        category=category,
        limit=limit,
        offset=offset,
    )
    return success(
        data=[ClothingItemResponse.from_item(i).model_dump(mode="json") for i in items],
        message=f"Retrieved {len(items)} wardrobe item(s)",
    )


@router.put("/{item_id}", summary="Update a wardrobe item")
async def update_item(
    item_id: str,
    body: ClothingItemUpdate,
    current_user: CurrentUser,
):
    """Update the category, color, or style of an existing wardrobe item."""
    # Verify item belongs to the current user before allowing update
    existing = await get_wardrobe_item_by_id(item_id)
    if existing is None:
        return error(message="Wardrobe item not found", status_code=404)
    if existing.user_id != current_user.id:
        return error(message="Not authorised to update this item", status_code=403)

    try:
        updated = await update_clothing_item(
            user_id=current_user.id,
            item_id=item_id,
            data=body,
        )
    except HTTPException as exc:
        return error(message=exc.detail, status_code=exc.status_code)

    return success(
        data=ClothingItemResponse.from_item(updated).model_dump(mode="json"),
        message="Wardrobe item updated",
    )


@router.delete("/{item_id}", summary="Delete a wardrobe item")
async def delete_item(
    item_id: str,
    current_user: CurrentUser,
):
    """Delete a wardrobe item and its associated Cloudinary image."""
    # Verify item belongs to the current user before allowing deletion
    existing = await get_wardrobe_item_by_id(item_id)
    if existing is None:
        return error(message="Wardrobe item not found", status_code=404)
    if existing.user_id != current_user.id:
        return error(message="Not authorised to delete this item", status_code=403)

    try:
        await delete_clothing_item(user_id=current_user.id, item_id=item_id)
    except HTTPException as exc:
        return error(message=exc.detail, status_code=exc.status_code)

    return success(data=None, message="Wardrobe item deleted successfully")
