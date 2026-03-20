import asyncio
import logging
import uuid
from datetime import datetime, timezone
from typing import Optional
from bson import ObjectId
from fastapi import HTTPException, status
from core.database import get_wardrobe_collection
from core.cloudinary_client import upload_image, delete_image, WARDROBE_FOLDER, build_public_id
from models.wardrobe import ClothingItem, ClothingItemCreate, ClothingItemUpdate

logger = logging.getLogger(__name__)

ALLOWED_CATEGORIES = {"top", "bottom", "footwear"}


def _doc_to_item(doc: dict) -> ClothingItem:
    """Convert a raw MongoDB document to a ClothingItem model."""
    doc["id"] = str(doc.pop("_id"))
    return ClothingItem(**doc)


async def get_wardrobe_item_by_id(item_id: str) -> Optional[ClothingItem]:
    """
    Fetch a single wardrobe item by its ID.
    Returns None if not found or the ID is invalid.
    """
    col = get_wardrobe_collection()
    try:
        oid = ObjectId(item_id)
    except Exception:
        return None
    doc = await col.find_one({"_id": oid})
    if doc is None:
        return None
    return _doc_to_item(doc)


async def get_user_wardrobe(
    user_id: str,
    category: Optional[str] = None,
    limit: int = 100,
    offset: int = 0,
) -> list[ClothingItem]:
    """
    Retrieve wardrobe items for a user, optionally filtered by category,
    with pagination support.
    """
    if category is not None and category not in ALLOWED_CATEGORIES:
        raise ValueError(
            f"Invalid category '{category}'. Allowed values: {', '.join(sorted(ALLOWED_CATEGORIES))}"
        )

    col = get_wardrobe_collection()
    query: dict = {"user_id": user_id}
    if category:
        query["category"] = category

    cursor = col.find(query).sort("created_at", -1).skip(offset).limit(limit)
    items: list[ClothingItem] = []
    async for doc in cursor:
        items.append(_doc_to_item(doc))
    return items


async def add_clothing_item(
    user_id: str,
    data: ClothingItemCreate,
    image_bytes: bytes,
) -> ClothingItem:
    """
    Upload image to Cloudinary, then persist the clothing item in MongoDB.
    """
    col = get_wardrobe_collection()
    item_id = str(uuid.uuid4())
    public_id = build_public_id(user_id, item_id)

    # Upload image
    image_url = await upload_image(
        file_bytes=image_bytes,
        public_id=public_id,
        folder=WARDROBE_FOLDER,
    )

    now = datetime.now(tz=timezone.utc)
    doc = {
        "_id": ObjectId(),
        "user_id": user_id,
        "category": data.category.value if hasattr(data.category, "value") else data.category,
        "color": data.color.lower().strip(),
        "style": data.style.value if hasattr(data.style, "value") else data.style,
        "image_url": image_url,
        "cloudinary_public_id": f"{WARDROBE_FOLDER}/{public_id}",
        "created_at": now,
    }

    await col.insert_one(doc)
    doc["id"] = str(doc.pop("_id"))
    logger.info("Wardrobe item added: %s for user %s", doc["id"], user_id)
    return ClothingItem(**doc)


async def update_clothing_item(
    user_id: str,
    item_id: str,
    data: ClothingItemUpdate,
) -> ClothingItem:
    """
    Update mutable fields (category, color, style) of a wardrobe item.
    Raises 404 if not found or 403 if owned by a different user.
    """
    col = get_wardrobe_collection()

    try:
        oid = ObjectId(item_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid item ID format")

    existing = await col.find_one({"_id": oid})
    if not existing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Wardrobe item not found")
    if existing["user_id"] != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorised to update this item")

    updates: dict = {}
    if data.category is not None:
        updates["category"] = data.category.value if hasattr(data.category, "value") else data.category
    if data.color is not None:
        updates["color"] = data.color.lower().strip()
    if data.style is not None:
        updates["style"] = data.style.value if hasattr(data.style, "value") else data.style

    if not updates:
        # Nothing to update — return existing item
        existing["id"] = str(existing.pop("_id"))
        return ClothingItem(**existing)

    await col.update_one({"_id": oid}, {"$set": updates})
    updated = await col.find_one({"_id": oid})
    return _doc_to_item(updated)


async def delete_clothing_item(user_id: str, item_id: str) -> bool:
    """
    Delete a wardrobe item from MongoDB and remove its image from Cloudinary.
    Raises 404 if not found, 403 if unauthorised.
    Returns True on success.
    """
    col = get_wardrobe_collection()

    try:
        oid = ObjectId(item_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid item ID format")

    existing = await col.find_one({"_id": oid})
    if not existing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Wardrobe item not found")
    if existing["user_id"] != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorised to delete this item")

    cloudinary_pid = existing.get("cloudinary_public_id", "")

    result = await col.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to delete item")

    # Non-blocking background deletion of Cloudinary image
    if cloudinary_pid:
        asyncio.create_task(delete_image(cloudinary_pid))

    logger.info("Wardrobe item deleted: %s for user %s", item_id, user_id)
    return True
