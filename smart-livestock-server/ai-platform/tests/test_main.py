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
    body = r.json()
    assert len(body["results"]) == 2
    # C1 回归：批量时每个 result 的 livestock_id 必须对应该 id，而非首个
    assert {res["livestock_id"] for res in body["results"]} == {10, 11}


def test_analyze_batch_rejects_empty(client):
    # review #1：批量端点空 livestock_ids → 400
    r = client.post("/ai/health/analyze",
                    json={"tenant_id": 1, "farm_id": 2, "livestock_ids": [], "window_hours": 24})
    assert r.status_code == 400


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
