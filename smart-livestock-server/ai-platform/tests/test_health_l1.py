import pytest
from app.capability.base import CapabilityContext, CapabilityLevel
from app.capability.health_l1 import HealthAnomalyL1
from app.capability.dl_l2 import DeepLearningL2
from app.capability.llm_l3 import LlmL3
from app.schemas import PredictRequest


def _make_req():
    return PredictRequest(tenant_id=1, farm_id=2, livestock_ids=[10])


def test_l1_is_available_when_has_data():
    cap = HealthAnomalyL1()
    ctx = CapabilityContext(n_eff=120)
    assert cap.is_available(ctx) is True
    assert cap.level == CapabilityLevel.L1


def test_l1_predict_normal_returns_low_score(normal_series):
    cap = HealthAnomalyL1()
    resp = cap.predict_series(_make_req(), normal_series, cohort_baselines=[])
    assert 0.0 <= resp.anomaly_score <= 1.0
    assert resp.anomaly_type in ("normal", "circadian_disruption", "abrupt_change", "multivariate")
    assert resp.capability_used == "health_l1"


def test_l1_predict_anomaly_scores_higher(anomaly_series, normal_series):
    cap = HealthAnomalyL1()
    normal_resp = cap.predict_series(_make_req(), normal_series, cohort_baselines=[])
    anomaly_resp = cap.predict_series(_make_req(), anomaly_series, cohort_baselines=[])
    assert anomaly_resp.anomaly_score > normal_resp.anomaly_score


def test_l1_cold_start_low_neff_still_returns(normal_series):
    cap = HealthAnomalyL1()
    ctx = CapabilityContext(n_eff=10)
    assert cap.is_available(ctx) is True  # L1 始终可用（内部降级到规则档）
    # tail(20)：20 槽全非空 → n_eff=20 < 30 → 路由 rules 档（冷启动）
    resp = cap.predict_series(_make_req(), normal_series.tail(20), cohort_baselines=[])
    assert resp.model_meta.get("router") == "rules"


def test_l2_l3_unavailable():
    assert DeepLearningL2().is_available(CapabilityContext()) is False
    assert LlmL3().is_available(CapabilityContext()) is False
