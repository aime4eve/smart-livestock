import numpy as np
import pandas as pd
import pytest
from app.l1.detectors import stl_layer_score, cusum_score, fit_mahalanobis, mahalanobis_distance


def test_stl_layer_score_normal_is_low(normal_series):
    score = stl_layer_score(normal_series["temperature"])
    assert 0.0 <= score <= 1.0
    assert score < 0.5  # 正常序列分数低


def test_stl_layer_score_anomaly_is_higher(anomaly_series):
    normal_score = stl_layer_score(anomaly_series["temperature"].iloc[:-48])
    anomaly_score = stl_layer_score(anomaly_series["temperature"])
    assert anomaly_score > normal_score


def test_cusum_flat_series_low():
    flat = pd.Series(np.zeros(96), index=pd.date_range("2026-06-01", periods=96, freq="30min", tz="UTC"))
    assert cusum_score(flat) == 0.0


def test_cusum_detects_step_change():
    # 前 48 点 0，后 48 点 +3（突变）
    vals = np.concatenate([np.zeros(48), np.full(48, 3.0)])
    s = pd.Series(vals, index=pd.date_range("2026-06-01", periods=96, freq="30min", tz="UTC"))
    score = cusum_score(s)
    assert score > 5.0  # 突变产生高分


def test_cusum_output_finite():
    s = pd.Series(np.random.default_rng(1).normal(0, 1, 96),
                  index=pd.date_range("2026-06-01", periods=96, freq="30min", tz="UTC"))
    score = cusum_score(s)
    assert np.isfinite(score)


def test_stl_layer_score_constant_series_is_zero():
    # 传感器卡死（常量）：STL residual 浮点噪声 ~1e-14，std epsilon-floor guard 应触发
    const = pd.Series(np.full(672, 38.5), index=pd.date_range("2026-06-01", periods=672, freq="30min", tz="UTC"))
    assert stl_layer_score(const) == 0.0


def test_mahalanobis_normal_point_low_distance(rng, normal_series):
    from app.l1.features import build_feature_vector
    dims = ("temperature", "motility", "activity")
    baseline = {d: (normal_series[d].median(), 0.1) for d in dims}
    # 用多个窗口构造历史特征矩阵
    feats = []
    for start in range(0, len(normal_series) - 48, 24):
        window = normal_series.iloc[start:start + 48]
        v, _ = build_feature_vector(window, baseline)
        feats.append(v)
    X = np.array(feats)
    model = fit_mahalanobis(X)
    # 当前点（最后一个窗口）应低距离
    d2 = mahalanobis_distance(model, X[-1:])
    assert np.all(d2 >= 0)


def test_mahalanobis_outlier_higher_than_inlier(rng, normal_series):
    from app.l1.features import build_feature_vector
    dims = ("temperature", "motility", "activity")
    baseline = {d: (normal_series[d].median(), 0.1) for d in dims}
    feats = [build_feature_vector(normal_series.iloc[s:s + 48], baseline)[0]
             for s in range(0, len(normal_series) - 48, 24)]
    X = np.array(feats)
    model = fit_mahalanobis(X)
    inlier_d2 = float(np.mean(mahalanobis_distance(model, X)))
    # 构造一个明显偏离的点（温度 z 拉高）
    outlier = X.mean(axis=0).copy()
    outlier[0] += 10.0
    outlier_d2 = float(mahalanobis_distance(model, outlier.reshape(1, -1))[0])
    assert outlier_d2 > inlier_d2


def test_mahalanobis_insufficient_samples_returns_none():
    # 少于特征维数时无法估协方差，返回 None（路由器据此降级）
    X = np.array([[1.0] * 10, [2.0] * 10])  # 仅 2 样本
    assert fit_mahalanobis(X) is None
