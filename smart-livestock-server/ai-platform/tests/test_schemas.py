import pytest
from app.schemas import (CapabilityLevel, PredictRequest, PredictResponse,
                         Contributions, AnalyzeResponse, AnomalyType, CapabilityUsed)


def test_predict_request_defaults():
    req = PredictRequest(tenant_id=1, farm_id=2, livestock_ids=[10, 11])
    assert req.window_hours == 24
    assert req.live_endpoint is False


def test_predict_response_fields():
    resp = PredictResponse(
        livestock_id=10, anomaly_score=0.82, anomaly_type="multivariate",
        contributions=Contributions(stl=0.7, cusum=0.3, joint=0.9),
        capability_used="health_l1", n_eff=120, model_meta={"router": "mahalanobis"},
    )
    assert resp.anomaly_score == pytest.approx(0.82)
    assert resp.capability_used == "health_l1"
    assert resp.model_meta["router"] == "mahalanobis"


def test_anomaly_score_range():
    with pytest.raises(Exception):
        PredictResponse(livestock_id=10, anomaly_score=1.5, anomaly_type="x",
                        contributions=Contributions(), capability_used="l1",
                        n_eff=1, model_meta={})


def test_capability_level_values():
    assert CapabilityLevel.L1 == "L1"
    assert CapabilityLevel.L2 == "L2"
    assert CapabilityLevel.L3 == "L3"


def test_analyze_response_envelope():
    r = AnalyzeResponse(request_id="req-1", results=[])
    assert r.results == []


def test_anomaly_type_enum_values():
    # 评审 M6：AnomalyType 枚举覆盖 design §4.4 四类
    assert AnomalyType.NORMAL == "normal"
    assert AnomalyType.CIRCADIAN_DISRUPTION == "circadian_disruption"
    assert AnomalyType.ABRUPT_CHANGE == "abrupt_change"
    assert AnomalyType.MULTIVARIATE == "multivariate"


def test_predict_response_rejects_invalid_anomaly_type():
    # 评审 M6：枚举约束拦截拼写错误（如 "abrubt_change"）
    with pytest.raises(Exception):
        PredictResponse(livestock_id=10, anomaly_score=0.5, anomaly_type="abrubt_change",
                        contributions=Contributions(), capability_used="health_l1",
                        n_eff=1, model_meta={})


def test_predict_response_rejects_invalid_capability_used():
    # 评审 M6：capability_used 仅允许 health_l1 / none
    with pytest.raises(Exception):
        PredictResponse(livestock_id=10, anomaly_score=0.5, anomaly_type="normal",
                        contributions=Contributions(), capability_used="l2_placeholder",
                        n_eff=1, model_meta={})
