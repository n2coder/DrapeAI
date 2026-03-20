import logging
import io
import cloudinary
import cloudinary.uploader
from fastapi import HTTPException, status
from core.config import settings

logger = logging.getLogger(__name__)

WARDROBE_FOLDER = "styleai/wardrobe"


def init_cloudinary() -> None:
    """Configure the Cloudinary SDK from application settings."""
    cloudinary.config(
        cloud_name=settings.cloudinary_cloud_name,
        api_key=settings.cloudinary_api_key,
        api_secret=settings.cloudinary_api_secret,
        secure=True,
    )
    logger.info("Cloudinary configured for cloud: %s", settings.cloudinary_cloud_name)


async def upload_image(
    file_bytes: bytes,
    public_id: str,
    folder: str = WARDROBE_FOLDER,
) -> str:
    """
    Upload image bytes to Cloudinary.

    Args:
        file_bytes: Raw image bytes.
        public_id:  Desired public ID (without folder prefix).
        folder:     Cloudinary folder path.

    Returns:
        The secure URL of the uploaded image.

    Raises:
        HTTPException 500 if upload fails.
    """
    if not settings.cloudinary_cloud_name:
        logger.warning("Cloudinary not configured — returning placeholder URL")
        return f"https://placeholder.styleai.app/{folder}/{public_id}.jpg"

    try:
        result = cloudinary.uploader.upload(
            io.BytesIO(file_bytes),
            public_id=public_id,
            folder=folder,
            overwrite=True,
            resource_type="image",
            transformation=[
                {"width": 1024, "height": 1024, "crop": "limit"},
                {"quality": "auto", "fetch_format": "auto"},
            ],
        )
        url: str = result.get("secure_url", "")
        if not url:
            raise ValueError("Cloudinary response missing secure_url")
        logger.info("Image uploaded: %s/%s -> %s", folder, public_id, url)
        return url
    except Exception as e:
        logger.error("Cloudinary upload failed for %s/%s: %s", folder, public_id, e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Image upload failed. Please try again.",
        )


async def delete_image(public_id: str) -> bool:
    """
    Delete an image from Cloudinary by its full public_id (including folder).

    Returns True on success, False on failure (non-raising).
    """
    if not settings.cloudinary_cloud_name:
        logger.warning("Cloudinary not configured — skipping image deletion for %s", public_id)
        return True

    try:
        result = cloudinary.uploader.destroy(public_id, resource_type="image")
        success = result.get("result") == "ok"
        if success:
            logger.info("Image deleted from Cloudinary: %s", public_id)
        else:
            logger.warning("Cloudinary delete returned non-ok result for %s: %s", public_id, result)
        return success
    except Exception as e:
        logger.error("Cloudinary delete failed for %s: %s", public_id, e)
        return False


def build_public_id(user_id: str, item_id: str) -> str:
    """Construct a deterministic Cloudinary public_id for a wardrobe item."""
    return f"{user_id}_{item_id}"
