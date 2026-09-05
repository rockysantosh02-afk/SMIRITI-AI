from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.firestore_service import FirestoreServiceError
from app.core.firebase_admin import FirebaseInitializationError, get_firestore
from app.core.config import settings
from app.exceptions import ForbiddenException, NotFoundException, ServerException, SmritiException, UnauthorizedException, ValidationException
from app.logging_config import configure_logging
from app.routers import auth, games, journal, reminders, sync, test_helpers, voice

configure_logging()
import logging
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize process-level application state without requiring Firebase."""
    logger.info("Smriti AI API started")
    yield
    logger.info("Smriti AI API stopped")


app = FastAPI(
    title="SMRITI-AI API",
    description="Backend services for Smriti AI cognitive care experiences.",
    version="0.1.0",
    lifespan=lifespan,
)

allowed_origins = [origin.strip() for origin in settings.ALLOWED_ORIGINS.split(",") if origin.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def security_headers(request: Request, call_next):
    """Add low-risk browser protections without logging request secrets."""
    response = await call_next(request)
    response.headers.setdefault("X-Content-Type-Options", "nosniff")
    response.headers.setdefault("X-Frame-Options", "DENY")
    response.headers.setdefault("Referrer-Policy", "no-referrer")
    return response


@app.get("/")
async def root():
    return {
        "service": "SMRITI-AI API",
        "version": app.version,
        "status": "running",
    }


@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "smriti-ai",
    }


@app.get("/test-firestore")
async def test_firestore():
    """Check that the backend can reach Firestore without modifying data."""
    try:
        next(get_firestore().collection("users").limit(1).stream(), None)
        return {"status": "connected", "service": "firestore"}
    except Exception:
        logger.exception("Firestore connectivity check failed")
        raise FirestoreServiceError(
            "Firestore is not configured or unavailable"
        ) from None


@app.get("/ready")
async def readiness_check():
    """Verify backend readiness including Firestore connectivity if configured."""
    try:
        get_firestore()
        return {"status": "ready", "service": "smriti-ai", "firestore": "configured"}
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={"status": "not_ready", "service": "smriti-ai", "error": str(e)},
        )


app.include_router(auth.router)
app.include_router(games.router)
app.include_router(test_helpers.router)
app.include_router(journal.router)
app.include_router(reminders.router)
app.include_router(sync.router)
app.include_router(voice.router)


def _error_response(status_code: int, detail: str) -> JSONResponse:
    return JSONResponse(status_code=status_code, content={"detail": detail, "code": str(status_code)})


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(_: Request, exc: StarletteHTTPException) -> JSONResponse:
    """Normalize FastAPI HTTP errors into the API error format."""
    detail = exc.detail if isinstance(exc.detail, str) else str(exc.detail)
    return _error_response(exc.status_code, detail)


@app.exception_handler(RequestValidationError)
async def validation_error_handler(_: Request, exc: RequestValidationError) -> JSONResponse:
    """Normalize request validation failures into the API error format."""
    return JSONResponse(status_code=422, content={"detail": str(exc.errors()), "code": "validation_error"})


@app.exception_handler(UnauthorizedException)
async def unauthorized_exception_handler(_: Request, exc: UnauthorizedException) -> JSONResponse:
    return _error_response(401, exc.detail)


@app.exception_handler(NotFoundException)
async def not_found_exception_handler(_: Request, exc: NotFoundException) -> JSONResponse:
    return _error_response(404, exc.detail)


@app.exception_handler(ForbiddenException)
async def forbidden_exception_handler(_: Request, exc: ForbiddenException) -> JSONResponse:
    return _error_response(403, exc.detail)


@app.exception_handler(SmritiException)
async def smriti_exception_handler(_: Request, exc: SmritiException) -> JSONResponse:
    status_code = {"unauthorized": 401, "forbidden": 403, "not_found": 404, "validation_error": 422, "server_error": 500}.get(exc.code, 500)
    return JSONResponse(status_code=status_code, content={"detail": exc.detail, "code": exc.code})


@app.exception_handler(FirestoreServiceError)
async def firestore_error_handler(_: Request, exc: FirestoreServiceError) -> JSONResponse:
    """Return a useful response for known Firestore failures."""
    return _error_response(503, str(exc))


@app.exception_handler(FirebaseInitializationError)
async def firebase_initialization_error_handler(
    _: Request, exc: FirebaseInitializationError
) -> JSONResponse:
    """Return a clear service-unavailable response when Firebase is not configured."""
    return _error_response(503, str(exc))


@app.exception_handler(Exception)
async def internal_error_handler(_: Request, exc: Exception) -> JSONResponse:
    """Prevent unexpected exceptions from leaking implementation details."""
    logger.exception("Unhandled application error: %s", exc)
    return _error_response(500, "Internal server error")