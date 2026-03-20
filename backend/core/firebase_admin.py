import logging
import os
import firebase_admin
from firebase_admin import auth, credentials
from fastapi import HTTPException, status
from core.config import settings

logger = logging.getLogger(__name__)

_firebase_app: firebase_admin.App | None = None


def init_firebase() -> None:
    """Initialise the Firebase Admin SDK from the service account credentials file."""
    global _firebase_app

    if _firebase_app is not None:
        logger.debug("Firebase already initialised")
        return

    creds_path = settings.firebase_credentials_path

    if not os.path.exists(creds_path):
        # In development / testing, allow missing credentials with a warning.
        logger.warning(
            "Firebase credentials file not found at %s. "
            "OTP verification will be unavailable.",
            creds_path,
        )
        return

    try:
        cred = credentials.Certificate(creds_path)
        _firebase_app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialised successfully")
    except Exception as e:
        logger.error("Failed to initialise Firebase Admin SDK: %s", e)
        raise


async def verify_firebase_token(id_token: str) -> dict:
    """
    Verify a Firebase phone-auth ID token.

    Returns the decoded JWT claims dict which includes `phone_number`.
    Raises HTTP 401 if the token is invalid or expired.
    Raises HTTP 503 if Firebase is not configured.
    """
    if _firebase_app is None:
        logger.error("Firebase not initialised — authentication service is unavailable")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service not configured",
        )

    try:
        decoded = auth.verify_id_token(id_token, app=_firebase_app)
        phone_number: str | None = decoded.get("phone_number")
        if not phone_number:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Token does not contain a phone number. Ensure phone auth was used.",
            )
        return decoded
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase token has expired. Please request a new OTP.",
        )
    except auth.InvalidIdTokenError as e:
        logger.warning("Invalid Firebase token: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase token",
        )
    except Exception as e:
        logger.error("Firebase token verification error: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token verification failed",
        )
