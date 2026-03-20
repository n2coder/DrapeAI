import logging
from datetime import datetime, timedelta, timezone
from jose import JWTError, ExpiredSignatureError, jwt
from fastapi import HTTPException, status
from core.config import settings

logger = logging.getLogger(__name__)

# Enforce a minimum-security algorithm; reject weak/none algorithms
ALLOWED_ALGORITHMS = {"HS256", "HS384", "HS512", "RS256", "RS384", "RS512"}

CREDENTIALS_EXCEPTION = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Could not validate credentials",
    headers={"WWW-Authenticate": "Bearer"},
)

TOKEN_EXPIRED_EXCEPTION = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Token has expired",
    headers={"WWW-Authenticate": "Bearer"},
)


def create_access_token(user_id: str) -> str:
    """Create a signed JWT access token for the given user_id."""
    if settings.jwt_algorithm not in ALLOWED_ALGORITHMS:
        raise ValueError(
            f"Insecure JWT algorithm '{settings.jwt_algorithm}'. "
            f"Must be one of: {', '.join(sorted(ALLOWED_ALGORITHMS))}"
        )
    now = datetime.now(tz=timezone.utc)
    expire = now + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {
        "sub": user_id,
        "iat": now,
        "exp": expire,
        "type": "access",
    }
    token = jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)
    return token


def verify_token(token: str) -> str:
    """
    Decode and validate a JWT token.

    Explicitly checks the exp claim with leeway=0 (strict expiration).
    Rejects tokens signed with weak or disallowed algorithms.
    Returns the user_id (subject) on success, raises HTTP 401 on failure.
    """
    if settings.jwt_algorithm not in ALLOWED_ALGORITHMS:
        logger.error("Insecure JWT algorithm configured: %s", settings.jwt_algorithm)
        raise CREDENTIALS_EXCEPTION

    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
            options={"leeway": 0},
        )

        # Explicitly verify the exp claim is present and not expired
        exp = payload.get("exp")
        if exp is None:
            logger.warning("JWT missing exp claim")
            raise CREDENTIALS_EXCEPTION

        now = datetime.now(tz=timezone.utc).timestamp()
        if now >= exp:
            logger.warning("JWT token has expired (exp=%s, now=%s)", exp, now)
            raise TOKEN_EXPIRED_EXCEPTION

        user_id: str | None = payload.get("sub")
        token_type: str | None = payload.get("type")

        if user_id is None:
            raise CREDENTIALS_EXCEPTION
        if token_type != "access":
            raise CREDENTIALS_EXCEPTION

        return user_id

    except ExpiredSignatureError:
        logger.warning("JWT token expired (caught by jose)")
        raise TOKEN_EXPIRED_EXCEPTION
    except JWTError as e:
        logger.warning("JWT verification failed: %s", e)
        raise CREDENTIALS_EXCEPTION
