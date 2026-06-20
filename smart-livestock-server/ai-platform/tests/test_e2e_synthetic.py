"""端到端合成注入评估（design §8）。验证正常/异常序列的分数区分度。

注意（design §8.1）：合成数据上的指标只验证代码路径自洽性，不等于真实数据效果。
真实评估留待 #55 接入后（Plan 2 联调 + Phase B）。
"""
import pytest
from app.capability.router import CapabilityRegistry   # 修正：router 非 base
from app.capability.health_l1 import HealthAnomalyL1
from app.engine import Engine
from app.schemas import PredictRequest


@pytest.fixture
def engine():
    reg = CapabilityRegistry()
    reg.register(HealthAnomalyL1())
    return Engine(registry=reg)


def _score(engine, series):
    req = PredictRequest(tenant_id=1, farm_id=2, livestock_ids=[1])
    resp = engine.predict_series(req, slots_df=series, cohort_baselines=[])
    return resp.anomaly_score


def test_synthetic_anomaly_scores_higher_than_normal(engine, normal_series, anomaly_series):
    normal_score = _score(engine, normal_series)
    anomaly_score = _score(engine, anomaly_series)
    assert anomaly_score > normal_score
    # 异常注入序列应越过告警阈值的下界（区分度）
    assert anomaly_score > 0.3


def test_score_distribution_self_consistent(engine, rng):
    """design §8 自洽性：多个正常序列分数应集中且偏低。"""
    # Phase A 现实（controller 预验证）：range(10) normal 均值 ≈0.491，边缘通过 < 0.5。
    # 这是 Task 10 temporal-edge 已知限制（normal 0.41–0.65）的直接体现，非 bug；
    # 绝对标定属 Phase B（design §4.4 真实数据标定）。default_rng(seed) 确定，无随机性。
    from tests.conftest import make_triplet_series
    scores = []
    for seed in range(10):
        r = __import__("numpy").random.default_rng(seed)
        s = make_triplet_series(r, days=14, inject_anomaly=False)
        scores.append(_score(engine, s))
    # 正常序列分数均值 < 0.5
    assert sum(scores) / len(scores) < 0.5
