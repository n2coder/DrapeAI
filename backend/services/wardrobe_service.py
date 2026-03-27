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
from engine.vision_analyzer import analyze_clothing_image
from engine.image_enhancer import enhance_clothing_image

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


async def add_clothing_item_from_url(
    user_id: str,
    image_url: str,
    category,
    color: str,
    style,
    brand: str | None = None,
    notes: str | None = None,
) -> ClothingItem:
    """
    Persist a wardrobe item whose image was uploaded directly to Cloudinary
    by the mobile client (unsigned upload preset). The Cloudinary URL is
    stored as-is; AI enrichment fetches the image bytes from the URL.
    """
    col = get_wardrobe_collection()
    item_id = str(uuid.uuid4())

    cat_val   = category.value if hasattr(category, "value") else str(category)
    style_val = style.value    if hasattr(style,    "value") else str(style)

    now = datetime.now(tz=timezone.utc)
    doc = {
        "_id": ObjectId(),
        "id": item_id,
        "user_id": user_id,
        "category": cat_val,
        "color": color.lower().strip(),
        "style": style_val,
        "image_url": image_url,
        "cloudinary_public_id": "",   # client-side upload — public_id not available
        "created_at": now,
        "brand": brand,
        "notes": notes,
    }
    if brand is None:
        doc.pop("brand")
    if notes is None:
        doc.pop("notes")

    result = await col.insert_one(doc)
    inserted_oid = result.inserted_id
    doc["id"] = str(doc.pop("_id"))
    item = ClothingItem(**doc)

    logger.info("Wardrobe item added (URL): %s for user %s", item.id, user_id)

    # Fire-and-forget AI enrichment — download bytes from the URL
    asyncio.create_task(_enrich_item_from_url(inserted_oid, image_url, color))

    return item


async def _enrich_item_from_url(oid: ObjectId, image_url: str, color: str) -> None:
    """Download image bytes from Cloudinary URL then run AI enrichment."""
    import httpx
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(image_url)
            resp.raise_for_status()
            image_bytes = resp.content
        await _enrich_item(oid, image_bytes, image_url, color)
    except Exception as e:
        logger.warning("Could not fetch image for enrichment %s: %s", str(oid), e)


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

    result = await col.insert_one(doc)
    inserted_oid = result.inserted_id
    doc["id"] = str(doc.pop("_id"))
    item = ClothingItem(**doc)

    logger.info("Wardrobe item added: %s for user %s", item.id, user_id)

    # Fire-and-forget: run AI enrichment in background (vision analysis + image enhancement)
    asyncio.create_task(_enrich_item(inserted_oid, image_bytes, image_url, data.color))

    return item


async def _enrich_item(oid: ObjectId, image_bytes: bytes, original_url: str, color: str) -> None:
    """
    Background task: run GPT-4o Vision analysis first to get garment type, then run
    Cloudinary/DALL-E image enhancement with a proper description.
    """
    try:
        # Vision runs first so we have the garment type for DALL-E
        attributes = await analyze_clothing_image(image_bytes)

        # Build a precise description for DALL-E using vision results
        if attributes:
            garment   = attributes.get("garment_type") or attributes.get("ai_category") or "clothing item"
            det_color = attributes.get("detected_color") or color
            fabric    = attributes.get("fabric_type") or ""
            pattern   = attributes.get("pattern") or ""
            fit       = attributes.get("fit_type") or ""
            # e.g. "slim-fit light blue denim jeans" or "oversized white cotton t-shirt"
            parts = [p for p in [fit, det_color, fabric, garment] if p and p not in ("solid", "plain")]
            item_description = " ".join(parts)
        else:
            item_description = f"{color} clothing item"

        enhanced_url, dalle_url = await enhance_clothing_image(
            image_bytes, original_url,
            item_description=item_description,
        )

        updates: dict = {}
        if attributes:
            updates["ai_attributes"] = attributes
        if enhanced_url and enhanced_url != original_url:
            updates["enhanced_url"] = enhanced_url
        if dalle_url:
            updates["dalle_url"] = dalle_url

        if updates:
            col = get_wardrobe_collection()
            await col.update_one({"_id": oid}, {"$set": updates})
            logger.info("AI enrichment saved for item %s (fields: %s)", str(oid), list(updates.keys()))
    except Exception as e:
        logger.warning("Background AI enrichment failed for %s: %s", str(oid), e)


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
    if data.image_url is not None:
        updates["image_url"] = data.image_url
    if data.brand is not None:
        updates["brand"] = data.brand
    if data.notes is not None:
        updates["notes"] = data.notes

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
