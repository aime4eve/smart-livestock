"""合成三维时序数据工厂。模拟真实生理节律（昼夜 sinusoidal）+ 可选异常注入。

用于算法单测与 design §8「合成注入」评估。遵守实现纪律：合成数据走与真实数据
完全相同的检测路径，不为此加分支。
"""
import numpy as np
import pandas as pd
import pytest

SLOTS_PER_DAY = 48  # 30min 粒度


def make_triplet_series(rng: np.random.Generator, days: int = 14,
                        base_temp: float = 38.5, base_motility: float = 3.0,
                        base_activity: float = 50.0, inject_anomaly: bool = False,
                        drop_ratio: float = 0.0) -> pd.DataFrame:
    """生成 days 天 30min 粒度三维时序，列为 [temperature, motility, activity]，索引为槽位时间。

    - inject_anomaly=True：最后 24h 注入突变（升温 1.5°C + 活动骤降 30），模拟"突然发病式跳变"。
    - drop_ratio：随机置 NaN 的槽位比例（测试缺失/N_eff 鲁棒性）。
    """
    n = days * SLOTS_PER_DAY
    idx = pd.date_range("2026-06-01", periods=n, freq="30min", tz="UTC")  # tz-aware（评审 #3：与 db 路径统一）
    hour = idx.hour.to_numpy()
    circadian = np.sin(hour / 24.0 * 2.0 * np.pi)

    temps = base_temp + 0.2 * circadian + rng.normal(0, 0.1, n)
    mots = base_motility + 0.3 * circadian + rng.normal(0, 0.2, n)
    acts = base_activity + 10.0 * circadian + rng.normal(0, 3.0, n)

    if inject_anomaly:
        temps[-SLOTS_PER_DAY:] += 1.5
        acts[-SLOTS_PER_DAY:] -= 30.0

    df = pd.DataFrame({"temperature": temps, "motility": mots, "activity": acts}, index=idx)

    if drop_ratio > 0:
        mask = rng.random(n) < drop_ratio
        df.loc[df.index[mask], "temperature"] = np.nan
    return df


@pytest.fixture
def rng() -> np.random.Generator:
    return np.random.default_rng(42)


@pytest.fixture
def normal_series(rng) -> pd.DataFrame:
    return make_triplet_series(rng, days=14, inject_anomaly=False)


@pytest.fixture
def anomaly_series(rng) -> pd.DataFrame:
    return make_triplet_series(rng, days=14, inject_anomaly=True)
