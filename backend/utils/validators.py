import re
from fastapi import HTTPException, status

# Allowed occasions for outfit requests
VALID_OCCASIONS = {"office", "casual", "party", "wedding", "date", "gym", "travel"}

# Allowed style preferences
VALID_STYLE_PREFERENCES = {"casual", "ethnic", "formal", "urban", "sporty", "bohemian"}


def validate_phone(phone: str) -> str:
    """
    Validate and normalise a phone number.

    Accepts strings with or without leading +91 / 0.
    Returns a clean 10-digit Indian mobile number string.
    Raises HTTP 400 if the format is invalid.
    """
    cleaned = phone.strip()

    # Strip country code variations
    if cleaned.startswith("+91"):
        cleaned = cleaned[3:]
    elif cleaned.startswith("91") and len(cleaned) == 12:
        cleaned = cleaned[2:]
    elif cleaned.startswith("0"):
        cleaned = cleaned[1:]

    # Remove any non-digit characters remaining
    cleaned = re.sub(r"\D", "", cleaned)

    if len(cleaned) != 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid phone number. Expected 10 digits after stripping country code, got '{cleaned}'.",
        )

    if not re.match(r"^[6-9]\d{9}$", cleaned):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number must start with 6, 7, 8, or 9 (Indian mobile numbers only).",
        )

    return cleaned


def validate_max_style_preferences(prefs: list[str]) -> list[str]:
    """
    Validate that the list has at most 2 style preferences and that each
    entry is a recognised style tag.

    Raises HTTP 400 on violation.
    """
    if len(prefs) > 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You can select a maximum of 2 style preferences.",
        )

    invalid = [p for p in prefs if p not in VALID_STYLE_PREFERENCES]
    if invalid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid style preferences: {invalid}. Allowed: {sorted(VALID_STYLE_PREFERENCES)}",
        )

    return prefs


def validate_occasion(occasion: str) -> str:
    """Ensure the occasion string is one of the supported values."""
    if occasion not in VALID_OCCASIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid occasion '{occasion}'. Allowed: {sorted(VALID_OCCASIONS)}",
        )
    return occasion
