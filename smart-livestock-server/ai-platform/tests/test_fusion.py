import numpy as np
import pytest
from app.l1.fusion import (normalize_stl, normalize_cusum, normalize_mahalanobis,
                           fuse, decide_anomaly_type)


def test_normalize_stl_identity_in_range_and_clips_at_bounds():
    # in-range → identity（区分"什么都不做"的错误实现）
    assert normalize_stl(0.7) == pytest.approx(0.7)
    assert normalize_stl(0.0) == pytest.approx(0.0)
    # 超上界 → clip 1（stl_layer_score sigmoid 理论上不产出，但 clip 契约需锁定）
    assert normalize_stl(1.5) == pytest.approx(1.0)
    # 负值（理论上不出现）→ clip 下界 0
    assert normalize_stl(-0.3) == pytest.approx(0.0)


def test_normalize_cusum_uses_history_max():
    # 当前 10，历史最大 20 → 0.5
    assert normalize_cusum(10.0, history_max=20.0) == pytest.approx(0.5)
    assert normalize_cusum(30.0, history_max=20.0) == pytest.approx(1.0)  # 超历史截断 1
    assert normalize_cusum(0.0, history_max=20.0) == pytest.approx(0.0)


def test_normalize_mahalanobis_chi2_cdf():
    # 自由度 10，d2 = 中位数附近 → ~0.5
    from scipy.stats import chi2
    d2 = chi2.median(df=10)
    p = normalize_mahalanobis(d2, df=10)
    assert 0.4 < p < 0.6


def test_fuse_weighted_average():
    score = fuse(stl=0.6, cusum=0.2, joint=0.8)
    assert score == pytest.approx(0.3 * 0.6 + 0.3 * 0.2 + 0.4 * 0.8)


def test_fuse_in_unit_range():
    score = fuse(stl=1.0, cusum=1.0, joint=1.0)
    assert score == pytest.approx(1.0)


def test_decide_anomaly_type_picks_dominant_layer():
    assert decide_anomaly_type(stl=0.9, cusum=0.1, joint=0.2) == "circadian_disruption"
    assert decide_anomaly_type(stl=0.1, cusum=0.9, joint=0.2) == "abrupt_change"
    assert decide_anomaly_type(stl=0.1, cusum=0.1, joint=0.9) == "multivariate"
    assert decide_anomaly_type(stl=0.1, cusum=0.1, joint=0.1) == "normal"


def test_guards_return_zero_on_degenerate_input():
    # history_max <= 0（含负值，冷启动/无历史）→ 0.0，避免除零
    assert normalize_cusum(5.0, history_max=0.0) == 0.0
    assert normalize_cusum(5.0, history_max=-1.0) == 0.0
    # df <= 0（协方差奇异/无自由度）→ 0.0
    assert normalize_mahalanobis(5.0, df=0) == 0.0
    assert normalize_mahalanobis(5.0, df=-2) == 0.0
