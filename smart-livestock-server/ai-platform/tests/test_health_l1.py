import numpy as np
import pytest

from app.capability.base import CapabilityContext, CapabilityLevel
from app.capability.health_l1 import HealthAnomalyL1
from app.capability.dl_l2 import DeepLearningL2
from app.capability.llm_l3 import LlmL3
from app.schemas import PredictRequest
from tests.conftest import make_triplet_series


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
    # 正常序列远离告警阈值（防误报，roadmap #2）。0.70 = 多 seed 实测最大 0.666 + 容差
    # （见 test_l1_normal_score_well_below_alert_threshold_across_seeds）。
    assert normal_resp.anomaly_score < 0.70, f"normal {normal_resp.anomaly_score}"


# 多 seed 绝对阈值（防误报，roadmap #2）；CUSUM/Mahalanobis 用经验排名不饱和。
# 实测 7 seed：normal_score max=0.666（cusum 已正确去饱和 0.93→0.23-0.77；
# joint 经验排名仍有正向偏置 0.77-1.0，因当前窗口相对历史 OAS 分布为 out-of-sample，
# 自然落在尾部——记录为已知现象，阈值选 0.70 = 实测最大 0.666 + 0.04 容差）。
@pytest.mark.parametrize("seed", [0, 1, 7, 42, 100, 123, 999])
def test_l1_normal_score_well_below_alert_threshold_across_seeds(seed):
    rng = np.random.default_rng(seed)
    normal = make_triplet_series(rng, inject_anomaly=False)
    cap = HealthAnomalyL1()
    resp = cap.predict_series(_make_req(), normal, cohort_baselines=[])
    assert resp.anomaly_score < 0.70, f"seed={seed}: normal {resp.anomaly_score}"
    assert resp.contributions.cusum < 0.85, f"seed={seed}: cusum {resp.contributions.cusum}"


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
