"""
Pydantic schemas for sensor data, breaches, shipments, and agent responses.
"""

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


# ── Enums ──────────────────────────────────────────────────────


class BreachSeverity(str, Enum):
    """Severity levels for temperature breaches."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class BreachStatus(str, Enum):
    """Lifecycle status of a breach event."""
    DETECTED = "detected"
    ANALYZING = "analyzing"
    ACTION_RECOMMENDED = "action_recommended"
    EXECUTING = "executing"
    RESOLVED = "resolved"


class ShipmentStatus(str, Enum):
    """Status of a shipment."""
    IN_TRANSIT = "in_transit"
    DELIVERED = "delivered"
    QUARANTINED = "quarantined"
    REJECTED = "rejected"


# ── Sensor Data ────────────────────────────────────────────────


class SensorReading(BaseModel):
    """A single temperature reading from a truck sensor."""
    sensor_id: str
    truck_id: str
    temperature: float = Field(..., description="Temperature in °C")
    humidity: Optional[float] = Field(None, description="Humidity percentage")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    location: Optional[dict] = Field(
        None, description="GPS coordinates {lat, lng}"
    )


class SensorReadingCreate(BaseModel):
    """Payload for posting a new sensor reading (e.g., from simulator)."""
    sensor_id: str
    truck_id: str
    temperature: float
    humidity: Optional[float] = None
    location: Optional[dict] = None


# ── Breach ─────────────────────────────────────────────────────


class BreachEvent(BaseModel):
    """Represents a detected temperature breach incident."""
    breach_id: str
    sensor_id: str
    truck_id: str
    temperature: float
    threshold_violated: str = Field(
        ..., description="Which threshold was violated (upper/lower/critical)"
    )
    severity: BreachSeverity
    status: BreachStatus = BreachStatus.DETECTED
    detected_at: datetime = Field(default_factory=datetime.utcnow)
    resolved_at: Optional[datetime] = None

    # Agent outputs populated progressively
    analysis: Optional[dict] = None
    recommended_actions: Optional[dict] = None
    execution_log: Optional[dict] = None


# ── Shipment ───────────────────────────────────────────────────


class Shipment(BaseModel):
    """A shipment being transported in a refrigerated truck."""
    shipment_id: str
    truck_id: str
    product_type: str = Field(..., description="e.g. Vaccines, Dairy, Seafood")
    quantity: int
    origin: str
    destination: str
    required_temp_min: float
    required_temp_max: float
    status: ShipmentStatus = ShipmentStatus.IN_TRANSIT
    loaded_at: Optional[datetime] = None
    estimated_arrival: Optional[datetime] = None


# ── Agent Responses ────────────────────────────────────────────


class AgentResponse(BaseModel):
    """Standardized wrapper for any agent's output."""
    agent_name: str
    breach_id: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    reasoning: str = Field(..., description="AI chain-of-thought reasoning")
    result: dict = Field(..., description="Structured output from the agent")
    confidence: Optional[float] = Field(
        None, ge=0, le=1, description="Agent's self-assessed confidence 0-1"
    )


class AnalysisResult(BaseModel):
    """Output of the Analysis Agent."""
    breach_id: str
    affected_shipments: list[str]
    severity: BreachSeverity
    exposure_duration_minutes: float
    product_risk_assessment: str
    reasoning: str


class DecisionResult(BaseModel):
    """Output of the Decision Agent."""
    breach_id: str
    recommended_actions: list[str]
    priority: str
    estimated_loss: Optional[float] = None
    reasoning: str


class ExecutionResult(BaseModel):
    """Output of the Execution Agent."""
    breach_id: str
    actions_taken: list[dict]
    notifications_sent: list[str]
    replacement_order: Optional[dict] = None
    quarantine_status: str
    reasoning: str
