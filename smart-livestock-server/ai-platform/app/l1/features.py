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
