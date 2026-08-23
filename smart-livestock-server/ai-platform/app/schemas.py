"""对外 API 契约（design §5.1 capability 同构契约 / §5.2 orchestration 端点）。"""
from __future__ import annotations

from enum import Enum
from pydantic import BaseModel, Field, field_validator


class CapabilityLevel(str, Enum):
    L1 = "L1"
    L2 = "L2"
    L3 = "L3"


class AnomalyType(str, Enum):
    """design §4.4 anomaly_type 取值（按主导层判定；三方都低 → normal）。"""
    NORMAL = "normal"
    CIRCADIAN_DISRUPTION = "circadian_disruption"
    ABRUPT_CHANGE = "abrupt_change"
    MULTIVARIATE = "multivariate"


class CapabilityUsed(str, Enum):
    """PredictResponse.capability_used 取值（评审 M6 枚举约束）。L2/L3 Phase A 占位不产生响应。"""
    HEALTH_L1 = "health_l1"
    NONE = "none"


class _BasePredict(BaseModel):
    """Predict 请求公共字段。单头/批量端点共享，livestock 维度各自定义（评审 M3）。"""
    tenant_id: int
    farm_id: int
    window_hours: int = 24
    live_endpoint: bool = False

    @field_validator("window_hours")
    @classmethod
    def _clamp_window(cls, v: int) -> int:
        # 720h = 30d 覆盖 14d 基线 + 余量；防 DoS（评审 #3）
        if not (1 <= v <= 720):
            raise ValueError("window_hours must be in [1, 720]")
        return v


class PredictRequest(_BasePredict):
    """批量端点 /analyze body 契约。livestock_ids 非空由路由校验；max_length=100 防 DoS（评审 #2）。"""
    livestock_ids: list[int] = Field(default_factory=list, max_length=100)


class SinglePredictRequest(_BasePredict):
    """单头端点 /analyze/{id} body 契约（评审 M3）：livestock_id 走 path 参数，body 不含 livestock_ids。"""


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
    anomaly_type: AnomalyType
    contributions: Contributions
    capability_used: CapabilityUsed
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


class BehaviorFeatureWindow(BaseModel):
    window_id: str
    feature_version: str
    feature_schema_hash: str
    input_quality: str
    sampling_mode: str
    features: dict[str, float | int | None]


class BehaviorCapability(str, Enum):
    L1_RULE = "L1_RULE"
    L2_SUPERVISED = "L2_SUPERVISED"


class BehaviorAnalyzeRequest(BaseModel):
    tenant_id: int
    farm_id: int
    requested_capability: BehaviorCapability = BehaviorCapability.L1_RULE
    model_name: str | None = None
    model_version: str | None = None
    windows: list[BehaviorFeatureWindow] = Field(min_length=1, max_length=5000)


class BehaviorPredictionResult(BaseModel):
    window_id: str
    dominant_behavior: str
    probability_vector: dict[str, float]
    predicted_labels: dict[str, str]
    capability_level: BehaviorCapability
    model_name: str
    model_version: str


class BehaviorAnalyzeResponse(BaseModel):
    request_id: str
    results: list[BehaviorPredictionResult]
    errors: list[dict] = Field(default_factory=list)


class BehaviorTrainRequest(BaseModel):
    dataset_id: str
    model_name: str = "behavior-l2"
    model_version: str = "v1"
    minimum_support: int = Field(default=1, ge=1)
    random_seed: int | None = None


class BehaviorTrainResponse(BaseModel):
    dataset_id: str
    model_name: str
    model_version: str
    artifact_hash: str
    manifest: dict
