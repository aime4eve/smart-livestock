"""Capability 同构契约（design §5.1）。"""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field

from app.schemas import (
    CapabilityLevel,
    PredictRequest,
    PredictResponse,
)


@dataclass
class CapabilityContext:
    """预测上下文：N_eff、路由状态等。"""
    n_eff: int = 0
    router_state: dict = field(default_factory=dict)


class Capability(ABC):
    """L1/L2/L3 同构契约。is_available 决定降级，predict 执行。"""

    @property
    @abstractmethod
    def level(self) -> CapabilityLevel: ...

    @abstractmethod
    def is_available(self, ctx: CapabilityContext) -> bool: ...

    @abstractmethod
    def predict(
        self, req: PredictRequest, ctx: CapabilityContext
    ) -> PredictResponse: ...
