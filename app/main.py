"""
Cold Chain Breach Detection System — FastAPI Application

Main FastAPI app with CORS, lifespan events, and route registration.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from app.config import settings
from app.services.firebase_service import FirebaseService
from app.services.monitor_service import MonitorService
from app.routes import sensor_routes, agent_routes, breach_routes


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown lifecycle hooks."""
    # ── Startup ────────────────────────────────────────────────
    logger.info("🚀 Cold Chain Breach Detection System starting up...")

    # Initialize Firebase
    firebase_service = FirebaseService()
    firebase_service.initialize()
    app.state.firebase = firebase_service
    logger.info("🔥 Firebase initialized")

    # Start the real-time sensor monitor
    monitor = MonitorService(firebase_service)
    app.state.monitor = monitor
    await monitor.start()
    logger.info("📡 Sensor monitoring started")

    yield

    # ── Shutdown ───────────────────────────────────────────────
    logger.info("🛑 Shutting down...")
    await monitor.stop()
    logger.info("👋 Goodbye!")


def create_app() -> FastAPI:
    """Factory function to create and configure the FastAPI application."""

    app = FastAPI(
        title="Cold Chain Breach Detection System",
        description=(
            "Real-time temperature monitoring and AI-driven breach response "
            "for refrigerated truck shipments."
        ),
        version="1.0.0",
        lifespan=lifespan,
    )

    # ── CORS (allow Flutter frontend) ──────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Tighten in production
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── Routes ─────────────────────────────────────────────────
    app.include_router(sensor_routes.router, prefix="/api/sensors", tags=["Sensors"])
    app.include_router(breach_routes.router, prefix="/api/breaches", tags=["Breaches"])
    app.include_router(agent_routes.router, prefix="/api/agents", tags=["Agents"])

    @app.get("/", tags=["Health"])
    async def health_check():
        return {
            "status": "operational",
            "system": "Cold Chain Breach Detection System",
            "version": "1.0.0",
        }

    return app


app = create_app()
