from pydantic_settings import BaseSettings
from pydantic import Field, field_validator
from functools import lru_cache


class Settings(BaseSettings):
    # MongoDB
    mongodb_url: str = Field(default="mongodb://localhost:27017", alias="MONGODB_URL")
    mongodb_db_name: str = Field(default="styleai", alias="MONGODB_DB_NAME")

    # Redis — Upstash REST API (avoids TLS socket issues)
    upstash_redis_url: str = Field(default="", alias="UPSTASH_REDIS_URL")
    upstash_redis_token: str = Field(default="", alias="UPSTASH_REDIS_TOKEN")

    # JWT — JWT_SECRET_KEY is required; no default allowed.
    jwt_secret_key: str = Field(alias="JWT_SECRET_KEY")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    jwt_expire_minutes: int = Field(default=43200, alias="JWT_EXPIRE_MINUTES")

    # Firebase
    firebase_credentials_path: str = Field(
        default="./firebase-credentials.json", alias="FIREBASE_CREDENTIALS_PATH"
    )

    # Cloudinary
    cloudinary_cloud_name: str = Field(default="", alias="CLOUDINARY_CLOUD_NAME")
    cloudinary_api_key: str = Field(default="", alias="CLOUDINARY_API_KEY")
    cloudinary_api_secret: str = Field(default="", alias="CLOUDINARY_API_SECRET")

    # OpenWeather
    openweather_api_key: str = Field(default="", alias="OPENWEATHER_API_KEY")

    # CORS — comma-separated list of allowed origins
    allowed_origins: str = Field(
        default="http://localhost:3000", alias="ALLOWED_ORIGINS"
    )

    # App
    debug: bool = Field(default=True, alias="DEBUG")
    app_title: str = "StyleAI API"
    app_version: str = "1.0.0"

    @field_validator("jwt_secret_key")
    @classmethod
    def jwt_secret_must_be_strong(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError(
                "JWT_SECRET_KEY must be at least 32 characters long. "
                "Generate one with: python -c \"import secrets; print(secrets.token_hex(32))\""
            )
        return v

    def get_allowed_origins_list(self) -> list[str]:
        """Parse the comma-separated ALLOWED_ORIGINS string into a list."""
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]

    model_config = {
        "env_file": ".env",
        "populate_by_name": True,
        "extra": "ignore",
    }


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
