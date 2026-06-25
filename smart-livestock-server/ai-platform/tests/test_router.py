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


def test_route_returns_none_when_all_unavailable():
    # select_available 的 None fallback 分支（全不可用）
    reg = CapabilityRegistry()
    reg.register(StubCap(CapabilityLevel.L1, False))
    reg.register(StubCap(CapabilityLevel.L2, False))
    assert reg.select_available(CapabilityContext()) is None


def test_neff_pure_threshold_boundary_is_strictly_less():
    # 锁定纯阈值边界（< 上阈，非 <=）：n_eff=30 恰升 maha，n_eff=200 恰升 iforest
    assert route_by_neff(29) == "rules"
    assert route_by_neff(30) == "mahalanobis"
    assert route_by_neff(199) == "mahalanobis"
    assert route_by_neff(200) == "iforest"
