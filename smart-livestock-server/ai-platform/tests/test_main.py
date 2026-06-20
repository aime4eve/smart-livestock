import pytest
import pandas as pd
from fastapi.testclient import TestClient
from app.main import app


@pytest.fixture
def client():
    return TestClient(app)


def test_live_endpoint(client):
    r = client.get("/ai/health/live")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_analyze_single(client, normal_series, monkeypatch):
    import app.main as mainmod
    monkeypatch.setattr(mainmod, "_fetch", lambda lid, h: {
        "temperature": normal_series["temperature"],
        "motility": normal_series["motility"],
        "activity": normal_series["activity"],
    })
    r = client.post("/ai/health/analyze/10", json={"tenant_id": 1, "farm_id": 2, "window_hours": 24})
    assert r.status_code == 200
    body = r.json()
    assert body["request_id"]
    assert len(body["results"]) == 1
    assert 0.0 <= body["results"][0]["anomaly_score"] <= 1.0


def test_analyze_batch(client, normal_series, monkeypatch):
    import app.main as mainmod
    monkeypatch.setattr(mainmod, "_fetch", lambda lid, h: {
        "temperature": normal_series["temperature"],
        "motility": normal_series["motility"],
        "activity": normal_series["activity"],
    })
    r = client.post("/ai/health/analyze",
                    json={"tenant_id": 1, "farm_id": 2, "livestock_ids": [10, 11], "window_hours": 24})
    assert r.status_code == 200
    assert len(r.json()["results"]) == 2


def test_analyze_single_handles_missing_data(client, monkeypatch):
    import app.main as mainmod
    monkeypatch.setattr(mainmod, "_fetch", lambda lid, h: {
        "temperature": pd.Series([], dtype=float),
        "motility": pd.Series([], dtype=float),
        "activity": pd.Series([], dtype=float),
    })
    r = client.post("/ai/health/analyze/10", json={"tenant_id": 1, "farm_id": 2, "window_hours": 24})
    # 无数据时返回 normal 兜底，不报 5xx
    assert r.status_code == 200
    assert r.json()["results"][0]["anomaly_score"] == 0.0
