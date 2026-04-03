import logging
from datetime import datetime, timezone
from fastapi import APIRouter, Request
from core.database import get_database
from core.rate_limiter import limiter
from models.waitlist import WaitlistRequest
from utils.response import success, error

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/waitlist", tags=["Waitlist"])


@router.post("", summary="Join the DrapeAI waitlist")
@limiter.limit("3/hour")
async def join_waitlist(request: Request, body: WaitlistRequest):
    """
    Public endpoint — no auth required.
    Saves an email + optional name to the waitlist collection.
    Silently deduplicates (same email returns success without saving twice).
    Rate-limited to 3 submissions per IP per hour.
    """
    db = get_database()
    col = db["waitlist"]

    email_lower = body.email.strip().lower()

    # Deduplicate — return success if already on list
    existing = await col.find_one({"email": email_lower})
    if existing:
        logger.info("Waitlist: duplicate submission for email (masked)")
        return success(
            data={"already_registered": True},
            message="You're already on the waitlist! We'll be in touch.",
        )

    doc = {
        "email": email_lower,
        "name": body.name,
        "source": "landing_page",
        "created_at": datetime.now(timezone.utc),
    }

    result = await col.insert_one(doc)
    logger.info("Waitlist: new entry inserted id=%s", result.inserted_id)

    return success(
        data={"already_registered": False},
        message="You're on the list! We'll notify you when DrapeAI launches.",
        status_code=201,
    )


@router.get("/count", summary="Get total waitlist count (public)")
async def waitlist_count():
    """Returns total number of waitlist signups — safe to show publicly."""
    db = get_database()
    col = db["waitlist"]
    count = await col.count_documents({})
    return success(data={"count": count}, message="Waitlist count")
