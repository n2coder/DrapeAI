from typing import Any, Optional
from fastapi.responses import JSONResponse


def success(
    data: Any = None,
    message: str = "Success",
    status_code: int = 200,
) -> JSONResponse:
    """Return a standardised success JSON response."""
    return JSONResponse(
        status_code=status_code,
        content={
            "success": True,
            "message": message,
            "data": data,
            "errors": None,
        },
    )


def error(
    message: str,
    status_code: int = 400,
    details: Optional[Any] = None,
) -> JSONResponse:
    """Return a standardised error JSON response."""
    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "message": message,
            "data": None,
            "errors": details,
        },
    )


def created(data: Any = None, message: str = "Created successfully") -> JSONResponse:
    return success(data=data, message=message, status_code=201)


def not_found(resource: str = "Resource") -> JSONResponse:
    return error(message=f"{resource} not found", status_code=404)


def unauthorized(message: str = "Unauthorized") -> JSONResponse:
    return error(message=message, status_code=401)
