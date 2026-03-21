"""
Tests: JWT creation, verification, expiry, and tamper detection.
"""
import time
from datetime import datetime, timedelta, timezone

import pytest
from jose import jwt
from fastapi import HTTPException

import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
os.environ.setdefault("JWT_SECRET_KEY", "test-secret-key-minimum-32-chars-ok")
os.environ.setdefault("MONGODB_URL", "mongodb://localhost:27017")
os.environ.setdefault("DEBUG", "true")

from core.security import create_access_token, verify_token

SECRET = "test-secret-key-minimum-32-chars-ok"
ALGO   = "HS256"
USER_ID = "507f1f77bcf86cd799439011"


# ── Token creation ────────────────────────────────────────────────────────

def test_create_token_returns_string():
    token = create_access_token(USER_ID)
    assert isinstance(token, str)
    assert len(token) > 20


def test_created_token_has_correct_subject():
    token = create_access_token(USER_ID)
    payload = jwt.decode(token, SECRET, algorithms=[ALGO])
    assert payload["sub"] == USER_ID


def test_created_token_has_type_access():
    token = create_access_token(USER_ID)
    payload = jwt.decode(token, SECRET, algorithms=[ALGO])
    assert payload["type"] == "access"


def test_created_token_has_future_expiry():
    token = create_access_token(USER_ID)
    payload = jwt.decode(token, SECRET, algorithms=[ALGO])
    exp = datetime.fromtimestamp(payload["exp"], tz=timezone.utc)
    assert exp > datetime.now(tz=timezone.utc)


# ── Token verification ────────────────────────────────────────────────────

def test_verify_valid_token_returns_user_id():
    token = create_access_token(USER_ID)
    result = verify_token(token)
    assert result == USER_ID


def test_verify_tampered_token_raises_401():
    token = create_access_token(USER_ID)
    tampered = token[:-4] + "XXXX"
    with pytest.raises(HTTPException) as exc_info:
        verify_token(tampered)
    assert exc_info.value.status_code == 401


def test_verify_expired_token_raises_401():
    now = datetime.now(tz=timezone.utc)
    payload = {
        "sub": USER_ID,
        "iat": now - timedelta(hours=2),
        "exp": now - timedelta(hours=1),   # already expired
        "type": "access",
    }
    expired_token = jwt.encode(payload, SECRET, algorithm=ALGO)
    with pytest.raises(HTTPException) as exc_info:
        verify_token(expired_token)
    assert exc_info.value.status_code == 401


def test_verify_token_missing_sub_raises_401():
    now = datetime.now(tz=timezone.utc)
    payload = {
        "iat": now,
        "exp": now + timedelta(hours=1),
        "type": "access",
        # no "sub"
    }
    token = jwt.encode(payload, SECRET, algorithm=ALGO)
    with pytest.raises(HTTPException) as exc_info:
        verify_token(token)
    assert exc_info.value.status_code == 401


def test_verify_token_wrong_type_raises_401():
    now = datetime.now(tz=timezone.utc)
    payload = {
        "sub": USER_ID,
        "iat": now,
        "exp": now + timedelta(hours=1),
        "type": "refresh",  # wrong type
    }
    token = jwt.encode(payload, SECRET, algorithm=ALGO)
    with pytest.raises(HTTPException) as exc_info:
        verify_token(token)
    assert exc_info.value.status_code == 401


def test_verify_token_missing_exp_raises_401():
    payload = {
        "sub": USER_ID,
        "iat": datetime.now(tz=timezone.utc),
        "type": "access",
        # no "exp"
    }
    # jose encode() has no options param — build a no-exp token manually
    import json, base64, hmac as _hmac, hashlib
    hdr = base64.urlsafe_b64encode(b'{"alg":"HS256","typ":"JWT"}').rstrip(b"=").decode()
    bdy = base64.urlsafe_b64encode(json.dumps({"sub": USER_ID, "iat": 1700000000, "type": "access"}).encode()).rstrip(b"=").decode()
    sig = base64.urlsafe_b64encode(_hmac.new(SECRET.encode(), f"{hdr}.{bdy}".encode(), hashlib.sha256).digest()).rstrip(b"=").decode()
    token = f"{hdr}.{bdy}.{sig}"
    with pytest.raises(HTTPException) as exc_info:
        verify_token(token)
    assert exc_info.value.status_code == 401


def test_verify_wrong_secret_raises_401():
    payload = {
        "sub": USER_ID,
        "iat": datetime.now(tz=timezone.utc),
        "exp": datetime.now(tz=timezone.utc) + timedelta(hours=1),
        "type": "access",
    }
    token = jwt.encode(payload, "totally-wrong-secret-key-xxxxx", algorithm=ALGO)
    with pytest.raises(HTTPException) as exc_info:
        verify_token(token)
    assert exc_info.value.status_code == 401


def test_verify_empty_string_raises_401():
    with pytest.raises(HTTPException) as exc_info:
        verify_token("")
    assert exc_info.value.status_code == 401
