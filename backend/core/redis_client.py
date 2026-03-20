import logging
import json
from typing import Any
from upstash_redis.asyncio import Redis
from core.config import settings

logger = logging.getLogger(__name__)

# TTL constants (seconds)
RECOMMENDATION_TTL = 3600   # 1 hour
WEATHER_TTL = 1800          # 30 minutes
USER_SESSION_TTL = 86400    # 24 hours

_redis: Redis | None = None


async def init_redis() -> None:
    global _redis
    try:
        _redis = Redis(
            url=settings.upstash_redis_url,
            token=settings.upstash_redis_token,
        )
        await _redis.ping()
        logger.info("Connected to Upstash Redis (REST API)")
    except Exception as e:
        logger.error("Failed to connect to Redis: %s", e)
        raise


async def close_redis() -> None:
    global _redis
    _redis = None
    logger.info("Redis connection closed")


def get_redis() -> Redis:
    if _redis is None:
        raise RuntimeError("Redis not initialised. Call init_redis() first.")
    return _redis


async def cache_get(key: str) -> Any | None:
    """Retrieve a JSON-deserialised value from Redis. Returns None on miss."""
    try:
        client = get_redis()
        raw = await client.get(key)
        if raw is None:
            return None
        return json.loads(raw) if isinstance(raw, str) else raw
    except Exception as e:
        logger.warning("Redis cache_get failed for key %s: %s", key, e)
        return None


async def cache_set(key: str, value: Any, ttl: int = RECOMMENDATION_TTL) -> bool:
    """Serialise value to JSON and store in Redis with a TTL."""
    try:
        client = get_redis()
        serialised = json.dumps(value, default=str)
        await client.setex(key, ttl, serialised)
        return True
    except Exception as e:
        logger.warning("Redis cache_set failed for key %s: %s", key, e)
        return False


async def cache_delete(key: str) -> bool:
    """Delete a key from Redis."""
    try:
        client = get_redis()
        await client.delete(key)
        return True
    except Exception as e:
        logger.warning("Redis cache_delete failed for key %s: %s", key, e)
        return False


async def cache_delete_pattern(pattern: str) -> int:
    """
    Delete all keys matching a pattern using SCAN (non-blocking).
    Returns number of deleted keys.
    """
    try:
        client = get_redis()
        keys = []
        cursor = 0
        while True:
            cursor, batch = await client.scan(cursor, match=pattern, count=100)
            keys.extend(batch)
            if cursor == 0:
                break
        if keys:
            await client.delete(*keys)
            return len(keys)
        return 0
    except Exception as e:
        logger.warning("Redis cache_delete_pattern failed for pattern %s: %s", pattern, e)
        return 0
