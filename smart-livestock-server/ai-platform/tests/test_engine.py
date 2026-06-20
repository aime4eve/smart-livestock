import pandas as pd
from app.engine import Engine
from app.capability.health_l1 import HealthAnomalyL1
from app.capability.router import CapabilityRegistry   # 修正：router 不是 base
from app.schemas import PredictRequest


def test_engine_routes_to_l1(normal_series):
    reg = CapabilityRegistry()
    reg.register(HealthAnomalyL1())
    engine = Engine(registry=reg)
    req = PredictRequest(tenant_id=1, farm_id=2, livestock_ids=[10])
    resp = engine.predict_series(req, slots_df=normal_series, cohort_baselines=[])
    assert resp.capability_used == "health_l1"


def test_engine_returns_none_when_no_capability(monkeypatch):
    reg = CapabilityRegistry()  # 空
    engine = Engine(registry=reg)
    req = PredictRequest(tenant_id=1, farm_id=2, livestock_ids=[10])
    df = pd.DataFrame()
    assert engine.predict_series(req, slots_df=df, cohort_baselines=[]) is None
