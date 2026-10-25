"""Health-check endpoint test.

Run with::

    pytest backend/tests/test_health.py -v
"""

import pytest
from fastapi.testclient import TestClient

from backend.app.main import app


@pytest.fixture(scope="module")
def client() -> TestClient:
    """Return a synchronous test client for the FastAPI app."""
    return TestClient(app)


def test_health_returns_200(client: TestClient) -> None:
    """GET /api/v1/health must return HTTP 200."""
    response = client.get("/api/v1/health")
    assert response.status_code == 200


def test_health_response_schema(client: TestClient) -> None:
    """GET /api/v1/health must return the expected JSON schema."""
    response = client.get("/api/v1/health")
    body = response.json()
    assert body["status"] == "ok"
    assert "version" in body


def test_health_content_type(client: TestClient) -> None:
    """GET /api/v1/health must return application/json."""
    response = client.get("/api/v1/health")
    assert "application/json" in response.headers["content-type"]
