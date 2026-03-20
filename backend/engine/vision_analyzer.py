"""
Option A — Vision Analysis.

Sends a clothing image to GPT-4o Vision and extracts structured attributes:
  - detected_color   : actual color seen in the image (may override user tag)
  - fabric_type      : e.g. "cotton", "denim", "silk", "polyester"
  - pattern          : e.g. "solid", "striped", "checkered", "floral", "graphic"
  - formality_level  : 1 (very casual) → 5 (very formal)
  - fit_type         : "slim", "regular", "oversized", "relaxed"
  - season           : ["summer"] | ["winter"] | ["all-season"] etc.
  - style_tags       : list of style descriptors e.g. ["streetwear", "minimalist"]
  - ai_category      : model's best guess at category (top/bottom/footwear)
  - confidence       : 0.0–1.0 overall confidence in the analysis

All fields are optional — if the model is unsure it returns null for that field.
Returns None if OpenAI is not configured or the call fails (graceful degradation).
"""

import base64
import json
import logging
from typing import Optional

from core.openai_client import get_openai_client

logger = logging.getLogger(__name__)

_SYSTEM_PROMPT = """You are a fashion AI assistant that analyses clothing images.
Your task is to examine the clothing item in the photo and return a JSON object
with the following fields. Be precise and concise.

{
  "detected_color": "<primary color name, e.g. navy, olive, off-white>",
  "fabric_type": "<e.g. cotton, denim, silk, wool, polyester, linen, synthetic>",
  "pattern": "<solid | striped | checkered | floral | graphic | abstract | animal-print | plain>",
  "formality_level": <integer 1-5, where 1=very casual, 5=very formal>,
  "fit_type": "<slim | regular | oversized | relaxed | tailored>",
  "season": ["<summer|winter|monsoon|spring|all-season> — list applicable seasons"],
  "style_tags": ["<2-4 style descriptors e.g. minimalist, streetwear, ethnic, preppy>"],
  "ai_category": "<top | bottom | footwear | outerwear | accessory>",
  "confidence": <float 0.0-1.0>
}

Rules:
- Return ONLY the raw JSON object, no markdown fences, no explanation.
- If you cannot determine a field with reasonable confidence, set it to null.
- detected_color should be a simple human-readable color name (not hex).
- formality_level: 1=gym/loungewear, 2=casual, 3=smart-casual, 4=business, 5=black-tie/ethnic formal.
"""


async def analyze_clothing_image(image_bytes: bytes) -> Optional[dict]:
    """
    Analyse a clothing image with GPT-4o Vision.

    Args:
        image_bytes: Raw bytes of the image (JPEG / PNG / WebP).

    Returns:
        Dict of extracted attributes, or None if unavailable / failed.
    """
    client = get_openai_client()
    if client is None:
        return None

    # Encode image as base64 data URL
    b64 = base64.b64encode(image_bytes).decode("utf-8")
    data_url = f"data:image/jpeg;base64,{b64}"

    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",  # Vision-capable, fast, cheap
            max_tokens=400,
            temperature=0.1,       # Low temp for consistent structured output
            messages=[
                {"role": "system", "content": _SYSTEM_PROMPT},
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image_url",
                            "image_url": {"url": data_url, "detail": "low"},
                        },
                        {
                            "type": "text",
                            "text": "Analyse this clothing item and return the JSON.",
                        },
                    ],
                },
            ],
        )

        raw = response.choices[0].message.content.strip()

        # Strip markdown fences if model adds them despite instructions
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]

        attributes = json.loads(raw)
        logger.info("Vision analysis complete — confidence=%.2f", attributes.get("confidence", 0))
        return attributes

    except json.JSONDecodeError as e:
        logger.warning("Vision analysis returned invalid JSON: %s", e)
        return None
    except Exception as e:
        logger.warning("Vision analysis failed: %s", e)
        return None
