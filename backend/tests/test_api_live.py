"""
Tests: Live API behaviour against the deployed Render backend.

All tests that need auth are skipped automatically if the backend is
unreachable (cold start) or if no DRAPEAI_TEST_TOKEN env var is set.

Set the token by running:
    $env:DRAPEAI_TEST_TOKEN = "<paste jwt here>"  # PowerShell
    export DRAPEAI_TEST_TOKEN="<paste jwt here>"   # bash
"""
import os
import pytest
import httpx

BASE = "https://drapeai-wnum.onrender.com"
TOKEN = os.environ.get("DRAPEAI_TEST_TOKEN", "")
TIMEOUT = 20


def _headers():
    return {"Authorization": f"Bearer {TOKEN}"}


def _get(path, **kwargs):
    return httpx.get(f"{BASE}{path}", timeout=TIMEOUT, **kwargs)


def _post(path, **kwargs):
    return httpx.post(f"{BASE}{path}", timeout=TIMEOUT, **kwargs)


def _put(path, **kwargs):
    return httpx.put(f"{BASE}{path}", timeout=TIMEOUT, **kwargs)


# ── Connectivity guard ────────────────────────────────────────────────────

@pytest.fixture(scope="module", autouse=True)
def backend_reachable():
    try:
        r = httpx.get(f"{BASE}/health", timeout=TIMEOUT)
        assert r.status_code == 200
    except Exception:
        pytest.skip("Render backend unreachable — skipping all live tests")


# ── Health ────────────────────────────────────────────────────────────────

def test_live_health_success():
    r = _get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["success"] is True
    assert body["status"] == "ok"
    assert "version" in body


# ── Auth: unauthenticated access ──────────────────────────────────────────

@pytest.mark.parametrize("path", [
    "/users/profile",
    "/users/weather?city=Mumbai",
    "/wardrobe/list",
    "/recommendations/today",
    "/recommendations/saved",
])
def test_live_protected_route_without_token_is_401(path):
    r = _get(path)
    assert r.status_code == 401


def test_live_garbage_token_is_401():
    r = _get("/users/profile", headers={"Authorization": "Bearer garbage.token.here"})
    assert r.status_code == 401


# ── Auth: bad OTP payload ─────────────────────────────────────────────────

def test_live_send_otp_missing_body_is_422():
    r = _post("/auth/send-otp", json={})
    assert r.status_code == 422


def test_live_verify_otp_missing_body_is_422():
    r = _post("/auth/verify-otp", json={})
    assert r.status_code == 422


# ── Authenticated tests (need DRAPEAI_TEST_TOKEN) ─────────────────────────

def skip_if_no_token():
    if not TOKEN:
        pytest.skip("DRAPEAI_TEST_TOKEN not set — skipping authenticated live tests")


def test_live_get_profile():
    skip_if_no_token()
    r = _get("/users/profile", headers=_headers())
    assert r.status_code == 200
    body = r.json()
    assert body["success"] is True
    data = body["data"]
    assert "id" in data
    assert "phone" in data
    assert "onboarding_complete" in data


def test_live_profile_has_expected_shape():
    skip_if_no_token()
    r = _get("/users/profile", headers=_headers())
    data = r.json()["data"]
    required_fields = ["id", "phone", "onboarding_complete", "created_at", "style_preferences"]
    for field in required_fields:
        assert field in data, f"Missing field: {field}"


def test_live_weather_mumbai():
    skip_if_no_token()
    r = _get("/users/weather?city=Mumbai", headers=_headers())
    assert r.status_code == 200
    data = r.json()["data"]
    assert "temperature" in data
    assert "condition" in data
    assert "cityName" in data
    assert isinstance(data["humidity"], int)
    assert data["cityName"].lower() in ("mumbai", "")


def test_live_weather_invalid_city_returns_404():
    skip_if_no_token()
    r = _get("/users/weather?city=xyznotacity123", headers=_headers())
    assert r.status_code == 404


def test_live_weather_missing_city_param_returns_422():
    skip_if_no_token()
    r = _get("/users/weather", headers=_headers())
    assert r.status_code == 422


def test_live_wardrobe_list_returns_items_array():
    skip_if_no_token()
    r = _get("/wardrobe/list", headers=_headers())
    assert r.status_code == 200
    body = r.json()
    assert body["success"] is True
    assert isinstance(body["data"], list)


def test_live_wardrobe_item_shape():
    skip_if_no_token()
    r = _get("/wardrobe/list", headers=_headers())
    items = r.json()["data"]
    if not items:
        pytest.skip("No wardrobe items to validate shape")
    item = items[0]
    for field in ["id", "user_id", "category", "color", "style", "image_url"]:
        assert field in item, f"Wardrobe item missing field: {field}"
    assert item["category"] in ("top", "bottom", "footwear", "outerwear",
                                "accessories", "dress", "ethnic wear")


def test_live_today_recommendation():
    skip_if_no_token()
    r = _get("/recommendations/today", headers=_headers())
    if r.status_code == 400:
        body = r.json()
        pytest.skip(f"Onboarding incomplete or no wardrobe: {body.get('message')}")
    assert r.status_code == 200
    data = r.json()["data"]
    assert "score" in data or "top" in data


def test_live_saved_outfits_returns_list():
    skip_if_no_token()
    r = _get("/recommendations/saved", headers=_headers())
    assert r.status_code == 200
    assert isinstance(r.json()["data"], list)


def test_live_update_profile_invalid_name_too_long():
    skip_if_no_token()
    r = _put(
        "/users/profile",
        headers={**_headers(), "Content-Type": "application/json"},
        content='{"name": "' + ("A" * 101) + '"}',
    )
    assert r.status_code == 400


def test_live_update_profile_no_fields_returns_400():
    skip_if_no_token()
    r = _put(
        "/users/profile",
        headers={**_headers(), "Content-Type": "application/json"},
        content='{}',
    )
    assert r.status_code == 400


def test_live_response_envelope_structure():
    """All endpoints return {success, message, data} envelope."""
    skip_if_no_token()
    r = _get("/users/profile", headers=_headers())
    body = r.json()
    assert "success" in body
    assert "message" in body
    assert "data" in body
