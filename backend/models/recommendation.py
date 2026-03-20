from datetime import date as Date, datetime, timezone
from typing import Optional
from pydantic import BaseModel, Field
from models.wardrobe import ClothingItem


class WeatherContext(BaseModel):
    city: str
    temperature_c: float
    condition: str
    humidity: int
    wind_kph: float


class OutfitRecommendation(BaseModel):
    """A complete outfit recommendation document."""

    id: str
    user_id: str
    top: ClothingItem
    bottom: ClothingItem
    footwear: ClothingItem
    occasion: str
    weather_context: WeatherContext
    score: float = Field(..., ge=0.0, le=100.0)
    explanation: list[str] = Field(default_factory=list)
    style_notes: str = ""
    date: Date = Field(default_factory=Date.today)
    is_saved: bool = False
    created_at: datetime = Field(default_factory=lambda: datetime.now(tz=timezone.utc))

    model_config = {"arbitrary_types_allowed": True}


class RecommendationRequest(BaseModel):
    """Body for the custom recommendation endpoint."""

    occasion: Optional[str] = Field(
        default="casual",
        description="one of: office, casual, party, wedding, date, gym, travel",
    )
    use_current_weather: bool = Field(
        default=True,
        description="If True, fetch live weather for the user's city",
    )


class RecommendationResponse(BaseModel):
    """API response wrapper for a recommendation."""

    id: str
    top: dict
    bottom: dict
    footwear: dict
    occasion: str
    weather_context: WeatherContext
    score: float
    explanation: list[str]
    style_notes: str
    date: Date
    is_saved: bool
    created_at: datetime

    @classmethod
    def from_recommendation(cls, rec: OutfitRecommendation) -> "RecommendationResponse":
        def _item_dict(item: ClothingItem) -> dict:
            return {
                "id": item.id,
                "category": item.category if isinstance(item.category, str) else item.category.value,
                "color": item.color,
                "style": item.style if isinstance(item.style, str) else item.style.value,
                "image_url": item.image_url,
            }

        return cls(
            id=rec.id,
            top=_item_dict(rec.top),
            bottom=_item_dict(rec.bottom),
            footwear=_item_dict(rec.footwear),
            occasion=rec.occasion,
            weather_context=rec.weather_context,
            score=rec.score,
            explanation=rec.explanation,
            style_notes=rec.style_notes,
            date=rec.date,
            is_saved=rec.is_saved,
            created_at=rec.created_at,
        )
