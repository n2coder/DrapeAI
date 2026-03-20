import logging
from core.weather_client import get_weather, WeatherData
from core.redis_client import cache_get, cache_set, WEATHER_TTL

logger = logging.getLogger(__name__)


async def get_weather_for_city(city: str) -> WeatherData:
    """
    Return weather data for a city, using Redis as a short-lived cache to
    avoid hammering the OpenWeather API.

    Cache key:  weather:{city_lower}
    TTL:        WEATHER_TTL (1800 seconds = 30 minutes)
    """
    cache_key = f"weather:{city.lower().strip()}"

    cached = await cache_get(cache_key)
    if cached:
        logger.debug("Weather cache hit for city: %s", city)
        return WeatherData(**cached)

    logger.debug("Weather cache miss for city: %s — fetching from API", city)
    weather = await get_weather(city)

    await cache_set(
        cache_key,
        {
            "city": weather.city,
            "temperature_c": weather.temperature_c,
            "condition": weather.condition,
            "humidity": weather.humidity,
            "wind_kph": weather.wind_kph,
            "description": weather.description,
        },
        ttl=WEATHER_TTL,
    )

    return weather
