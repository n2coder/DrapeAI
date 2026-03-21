"""
Shared fixtures for DrapeAI test suite.

Uses FastAPI TestClient with a fully mocked MongoDB/Redis so tests run
offline and never touch the production database.
"""
import os
import sys
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

# ── make sure `backend/` is on the path so imports resolve ────────────────
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

# ── stub env vars before any app module is imported ──────────────────────
os.environ.setdefault("JWT_SECRET_KEY", "test-secret-key-minimum-32-chars-ok")
os.environ.setdefault("MONGODB_URL", "mongodb://localhost:27017")
os.environ.setdefault("UPSTASH_REDIS_URL", "")
os.environ.setdefault("UPSTASH_REDIS_TOKEN", "")
os.environ.setdefault("FIREBASE_CREDENTIALS_JSON", "")
os.environ.setdefault("DEBUG", "true")

# ── sample user profiles ──────────────────────────────────────────────────
SAMPLE_USER_ID = "507f1f77bcf86cd799439011"
SAMPLE_USER_ONBOARDED = {
    "_id": None,  # filled per-test
    "id": SAMPLE_USER_ID,
    "phone": "+919876543210",
    "name": "Naresh Chaudhary",
    "gender": "male",
    "age_range": "25-34",
    "city": "Mumbai",
    "style_preferences": ["casual", "urban"],
    "onboarding_complete": True,
    "created_at": datetime.now(tz=timezone.utc),
    "last_login": datetime.now(tz=timezone.utc),
}

SAMPLE_USER_NEW = {
    "id": "507f1f77bcf86cd799439022",
    "phone": "+919876543211",
    "name": None,
    "gender": None,
    "age_range": None,
    "city": None,
    "style_preferences": [],
    "onboarding_complete": False,
    "created_at": datetime.now(tz=timezone.utc),
    "last_login": None,
}

SAMPLE_WARDROBE = [
    {
        "id": "item001", "user_id": SAMPLE_USER_ID,
        "category": "top", "color": "white", "style": "casual",
        "image_url": "https://res.cloudinary.com/test/image/upload/top.jpg",
        "cloudinary_public_id": "styleai/wardrobe/item001",
        "created_at": datetime.now(tz=timezone.utc),
        "ai_attributes": None, "enhanced_url": None, "dalle_url": None,
    },
    {
        "id": "item002", "user_id": SAMPLE_USER_ID,
        "category": "bottom", "color": "navy", "style": "casual",
        "image_url": "https://res.cloudinary.com/test/image/upload/bottom.jpg",
        "cloudinary_public_id": "styleai/wardrobe/item002",
        "created_at": datetime.now(tz=timezone.utc),
        "ai_attributes": None, "enhanced_url": None, "dalle_url": None,
    },
    {
        "id": "item003", "user_id": SAMPLE_USER_ID,
        "category": "footwear", "color": "white", "style": "casual",
        "image_url": "https://res.cloudinary.com/test/image/upload/shoes.jpg",
        "cloudinary_public_id": "styleai/wardrobe/item003",
        "created_at": datetime.now(tz=timezone.utc),
        "ai_attributes": None, "enhanced_url": None, "dalle_url": None,
    },
]


def make_jwt(user_id: str = SAMPLE_USER_ID) -> str:
    """Mint a real (but test-key-signed) JWT for the given user_id."""
    from core.security import create_access_token
    return create_access_token(user_id)


@pytest.fixture(scope="session")
def valid_token():
    return make_jwt()


@pytest.fixture(scope="session")
def auth_headers(valid_token):
    return {"Authorization": f"Bearer {valid_token}"}
