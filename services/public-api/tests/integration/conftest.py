"""
Minimal integration test fixtures.
"""

from collections.abc import AsyncGenerator

import pytest
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient


@pytest.fixture
async def app() -> AsyncGenerator[FastAPI, None]:
    """
    Create a minimal FastAPI application for integration testing.
    """
    app = FastAPI(title="Test App")

    @app.get("/healthz")
    async def health_check() -> dict[str, str]:
        return {"status": "ok"}

    yield app


@pytest.fixture
async def client(app: FastAPI) -> AsyncGenerator[AsyncClient, None]:
    """
    Create an HTTP client for the test app.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
