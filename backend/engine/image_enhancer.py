"""
AI Image Enhancement Pipeline.

Takes a raw clothing photo and produces a clean, product-style image:
  1. GPT-4o Vision grades the photo quality
  2. Cloudinary URL transformations: auto-enhance, sharpen, colour-correct
  3. Background removal via Cloudinary e_background_removal add-on
     (free tier: 50/month — gracefully falls back if not enabled)
  4. DALL-E image enhancement as final option for wrinkle / noise removal
     (only triggered if photo quality is below threshold)

Returns:
  enhanced_url  — Cloudinary URL with all transformations baked in (instant)
  clean_url     — DALL-E refined version (higher quality, takes ~5s, may be None)
"""

import base64
import logging
import re
from typing import Optional, Tuple

from core.openai_client import get_openai_client

logger = logging.getLogger(__name__)

# ── Cloudinary URL transformation helpers ────────────────────────────────────

def build_enhanced_cloudinary_url(original_url: str) -> str:
    """
    Inject free Cloudinary transformations into an existing secure URL.

    Transformations applied (all free-tier):
      e_improve:outdoor:60   — AI auto-enhance for product photography
      e_auto_color           — auto white balance / colour correction
      e_auto_contrast        — stretch contrast range
      e_sharpen:80           — sharpen edges (clothing detail)

    Note: e_background_removal is a paid add-on and is intentionally excluded.
    """
    if not original_url or "res.cloudinary.com" not in original_url:
        return original_url

    transforms = (
        "e_improve:outdoor:60,"
        "e_auto_color,"
        "e_auto_contrast,"
        "e_sharpen:80"
    )
    enhanced = re.sub(
        r"(/upload/)",
        f"/upload/{transforms}/",
        original_url,
        count=1,
    )
    return enhanced


# ── GPT-4o photo quality grader ──────────────────────────────────────────────

_GRADE_PROMPT = """You are a fashion product photography expert.
Grade this clothing photo on a scale 0-10 and identify issues.

Return ONLY raw JSON:
{
  "score": <0-10 float>,
  "issues": ["<e.g. wrinkled fabric>", "<crumpled>", "<poor lighting>", "<cluttered background>"],
  "is_flat_lay": <true/false — is item laid flat on surface?>,
  "needs_enhancement": <true if score < 7>
}"""


async def grade_photo(image_bytes: bytes) -> Optional[dict]:
    """Ask GPT-4o to grade photo quality. Returns None on failure."""
    client = get_openai_client()
    if client is None:
        return None
    try:
        import json
        b64 = base64.b64encode(image_bytes).decode()
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=200,
            temperature=0,
            messages=[
                {"role": "system", "content": _GRADE_PROMPT},
                {"role": "user", "content": [
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64}", "detail": "low"}},
                    {"type": "text", "text": "Grade this clothing photo."},
                ]},
            ],
        )
        raw = resp.choices[0].message.content.strip()
        if raw.startswith("```"):
            raw = raw.split("```")[1].lstrip("json").strip()
        return json.loads(raw)
    except Exception as e:
        logger.warning("Photo grading failed: %s", e)
        return None


# ── DALL-E wrinkle / clutter removal ─────────────────────────────────────────

async def enhance_with_dalle(image_bytes: bytes, item_description: str) -> Optional[str]:
    """
    Use DALL-E to produce a clean product-style render of the clothing item.
    Only used when the original photo is low quality (wrinkled, bad lighting).

    Returns a URL to the DALL-E generated image, or None on failure.
    """
    client = get_openai_client()
    if client is None:
        return None

    prompt = (
        f"High-end e-commerce product photo of exactly one {item_description}. "
        "The garment must match the description precisely — do not change the garment type, colour, or style. "
        "Flat lay on a pure white background, perfect soft studio lighting, no wrinkles, "
        "no shadows, crisp edges, shot straight from above, magazine quality."
    )

    try:
        response = await client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            quality="standard",
            n=1,
        )
        url = response.data[0].url
        logger.info("DALL-E enhancement generated: %s", url[:60])
        return url
    except Exception as e:
        logger.warning("DALL-E enhancement failed: %s", e)
        return None


# ── Main entry point ──────────────────────────────────────────────────────────

async def enhance_clothing_image(
    image_bytes: bytes,
    original_url: str,
    item_description: str = "clothing item",
) -> Tuple[str, Optional[str]]:
    """
    Full enhancement pipeline.

    Returns:
        (enhanced_cloudinary_url, dalle_url_or_None)
        enhanced_cloudinary_url is always returned (instant, URL-based).
        dalle_url is only returned when photo quality is poor (score < 6).
    """
    # Always generate the Cloudinary enhanced URL (free, instant)
    # DALL-E generation is disabled — it generates from text and produces wrong garments.
    enhanced_url = build_enhanced_cloudinary_url(original_url)
    return enhanced_url, None
