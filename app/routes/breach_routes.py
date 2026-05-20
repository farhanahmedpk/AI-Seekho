"""
Breach Routes — Endpoints for querying and managing breach events.
"""

from fastapi import APIRouter, Request, HTTPException

router = APIRouter()


@router.get("/", summary="List all breaches")
async def list_breaches(request: Request):
    """Get all recorded breach events from Firebase."""
    firebase = request.app.state.firebase
    data = firebase.get_data("/breaches")
    return {"breaches": data or {}}


@router.get("/{breach_id}", summary="Get breach details")
async def get_breach(breach_id: str, request: Request):
    """Get full details of a specific breach including agent responses."""
    firebase = request.app.state.firebase
    data = firebase.get_data(f"/breaches/{breach_id}")

    if not data:
        raise HTTPException(status_code=404, detail=f"Breach {breach_id} not found")

    return {"breach": data}


@router.get("/{breach_id}/timeline", summary="Get breach agent timeline")
async def get_breach_timeline(breach_id: str, request: Request):
    """Get the agent response timeline for a breach (for frontend visualization)."""
    firebase = request.app.state.firebase
    responses = firebase.get_data(f"/breaches/{breach_id}/agent_responses")

    if not responses:
        raise HTTPException(
            status_code=404,
            detail=f"No agent responses found for breach {breach_id}",
        )

    return {"breach_id": breach_id, "agent_timeline": responses}


@router.get("/notifications/all", summary="Get all notifications")
async def get_notifications(request: Request):
    """Get all notifications (breach alerts, resolution updates, etc.)."""
    firebase = request.app.state.firebase
    data = firebase.get_data("/notifications")
    return {"notifications": data or {}}
