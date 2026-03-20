from datetime import datetime, timezone
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class Category(str, Enum):
    top = "top"
    bottom = "bottom"
    footwear = "footwear"


class Style(str, Enum):
    casual = "casual"
    ethnic = "ethnic"
    formal = "formal"
    urban = "urban"


class ClothingItem(BaseModel):
    """Full clothing item as stored in and returned from MongoDB."""

    id: str
    user_id: str
    category: Category
    color: str
    style: Style
    image_url: str
    cloudinary_public_id: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(tz=timezone.utc))

    model_config = {"use_enum_values": True}


class ClothingItemCreate(BaseModel):
    """Data provided when adding a new wardrobe item (form fields)."""

    category: Category
    color: str = Field(..., min_length=1, max_length=50)
    style: Style


class ClothingItemUpdate(BaseModel):
    """Fields that can be updated on an existing wardrobe item."""

    category: Optional[Category] = None
    color: Optional[str] = Field(default=None, min_length=1, max_length=50)
    style: Optional[Style] = None


class ClothingItemResponse(BaseModel):
    """API response representation of a clothing item."""

    id: str
    user_id: str
    category: str
    color: str
    style: str
    image_url: str
    cloudinary_public_id: str
    created_at: datetime

    @classmethod
    def from_item(cls, item: ClothingItem) -> "ClothingItemResponse":
        return cls(
            id=item.id,
            user_id=item.user_id,
            category=item.category if isinstance(item.category, str) else item.category.value,
            color=item.color,
            style=item.style if isinstance(item.style, str) else item.style.value,
            image_url=item.image_url,
            cloudinary_public_id=item.cloudinary_public_id,
            created_at=item.created_at,
        )
