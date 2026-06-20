"""L1 检测器（design §4.3）。

L1a STL：近窗口 STL residual 峰值的 z-score，sigmoid 压到 [0,1]。
L1b CUSUM：双侧累积和变点（手写，可控可测）。
L1c Mahalanobis 见 Task 7。

L1a 实测修正（Task 6）：原 max+MAD+full 对正常序列 STL residual 尖峰分布过敏感
（MAD 低估 std + max 极值序统计 → normal score 0.976 > 0.5）。改用近窗口 |residual|
的 95th percentile 作 peak、全历史 residual std 归一化（residual 近高斯，std 准）。
"""
import numpy as np
import pandas as pd

from app.l1.features import stl_residual


def stl_layer_score(series: pd.Series, period: int = 48) -> float:
    """L1a：近窗口 STL residual 峰值的 z-score，经 sigmoid 压到 [0,1]。

    高 residual 峰值 → 高分（捕获"节律被破坏"型异常）。

    peak = 近检测窗口（detect_n 槽）|residual - 全历史均值| 的 95th percentile
    （非 max，降低极值序统计对噪声的过敏感）。
    normalizer = 全历史 residual 的 std（residual 已去趋势、近高斯，std 是准确尺度；
    MAD 对 STL residual 的尖峰分布系统性低估，不适用）。
    """
    from app.config import settings
    resid = stl_residual(series, period=period).dropna()
    if resid.empty:
        return 0.0
    std = float(resid.std())
    if std < 1e-9 or not np.isfinite(std):
        return 0.0
    center = float(resid.mean())
    detect_n = settings.detection_window_hours * 2  # 24h → 48 槽
    recent = resid.tail(detect_n)
    if recent.empty:
        return 0.0
    dev = np.abs(recent.to_numpy() - center)
    peak = float(np.percentile(dev, 95))
    z = peak / std
    # 经验映射：z 峰值 3+ 视为显著异常 → sigmoid 拉伸
    return float(1.0 / (1.0 + np.exp(-(z - 3.0))))


def cusum_score(series: pd.Series) -> float:
    """L1b：双侧 CUSUM 变点分数（design §4.3 突变检测）。

    标准化残差后正向/负向累积，取峰值。返回原始累积量（非 [0,1]，
    由 fusion.normalize_cusum 统一归一化）。
    """
    s = series.dropna()
    if len(s) < 2:
        return 0.0
    z = (s - s.mean())
    std = z.std()
    if std < 1e-9 or not np.isfinite(std):
        return 0.0
    z = (z / std).to_numpy()
    pos = np.cumsum(np.clip(z, 0.0, None))
    neg = np.cumsum(np.clip(-z, 0.0, None))
    peak = max(float(pos.max()) if pos.size else 0.0,
               float(neg.max()) if neg.size else 0.0)
    return float(peak)
