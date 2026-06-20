"""engine 执行层（design §3 Phase A 透传：TaskPlan → capability 门面）。

Phase A 透传是为固定 engine→capability 调用协议，Phase B/C 填多 agent 不破坏调用方。
"""
import pandas as pd

from app.capability.base import CapabilityContext      # CapabilityContext 在 base
from app.capability.router import CapabilityRegistry   # CapabilityRegistry 在 router
from app.schemas import PredictRequest, PredictResponse


class Engine:
    def __init__(self, registry: CapabilityRegistry):
        self._registry = registry

    def predict_series(self, req: PredictRequest, slots_df: pd.DataFrame,
                       cohort_baselines: list[tuple[float, float]],
                       n_eff: int = 0) -> PredictResponse | None:
        ctx = CapabilityContext(n_eff=n_eff)
        cap = self._registry.select_available(ctx)
        if cap is None:
            return None
        # L1 暴露 predict_series；L2/L3 Phase A 未就绪不会被选中
        from app.capability.health_l1 import HealthAnomalyL1
        if isinstance(cap, HealthAnomalyL1):
            return cap.predict_series(req, slots_df, cohort_baselines)
        return cap.predict(req, ctx)
