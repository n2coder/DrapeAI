from datetime import datetime, timezone
from enum import Enum
from typing import Any, Dict, Optional
from pydantic import BaseModel, Field


class Category(str, Enum):
    top = "top"
    bottom = "bottom"
    footwear = "footwear"
    outerwear = "outerwear"
    accessories = "accessories"
    dress = "dress"
    ethnic_wear = "ethnic_wear"


class Style(str, Enum):
    casual = "casual"
    ethnic = "ethnic"
    formal = "formal"
    urban = "urban"
    streetwear = "streetwear"
    bohemian = "bohemian"
    minimalist = "minimalist"


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
    # Populated asynchronously by GPT-4o Vision after upload
    ai_attributes: Optional[Dict[str, Any]] = None
    # Populated asynchronously by image enhancer after upload
    enhanced_url: Optional[str] = None   # Cloudinary BG-removed / colour-corrected URL
    dalle_url: Optional[str] = None      # DALL-E clean product render (only for low-quality photos)

    model_config = {"use_enum_values": True}


class ClothingItemCreate(BaseModel):
    """Data provided when adding a new wardrobe item (form fields)."""

    category: Category
    color: str = Field(..., min_length=1, max_length=50)
    style: Style


class ClothingItemAddRequest(BaseModel):
    """JSON body for POST /wardrobe/add (Flutter uploads image to Cloudinary directly)."""

    image_url: str = Field(..., min_length=1)
    category: Category
    color: str = Field(..., min_length=1, max_length=50)
    style: Style
    brand: Optional[str] = Field(default=None, max_length=100)
    notes: Optional[str] = Field(default=None, max_length=500)


class ClothingItemUpdate(BaseModel):
    """Fields that can be updated on an existing wardrobe item."""

    category: Optional[Category] = None
    color: Optional[str] = Field(default=None, min_length=1, max_length=50)
    style: Optional[Style] = None
    image_url: Optional[str] = Field(default=None, min_length=1)
    brand: Optional[str] = Field(default=None, max_length=100)
    notes: Optional[str] = Field(default=None, max_length=500)


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
    ai_attributes: Optional[Dict[str, Any]] = None
    enhanced_url: Optional[str] = None
    dalle_url: Optional[str] = None

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
            ai_attributes=item.ai_attributes,
            enhanced_url=item.enhanced_url,
            dalle_url=item.dalle_url,
        )
