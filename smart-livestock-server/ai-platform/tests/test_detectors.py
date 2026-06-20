import numpy as np
import pandas as pd
import pytest
from app.l1.detectors import stl_layer_score, cusum_score


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
