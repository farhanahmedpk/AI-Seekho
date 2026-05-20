"""
Cold Chain Breach Detection System — Configuration

Loads environment variables and defines application-wide settings
including temperature thresholds, Firebase config, and Gemini API keys.
"""

from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # ── Gemini AI ──────────────────────────────────────────────
    gemini_api_key: str = Field(default="", description="Google Gemini API key")
    openrouter_api_key: str = Field(..., description="OpenRouter API key")
    openrouter_api_key_2: str = Field(default="", description="Optional fallback OpenRouter API key 2")
    openrouter_api_key_3: str = Field(default="", description="Optional fallback OpenRouter API key 3")

    # ── Firebase ───────────────────────────────────────────────
    firebase_database_url: str = Field(..., description="Firebase Realtime DB URL")
    firebase_service_account_path: str = Field(
        default="serviceAccountKey.json",
        description="Path to Firebase service account JSON",
    )

    # ── Application ────────────────────────────────────────────
    app_host: str = Field(default="0.0.0.0")
    app_port: int = Field(default=8000)
    app_debug: bool = Field(default=True)

    # ── Temperature Thresholds (°C) ────────────────────────────
    temp_breach_upper: float = Field(
        default=8.0,
        description="Upper temp limit — above this is a breach",
    )
    temp_breach_lower: float = Field(
        default=-25.0,
        description="Lower temp limit — below this is a breach",
    )
    temp_critical_upper: float = Field(
        default=15.0,
        description="Critical upper threshold — immediate action needed",
    )
    temp_critical_lower: float = Field(
        default=-30.0,
        description="Critical lower threshold — immediate action needed",
    )

    # ── Monitoring ─────────────────────────────────────────────
    monitor_interval: int = Field(
        default=5,
        description="Sensor polling interval in seconds",
    )

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
    }


# Singleton instance used throughout the app
settings = Settings()
