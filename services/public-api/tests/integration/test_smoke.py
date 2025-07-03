"""
Basic smoke test to verify the integration testing framework.
"""

import pytest
from fastapi.testclient import TestClient


@pytest.mark.integration
def test_health_check(client: TestClient) -> None:
    """
    Tests that the health check endpoint returns a 200 OK response.
    """
    response = client.get("/health")
    assert response.status_code == 200  # nosec B101
    assert "status" in response.json()  # nosec B101
    assert response.json()["status"] == "healthy"  # nosec B101
