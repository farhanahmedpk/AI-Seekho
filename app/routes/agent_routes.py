"""
Agent Routes — Endpoints to manually trigger agents or query agent status.

Useful for testing individual agents or re-running the pipeline.
"""

import asyncio
from fastapi import APIRouter, Request, HTTPException

from app.agents.pipeline import run_agent_pipeline

router = APIRouter()


@router.post("/trigger/{breach_id}", summary="Manually trigger agent pipeline")
async def trigger_pipeline(breach_id: str, request: Request):
    """
    Manually trigger the full agent pipeline for an existing breach.
    Useful for re-processing or demo purposes.
    """
    firebase = request.app.state.firebase
    breach_data = firebase.get_data(f"/breaches/{breach_id}")

    if not breach_data:
        raise HTTPException(status_code=404, detail=f"Breach {breach_id} not found")

    # Run pipeline as background task
    asyncio.create_task(run_agent_pipeline(breach_id, breach_data, firebase))

    return {
        "status": "pipeline_triggered",
        "breach_id": breach_id,
        "message": "Agent pipeline is running in the background",
    }


@router.get("/responses/{breach_id}", summary="Get all agent responses for a breach")
async def get_agent_responses(breach_id: str, request: Request):
    """Get the responses from all agents for a specific breach."""
    firebase = request.app.state.firebase
    responses = firebase.get_data(f"/breaches/{breach_id}/agent_responses")

    if not responses:
        raise HTTPException(
            status_code=404,
            detail=f"No agent responses found for {breach_id}",
        )

    return {"breach_id": breach_id, "agent_responses": responses}


@router.get("/status/{breach_id}", summary="Get pipeline status")
async def get_pipeline_status(breach_id: str, request: Request):
    """Quick check on the current status of a breach's pipeline."""
    firebase = request.app.state.firebase
    breach_data = firebase.get_data(f"/breaches/{breach_id}")

    if not breach_data:
        raise HTTPException(status_code=404, detail=f"Breach {breach_id} not found")

    return {
        "breach_id": breach_id,
        "status": breach_data.get("status", "unknown"),
        "severity": breach_data.get("severity", "unknown"),
    }
