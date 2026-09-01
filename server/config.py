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

    # Plain string, comma-separated. MUST stay str: pydantic-settings tries
    # to json.loads() env values for list fields, and Render sets "*" which
    # is not valid JSON -> SettingsError at startup -> deploy fails.
    CORS_ORIGINS: str = os.getenv("CORS_ORIGINS", "*")

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]

    # Set true in production (Render). Disables uvicorn --reload.
    PRODUCTION: bool = os.getenv("PRODUCTION", "false").lower() in ("1", "true", "yes")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
