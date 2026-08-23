"""orchestration 入口（design §3/§5.2）。FastAPI 端点 → engine → capability。"""
import uuid

import pandas as pd
from fastapi import FastAPI
from fastapi.responses import JSONResponse

from app.capability.router import CapabilityRegistry   # 修正：router 非 base
from app.capability.health_l1 import HealthAnomalyL1
from app.capability.dl_l2 import DeepLearningL2
from app.capability.llm_l3 import LlmL3
from app.engine import Engine
from app.l1.features import resample_to_slots
from app.schemas import (AnalyzeResponse, Contributions, PredictRequest, PredictResponse,
                         SinglePredictRequest, AnomalyType, CapabilityUsed)
from app.behavior.rules import predict_l1
from app.behavior.dataset import fetch_training_dataset
from app.behavior.model import BehaviorModelStore, predict_l2_batch
from app.config import settings
from app.schemas import (
    BehaviorAnalyzeRequest,
    BehaviorAnalyzeResponse,
    BehaviorCapability,
    BehaviorPredictionResult,
    BehaviorTrainRequest,
    BehaviorTrainResponse,
)
import app.db as dbmod

app = FastAPI(title="ai-platform", version="phase-a")

# 装配三层（design §3）：orchestration=本文件，engine=Engine，capability=registry
_registry = CapabilityRegistry()
_registry.register(HealthAnomalyL1())
_registry.register(DeepLearningL2())
_registry.register(LlmL3())
_engine = Engine(registry=_registry)
_behavior_models = BehaviorModelStore()


def _fetch(conn, livestock_id: int, window_hours: int) -> dict[str, pd.Series]:
    """从 PG 取三维时序（Task 12 db.fetch_window 的可 mock 包装）。"""
    return dbmod.fetch_window(conn, livestock_id, window_hours)


def _predict_one(req: PredictRequest, livestock_id: int, conn) -> PredictResponse:
    series = _fetch(conn, livestock_id, req.window_hours)
    # 无数据兜底：L1 本可运行但数据层为空，capability_used="health_l1" 表"本应由谁处理"
    if all(s.empty for s in series.values()):
        return PredictResponse(
            livestock_id=livestock_id, anomaly_score=0.0, anomaly_type=AnomalyType.NORMAL,
            contributions=Contributions(stl=0.0, cusum=0.0, joint=0.0),
            capability_used=CapabilityUsed.HEALTH_L1, n_eff=0, model_meta={"reason": "no_data"},
        )
    slots_df = resample_to_slots(series["temperature"], series["motility"], series["activity"])
    resp = _engine.predict_series(req, slots_df=slots_df, cohort_baselines=[], n_eff=0)
    if resp is None:
        # 无可用 capability：registry 无就绪层，capability_used="none" 表"无人处理"
        return PredictResponse(
            livestock_id=livestock_id, anomaly_score=0.0, anomaly_type=AnomalyType.NORMAL,
            contributions=Contributions(stl=0.0, cusum=0.0, joint=0.0),
            capability_used=CapabilityUsed.NONE, n_eff=0, model_meta={"reason": "no_capability"},
        )
    # 批量时 health_l1 用 req.livestock_ids[0] 会误标，统一用入参 livestock_id 覆盖
    resp.livestock_id = livestock_id
    return resp


@app.get("/ai/health/live")
def live():
    return {"status": "ok"}


@app.post("/ai/health/analyze", response_model=AnalyzeResponse)
def analyze_batch(req: PredictRequest):
    # 批量端点要求 livestock_ids 非空（评审 #1：单头端点走路径参数可省）
    if not req.livestock_ids:
        return JSONResponse(status_code=400, content={"detail": "livestock_ids must not be empty"})
    # 评审 H1：批量共享一个只读连接，避免每头一次 TCP+auth 握手
    with dbmod.connect() as conn:
        results = [_predict_one(req, lid, conn) for lid in req.livestock_ids]
    return AnalyzeResponse(request_id=str(uuid.uuid4()), results=results)


