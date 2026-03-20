import logging
from dataclasses import dataclass
import httpx
from core.config import settings

logger = logging.getLogger(__name__)

OPENWEATHER_BASE_URL = "https://api.openweathermap.org/data/2.5/weather"


@dataclass
class WeatherData:
    city: str
    temperature_c: float
    condition: str          # cold / mild / warm / hot / rainy / humid
    humidity: int
    wind_kph: float
    description: str        # raw description from API


def _map_condition(temperature_c: float, description: str, humidity: int) -> str:
    """Map numeric weather data to a named condition string."""
    desc_lower = description.lower()

    # Rain check takes priority
    if any(word in desc_lower for word in ("rain", "drizzle", "shower", "storm", "thunder")):
        return "rainy"

    # Humidity
    if humidity >= 80 and temperature_c >= 25:
        return "humid"

    # Temperature ranges
    if temperature_c < 15:
        return "cold"
    if temperature_c <= 25:
        return "mild"
    if temperature_c <= 32:
        return "warm"
    return "hot"


async def get_weather(city: str) -> WeatherData:
    """
    Fetch current weather for a city from OpenWeatherMap.
    Falls back to default mild weather when the API key is missing or the
    request fails, so the rest of the recommendation flow is unaffected.
    """
    if not settings.openweather_api_key:
        logger.warning("OpenWeather API key not configured — using default weather for %s", city)
        return WeatherData(
            city=city,
            temperature_c=25.0,
            condition="mild",
            humidity=60,
            wind_kph=10.0,
            description="clear sky",
        )

    params = {
        "q": city,
        "appid": settings.openweather_api_key,
        "units": "metric",
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(OPENWEATHER_BASE_URL, params=params)
            response.raise_for_status()
            data = response.json()

        temp_c: float = data["main"]["temp"]
        humidity: int = data["main"]["humidity"]
        wind_ms: float = data["wind"].get("speed", 0.0)
        wind_kph: float = round(wind_ms * 3.6, 1)
        description: str = data["weather"][0]["description"] if data.get("weather") else "clear sky"
        condition = _map_condition(temp_c, description, humidity)

        return WeatherData(
            city=city,
            temperature_c=round(temp_c, 1),
            condition=condition,
            humidity=humidity,
            wind_kph=wind_kph,
            description=description,
        )

    except httpx.HTTPStatusError as e:
        logger.warning(
            "OpenWeather API HTTP error for city '%s': %s — using default", city, e.response.status_code
        )
    except httpx.RequestError as e:
        logger.warning("OpenWeather API request error for city '%s': %s — using default", city, e)
    except (KeyError, ValueError) as e:
        logger.warning("Unexpected OpenWeather response format: %s — using default", e)

    # Fallback default
    return WeatherData(
        city=city,
        temperature_c=25.0,
        condition="mild",
        humidity=60,
        wind_kph=10.0,
        description="clear sky",
    )
