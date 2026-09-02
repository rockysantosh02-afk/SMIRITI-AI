"""Application-specific exceptions used by API handlers."""


class SmritiException(Exception):
    """Base exception with a stable API error code."""

    code = "smriti_error"

    def __init__(self, detail: str, code: str | None = None) -> None:
        self.detail = detail
        self.code = code or self.code
        super().__init__(detail)


class UnauthorizedException(SmritiException):
    """Raised when a request lacks valid authentication."""

    code = "unauthorized"

    def __init__(self, detail: str = "Authentication required") -> None:
        super().__init__(detail)


class NotFoundException(SmritiException):
    """Raised when a requested resource does not exist."""

    code = "not_found"

    def __init__(self, detail: str = "Resource not found") -> None:
        super().__init__(detail)


class ForbiddenException(SmritiException):
    """Raised when an authenticated user lacks permission."""

    code = "forbidden"

    def __init__(self, detail: str = "Access forbidden") -> None:
        super().__init__(detail)


class ValidationException(SmritiException):
    """Raised when request data fails validation."""

    code = "validation_error"


class ServerException(SmritiException):
    """Raised for an unexpected server-side failure."""

    code = "server_error"