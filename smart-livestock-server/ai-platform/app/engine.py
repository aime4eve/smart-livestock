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
        # n_eff 双轨（评审 M5）：ctx.n_eff 预留给 L2/L3 路由（按规模/就绪度选档），
        # L1 的 is_available 恒 True、不读 ctx.n_eff，内部用 compute_neff(slots_df) 重算。
        # 调用方（main._predict_one）传 0 占位即可，真实 N_eff 由 L1 自行从窗口推导。
        ctx = CapabilityContext(n_eff=n_eff)
        cap = self._registry.select_available(ctx)
        if cap is None:
            return None
        # L1 暴露 predict_series；L2/L3 Phase A 未就绪不会被选中
        from app.capability.health_l1 import HealthAnomalyL1
        if isinstance(cap, HealthAnomalyL1):
            return cap.predict_series(req, slots_df, cohort_baselines)
        return cap.predict(req, ctx)
