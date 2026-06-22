import pytest
import pandas as pd
from contextlib import contextmanager
from fastapi.testclient import TestClient
from app.main import app


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def stub_connect(monkeypatch):
    """评审 H1：端点调 dbmod.connect()，测试 stub 成 yield None（_fetch 另行 mock，conn 不做真实查询）。"""
    @contextmanager
    def _fake():
        yield None
    import app.db as dbmod
    monkeypatch.setattr(dbmod, "connect", _fake)


def test_live_endpoint(client):
    r = client.get("/ai/health/live")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_analyze_single(client, normal_series, monkeypatch, stub_connect):
    import app.main as mainmod
    monkeypatch.setattr(mainmod, "_fetch", lambda conn, lid, h: {
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


def test_analyze_batch(client, normal_series, monkeypatch, stub_connect):
    import app.main as mainmod
    monkeypatch.setattr(mainmod, "_fetch", lambda conn, lid, h: {
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


def test_analyze_single_handles_missing_data(client, monkeypatch, stub_connect):
    import app.main as mainmod
    monkeypatch.setattr(mainmod, "_fetch", lambda conn, lid, h: {
        "temperature": pd.Series([], dtype=float),
        "motility": pd.Series([], dtype=float),
        "activity": pd.Series([], dtype=float),
    })
    r = client.post("/ai/health/analyze/10", json={"tenant_id": 1, "farm_id": 2, "window_hours": 24})
    # 无数据时返回 normal 兜底，不报 5xx
    assert r.status_code == 200
    assert r.json()["results"][0]["anomaly_score"] == 0.0


def test_analyze_single_ignores_body_livestock_ids(client, normal_series, monkeypatch, stub_connect):
    # 评审 M3：单头端点用 SinglePredictRequest（无 livestock_ids 字段），
    # 客户端误传 body livestock_ids 应被 pydantic 忽略，以 path 参数为准
    import app.main as mainmod
    monkeypatch.setattr(mainmod, "_fetch", lambda conn, lid, h: {
        "temperature": normal_series["temperature"],
        "motility": normal_series["motility"],
        "activity": normal_series["activity"],
    })
    r = client.post("/ai/health/analyze/10",
                    json={"tenant_id": 1, "farm_id": 2, "window_hours": 24, "livestock_ids": [999]})
    assert r.status_code == 200
    assert r.json()["results"][0]["livestock_id"] == 10  # path 参数，非 body 的 999
