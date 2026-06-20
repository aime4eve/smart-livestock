import pytest
from app.capability.base import Capability, CapabilityLevel, CapabilityContext
from app.capability.router import CapabilityRegistry, route_by_neff


class StubCap(Capability):
    def __init__(self, level, available):
        self._level = level
        self._available = available
    @property
    def level(self): return self._level
    def is_available(self, ctx): return self._available
    def predict(self, req): raise NotImplementedError


def test_route_picks_highest_available_level():
    reg = CapabilityRegistry()
    reg.register(StubCap(CapabilityLevel.L1, True))
    reg.register(StubCap(CapabilityLevel.L2, False))  # 未就绪
    reg.register(StubCap(CapabilityLevel.L3, False))
    cap = reg.select_available(CapabilityContext())
    assert cap.level == CapabilityLevel.L1  # 降级到 L1


def test_route_picks_l2_when_available():
    reg = CapabilityRegistry()
    reg.register(StubCap(CapabilityLevel.L1, True))
    reg.register(StubCap(CapabilityLevel.L2, True))
    cap = reg.select_available(CapabilityContext())
    assert cap.level == CapabilityLevel.L2


def test_neff_route_small_sample_uses_rules():
    # N_eff < 30 → rules（返回 None 表示 L1 内部再降级到规则）
    assert route_by_neff(10) == "rules"


def test_neff_route_medium_uses_mahalanobis():
    assert route_by_neff(120) == "mahalanobis"


def test_neff_route_large_uses_iforest():
    assert route_by_neff(300) == "iforest"


def test_neff_hysteresis_avoids_jitter():
    # 升档需 ≥200，降档需 <160（±20% 迟滞）
    router_state = {"current": "mahalanobis"}
    # N_eff=180（在 160-200 迟滞带），保持 mahalanobis 不切 iforest
    assert route_by_neff(180, state=router_state) == "mahalanobis"
    # N_eff=210 升 iforest
    assert route_by_neff(210, state=router_state) == "iforest"
    # 回落到 170（仍 >160）保持 iforest
    router_state["current"] = "iforest"
    assert route_by_neff(170, state=router_state) == "iforest"
    # 跌破 160 降回 mahalanobis
    assert route_by_neff(150, state=router_state) == "mahalanobis"


def test_route_pure_threshold_vs_hysteresis_diverge():
    # 评审 N3：锁定纯阈值 vs 迟滞的分叉点（iforest 档 + mahalanobis 档各一）。
    # iforest 迟滞带 [160,200)：N_eff=180 纯阈值→mahalanobis(<200)，已 iforest→保持(>=160)
    assert route_by_neff(180, state=None) == "mahalanobis"
    assert route_by_neff(180, state={"current": "iforest"}) == "iforest"
    # mahalanobis 迟滞带 [24,30)：N_eff=25 纯阈值→rules(<30)，已 mahalanobis→保持(>=24)
    assert route_by_neff(25, state=None) == "rules"
    assert route_by_neff(25, state={"current": "mahalanobis"}) == "mahalanobis"
