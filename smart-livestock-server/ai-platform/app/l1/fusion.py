"""L1 融合层（design §4.4）。各层分数先归一化到 [0,1] 再加权。"""
import numpy as np
from scipy.stats import chi2

from app.config import settings
from app.schemas import AnomalyType


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
                        threshold: float = 0.5) -> AnomalyType:
    """按主导层判定 anomaly_type（design §4.4）。三方都低 → normal。

    threshold 作用于**各层归一化分数**（stl/cusum/joint，即 contributions），
    是"类型翻转点"（normal → 异常子类，供可解释性标签）；
    与 config.alert_threshold（作用于**融合 score**、由 Java 端触发告警）是**不同对象不同概念**，
    勿把 alert_threshold 传入此处——那会把 0.5–0.7 的异常记录误标 normal、丢失可解释性。
    """
    layers = {AnomalyType.CIRCADIAN_DISRUPTION: stl,
              AnomalyType.ABRUPT_CHANGE: cusum,
              AnomalyType.MULTIVARIATE: joint}
    dominant = max(layers, key=layers.get)
    if layers[dominant] < threshold:
        return AnomalyType.NORMAL
    return dominant
