import json
import logging
import os
import tempfile
import firebase_admin
from firebase_admin import auth, credentials
from fastapi import HTTPException, status
from core.config import settings

logger = logging.getLogger(__name__)

_firebase_app: firebase_admin.App | None = None


def init_firebase() -> None:
    """Initialise the Firebase Admin SDK.

    Tries, in order:
    1. FIREBASE_CREDENTIALS_JSON env var (JSON string — preferred for cloud deployments)
    2. FIREBASE_CREDENTIALS_PATH file (local / Docker volume)
    """
    global _firebase_app

    if _firebase_app is not None:
        logger.debug("Firebase already initialised")
        return

    cred = None

    # 1. Try JSON string from environment variable
    if settings.firebase_credentials_json:
        try:
            cred_dict = json.loads(settings.firebase_credentials_json)
            cred = credentials.Certificate(cred_dict)
            logger.info("Firebase Admin SDK initialised from FIREBASE_CREDENTIALS_JSON env var")
        except Exception as e:
            logger.error("Failed to parse FIREBASE_CREDENTIALS_JSON: %s", e)
            raise

    # 2. Fall back to credentials file path
    if cred is None:
        creds_path = settings.firebase_credentials_path
        if not os.path.exists(creds_path):
            logger.warning(
                "Firebase credentials not found (checked FIREBASE_CREDENTIALS_JSON env var "
                "and file path %s). OTP verification will be unavailable.",
                creds_path,
            )
            return
        try:
            cred = credentials.Certificate(creds_path)
            logger.info("Firebase Admin SDK initialised from file %s", creds_path)
        except Exception as e:
            logger.error("Failed to initialise Firebase Admin SDK from file: %s", e)
            raise

    try:
        _firebase_app = firebase_admin.initialize_app(cred)
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
