"""
Centralized rate limiting configuration using slowapi.
"""
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["200/hour", "50/minute"],
    storage_uri="memory://",  # Use Redis URI in production: redis://localhost:6379
)
