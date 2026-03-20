import logging
from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel
from core.firebase_admin import verify_firebase_token
from core.rate_limiter import limiter
from core.security import create_access_token
from services.auth_service import get_or_create_user, update_last_login
from utils.response import success, error
from utils.validators import validate_phone

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


# ---------------------------------------------------------------------------
# Request / Response schemas
# ---------------------------------------------------------------------------

class LoginRequest(BaseModel):
    phone: str


class LoginResponse(BaseModel):
    message: str
    phone: str


class VerifyOTPRequest(BaseModel):
    firebase_id_token: str


class VerifyOTPResponse(BaseModel):
    access_token: str
    token_type: str
    is_new_user: bool
    user_id: str


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post("/login", summary="Initiate phone login (send OTP via Firebase)")
@limiter.limit("5/hour")
async def login(request: Request, body: LoginRequest):
    """
    Validates the phone number format and instructs the client to trigger
    Firebase phone authentication on the client side.

    The actual OTP dispatch is handled by the Firebase SDK on the client.
    This endpoint is a server-side guard to ensure only valid phone numbers
    proceed to the Firebase auth flow.
    """
    try:
        cleaned_phone = validate_phone(body.phone)
    except HTTPException as exc:
        return error(message=exc.detail, status_code=exc.status_code)

    logger.info("Login initiated for a validated phone number")

    return success(
        data={
            "phone": f"+91{cleaned_phone}",
            "message": "Phone number validated. Please complete Firebase OTP verification on the client.",
        },
        message="OTP flow initiated",
    )


@router.post("/verify-otp", summary="Verify Firebase OTP and get JWT access token")
@limiter.limit("5/hour")
async def verify_otp(request: Request, body: VerifyOTPRequest):
    """
    Accepts a Firebase ID token obtained after the user completes phone OTP
    verification on the client. Verifies it with Firebase Admin SDK, then
    creates or retrieves the user account and returns a JWT access token.
    """
    token = body.firebase_id_token.strip() if body.firebase_id_token else ""

    # Validate token format: must be a proper JWT (3 dot-separated parts, min 100 chars)
    if not token:
        return error(message="firebase_id_token is required", status_code=400)

    parts = token.split(".")
    if len(parts) != 3 or len(token) < 100:
        return error(
            message="firebase_id_token must be a valid JWT (3 dot-separated parts, minimum 100 characters)",
            status_code=400,
        )

    # Verify token with Firebase Admin SDK
    try:
        decoded_claims = await verify_firebase_token(token)
    except HTTPException as exc:
        return error(message=exc.detail, status_code=exc.status_code)

    raw_phone: str = decoded_claims.get("phone_number", "")
    if not raw_phone:
        return error(
            message="Firebase token does not contain a phone number",
            status_code=400,
        )

    # Normalise phone number
    try:
        cleaned_phone = validate_phone(raw_phone)
    except HTTPException as exc:
        return error(message=exc.detail, status_code=exc.status_code)

    # Create or retrieve user
    user, is_new_user = await get_or_create_user(cleaned_phone)

    # Update last login timestamp (fire-and-forget style)
    await update_last_login(user.id)

    # Issue JWT
    access_token = create_access_token(user.id)

    # Log only user ID — never log phone numbers
    logger.info("User %s authenticated (new=%s)", user.id, is_new_user)

    return success(
        data={
            "access_token": access_token,
            "token_type": "bearer",
            "is_new_user": is_new_user,
            "user_id": user.id,
        },
        message="Authentication successful",
    )
