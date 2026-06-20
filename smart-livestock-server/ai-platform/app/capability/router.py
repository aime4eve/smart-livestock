"""capability 门面 + L1 内部 N_eff 路由（design §3 registry + §4.3 分档/迟滞）。"""
from typing import Optional

from app.config import settings
from app.capability.base import (
    Capability,
    CapabilityContext,
    CapabilityLevel,
)


class CapabilityRegistry:
    """capability 门面：注册 + 按可用性选最高就绪层（design §3 registry+router）。"""

    def __init__(self):
        self._caps: dict[CapabilityLevel, Capability] = {}

    def register(self, cap: Capability) -> None:
        self._caps[cap.level] = cap

    def select_available(self, ctx: CapabilityContext) -> Optional[Capability]:
        for level in (CapabilityLevel.L3, CapabilityLevel.L2, CapabilityLevel.L1):
            cap = self._caps.get(level)
            if cap is not None and cap.is_available(ctx):
                return cap
        return None


def route_by_neff(n_eff: int, state: dict | None = None) -> str:
    """返回算法名：rules / mahalanobis / iforest。

    state: 可变 dict {"current": <algo>}，用于跨次调用保持迟滞。
        无 state（或 current 为 None）则按纯阈值路由，不应用迟滞。
    升档需 N_eff ≥ 上阈；降档需 N_eff < 下阈（下阈 = 上阈 × (1 - hyst)）。

    注意：本函数不修改 state，只读取 state["current"] 并返回选择结果。
    调用方负责把返回值回写 state["current"]（测试中显式设置以模拟）。
    """
    hi_iforest = settings.neff_iforest_min                              # 200
    lo_iforest = int(hi_iforest * (1 - settings.neff_hysteresis))      # 160
    hi_maha = settings.neff_mahalanobis_min                             # 30
    lo_maha = int(hi_maha * (1 - settings.neff_hysteresis))            # 24

    current = (state or {}).get("current")

    # 无迟滞状态：纯阈值
    if current is None:
        if n_eff < hi_maha:
            return "rules"
        if n_eff < hi_iforest:
            return "mahalanobis"
        return "iforest"

    # 有迟滞：仅在跨出迟滞带时切换
    if current == "rules":
        return "mahalanobis" if n_eff >= hi_maha else "rules"
    if current == "mahalanobis":
        if n_eff >= hi_iforest:
            return "iforest"
        if n_eff < lo_maha:
            return "rules"
        return "mahalanobis"
    if current == "iforest":
        return "mahalanobis" if n_eff < lo_iforest else "iforest"
    # 未知 current，退回纯阈值
    return route_by_neff(n_eff, state=None)
