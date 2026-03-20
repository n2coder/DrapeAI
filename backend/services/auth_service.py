import logging
from datetime import datetime, timezone
from typing import Tuple
from bson import ObjectId
from core.database import get_users_collection
from models.user import UserDocument

logger = logging.getLogger(__name__)


async def get_or_create_user(phone: str) -> Tuple[UserDocument, bool]:
    """
    Find an existing user by phone number or create a new one.

    Args:
        phone: Normalised 10-digit phone number string.

    Returns:
        (UserDocument, is_new_user: bool)
    """
    col = get_users_collection()
    now = datetime.now(tz=timezone.utc)

    raw = await col.find_one({"phone": phone})
    if raw is not None:
        raw["id"] = str(raw.pop("_id"))
        user = UserDocument(**raw)
        logger.info("Existing user found: %s", user.id)
        return user, False

    # Create new user document
    new_doc = {
        "phone": phone,
        "name": None,
        "gender": None,
        "age_range": None,
        "city": None,
        "style_preferences": [],
        "onboarding_complete": False,
        "created_at": now,
        "last_login": now,
    }
    result = await col.insert_one(new_doc)
    new_doc["id"] = str(result.inserted_id)
    new_doc.pop("_id", None)

    user = UserDocument(**new_doc)
    logger.info("New user created: %s (phone: %s)", user.id, phone)
    return user, True


async def update_last_login(user_id: str) -> None:
    """Update the last_login timestamp for a user."""
    col = get_users_collection()
    try:
        oid = ObjectId(user_id)
        await col.update_one(
            {"_id": oid},
            {"$set": {"last_login": datetime.now(tz=timezone.utc)}},
        )
    except Exception as e:
        logger.warning("Failed to update last_login for user %s: %s", user_id, e)
