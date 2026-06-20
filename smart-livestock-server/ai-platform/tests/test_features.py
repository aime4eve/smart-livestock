import numpy as np
import pandas as pd
import pytest
from app.l1.features import resample_to_slots, compute_neff


def test_resample_aligns_to_30min_slots(rng):
    # 原始点：每小时 2 个（非 30min 整齐），应聚合到 30min 槽
    idx = pd.date_range("2026-06-01", periods=96, freq="15min", tz="UTC")
    temps = pd.Series(np.full(96, 38.5), index=idx, name="temperature")
    mots = pd.Series(np.full(96, 3.0), index=idx, name="motility")
    acts = pd.Series(np.full(96, 50.0), index=idx, name="activity")
    df = resample_to_slots(temps, mots, acts)
    # 96 个 15min 点 = 24h = 48 个 30min 槽
    assert len(df) == 48
    assert {"temperature", "motility", "activity"} <= set(df.columns)


def test_neff_counts_full_triplet_slots(normal_series):
    df = resample_to_slots(
        normal_series["temperature"], normal_series["motility"], normal_series["activity"])
    neff = compute_neff(df)
    # 14 天完整数据，无缺失 → 14*48 = 672
    assert neff == 14 * 48


def test_neff_ignores_slots_with_missing_dim(rng):
    df = make_df_with_missing(rng, missing_dim="temperature", n_missing=10)
    neff = compute_neff(df)
    total = len(df)
    assert neff == total - 10


def make_df_with_missing(rng, missing_dim, n_missing):
    n = 100
    idx = pd.date_range("2026-06-01", periods=n, freq="30min", tz="UTC")  # tz-aware（评审 #3：与 db 路径统一）
    df = pd.DataFrame({
        "temperature": np.full(n, 38.5),
        "motility": np.full(n, 3.0),
        "activity": np.full(n, 50.0),
    }, index=idx)
    df.loc[df.index[:n_missing], missing_dim] = np.nan
    return df


from app.l1.features import robust_baseline, cohort_baseline


def test_robust_baseline_median_and_mad():
    vals = np.array([38.4, 38.5, 38.5, 38.6, 38.5])
    median, mad = robust_baseline(vals)
    assert median == pytest.approx(38.5)
    # MAD = median(|x - median|) = median([0.1,0,0,0.1,0]) = 0.0 → 用 0.0 防除零
    assert mad >= 0.0


def test_robust_baseline_ignores_nan():
    vals = np.array([38.5, np.nan, 38.6, 38.5, np.nan])
    median, mad = robust_baseline(vals)
    assert median == pytest.approx(38.5)


def test_robust_baseline_empty_returns_nan():
    median, mad = robust_baseline(np.array([np.nan, np.nan]))
    assert np.isnan(median)


def test_cohort_baseline_falls_back_to_group_median():
    individuals = [(38.5, 0.1), (38.7, 0.1), (38.6, 0.1)]
    median, mad = cohort_baseline(individuals)
    # 三个体中位数 38.5/38.7/38.6 的中位数 = 38.6
    assert median == pytest.approx(38.6)
