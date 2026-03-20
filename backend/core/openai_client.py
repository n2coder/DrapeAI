"""
OpenAI client singleton.

Usage:
    from core.openai_client import get_openai_client
    client = get_openai_client()   # returns None if key not configured
"""
import logging
from typing import Optional
from openai import AsyncOpenAI
from core.config import settings

logger = logging.getLogger(__name__)

_client: Optional[AsyncOpenAI] = None


def get_openai_client() -> Optional[AsyncOpenAI]:
    global _client
    if _client is not None:
        return _client
    if not settings.openai_api_key:
        logger.warning("OPENAI_API_KEY not set — AI features disabled")
        return None
    _client = AsyncOpenAI(api_key=settings.openai_api_key)
    logger.info("OpenAI client initialised")
    return _client
