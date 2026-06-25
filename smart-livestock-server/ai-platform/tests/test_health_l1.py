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
# Mahalanobis d2_hist 使用 LOOCV（每个历史样本在排除自身的 OAS 模型下计距），消除
# 原 in-sample 偏差（in-sample joint 1.000 → LOOCV joint 0.75-0.96）。
# Baseline self-leak 修复（评审 #4 延伸至基线层）：baseline 改从 history_df 算，排除当前窗口。
# 实测影响可忽略（normal_score 0.41-0.65 未变）——因 baseline 仅影响 Mahalanobis 10 维中的 3 维
# (dim_z)，其余 7 维 (slope*3 + stl_peak*3 + cusum) 由时序边界效应主导：当前窗口位于历史分布
# 的天然尾部（slope/stl_peak 末段噪声），与 baseline 无关。Phase A 已知限制：normal 残留 0.41-0.65，
# 待 Phase B 真实数据校准（更长的历史基线 + 更细的特征工程可进一步压低）。
# 阈值 0.70 = 实测最大 0.65 + 0.05 容差；anomaly > normal 在所有 seed 上稳定成立（test_l1_predict_anomaly_scores_higher）。
@pytest.mark.parametrize("seed", [0, 1, 7, 42, 100, 123, 999])
def test_l1_normal_score_well_below_alert_threshold_across_seeds(seed):
    rng = np.random.default_rng(seed)
    normal = make_triplet_series(rng, inject_anomaly=False)
    # 同 seed 注入异常（对齐 anomaly_series fixture）：验证判别力不被压低
    rng2 = np.random.default_rng(seed)
    anomaly = make_triplet_series(rng2, inject_anomaly=True)
    cap = HealthAnomalyL1()
    resp = cap.predict_series(_make_req(), normal, cohort_baselines=[])
    resp_a = cap.predict_series(_make_req(), anomaly, cohort_baselines=[])
    assert resp.anomaly_score < 0.70, f"seed={seed}: normal {resp.anomaly_score}"
    assert resp.contributions.cusum < 0.85, f"seed={seed}: cusum {resp.contributions.cusum}"
    assert resp.contributions.joint < 1.0, f"seed={seed}: joint {resp.contributions.joint}"
    # 判别力（roadmap #1）：anomaly 必须高于 normal
    assert resp_a.anomaly_score > resp.anomaly_score, (
        f"seed={seed}: anomaly {resp_a.anomaly_score} <= normal {resp.anomaly_score}")


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
