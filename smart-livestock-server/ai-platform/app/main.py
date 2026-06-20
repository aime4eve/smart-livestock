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
from app.schemas import AnalyzeResponse, Contributions, PredictRequest, PredictResponse
import app.db as dbmod

app = FastAPI(title="ai-platform", version="phase-a")

# 装配三层（design §3）：orchestration=本文件，engine=Engine，capability=registry
_registry = CapabilityRegistry()
_registry.register(HealthAnomalyL1())
_registry.register(DeepLearningL2())
_registry.register(LlmL3())
_engine = Engine(registry=_registry)


def _fetch(livestock_id: int, window_hours: int) -> dict[str, pd.Series]:
    """从 PG 取三维时序（Task 12 db.fetch_window 的可 mock 包装）。"""
    return dbmod.fetch_window(livestock_id, window_hours)


def _predict_one(req: PredictRequest, livestock_id: int) -> PredictResponse:
    series = _fetch(livestock_id, req.window_hours)
    # 无数据兜底：L1 本可运行但数据层为空，capability_used="health_l1" 表"本应由谁处理"
    if all(s.empty for s in series.values()):
        return PredictResponse(
            livestock_id=livestock_id, anomaly_score=0.0, anomaly_type="normal",
            contributions=Contributions(stl=0.0, cusum=0.0, joint=0.0),
            capability_used="health_l1", n_eff=0, model_meta={"reason": "no_data"},
        )
    slots_df = resample_to_slots(series["temperature"], series["motility"], series["activity"])
    resp = _engine.predict_series(req, slots_df=slots_df, cohort_baselines=[], n_eff=0)
    if resp is None:
        # 无可用 capability：registry 无就绪层，capability_used="none" 表"无人处理"
        return PredictResponse(
            livestock_id=livestock_id, anomaly_score=0.0, anomaly_type="normal",
            contributions=Contributions(stl=0.0, cusum=0.0, joint=0.0),
            capability_used="none", n_eff=0, model_meta={"reason": "no_capability"},
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
    results = [_predict_one(req, lid) for lid in req.livestock_ids]
    return AnalyzeResponse(request_id=str(uuid.uuid4()), results=results)


@app.post("/ai/health/analyze/{livestock_id}", response_model=AnalyzeResponse)
def analyze_single(livestock_id: int, req: PredictRequest):
    results = [_predict_one(req, livestock_id)]
    return AnalyzeResponse(request_id=str(uuid.uuid4()), results=results)
