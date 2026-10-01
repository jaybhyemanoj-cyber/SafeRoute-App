import os
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check():
    """Test GET /health returns status ok."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "SafeRoute AI API"

def test_api_health_check():
    """Test GET /api/health returns status ok."""
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "SafeRoute AI API"

def test_explain_route_input_validation():
    """Test POST /api/explain-route with invalid safety_score range."""
    invalid_payload = {
        "safety_score": 150,  # Invalid: > 100
        "distance_km": 1.2,
        "duration_min": 15
    }
    response = client.post("/api/explain-route", json=invalid_payload)
    assert response.status_code == 422  # Unprocessable Entity (Pydantic validation)

def test_explain_hazard_fallback():
    """Test POST /api/explain-hazard handles missing keys gracefully."""
    # Ensure no keys set for test
    os.environ.pop("GEMINI_API_KEY", None)
    os.environ.pop("GROQ_API_KEY_1", None)
    
    payload = {
        "hazard_type": "poor_lighting",
        "distance_m": 12.5,
        "description": "Unlit street corner",
        "confidence": 0.8
    }
    response = client.post("/api/explain-hazard", json=payload)
    assert response.status_code == 500
    data = response.json()
    assert data["detail"]["fallback_available"] is True
