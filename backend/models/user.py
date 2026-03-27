from datetime import datetime, timezone
from typing import Optional
from pydantic import BaseModel, Field, field_validator


class UserDocument(BaseModel):
    """Represents a user document as stored/retrieved from MongoDB."""

    id: str
    phone: str
    name: Optional[str] = None
    gender: Optional[str] = None              # male / female / non_binary / prefer_not_to_say
    age_range: Optional[str] = None           # 18-24 / 25-34 / 35-44 / 45+
    city: Optional[str] = None
    style_preferences: list[str] = Field(default_factory=list)
    onboarding_complete: bool = False
    created_at: datetime = Field(default_factory=lambda: datetime.now(tz=timezone.utc))
    last_login: Optional[datetime] = None

    model_config = {"arbitrary_types_allowed": True}


class UserCreate(BaseModel):
    """Payload used internally when creating a new user."""

    phone: str
    name: Optional[str] = None


class UserUpdate(BaseModel):
    """Fields a user can update on their own profile."""

    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    city: Optional[str] = Field(default=None, min_length=1, max_length=100)
    gender: Optional[str] = None
    age_range: Optional[str] = None
    style_preferences: Optional[list[str]] = None

    @field_validator("gender")
    @classmethod
    def validate_gender(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        allowed = {"male", "female", "other", "non_binary", "prefer_not_to_say"}
        if v not in allowed:
            raise ValueError(f"gender must be one of {allowed}")
        return v

    @field_validator("age_range")
    @classmethod
    def validate_age_range(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        allowed = {"13-17", "18-24", "25-34", "35-44", "45-54", "55+"}
        if v not in allowed:
            raise ValueError(f"age_range must be one of {allowed}")
        return v

    @field_validator("style_preferences")
    @classmethod
    def validate_style_preferences(cls, v: Optional[list[str]]) -> Optional[list[str]]:
        if v is None:
            return v
        allowed = {"casual", "ethnic", "formal", "urban", "streetwear", "bohemian", "minimalist", "sporty"}
        for pref in v:
            if pref not in allowed:
                raise ValueError(f"style_preference '{pref}' is not valid. Allowed: {allowed}")
        if len(v) > 2:
            raise ValueError("Maximum 2 style preferences allowed")
        return v


class OnboardingData(BaseModel):
    """Payload for the onboarding step."""

    gender: str
    age_range: str
    city: str = Field(..., min_length=1, max_length=100)
    style_preferences: list[str] = Field(..., min_length=1, max_length=2)

    @field_validator("gender")
    @classmethod
    def validate_gender(cls, v: str) -> str:
        allowed = {"male", "female", "other", "non_binary", "prefer_not_to_say"}
        if v not in allowed:
            raise ValueError(f"gender must be one of {allowed}")
        return v

    @field_validator("age_range")
    @classmethod
    def validate_age_range(cls, v: str) -> str:
        allowed = {"13-17", "18-24", "25-34", "35-44", "45-54", "55+", "45+"}
        if v not in allowed:
            raise ValueError(f"age_range must be one of {allowed}")
        return v

    @field_validator("style_preferences")
    @classmethod
    def validate_style_preferences(cls, v: list[str]) -> list[str]:
        allowed = {"casual", "ethnic", "formal", "urban", "streetwear", "bohemian", "minimalist", "sporty"}
        for pref in v:
            if pref not in allowed:
                raise ValueError(f"style_preference '{pref}' is not valid. Allowed: {allowed}")
        if len(v) > 2:
            raise ValueError("Maximum 2 style preferences allowed")
        return v


class UserResponse(BaseModel):
    """Public-facing user representation returned by the API."""

    id: str
    phone: str
    name: Optional[str] = None
    gender: Optional[str] = None
    age_range: Optional[str] = None
    city: Optional[str] = None
    style_preferences: list[str] = Field(default_factory=list)
    onboarding_complete: bool = False
    created_at: datetime

    @classmethod
    def from_document(cls, doc: UserDocument) -> "UserResponse":
        return cls(
            id=doc.id,
            phone=doc.phone,
            name=doc.name,
            gender=doc.gender,
            age_range=doc.age_range,
            city=doc.city,
            style_preferences=doc.style_preferences,
            onboarding_complete=doc.onboarding_complete,
            created_at=doc.created_at,
        )
