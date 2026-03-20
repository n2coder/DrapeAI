"""
GDPR compliance utilities for StyleAI.

Provides:
- delete_user_data: Right to erasure (GDPR Article 17)
- export_user_data:  Right of access (GDPR Article 15)
"""
import logging
from core.database import get_users_collection, get_wardrobe_collection, get_recommendations_collection
from core.redis_client import cache_delete_pattern

logger = logging.getLogger(__name__)


async def delete_user_data(user_id: str) -> dict:
    """
    Permanently delete all data associated with a user.

    Deletes:
    - User document from the users collection
    - All wardrobe items from the wardrobe_items collection
    - All Cloudinary images for those wardrobe items
    - All recommendation documents from the recommendations collection
    - All Redis cache keys for the user

    Returns a summary dict with counts of deleted items per collection.
    """
    summary: dict = {
        "users_deleted": 0,
        "wardrobe_items_deleted": 0,
        "cloudinary_images_deleted": 0,
        "recommendations_deleted": 0,
        "cache_keys_deleted": 0,
    }

    # --- Delete wardrobe items and their Cloudinary images ---
    wardrobe_col = get_wardrobe_collection()
    wardrobe_cursor = wardrobe_col.find({"user_id": user_id}, {"cloudinary_public_id": 1})
    cloudinary_ids = []
    async for doc in wardrobe_cursor:
        pid = doc.get("cloudinary_public_id", "")
        if pid:
            cloudinary_ids.append(pid)

    # Delete images from Cloudinary (best effort)
    from core.cloudinary_client import delete_image
    for public_id in cloudinary_ids:
        try:
            deleted = await delete_image(public_id)
            if deleted:
                summary["cloudinary_images_deleted"] += 1
        except Exception as e:
            logger.warning("Failed to delete Cloudinary image %s for user %s: %s", public_id, user_id, e)

    # Delete all wardrobe documents
    wardrobe_result = await wardrobe_col.delete_many({"user_id": user_id})
    summary["wardrobe_items_deleted"] = wardrobe_result.deleted_count

    # --- Delete recommendations ---
    rec_col = get_recommendations_collection()
    rec_result = await rec_col.delete_many({"user_id": user_id})
    summary["recommendations_deleted"] = rec_result.deleted_count

    # --- Delete user document ---
    users_col = get_users_collection()
    user_result = await users_col.delete_one({"id": user_id})
    if user_result.deleted_count == 0:
        # Try with ObjectId-based _id field as fallback
        from bson import ObjectId
        try:
            user_result = await users_col.delete_one({"_id": ObjectId(user_id)})
        except Exception:
            pass
    summary["users_deleted"] = user_result.deleted_count

    # --- Clear Redis cache keys for user ---
    try:
        deleted_keys = await cache_delete_pattern(f"*{user_id}*")
        summary["cache_keys_deleted"] = deleted_keys
    except Exception as e:
        logger.warning("Failed to clear Redis cache for user %s: %s", user_id, e)

    logger.info("GDPR deletion complete for user %s: %s", user_id, summary)
    return summary


async def export_user_data(user_id: str) -> dict:
    """
    Export all personal data held for a user.

    Fetches data from:
    - users collection (profile data)
    - wardrobe_items collection
    - recommendations collection

    Returns a dict containing all data (for GDPR Article 15 right of access).
    """
    export: dict = {
        "user_id": user_id,
        "profile": None,
        "wardrobe_items": [],
        "recommendations": [],
    }

    # --- User profile ---
    users_col = get_users_collection()
    from bson import ObjectId
    user_doc = None
    try:
        user_doc = await users_col.find_one({"_id": ObjectId(user_id)})
    except Exception:
        pass
    if user_doc:
        user_doc["id"] = str(user_doc.pop("_id"))
        # Remove sensitive internal fields
        user_doc.pop("__v", None)
        export["profile"] = user_doc

    # --- Wardrobe items ---
    wardrobe_col = get_wardrobe_collection()
    wardrobe_cursor = wardrobe_col.find({"user_id": user_id})
    async for doc in wardrobe_cursor:
        doc["id"] = str(doc.pop("_id"))
        export["wardrobe_items"].append(doc)

    # --- Recommendations ---
    rec_col = get_recommendations_collection()
    rec_cursor = rec_col.find({"user_id": user_id}).sort("created_at", -1).limit(500)
    async for doc in rec_cursor:
        # _id is a string UUID for recommendations
        if "_id" in doc:
            doc["id"] = doc.pop("_id")
        export["recommendations"].append(doc)

    logger.info(
        "GDPR export complete for user %s: profile=%s, wardrobe=%d, recommendations=%d",
        user_id,
        "found" if export["profile"] else "not found",
        len(export["wardrobe_items"]),
        len(export["recommendations"]),
    )
    return export