@app.post("/ai/health/analyze/{livestock_id}", response_model=AnalyzeResponse)
def analyze_single(livestock_id: int, req: SinglePredictRequest):
    # 评审 M3：单头端点 body 不含 livestock_ids（走 path 参数），构造 engine 请求注入
    engine_req = PredictRequest(
        tenant_id=req.tenant_id, farm_id=req.farm_id,
        livestock_ids=[livestock_id],
        window_hours=req.window_hours, live_endpoint=req.live_endpoint,
    )
    with dbmod.connect() as conn:
        results = [_predict_one(engine_req, livestock_id, conn)]
    return AnalyzeResponse(request_id=str(uuid.uuid4()), results=results)


@app.post("/ai/behavior/analyze", response_model=BehaviorAnalyzeResponse)
def analyze_behavior(req: BehaviorAnalyzeRequest):
    results: list[BehaviorPredictionResult] = []
    errors: list[dict] = []

    if req.requested_capability is not BehaviorCapability.L1_RULE:
        if not req.model_name or not req.model_version:
            return JSONResponse(status_code=422, content={
                "detail": "L2 model name and version are required"
            })
        artifact = None
        compatible_windows = []
        for window in req.windows:
            try:
                if artifact is None:
                    artifact, _ = _behavior_models.load(
                        req.model_name,
                        req.model_version,
                        window.feature_version,
                        window.feature_schema_hash,
                    )
                else:
                    from app.behavior.contract import validate_contract
                    validate_contract(
                        window.feature_version,
                        window.feature_schema_hash,
                        window.features,
                    )
                compatible_windows.append(window)
            except (ValueError, TypeError, FileNotFoundError) as exc:
                errors.append({"window_id": window.window_id, "message": str(exc)})
        try:
            if artifact is None:
                raise FileNotFoundError("behavior model artifact not found")
            results.extend(BehaviorPredictionResult(**item) for item in predict_l2_batch(
                artifact,
                compatible_windows,
                req.model_name,
                req.model_version,
            ))
        except (ValueError, TypeError, FileNotFoundError) as exc:
            if not errors:
                errors.append({"window_id": "batch", "message": str(exc)})
        return BehaviorAnalyzeResponse(
            request_id=str(uuid.uuid4()), results=results, errors=errors
        )

    for window in req.windows:
        try:
            prediction = predict_l1(
                window.window_id,
                window.feature_version,
                window.feature_schema_hash,
                window.input_quality,
                window.sampling_mode,
                window.features,
            )
            results.append(BehaviorPredictionResult(
                window_id=prediction.window_id,
                dominant_behavior=prediction.dominant_behavior,
                probability_vector=prediction.probability_vector,
                predicted_labels=prediction.labels,
                capability_level=prediction.capability,
                model_name=prediction.model_name,
                model_version=prediction.model_version,
            ))
        except (ValueError, TypeError, FileNotFoundError) as exc:
            errors.append({"window_id": window.window_id, "message": str(exc)})
    return BehaviorAnalyzeResponse(
        request_id=str(uuid.uuid4()), results=results, errors=errors
    )


@app.post("/ai/behavior/train", response_model=BehaviorTrainResponse)
def train_behavior(req: BehaviorTrainRequest):
    seed = settings.behavior_model_seed if req.random_seed is None else req.random_seed
    try:
        with dbmod.connect() as conn:
            dataset = fetch_training_dataset(conn, req.dataset_id)
        artifact_hash, manifest = _behavior_models.train(
            dataset["windows"],
            req.model_name,
            req.model_version,
            dataset["dataset_id"],
            dataset["definition_digest"],
            dataset["generator_version"],
            req.minimum_support,
            seed,
        )
    except (ValueError, FileNotFoundError, FileExistsError) as exc:
        return JSONResponse(status_code=409, content={"detail": str(exc)})
    return BehaviorTrainResponse(
        dataset_id=req.dataset_id,
        model_name=req.model_name,
        model_version=req.model_version,
        artifact_hash=artifact_hash,
        manifest=manifest,
    )
