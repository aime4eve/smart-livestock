"""对外 API 契约（design §5.1 capability 同构契约 / §5.2 orchestration 端点）。"""
from enum import Enum
from pydantic import BaseModel, Field, field_validator


class CapabilityLevel(str, Enum):
    L1 = "L1"
    L2 = "L2"
    L3 = "L3"


class PredictRequest(BaseModel):
    tenant_id: int
    farm_id: int
    # 单头端点 /analyze/{id} 走路径参数，body 可不传 livestock_ids（评审 #1）；
    # 批量端点在路由内校验非空
    livestock_ids: list[int] = Field(default_factory=list)
    window_hours: int = 24
    live_endpoint: bool = False


class Contributions(BaseModel):
    """各层贡献度（可解释性，design §4.4）。"""
    stl: float = 0.0
    cusum: float = 0.0
    joint: float = 0.0
    # 各维度细分（可选）
    per_dim: dict[str, float] = Field(default_factory=dict)


class PredictResponse(BaseModel):
    livestock_id: int
    anomaly_score: float = Field(ge=0.0, le=1.0)
    anomaly_type: str  # circadian_disruption / abrupt_change / multivariate / normal
    contributions: Contributions
    capability_used: str
    n_eff: int
    model_meta: dict = Field(default_factory=dict)

    @field_validator("anomaly_score")
    @classmethod
    def _clamp(cls, v: float) -> float:
        if v < 0.0 or v > 1.0:
            raise ValueError("anomaly_score must be in [0,1]")
        return v


class AnalyzeResponse(BaseModel):
    request_id: str
    results: list[PredictResponse]
