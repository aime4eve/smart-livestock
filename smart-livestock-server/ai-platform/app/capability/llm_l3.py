"""L3 LLM capability（Phase A 占位，design §3 is_available=False）。"""
from app.capability.base import Capability, CapabilityContext, CapabilityLevel
from app.schemas import PredictRequest, PredictResponse


class LlmL3(Capability):
    @property
    def level(self) -> CapabilityLevel:
        return CapabilityLevel.L3

    def is_available(self, ctx: CapabilityContext) -> bool:
        return False  # Phase A 未实现

    def predict(self, req: PredictRequest, ctx: CapabilityContext) -> PredictResponse:
        raise NotImplementedError("L3 LLM not available in Phase A")
