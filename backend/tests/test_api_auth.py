"""
Tests: API auth behaviour — 401 on missing/bad tokens, 422 on bad payloads.
Uses FastAPI TestClient with mocked Firebase + MongoDB.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
os.environ.setdefault("JWT_SECRET_KEY", "test-secret-key-minimum-32-chars-ok")
os.environ.setdefault("MONGODB_URL", "mongodb://localhost:27017")
os.environ.setdefault("DEBUG", "true")

from unittest.mock import AsyncMock, MagicMock, patch
import pytest
from fastapi.testclient import TestClient


# ── App bootstrap with all external services mocked ──────────────────────

@pytest.fixture(scope="module")
def client():
    with (
        patch("core.database.connect_to_mongo", new_callable=AsyncMock),
        patch("core.database.init_indexes",     new_callable=AsyncMock),
        patch("core.database.close_mongo_connection", new_callable=AsyncMock),
        patch("core.redis_client.init_redis",   new_callable=AsyncMock),
        patch("core.redis_client.close_redis",  new_callable=AsyncMock),
        patch("core.firebase_admin.init_firebase"),
        patch("core.cloudinary_client.init_cloudinary"),
    ):
        from main import app
        with TestClient(app, raise_server_exceptions=False) as c:
            yield c


# ── No token → 401 ───────────────────────────────────────────────────────

@pytest.mark.parametrize("path", [
    "/users/profile",
    "/users/weather?city=Mumbai",
    "/wardrobe/list",
    "/recommendations/today",
    "/recommendations/saved",
])
def test_protected_routes_without_token_return_401(client, path):
    r = client.get(path)
    assert r.status_code == 401, f"{path} → expected 401 got {r.status_code}"


@pytest.mark.parametrize("path", [
    "/users/profile",
    "/users/me",
])
def test_protected_delete_without_token_returns_401(client, path):
    r = client.delete(path)
    assert r.status_code == 401


# ── Garbage token → 401 ──────────────────────────────────────────────────

def test_garbage_bearer_token_returns_401(client):
    r = client.get(
        "/users/profile",
        headers={"Authorization": "Bearer this.is.garbage"},
    )
    assert r.status_code == 401


def test_malformed_auth_header_returns_401(client):
    r = client.get(
        "/users/profile",
        headers={"Authorization": "NotBearer token"},
    )
    assert r.status_code == 401


# ── Health is public ─────────────────────────────────────────────────────

def test_health_is_public(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["success"] is True


# ── Auth endpoints accept correct payload shape ───────────────────────────

def test_send_otp_missing_phone_returns_422(client):
    r = client.post("/auth/send-otp", json={})
    assert r.status_code == 422


def test_send_otp_empty_phone_returns_422(client):
    r = client.post("/auth/send-otp", json={"phone_number": ""})
    # empty string should fail validation
    assert r.status_code in (400, 422)


def test_verify_otp_missing_token_returns_422(client):
    r = client.post("/auth/verify-otp", json={})
    assert r.status_code == 422


# ── 404 for unknown routes ───────────────────────────────────────────────

def test_unknown_route_returns_404(client):
    r = client.get("/does-not-exist")
    assert r.status_code == 404
    body = r.json()
    assert body["success"] is False
