"""API v1 router.

All endpoint handlers are registered here and included by the app factory
with the prefix ``/api/v1``.

Current endpoints (Phase 0 stub):
    GET /api/v1/health  →  liveness probe
"""

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


# ── Response schemas ──────────────────────────────────────────────────────────

class HealthResponse(BaseModel):
    """Response body for the health-check endpoint."""

    status: str
    version: str


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Liveness probe",
    tags=["health"],
)
async def health_check() -> HealthResponse:
    """Return ``{"status": "ok"}`` to confirm the service is alive.

    This endpoint is intentionally dependency-free so that it succeeds
    even if the database or external services are unavailable.
    """
    return HealthResponse(status="ok", version="0.1.0")
