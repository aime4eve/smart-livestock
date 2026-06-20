"""L1 特征工程（design §4.2）。本模块：时序对齐 + N_eff。"""
import numpy as np
import pandas as pd

from app.config import settings

_DIMS = ("temperature", "motility", "activity")


def resample_to_slots(temperature: pd.Series, motility: pd.Series,
                      activity: pd.Series) -> pd.DataFrame:
    """将三张表的原始点重采样对齐到 30min 槽位，每槽取均值（design §4.1 粒度）。

    入参为带 DatetimeIndex 的 Series（来自 db.py 的查询）。缺失槽位为 NaN。
    """
    rule = f"{settings.slot_minutes}min"
    return pd.DataFrame({
        "temperature": temperature.resample(rule).mean(),
        "motility": motility.resample(rule).mean(),
        "activity": activity.resample(rule).mean(),
    })


def compute_neff(slots_df: pd.DataFrame) -> int:
    """N_eff：三维均非空的 30min 槽位数（design §4.3）。"""
    present = slots_df[list(_DIMS)].notna().all(axis=1)
    return int(present.sum())


def robust_baseline(values: np.ndarray) -> tuple[float, float]:
    """稳健个体基线：中位数 + MAD（design §4.2）。

    返回 (median, mad)。MAD=median(|x-median|)，为 0 时返回 0（防 z-score 除零，
    由调用方用 max(mad, eps) 兜底）。NaN 自动剔除。
    """
    v = values[np.isfinite(values)]
    if v.size == 0:
        return (float("nan"), 0.0)
    median = float(np.median(v))
    mad = float(np.median(np.abs(v - median)))
    return (median, mad)


def cohort_baseline(individual_baselines: list[tuple[float, float]]) -> tuple[float, float]:
    """群体基线兜底（冷启动，design §4.2）：所有个体 median 的 median + 其 MAD。"""
    medians = np.array([m for m, _ in individual_baselines if np.isfinite(m)], dtype=float)
    if medians.size == 0:
        return (float("nan"), 0.0)
    m = float(np.median(medians))
    mad = float(np.median(np.abs(medians - m)))
    return (m, mad)


from statsmodels.tsa.seasonal import STL

# 特征维度常量（design §4.2：3 维 × 3 特征 + CUSUM = 10）
FEATURE_DIMS = 10
_PERIOD_SLOTS = 48  # 30min × 48 = 24h
_DIM_NAMES = ("temperature", "motility", "activity")


def stl_residual(series: pd.Series, period: int = _PERIOD_SLOTS) -> pd.Series:
    """STL 分解取 residual（design §4.2 L1a 节律剥离，周期 24h）。

    序列短于一个周期时，退化为去均值（避免 statsmodels 报错）。
    """
    s = series.dropna()
    if len(s) < period:
        return series - series.mean()
    stl = STL(s, period=period, robust=True)
    resid = stl.fit().resid
    return resid.reindex(series.index)


def _slope(values: np.ndarray) -> float:
    """简单线性回归斜率（一维）。"""
    n = len(values)
    if n < 2:
        return 0.0
    x = np.arange(n, dtype=float)
    y = values - values.mean()
    denom = ((x - x.mean()) ** 2).sum()
    if denom == 0:
        return 0.0
    return float(np.sum((x - x.mean()) * y) / denom)


def build_feature_vector(slots_df: pd.DataFrame,
                         baselines: dict[str, tuple[float, float]]) -> tuple[np.ndarray, list[str]]:
    """构建 10 维特征向量（design §4.2）。

    baselines: {dim: (median, mad)}（来自 robust_baseline / cohort_baseline）。
    返回 (feature_vector[10], feature_names[10])。CUSUM 维（第 10 维）此处占位 0，
    由 detectors.cusum_score 在 L1 编排时填入。
    """
    from app.config import settings
    detect_n = settings.detection_window_hours * 2  # 24h → 48 槽
    recent = slots_df.tail(detect_n)

    names: list[str] = []
    feats: list[float] = []
    for dim in _DIM_NAMES:
        median, mad = baselines[dim]
        eps = max(mad * 1.4826, 1e-6)  # MAD → 近似 std
        col = recent[dim].dropna()
        if col.empty or np.isnan(median):
            feats.extend([0.0, 0.0, 0.0])
        else:
            z = float((col.mean() - median) / eps)
            slope = _slope(col.to_numpy())
            resid = stl_residual(slots_df[dim]).tail(len(recent))
            stl_peak = float(np.nanmax(np.abs(resid.to_numpy()))) if resid.notna().any() else 0.0
            feats.extend([z, slope, stl_peak])
        names.extend([f"{dim}_z", f"{dim}_slope", f"{dim}_stl_peak"])

    feats.append(0.0)  # cusum 占位
    names.append("cusum")
    assert len(feats) == FEATURE_DIMS
    return np.array(feats, dtype=float), names
