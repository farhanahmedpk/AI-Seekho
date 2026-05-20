"""
Monitor Service

Continuously polls Firebase sensor readings and detects temperature breaches.
When a breach is detected, it kicks off the multi-agent pipeline.
"""

import asyncio
import uuid
from datetime import datetime

from loguru import logger

from app.config import settings
from app.models.schemas import BreachSeverity, BreachStatus
from app.services.firebase_service import FirebaseService


class MonitorService:
    """
    Background service that monitors sensor readings from Firebase
    and triggers the agent pipeline when a breach is detected.
    """

    def __init__(self, firebase: FirebaseService):
        self.firebase = firebase
        self._running = False
        self._task: asyncio.Task | None = None

    async def start(self):
        """Start the monitoring loop as a background task."""
        self._running = True
        self._task = asyncio.create_task(self._monitor_loop())
        logger.info(
            f"Monitor started — polling every {settings.monitor_interval}s"
        )

    async def stop(self):
        """Gracefully stop the monitoring loop."""
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        logger.info("Monitor stopped")

    async def _monitor_loop(self):
        """Main polling loop — reads all truck sensors and checks thresholds."""
        while self._running:
            try:
                await self._check_all_trucks()
            except Exception as e:
                logger.error(f"Monitor loop error: {e}")

            await asyncio.sleep(settings.monitor_interval)

    async def _check_all_trucks(self):
        """Fetch latest readings for every truck and evaluate thresholds."""
        trucks_data = self.firebase.get_all_trucks()
        if not trucks_data:
            return

        for truck_id, readings in trucks_data.items():
            if not readings:
                continue

            # Get the most recent reading (last pushed entry)
            if isinstance(readings, dict):
                latest_key = list(readings.keys())[-1]
                latest = readings[latest_key]
            else:
                continue

            temperature = latest.get("temperature")
            if temperature is None:
                continue

            # ── Threshold check ────────────────────────────────
            breach_type = self._evaluate_temperature(temperature)
            if breach_type:
                await self._handle_breach(
                    truck_id=truck_id,
                    sensor_id=latest.get("sensor_id", "unknown"),
                    temperature=temperature,
                    breach_type=breach_type,
                )

    def _evaluate_temperature(self, temp: float) -> str | None:
        """
        Check if a temperature value violates any threshold.

        Returns:
            A string describing the violation type, or None if within bounds.
        """
        if temp >= settings.temp_critical_upper:
            return "critical_upper"
        elif temp <= settings.temp_critical_lower:
            return "critical_lower"
        elif temp >= settings.temp_breach_upper:
            return "upper"
        elif temp <= settings.temp_breach_lower:
            return "lower"
        return None

    def _classify_severity(self, breach_type: str) -> BreachSeverity:
        """Map breach type to severity level."""
        if "critical" in breach_type:
            return BreachSeverity.CRITICAL
        return BreachSeverity.HIGH

    async def _handle_breach(
        self,
        truck_id: str,
        sensor_id: str,
        temperature: float,
        breach_type: str,
    ):
        """
        Called when a breach is detected.
        Creates a breach record and triggers the agent pipeline.
        """
        breach_id = f"BREACH-{uuid.uuid4().hex[:8].upper()}"
        severity = self._classify_severity(breach_type)

        breach_data = {
            "breach_id": breach_id,
            "sensor_id": sensor_id,
            "truck_id": truck_id,
            "temperature": temperature,
            "threshold_violated": breach_type,
            "severity": severity.value,
            "status": BreachStatus.DETECTED.value,
            "detected_at": datetime.utcnow().isoformat(),
        }

        # Persist to Firebase
        self.firebase.save_breach(breach_id, breach_data)
        logger.warning(
            f"🚨 BREACH DETECTED — {breach_id} | Truck: {truck_id} | "
            f"Temp: {temperature}°C | Severity: {severity.value}"
        )

        # Trigger the agent pipeline asynchronously
        from app.agents.pipeline import run_agent_pipeline

        asyncio.create_task(run_agent_pipeline(breach_id, breach_data, self.firebase))
