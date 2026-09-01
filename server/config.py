import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", "sqlite+aiosqlite:///./locked_in.db"
    )
    SECRET_KEY: str = os.getenv("SECRET_KEY", "locked-in-dev-secret-change-in-production-2026")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    REFRESH_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 30  # 30 days
    ADMIN_INVITE_CODE: str = "LOCKEDIN2026"
    CORS_ORIGINS: list[str] = ["*"]
    # Set true in production (Render). Disables uvicorn --reload.
    PRODUCTION: bool = os.getenv("PRODUCTION", "false").lower() in ("1", "true", "yes")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
