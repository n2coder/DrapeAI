import asyncio
import logging
import os
import time
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from core.config import settings
from core.database import connect_to_mongo, close_mongo_connection, init_indexes
from core.redis_client import init_redis, close_redis
from core.firebase_admin import init_firebase
from core.cloudinary_client import init_cloudinary
from core.rate_limiter import limiter
from middleware.security_headers import SecurityHeadersMiddleware
from routers import auth, users, wardrobe, recommendations

# ---------------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Lifespan — startup / shutdown
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialise all external services on startup and tear them down cleanly."""
    logger.info("Starting StyleAI API v%s", settings.app_version)

    # MongoDB
    await connect_to_mongo()
    await init_indexes()

    # Redis
    await init_redis()

    # Firebase Admin SDK
    init_firebase()

    # Cloudinary
    init_cloudinary()

    logger.info("All services initialised — application is ready")

    # Start self-ping keep-alive task (prevents Render free tier from sleeping)
    keep_alive_task = asyncio.create_task(_keep_alive_loop())

    yield  # ---------- application running ----------

    logger.info("Shutting down StyleAI API…")
    keep_alive_task.cancel()
    await close_mongo_connection()
    await close_redis()
    logger.info("Shutdown complete")


# ---------------------------------------------------------------------------
# Keep-alive loop (prevents Render free tier from sleeping after 15 min)
# ---------------------------------------------------------------------------
async def _keep_alive_loop() -> None:
    """
    Pings the app's own /health endpoint every 10 minutes.
    Only runs when RENDER_EXTERNAL_URL env var is set (i.e. on Render).
    """
    render_url = os.getenv("RENDER_EXTERNAL_URL")
    if not render_url:
        logger.info("Keep-alive disabled (not running on Render)")
        return

    ping_url = f"{render_url.rstrip('/')}/health"
    interval = 10 * 60  # 10 minutes
    logger.info("Keep-alive started — pinging %s every %d min", ping_url, interval // 60)

    await asyncio.sleep(60)  # wait 1 min after startup before first ping
    while True:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(ping_url)
                logger.info("Keep-alive ping → %s %s", ping_url, resp.status_code)
        except Exception as exc:
            logger.warning("Keep-alive ping failed: %s", exc)
        await asyncio.sleep(interval)


# ---------------------------------------------------------------------------
# FastAPI application
# ---------------------------------------------------------------------------
app = FastAPI(
    title=settings.app_title,
    version=settings.app_version,
    description=(
        "StyleAI Backend — rule-based outfit recommendation engine "
        "with phone authentication, wardrobe management, and weather-aware suggestions."
    ),
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
    lifespan=lifespan,
)

# ---------------------------------------------------------------------------
# Rate limiter setup
# ---------------------------------------------------------------------------
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# ---------------------------------------------------------------------------
# Middleware
# ---------------------------------------------------------------------------

# Security headers — must be added before other middleware
app.add_middleware(SecurityHeadersMiddleware)

# CORS — use explicit allowed origins from settings; never wildcard with credentials
_allowed_origins = settings.get_allowed_origins_list()
app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def request_logging_middleware(request: Request, call_next):
    """Log every incoming request and its response time."""
    start_time = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - start_time) * 1000
    logger.info(
        "%s %s — %s  (%.1f ms)",
        request.method,
        request.url.path,
        response.status_code,
        elapsed_ms,
    )
    return response


# ---------------------------------------------------------------------------
# Global exception handlers
# ---------------------------------------------------------------------------

@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={
            "success": False,
            "message": f"Endpoint '{request.url.path}' not found",
            "data": None,
            "errors": None,
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_error_handler(request: Request, exc: RequestValidationError):
    errors = []
    for err in exc.errors():
        errors.append({
            "field": " -> ".join(str(loc) for loc in err["loc"]),
            "message": err["msg"],
            "type": err["type"],
        })
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "success": False,
            "message": "Request validation failed",
            "data": None,
            "errors": errors,
        },
    )


@app.exception_handler(500)
async def internal_error_handler(request: Request, exc):
    logger.exception("Unhandled internal server error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "message": "An unexpected internal server error occurred",
            "data": None,
            "errors": None,
        },
    )


# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(wardrobe.router)
app.include_router(recommendations.router)


# ---------------------------------------------------------------------------
# Root + Health check
# ---------------------------------------------------------------------------
@app.get("/", tags=["System"], summary="API root", include_in_schema=False)
async def root():
    """Root endpoint — confirms the API is live."""
    return {
        "success": True,
        "service": settings.app_title,
        "version": settings.app_version,
        "message": "DrapeAI API is running. Visit /health for status.",
        "docs": "/docs" if settings.debug else None,
    }


@app.get("/health", tags=["System"], summary="Health check")
async def health_check():
    """Returns service health status. Used by load balancers and monitoring."""
    return {
        "success": True,
        "status": "ok",
        "version": settings.app_version,
        "service": settings.app_title,
    }


# ---------------------------------------------------------------------------
# Entry point (dev server)
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
        log_level="debug" if settings.debug else "info",
    )
