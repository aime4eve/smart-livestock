"""capability 门面 + L1 内部 N_eff 路由（design §3 registry + §4.3 分档）。"""
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


def route_by_neff(n_eff: int) -> str:
    """返回算法名：rules / mahalanobis / iforest（design §4.3 N_eff 分档，纯阈值）。

    design §4.3 第 112 行要求的 ±20% hysteresis 需要 per-individual 跨次状态
    （"同一头牛"持续 N_eff），Phase A 无 DB 写权限、单实例进程内 dict 多实例失效，
    故不实现。Plan 2 Java 定时批量接入时，按 livestock_id 分键补状态化迟滞
    （Redis/PG 持久态）。

    当前纯阈值：N_eff<30→rules、<200→mahalanobis、≥200→iforest。
    临界抖动后果（无迟滞）：N_eff 在 29↔31 间跳变时 joint 项开关 → 同一头牛
    相邻检测分数可能波动；Plan 2 若 Java 端有告警去抖/时间窗聚合可吸收。
    """
    hi_iforest = settings.neff_iforest_min   # 200
    hi_maha = settings.neff_mahalanobis_min  # 30
    if n_eff < hi_maha:
        return "rules"
    if n_eff < hi_iforest:
        return "mahalanobis"
    return "iforest"
