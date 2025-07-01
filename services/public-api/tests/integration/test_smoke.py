"""
Basic smoke test to verify the integration testing framework.
"""

import pytest
from httpx import AsyncClient


@pytest.mark.integration
async def test_health_check(client: AsyncClient) -> None:
    """
    Tests that the health check endpoint returns a 200 OK response.
    """
    response = await client.get("/healthz")
    assert response.status_code == 200  # nosec B101
    assert response.json() == {"status": "ok"}  # nosec B101
