import logging
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo import ASCENDING, IndexModel
from core.config import settings

logger = logging.getLogger(__name__)

_client: AsyncIOMotorClient | None = None
_database: AsyncIOMotorDatabase | None = None


async def connect_to_mongo() -> None:
    global _client, _database
    try:
        _client = AsyncIOMotorClient(
            settings.mongodb_url,
            maxPoolSize=100,
            minPoolSize=10,
            serverSelectionTimeoutMS=5000,
            connectTimeoutMS=10000,
        )
        _database = _client[settings.mongodb_db_name]
        # Verify connection
        await _client.admin.command("ping")
        logger.info("Connected to MongoDB at %s", settings.mongodb_url)
    except Exception as e:
        logger.error("Failed to connect to MongoDB: %s", e)
        raise


async def close_mongo_connection() -> None:
    global _client
    if _client:
        _client.close()
        logger.info("MongoDB connection closed")


def get_database() -> AsyncIOMotorDatabase:
    if _database is None:
        raise RuntimeError("Database not initialised. Call connect_to_mongo() first.")
    return _database


async def init_indexes() -> None:
    """Create all required MongoDB indexes."""
    db = get_database()

    # users collection — unique index on phone
    users_col = db["users"]
    await users_col.create_indexes(
        [
            IndexModel([("phone", ASCENDING)], unique=True, name="users_phone_unique"),
            IndexModel([("created_at", ASCENDING)], name="users_created_at"),
        ]
    )
    logger.info("Users indexes created")

    # wardrobe_items collection
    wardrobe_col = db["wardrobe_items"]
    await wardrobe_col.create_indexes(
        [
            IndexModel([("user_id", ASCENDING)], name="wardrobe_user_id"),
            IndexModel([("user_id", ASCENDING), ("category", ASCENDING)], name="wardrobe_user_category"),
            IndexModel([("created_at", ASCENDING)], name="wardrobe_created_at"),
        ]
    )
    logger.info("Wardrobe indexes created")

    # recommendations collection
    rec_col = db["recommendations"]
    await rec_col.create_indexes(
        [
            IndexModel([("user_id", ASCENDING), ("date", ASCENDING)], name="rec_user_date"),
            IndexModel([("user_id", ASCENDING), ("is_saved", ASCENDING)], name="rec_user_saved"),
            IndexModel([("created_at", ASCENDING)], name="rec_created_at"),
        ]
    )
    logger.info("Recommendations indexes created")

    # waitlist collection — unique email
    waitlist_col = db["waitlist"]
    await waitlist_col.create_indexes(
        [
            IndexModel([("email", ASCENDING)], unique=True, name="waitlist_email_unique"),
            IndexModel([("created_at", ASCENDING)], name="waitlist_created_at"),
        ]
    )
    logger.info("Waitlist indexes created")


# Shortcut helpers
def get_users_collection():
    return get_database()["users"]


def get_wardrobe_collection():
    return get_database()["wardrobe_items"]


def get_recommendations_collection():
    return get_database()["recommendations"]
