"""L1 融合层（design §4.4）。各层分数先归一化到 [0,1] 再加权。"""
import numpy as np
from scipy.stats import chi2

from app.config import settings


def normalize_stl(stl_score: float) -> float:
    """STL 层分数已在 detectors.stl_layer_score 经 sigmoid 压到 [0,1]，直接截断返回。"""
    return float(np.clip(stl_score, 0.0, 1.0))


def normalize_cusum(cusum_raw: float, history_max: float) -> float:
    """CUSUM 用历史最大值归一化（design §4.4），超历史截断为 1。"""
    if history_max <= 0:
        return 0.0
    return float(np.clip(cusum_raw / history_max, 0.0, 1.0))


def normalize_mahalanobis(d2: float, df: int) -> float:
    """Mahalanobis 平方距离用 χ² CDF 归一化（design §4.4）。"""
    if df <= 0:
        return 0.0
    return float(np.clip(chi2.cdf(d2, df=df), 0.0, 1.0))


def fuse(stl: float, cusum: float, joint: float) -> float:
    """加权融合（design §4.4 初始权重 0.3/0.3/0.4）。"""
    s = settings.w_stl * stl + settings.w_cusum * cusum + settings.w_joint * joint
    return float(np.clip(s, 0.0, 1.0))


def decide_anomaly_type(stl: float, cusum: float, joint: float,
                        threshold: float = 0.5) -> str:
    """按主导层判定 anomaly_type（design §4.4）。三方都低 → normal。"""
    layers = {"circadian_disruption": stl, "abrupt_change": cusum, "multivariate": joint}
    dominant = max(layers, key=layers.get)
    if layers[dominant] < threshold:
        return "normal"
    return dominant
