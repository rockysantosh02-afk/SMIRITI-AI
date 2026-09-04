from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://smriti:smriti123@localhost:5432/smriti_ai"

    REDIS_URL: str = "redis://localhost:6379/0"

    FIREBASE_PROJECT_ID: str = ""

    FIREBASE_STORAGE_BUCKET: str = ""

    FIREBASE_CREDENTIALS_PATH: str = "service-account-key.json"

    SECRET_KEY: str = "CHANGE_THIS_SECRET_KEY"

    ALGORITHM: str = "HS256"

    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    DEVICE_TOKEN_EXPIRE_DAYS: int = 180

    GEMINI_API_KEY: str | None = None

    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:5000,http://127.0.0.1:3000"
    ENVIRONMENT: str = "development"

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore"
    )


settings = Settings()