import logging
from typing import Annotated
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from bson import ObjectId
from core.security import verify_token
from core.database import get_users_collection
from models.user import UserDocument

logger = logging.getLogger(__name__)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/verify-otp")


async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
) -> UserDocument:
    """
    Dependency that validates the Bearer JWT and returns the corresponding
    UserDocument. Raises HTTP 401 if the token is invalid or the user is
    not found in MongoDB.
    """
    user_id = verify_token(token)

    users_col = get_users_collection()
    try:
        oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user identifier in token",
        )

    raw = await users_col.find_one({"_id": oid})
    if raw is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User associated with this token no longer exists",
        )

    raw["id"] = str(raw.pop("_id"))
    return UserDocument(**raw)


CurrentUser = Annotated[UserDocument, Depends(get_current_user)]
