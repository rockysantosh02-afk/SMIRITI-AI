from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = ""

    # Redis
    REDIS_URL: str = ""

    # ===== FIREBASE CONFIGURATION =====
    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_WEB_API_KEY: str = ""
    FIREBASE_AUTH_DOMAIN: str = ""
    FIREBASE_STORAGE_BUCKET: str = ""
    FIREBASE_MESSAGING_SENDER_ID: str = ""
    FIREBASE_APP_ID: str = ""
    FIREBASE_MEASUREMENT_ID: str = ""

    # Firebase Service Account (JSON fields as env vars)
    FIREBASE_TYPE: str = "service_account"
    FIREBASE_PRIVATE_KEY_ID: str = ""
    FIREBASE_PRIVATE_KEY: str = ""
    FIREBASE_CLIENT_EMAIL: str = ""
    FIREBASE_CLIENT_ID: str = ""
    FIREBASE_AUTH_URI: str = "https://accounts.google.com/o/oauth2/auth"
    FIREBASE_TOKEN_URI: str = "https://oauth2.googleapis.com/token"
    FIREBASE_AUTH_PROVIDER_X509_CERT_URL: str = "https://www.googleapis.com/oauth2/v1/certs"
    FIREBASE_CLIENT_X509_CERT_URL: str = ""

    # ===== SECURITY =====
    SECRET_KEY: str = "CHANGE_THIS_SECRET_KEY"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    DEVICE_TOKEN_EXPIRE_DAYS: int = 180

    # ===== EXTERNAL APIS =====
    GEMINI_API_KEY: str | None = None

    # ===== CORS & DEPLOYMENT =====
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:5000,http://127.0.0.1:3000"
    ENVIRONMENT: str = "development"

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore"
    )


settings = Settings()