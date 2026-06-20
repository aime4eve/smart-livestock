# AI-Platform Phase A 实施计划（Python 无监督异常检测服务）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从零搭建 ai-platform Python 微服务，实现三层骨架（orchestration/engine/capability）+ L1 无监督健康异常检测（STL+CUSUM+Mahalanobis，按 N_eff 路由），对外暴露 `/ai/health/analyze`，供 Java 后端调用。

**Architecture:** FastAPI 服务，`app/orchestration`(main 端点) → `app/engine`(透传) → `app/capability`(registry+router 门面 → L1 实心 / L2·L3 占位)。L1 = `l1/features`(特征工程) + `l1/detectors`(STL/CUSUM/Mahalanobis) + `l1/fusion`(归一化加权)。数据访问 `app/db` 直连 PostgreSQL 只读查询三张时序表。

**Tech Stack:** Python 3.11 + FastAPI + pydantic v2 + psycopg v3 + numpy + pandas + scikit-learn + statsmodels(STL) + scipy(χ² CDF) + pytest。

**关联文档:**
- 战术设计：`docs/superpowers/specs/2026-06-19-ai-health-anomaly-detection-design.md`
- 战略路线图：`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md`
- 后续 Plan 2（Java 接入 + DB V38）、Plan 3（Flutter 双轨）独立成文。

**实现纪律（roadmap 决策 #2）:** 不为数据来源加分支；模拟器与真实数据走同一检测路径。

**与 Plan 2 的边界:** Plan 1 只建 Python 服务 + docker 集成。只读 DB 账号的 `CREATE ROLE + GRANT SELECT` 归 **Plan 2 V38**；Plan 1 的 docker-compose 用可配置账号 `${AI_DB_USER:-postgres}` 临时跑通，README 注明 V38 落地后切换只读账号。

---

## File Structure

```
smart-livestock-server/ai-platform/
├── Dockerfile
├── requirements.txt
├── pytest.ini
├── README.md
├── app/
│   ├── __init__.py
│   ├── main.py              # orchestration: FastAPI app + /ai/health/analyze 端点
│   ├── config.py            # 环境变量配置（权重/阈值/DB/窗口）
│   ├── schemas.py           # pydantic 契约（PredictRequest/Response 等）
│   ├── db.py                # 直连 PG 只读：查三张时序表窗口
│   ├── engine.py            # engine 层：TaskPlan → capability 门面（透传）
│   ├── capability/
│   │   ├── __init__.py
│   │   ├── base.py          # Capability ABC + CapabilityLevel + CapabilityRegistry
│   │   ├── router.py        # 双维度路由（能力降级 L3→L2→L1 + N_eff 分档迟滞）
│   │   ├── health_l1.py     # L1 health_anomaly（实心★）
│   │   ├── dl_l2.py         # L2 深度学习占位（is_available=False）
│   │   └── llm_l3.py        # L3 LLM 占位（is_available=False）
│   └── l1/
│       ├── __init__.py
│       ├── features.py      # 时序对齐/N_eff/稳健基线/STL 残差/10维特征向量
│       ├── detectors.py     # L1a STL + L1b CUSUM + L1c Mahalanobis
│       └── fusion.py        # 各层归一化 + 加权融合
└── tests/
    ├── __init__.py
    ├── conftest.py          # 合成三维时序 fixtures
    ├── test_schemas.py
    ├── test_features.py
    ├── test_detectors.py
    ├── test_fusion.py
    ├── test_router.py
    ├── test_health_l1.py
    ├── test_engine.py
    ├── test_db.py
    └── test_main.py
```

**职责边界:** `l1/` 是纯算法（无 IO，numpy/pandas/sklearn，最易测）；`capability/` 是门面与路由；`engine.py` 透传；`db.py` 隔离 PG；`main.py` 编排 HTTP。算法层不 import db/main，保证可独立单测。

---

## Task 1: 项目骨架与依赖

**Files:**
- Create: `smart-livestock-server/ai-platform/requirements.txt`
- Create: `smart-livestock-server/ai-platform/Dockerfile`
- Create: `smart-livestock-server/ai-platform/pytest.ini`
- Create: `smart-livestock-server/ai-platform/app/__init__.py`
- Create: `smart-livestock-server/ai-platform/app/config.py`
- Create: `smart-livestock-server/ai-platform/tests/__init__.py`
- Create: `smart-livestock-server/ai-platform/tests/conftest.py`
- Create: `smart-livestock-server/ai-platform/tests/test_smoke.py`
- Create: `smart-livestock-server/ai-platform/README.md`

- [ ] **Step 1: 创建 requirements.txt**

```
fastapi==0.115.6
uvicorn[standard]==0.34.0
pydantic==2.10.4
psycopg[binary]==3.2.3
numpy==2.2.1
pandas==2.2.3
scikit-learn==1.6.0
statsmodels==0.14.4
scipy==1.14.1
httpx==0.28.1
pytest==8.3.4
```

> 说明：Phase A 不引入 `pyod`/`ruptures`——iForest 档属 Phase B，CUSUM 用可控的手写实现（见 Task 7）。

- [ ] **Step 2: 创建 Dockerfile**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 3: 创建 pytest.ini**

```ini
[pytest]
testpaths = tests
python_files = test_*.py
```

- [ ] **Step 4: 创建 app/config.py（设计 §4.3/§4.4 全部可调参数）**

```python
"""ai-platform 配置。所有阈值/权重/窗口集中于此（design §4.3 N_eff 分档、§4.4 融合权重）。"""
import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    # PostgreSQL 只读连接（账号由 Plan 2 V38 创建，Phase A 临时用 postgres 跑通）
    db_host: str = os.getenv("AI_DB_HOST", "postgres")
    db_port: int = int(os.getenv("AI_DB_PORT", "5432"))
    db_name: str = os.getenv("AI_DB_NAME", "smart_livestock")
    db_user: str = os.getenv("AI_DB_USER", "postgres")
    db_password: str = os.getenv("AI_DB_PASSWORD", "postgres")

    # 融合权重（design §4.4 初始值；联合层略高，捕获多维耦合盲区）
    w_stl: float = float(os.getenv("AI_W_STL", "0.3"))
    w_cusum: float = float(os.getenv("AI_W_CUSUM", "0.3"))
    w_joint: float = float(os.getenv("AI_W_JOINT", "0.4"))

    # N_eff 分档阈值（design §4.3）
    neff_mahalanobis_min: int = int(os.getenv("AI_NEFF_MAH_MIN", "30"))
    neff_iforest_min: int = int(os.getenv("AI_NEFF_IFOREST_MIN", "200"))
    neff_hysteresis: float = float(os.getenv("AI_NEFF_HYST", "0.2"))  # ±20% 迟滞

    # 时序窗口与粒度（design §4.1）
    detection_window_hours: int = int(os.getenv("AI_DETECT_WINDOW_H", "24"))
    baseline_window_days: int = int(os.getenv("AI_BASELINE_WINDOW_D", "14"))
    slot_minutes: int = int(os.getenv("AI_SLOT_MIN", "30"))

    # 告警阈值（融合分数超此值由 Java 端写 alerts）
    alert_threshold: float = float(os.getenv("AI_ALERT_THRESHOLD", "0.7"))


settings = Settings()
```

- [ ] **Step 5: 创建 app/__init__.py 与 tests/__init__.py（空文件）**

```python
```

- [ ] **Step 6: 创建 tests/conftest.py（合成三维时序 fixtures，后续所有算法 task 复用）**

```python
"""合成三维时序数据工厂。模拟真实生理节律（昼夜 sinusoidal）+ 可选异常注入。

用于算法单测与 design §8「合成注入」评估。遵守实现纪律：合成数据走与真实数据
完全相同的检测路径，不为此加分支。
"""
import numpy as np
import pandas as pd
import pytest

SLOTS_PER_DAY = 48  # 30min 粒度


def make_triplet_series(rng: np.random.Generator, days: int = 14,
                        base_temp: float = 38.5, base_motility: float = 3.0,
                        base_activity: float = 50.0, inject_anomaly: bool = False,
                        drop_ratio: float = 0.0) -> pd.DataFrame:
    """生成 days 天 30min 粒度三维时序，列为 [temperature, motility, activity]，索引为槽位时间。

    - inject_anomaly=True：最后 24h 注入突变（升温 1.5°C + 活动骤降 30），模拟"突然发病式跳变"。
    - drop_ratio：随机置 NaN 的槽位比例（测试缺失/N_eff 鲁棒性）。
    """
    n = days * SLOTS_PER_DAY
    idx = pd.date_range("2026-06-01", periods=n, freq="30min")
    hour = idx.hour.to_numpy()
    circadian = np.sin(hour / 24.0 * 2.0 * np.pi)

    temps = base_temp + 0.2 * circadian + rng.normal(0, 0.1, n)
    mots = base_motility + 0.3 * circadian + rng.normal(0, 0.2, n)
    acts = base_activity + 10.0 * circadian + rng.normal(0, 3.0, n)

    if inject_anomaly:
        temps[-SLOTS_PER_DAY:] += 1.5
        acts[-SLOTS_PER_DAY:] -= 30.0

    df = pd.DataFrame({"temperature": temps, "motility": mots, "activity": acts}, index=idx)

    if drop_ratio > 0:
        mask = rng.random(n) < drop_ratio
        df.loc[df.index[mask], "temperature"] = np.nan
    return df


@pytest.fixture
def rng() -> np.random.Generator:
    return np.random.default_rng(42)


@pytest.fixture
def normal_series(rng) -> pd.DataFrame:
    return make_triplet_series(rng, days=14, inject_anomaly=False)


@pytest.fixture
def anomaly_series(rng) -> pd.DataFrame:
    return make_triplet_series(rng, days=14, inject_anomaly=True)
```

- [ ] **Step 7: 写冒烟测试**

`tests/test_smoke.py`:
```python
import pytest
from app.config import settings


def test_settings_weights_sum_to_one():
    assert settings.w_stl + settings.w_cusum + settings.w_joint == pytest.approx(1.0)


def test_settings_defaults():
    assert settings.neff_mahalanobis_min == 30
    assert settings.slot_minutes == 30
```

- [ ] **Step 8: 创建 README.md**

```markdown
# ai-platform

Phase A：无监督健康异常检测 Python 微服务（design `docs/superpowers/specs/2026-06-19-ai-health-anomaly-detection-design.md`）。

## 本地开发

```bash
cd smart-livestock-server/ai-platform
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest                         # 全部测试
uvicorn app.main:app --reload  # 本地起服务（需 PG）
```

## 配置

环境变量见 `app/config.py`。DB 连接：
- Phase A 临时用 `postgres` 超管账号跑通。
- **生产切换**：Plan 2 的 `V38__add_ai_anomaly_tables.sql` 创建只读账号后，设 `AI_DB_USER` 为该只读账号。

## 与 Java 后端的关系

Java 后端（`HealthAnomalyService`）经 HTTP 调本服务的 `/ai/health/analyze`，ai-platform 直连 PG 只读查询时序窗口、返回 `PredictResponse`，由 Java 端写库（见 design §3）。
```

- [ ] **Step 9: 安装依赖并跑冒烟测试**

Run: `cd smart-livestock-server/ai-platform && pip install -r requirements.txt && pytest tests/test_smoke.py -v`
Expected: 2 passed

- [ ] **Step 10: Commit**

```bash
git add smart-livestock-server/ai-platform/
git commit -m "feat(ai-platform): 项目骨架与依赖（Phase A Task 1）"
```

---

## Task 2: API schemas（pydantic 契约）

锁定 design §5.1/§5.2 对外契约，后续 task 全部对齐此处的字段名。

**Files:**
- Create: `smart-livestock-server/ai-platform/app/schemas.py`
- Create: `smart-livestock-server/ai-platform/tests/test_schemas.py`

- [ ] **Step 1: 写失败测试**

`tests/test_schemas.py`:
```python
import pytest
from app.schemas import (CapabilityLevel, PredictRequest, PredictResponse,
                         Contributions, AnalyzeResponse)


def test_predict_request_defaults():
    req = PredictRequest(tenant_id=1, farm_id=2, livestock_ids=[10, 11])
    assert req.window_hours == 24
    assert req.live_endpoint is False


def test_predict_response_fields():
    resp = PredictResponse(
        livestock_id=10, anomaly_score=0.82, anomaly_type="multivariate",
        contributions=Contributions(stl=0.7, cusum=0.3, joint=0.9),
        capability_used="health_l1", n_eff=120, model_meta={"router": "mahalanobis"},
    )
    assert resp.anomaly_score == pytest.approx(0.82)
    assert resp.capability_used == "health_l1"
    assert resp.model_meta["router"] == "mahalanobis"


def test_anomaly_score_range():
    with pytest.raises(Exception):
        PredictResponse(livestock_id=10, anomaly_score=1.5, anomaly_type="x",
                        contributions=Contributions(), capability_used="l1",
                        n_eff=1, model_meta={})


def test_capability_level_values():
    assert CapabilityLevel.L1 == "L1"
    assert CapabilityLevel.L2 == "L2"
    assert CapabilityLevel.L3 == "L3"


def test_analyze_response_envelope():
    r = AnalyzeResponse(request_id="req-1", results=[])
    assert r.results == []
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_schemas.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.schemas'`

- [ ] **Step 3: 实现 schemas.py**

```python
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
    livestock_ids: list[int]
    window_hours: int = 24
    # 仅 /ai/health/live 探活用，正常 analyze 不设
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
```

- [ ] **Step 4: 跑测试确认通过**

Run: `pytest tests/test_schemas.py -v`
Expected: 5 passed

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/ai-platform/app/schemas.py smart-livestock-server/ai-platform/tests/test_schemas.py
git commit -m "feat(ai-platform): API schemas 契约（Task 2）"
```

---

## Task 3: 时序对齐与 N_eff 计算

design §4.3：N_eff = 过去 14 天内三维（体温/蠕动/活动）均非空的 30min 槽位数。

**Files:**
- Create: `smart-livestock-server/ai-platform/app/l1/__init__.py`
- Create: `smart-livestock-server/ai-platform/app/l1/features.py`
- Create: `smart-livestock-server/ai-platform/tests/test_features.py`

- [ ] **Step 1: 写失败测试**

`tests/test_features.py`（本 task 仅覆盖对齐与 N_eff）:
```python
import numpy as np
import pandas as pd
import pytest
from app.l1.features import resample_to_slots, compute_neff


def test_resample_aligns_to_30min_slots(rng):
    # 原始点：每小时 2 个（非 30min 整齐），应聚合到 30min 槽
    idx = pd.date_range("2026-06-01", periods=96, freq="15min")
    temps = pd.Series(np.full(96, 38.5), index=idx, name="temperature")
    mots = pd.Series(np.full(96, 3.0), index=idx, name="motility")
    acts = pd.Series(np.full(96, 50.0), index=idx, name="activity")
    df = resample_to_slots(temps, mots, acts)
    # 96 个 15min 点 = 24h = 48 个 30min 槽
    assert len(df) == 48
    assert {"temperature", "motility", "activity"} <= set(df.columns)


def test_neff_counts_full_triplet_slots(normal_series):
    df = resample_to_slots(
        normal_series["temperature"], normal_series["motility"], normal_series["activity"])
    neff = compute_neff(df)
    # 14 天完整数据，无缺失 → 14*48 = 672
    assert neff == 14 * 48


def test_neff_ignores_slots_with_missing_dim(rng):
    df = make_df_with_missing(rng, missing_dim="temperature", n_missing=10)
    neff = compute_neff(df)
    total = len(df)
    assert neff == total - 10


def make_df_with_missing(rng, missing_dim, n_missing):
    n = 100
    idx = pd.date_range("2026-06-01", periods=n, freq="30min")
    df = pd.DataFrame({
        "temperature": np.full(n, 38.5),
        "motility": np.full(n, 3.0),
        "activity": np.full(n, 50.0),
    }, index=idx)
    df.loc[df.index[:n_missing], missing_dim] = np.nan
    return df
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_features.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: 实现 app/l1/__init__.py（空）与 app/l1/features.py（本 task 部分）**

`app/l1/__init__.py`:
```python
```

`app/l1/features.py`（先只放 resample/neff，后续 task 扩展）:
```python
"""L1 特征工程（design §4.2）。本模块：时序对齐 + N_eff。"""
import numpy as np
import pandas as pd

from app.config import settings

_DIMS = ("temperature", "motility", "activity")


def resample_to_slots(temperature: pd.Series, motility: pd.Series,
                      activity: pd.Series) -> pd.DataFrame:
    """将三张表的原始点重采样对齐到 30min 槽位，每槽取均值（design §4.1 粒度）。

    入参为带 DatetimeIndex 的 Series（来自 db.py 的查询）。缺失槽位为 NaN。
    """
    rule = f"{settings.slot_minutes}min"
    return pd.DataFrame({
        "temperature": temperature.resample(rule).mean(),
        "motility": motility.resample(rule).mean(),
        "activity": activity.resample(rule).mean(),
    })


def compute_neff(slots_df: pd.DataFrame) -> int:
    """N_eff：三维均非空的 30min 槽位数（design §4.3）。"""
    present = slots_df[list(_DIMS)].notna().all(axis=1)
    return int(present.sum())
```

- [ ] **Step 4: 跑测试确认通过**

Run: `pytest tests/test_features.py -v`
Expected: 3 passed

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/ai-platform/app/l1/ smart-livestock-server/ai-platform/tests/test_features.py
git commit -m "feat(ai-platform): 时序对齐与 N_eff 计算（Task 3）"
```

---

## Task 4: 稳健基线（个体中位数+MAD，群体兜底）

design §4.2：个体自适应基线（中位数+MAD），冷启动（<14 天）用群体基线兜底。基线**不回写** `temperature_logs.baseline_temp`（design §4.2 边界）。

**Files:**
- Modify: `smart-livestock-server/ai-platform/app/l1/features.py`（追加）
- Modify: `smart-livestock-server/ai-platform/tests/test_features.py`（追加）

- [ ] **Step 1: 追加失败测试**

追加到 `tests/test_features.py`:
```python
from app.l1.features import robust_baseline, cohort_baseline


def test_robust_baseline_median_and_mad():
    vals = np.array([38.4, 38.5, 38.5, 38.6, 38.5])
    median, mad = robust_baseline(vals)
    assert median == pytest.approx(38.5)
    # MAD = median(|x - median|) = median([0.1,0,0,0.1,0]) = 0.0 → 用 0.0 防除零
    assert mad >= 0.0


def test_robust_baseline_ignores_nan():
    vals = np.array([38.5, np.nan, 38.6, 38.5, np.nan])
    median, mad = robust_baseline(vals)
    assert median == pytest.approx(38.5)


def test_robust_baseline_empty_returns_nan():
    median, mad = robust_baseline(np.array([np.nan, np.nan]))
    assert np.isnan(median)


def test_cohort_baseline_falls_back_to_group_median():
    individuals = [(38.5, 0.1), (38.7, 0.1), (38.6, 0.1)]
    median, mad = cohort_baseline(individuals)
    # 三个体中位数 38.5/38.7/38.6 的中位数 = 38.6
    assert median == pytest.approx(38.6)
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_features.py -v -k "baseline or cohort"`
Expected: FAIL — `ImportError: cannot import name 'robust_baseline'`

- [ ] **Step 3: 实现基线函数（追加到 features.py）**

```python
def robust_baseline(values: np.ndarray) -> tuple[float, float]:
    """稳健个体基线：中位数 + MAD（design §4.2）。

    返回 (median, mad)。MAD=median(|x-median|)，为 0 时返回 0（防 z-score 除零，
    由调用方用 max(mad, eps) 兜底）。NaN 自动剔除。
    """
    v = values[np.isfinite(values)]
    if v.size == 0:
        return (float("nan"), 0.0)
    median = float(np.median(v))
    mad = float(np.median(np.abs(v - median)))
    return (median, mad)


def cohort_baseline(individual_baselines: list[tuple[float, float]]) -> tuple[float, float]:
    """群体基线兜底（冷启动，design §4.2）：所有个体 median 的 median + 其 MAD。"""
    medians = np.array([m for m, _ in individual_baselines if np.isfinite(m)], dtype=float)
    if medians.size == 0:
        return (float("nan"), 0.0)
    m = float(np.median(medians))
    mad = float(np.median(np.abs(medians - m)))
    return (m, mad)
```

- [ ] **Step 4: 跑测试确认通过**

Run: `pytest tests/test_features.py -v`
Expected: 7 passed（3 旧 + 4 新）

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/ai-platform/app/l1/features.py smart-livestock-server/ai-platform/tests/test_features.py
git commit -m "feat(ai-platform): 稳健基线（个体+群体兜底）（Task 4）"
```

---

## Task 5: STL 残差与 10 维特征向量

design §4.2：每维 STL 分解（周期 24h）取 residual；每维 3 特征（24h 均值相对基线 z-score、24h 趋势斜率、近 6h STL residual 峰值）× 3 维 + CUSUM = 10 特征。

**Files:**
- Modify: `smart-livestock-server/ai-platform/app/l1/features.py`
- Modify: `smart-livestock-server/ai-platform/tests/test_features.py`

- [ ] **Step 1: 追加失败测试**

```python
from app.l1.features import stl_residual, build_feature_vector, FEATURE_DIMS

FEATURE_NAMES = 10


def test_stl_residual_removes_circadian(normal_series):
    resid = stl_residual(normal_series["temperature"])
    # 去除昼夜节律后，残差应远小于原始波动幅度
    assert resid.std() < normal_series["temperature"].std()


def test_stl_residual_handles_short_series():
    short = pd.Series(np.full(20, 38.5), index=pd.date_range("2026-06-01", periods=20, freq="30min"))
    resid = stl_residual(short)
    # 不足一个周期（48），返回去均值序列不报错
    assert len(resid) == 20


def test_build_feature_vector_shape(normal_series):
    import numpy as np
    baseline = {d: (normal_series[d].median(), 0.1) for d in ("temperature", "motility", "activity")}
    vec, names = build_feature_vector(normal_series, baseline)
    assert vec.shape == (FEATURE_NAMES,)
    assert len(names) == FEATURE_NAMES
    # 正常序列的 z-score 特征应接近 0（相对自身基线）
    assert vec[0] == pytest.approx(0.0, abs=1.0)


def test_feature_vector_anomaly_elevates_z(anomaly_series):
    baseline = {d: (anomaly_series[d].iloc[:-48].median(), 0.1)
                for d in ("temperature", "motility", "activity")}
    vec, _ = build_feature_vector(anomaly_series, baseline)
    # 第一维 temp_z（最后 24h 注入升温）应显著为正
    assert vec[0] > 5.0
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_features.py -v -k "stl or feature_vector"`
Expected: FAIL — `ImportError`

- [ ] **Step 3: 实现 STL 残差与特征向量**

追加到 `app/l1/features.py`:
```python
from statsmodels.tsa.seasonal import STL

# 特征维度常量（design §4.2：3 维 × 3 特征 + CUSUM = 10）
FEATURE_DIMS = 10
_PERIOD_SLOTS = 48  # 30min × 48 = 24h
_DIM_NAMES = ("temperature", "motility", "activity")


def stl_residual(series: pd.Series, period: int = _PERIOD_SLOTS) -> pd.Series:
    """STL 分解取 residual（design §4.2 L1a 节律剥离，周期 24h）。

    序列短于一个周期时，退化为去均值（避免 statsmodels 报错）。
    """
    s = series.dropna()
    if len(s) < period:
        return series - series.mean()
    stl = STL(s, period=period, robust=True)
    resid = stl.fit().resid
    return resid.reindex(series.index)


def _slope(values: np.ndarray) -> float:
    """简单线性回归斜率（一维）。"""
    n = len(values)
    if n < 2:
        return 0.0
    x = np.arange(n, dtype=float)
    y = values - values.mean()
    denom = ((x - x.mean()) ** 2).sum()
    if denom == 0:
        return 0.0
    return float(np.sum((x - x.mean()) * y) / denom)


def build_feature_vector(slots_df: pd.DataFrame,
                         baselines: dict[str, tuple[float, float]]) -> tuple[np.ndarray, list[str]]:
    """构建 10 维特征向量（design §4.2）。

    baselines: {dim: (median, mad)}（来自 robust_baseline / cohort_baseline）。
    返回 (feature_vector[10], feature_names[10])。CUSUM 维（第 10 维）此处占位 0，
    由 detectors.cusum_score 在 L1 编排时填入。
    """
    from app.config import settings
    detect_n = settings.detection_window_hours * 2  # 24h → 48 槽
    recent = slots_df.tail(detect_n)

    names: list[str] = []
    feats: list[float] = []
    for dim in _DIM_NAMES:
        median, mad = baselines[dim]
        eps = max(mad * 1.4826, 1e-6)  # MAD → 近似 std
        col = recent[dim].dropna()
        if col.empty or np.isnan(median):
            feats.extend([0.0, 0.0, 0.0])
        else:
            z = float((col.mean() - median) / eps)
            slope = _slope(col.to_numpy())
            resid = stl_residual(slots_df[dim]).tail(len(recent))
            stl_peak = float(np.nanmax(np.abs(resid.to_numpy()))) if resid.notna().any() else 0.0
            feats.extend([z, slope, stl_peak])
        names.extend([f"{dim}_z", f"{dim}_slope", f"{dim}_stl_peak"])

    feats.append(0.0)  # cusum 占位
    names.append("cusum")
    assert len(feats) == FEATURE_DIMS
    return np.array(feats, dtype=float), names
```

- [ ] **Step 4: 跑测试确认通过**

Run: `pytest tests/test_features.py -v`
Expected: all passed

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/ai-platform/app/l1/features.py smart-livestock-server/ai-platform/tests/test_features.py
git commit -m "feat(ai-platform): STL 残差与 10 维特征向量（Task 5）"
```

---

## Task 6: L1a STL 检测器 + L1b CUSUM 检测器

design §4.3：L1a STL 节律剥离分数、L1b CUSUM 变点分数。手写 CUSUM（可控可测，不引 ruptures）。

**Files:**
- Create: `smart-livestock-server/ai-platform/app/l1/detectors.py`
- Create: `smart-livestock-server/ai-platform/tests/test_detectors.py`

- [ ] **Step 1: 写失败测试**

`tests/test_detectors.py`:
```python
import numpy as np
import pandas as pd
import pytest
from app.l1.detectors import stl_layer_score, cusum_score


def test_stl_layer_score_normal_is_low(normal_series):
    score = stl_layer_score(normal_series["temperature"])
    assert 0.0 <= score <= 1.0
    assert score < 0.5  # 正常序列分数低


def test_stl_layer_score_anomaly_is_higher(anomaly_series):
    normal_score = stl_layer_score(anomaly_series["temperature"].iloc[:-48])
    anomaly_score = stl_layer_score(anomaly_series["temperature"])
    assert anomaly_score > normal_score


def test_cusum_flat_series_low():
    flat = pd.Series(np.zeros(96), index=pd.date_range("2026-06-01", periods=96, freq="30min"))
    assert cusum_score(flat) == pytest.approx(0.0, abs=0.5)


def test_cusum_detects_step_change():
    # 前 48 点 0，后 48 点 +3（突变）
    vals = np.concatenate([np.zeros(48), np.full(48, 3.0)])
    s = pd.Series(vals, index=pd.date_range("2026-06-01", periods=96, freq="30min"))
    score = cusum_score(s)
    assert score > 5.0  # 突变产生高分


def test_cusum_output_finite():
    s = pd.Series(np.random.default_rng(1).normal(0, 1, 96),
                  index=pd.date_range("2026-06-01", periods=96, freq="30min"))
    score = cusum_score(s)
    assert np.isfinite(score)
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_detectors.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: 实现 detectors.py（L1a + L1b）**

```python
"""L1 检测器（design §4.3）。

L1a STL：节律剥离后取近窗口 residual 峰值的稳健 z-score。
L1b CUSUM：双侧累积和变点（手写，可控可测）。
L1c Mahalanobis 见 Task 7。
"""
import numpy as np
import pandas as pd

from app.l1.features import stl_residual


def stl_layer_score(series: pd.Series, period: int = 48) -> float:
    """L1a：STL residual 峰值的稳健 z-score，再经 sigmoid 压到 [0,1]。

    高 residual 峰值 → 高分（捕获"节律被破坏"型异常）。
    """
    resid = stl_residual(series, period=period).dropna()
    if resid.empty:
        return 0.0
    median = float(np.median(resid))
    mad = float(np.median(np.abs(resid - median)))
    eps = max(mad * 1.4826, 1e-6)
    peak = float(np.max(np.abs(resid - median) / eps))
    # 经验映射：z 峰值 3+ 视为显著异常 → sigmoid 拉伸
    return float(1.0 / (1.0 + np.exp(-(peak - 3.0))))


def cusum_score(series: pd.Series) -> float:
    """L1b：双侧 CUSUM 变点分数（design §4.3 突变检测）。

    标准化残差后正向/负向累积，取峰值。返回原始累积量（非 [0,1]，
    由 fusion.normalize_cusum 统一归一化）。
    """
    s = series.dropna()
    if len(s) < 2:
        return 0.0
    z = (s - s.mean())
    std = z.std()
    if std == 0 or not np.isfinite(std):
        return 0.0
    z = (z / std).to_numpy()
    pos = np.cumsum(np.clip(z, 0.0, None))
    neg = np.cumsum(np.clip(-z, 0.0, None))
    peak = max(float(pos.max()) if pos.size else 0.0,
               float(neg.max()) if neg.size else 0.0)
    return float(peak)
```

- [ ] **Step 4: 跑测试确认通过**

Run: `pytest tests/test_detectors.py -v`
Expected: 5 passed

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/ai-platform/app/l1/detectors.py smart-livestock-server/ai-platform/tests/test_detectors.py
git commit -m "feat(ai-platform): L1a STL + L1b CUSUM 检测器（Task 6）"
```

---

## Task 7: L1c Mahalanobis 联合检测器

design §4.3：按 N_eff 路由，30≤N_eff<200 用 Mahalanobis（Phase A 落这档）。捕获"单维不超阈但多维同时偏离"。

**Files:**
- Modify: `smart-livestock-server/ai-platform/app/l1/detectors.py`
- Modify: `smart-livestock-server/ai-platform/tests/test_detectors.py`

- [ ] **Step 1: 追加失败测试**

```python
from app.l1.detectors import fit_mahalanobis, mahalanobis_distance


def test_mahalanobis_normal_point_low_distance(rng, normal_series):
    from app.l1.features import build_feature_vector
    dims = ("temperature", "motility", "activity")
    baseline = {d: (normal_series[d].median(), 0.1) for d in dims}
    # 用多个窗口构造历史特征矩阵
    feats = []
    for start in range(0, len(normal_series) - 48, 24):
        window = normal_series.iloc[start:start + 48]
        v, _ = build_feature_vector(window, baseline)
        feats.append(v)
    X = np.array(feats)
    model = fit_mahalanobis(X)
    # 当前点（最后一个窗口）应低距离
    d2 = mahalanobis_distance(model, X[-1:])
    assert np.all(d2 >= 0)


def test_mahalanobis_outlier_higher_than_inlier(rng, normal_series):
    from app.l1.features import build_feature_vector
    dims = ("temperature", "motility", "activity")
    baseline = {d: (normal_series[d].median(), 0.1) for d in dims}
    feats = [build_feature_vector(normal_series.iloc[s:s + 48], baseline)[0]
             for s in range(0, len(normal_series) - 48, 24)]
    X = np.array(feats)
    model = fit_mahalanobis(X)
    inlier_d2 = float(np.mean(mahalanobis_distance(model, X)))
    # 构造一个明显偏离的点（温度 z 拉高）
    outlier = X.mean(axis=0).copy()
    outlier[0] += 10.0
    outlier_d2 = float(mahalanobis_distance(model, outlier.reshape(1, -1))[0])
    assert outlier_d2 > inlier_d2


def test_mahalanobis_insufficient_samples_returns_none():
    # 少于特征维数时无法估协方差，返回 None（路由器据此降级）
    X = np.array([[1.0] * 10, [2.0] * 10])  # 仅 2 样本
    assert fit_mahalanobis(X) is None
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_detectors.py -v -k "mahalanobis"`
Expected: FAIL — `ImportError`

- [ ] **Step 3: 实现 Mahalanobis（追加到 detectors.py）**

```python
from sklearn.covariance import EmpiricalCovariance
from app.l1.features import FEATURE_DIMS


def fit_mahalanobis(history_features: np.ndarray):
    """用历史特征矩阵拟合协方差，返回模型（design §4.3 L1c）。

    样本数 < FEATURE_DIMS+1 时返回 None（协方差不可估，路由器降级到纯规则）。
    """
    X = np.asarray(history_features, dtype=float)
    if X.ndim != 2 or X.shape[0] < FEATURE_DIMS + 1:
        return None
    # 去常量列（方差 0）避免奇异协方差
    var = X.var(axis=0)
    keep = var > 1e-12
    if keep.sum() < 2:
        return None
    model = EmpiricalCovariance().fit(X[:, keep])
    return {"model": model, "keep_mask": keep}


def mahalanobis_distance(model, points: np.ndarray) -> np.ndarray:
    """返回平方 Mahalanobis 距离（χ² 自由度 = 保留特征数）。"""
    if model is None:
        return np.zeros(len(points))
    P = np.asarray(points, dtype=float)[:, model["keep_mask"]]
    return model["model"].mahalanobis(P)
```

- [ ] **Step 4: 跑测试确认通过**

Run: `pytest tests/test_detectors.py -v`
Expected: all passed（5 旧 + 3 新）

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/ai-platform/app/l1/detectors.py smart-livestock-server/ai-platform/tests/test_detectors.py
git commit -m "feat(ai-platform): L1c Mahalanobis 联合检测器（Task 7）"
```

---

## Task 8: 融合（归一化 + 加权）

design §4.4：各层先归一化到 [0,1]（STL 用 14 天 99 分位、CUSUM 用历史最大、Mahalanobis 用 χ² CDF）再加权（0.3/0.3/0.4）。anomaly_type 按主导层判定。

**Files:**
- Create: `smart-livestock-server/ai-platform/app/l1/fusion.py`
- Create: `smart-livestock-server/ai-platform/tests/test_fusion.py`

- [ ] **Step 1: 写失败测试**

`tests/test_fusion.py`:
```python
import numpy as np
import pytest
from app.l1.fusion import (normalize_stl, normalize_cusum, normalize_mahalanobis,
                           fuse, decide_anomaly_type)


def test_normalize_stl_clamps_to_unit():
    assert normalize_stl(0.0) == pytest.approx(0.0, abs=0.01)
    assert normalize_stl(2.0) == pytest.approx(1.0)  # sigmoid 上界趋 1
    assert 0.0 <= normalize_stl(0.7) <= 1.0


def test_normalize_cusum_uses_history_max():
    # 当前 10，历史最大 20 → 0.5
    assert normalize_cusum(10.0, history_max=20.0) == pytest.approx(0.5)
    assert normalize_cusum(30.0, history_max=20.0) == pytest.approx(1.0)  # 超历史截断 1
    assert normalize_cusum(0.0, history_max=20.0) == pytest.approx(0.0)


def test_normalize_mahalanobis_chi2_cdf():
    # 自由度 10，d2 = 中位数附近 → ~0.5
    from scipy.stats import chi2
    d2 = chi2.median(df=10)
    p = normalize_mahalanobis(d2, df=10)
    assert 0.4 < p < 0.6


def test_fuse_weighted_average():
    score = fuse(stl=0.6, cusum=0.2, joint=0.8)
    assert score == pytest.approx(0.3 * 0.6 + 0.3 * 0.2 + 0.4 * 0.8)


def test_fuse_in_unit_range():
    score = fuse(stl=1.0, cusum=1.0, joint=1.0)
    assert score == pytest.approx(1.0)


def test_decide_anomaly_type_picks_dominant_layer():
    assert decide_anomaly_type(stl=0.9, cusum=0.1, joint=0.2) == "circadian_disruption"
    assert decide_anomaly_type(stl=0.1, cusum=0.9, joint=0.2) == "abrupt_change"
    assert decide_anomaly_type(stl=0.1, cusum=0.1, joint=0.9) == "multivariate"
    assert decide_anomaly_type(stl=0.1, cusum=0.1, joint=0.1) == "normal"
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_fusion.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: 实现 fusion.py**

```python
"""L1 融合层（design §4.4）。各层分数先归一化到 [0,1] 再加权。"""
import numpy as np
from scipy.stats import chi2

from app.config import settings


def normalize_stl(stl_score: float) -> float:
    """STL 层分数已在 detectors.stl_layer_score 经 sigmoid 压到 [0,1]，直接截断返回。"""
    return float(np.clip(stl_score, 0.0, 1.0))


def normalize_cusum(cusum_raw: float, history_max: float) -> float:
    """CUSUM 用历史最大值归一化（design §4.4），超历史截断为 1。"""
    if history_max <= 0:
        return 0.0
    return float(np.clip(cusum_raw / history_max, 0.0, 1.0))


def normalize_mahalanobis(d2: float, df: int) -> float:
    """Mahalanobis 平方距离用 χ² CDF 归一化（design §4.4）。"""
    if df <= 0:
        return 0.0
    return float(np.clip(chi2.cdf(d2, df=df), 0.0, 1.0))


def fuse(stl: float, cusum: float, joint: float) -> float:
    """加权融合（design §4.4 初始权重 0.3/0.3/0.4）。"""
    s = settings.w_stl * stl + settings.w_cusum * cusum + settings.w_joint * joint
    return float(np.clip(s, 0.0, 1.0))


def decide_anomaly_type(stl: float, cusum: float, joint: float,
                        threshold: float = 0.5) -> str:
    """按主导层判定 anomaly_type（design §4.4）。三方都低 → normal。"""
    layers = {"circadian_disruption": stl, "abrupt_change": cusum, "multivariate": joint}
    dominant = max(layers, key=layers.get)
    if layers[dominant] < threshold:
        return "normal"
    return dominant
```

- [ ] **Step 4: 跑测试确认通过**

Run: `pytest tests/test_fusion.py -v`
Expected: 6 passed

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/ai-platform/app/l1/fusion.py smart-livestock-server/ai-platform/tests/test_fusion.py
git commit -m "feat(ai-platform): 融合归一化与加权（Task 8）"
```

---

## Task 9: capability base + router（双维度路由 + N_eff 迟滞）

design §5.1 capability 同构契约；§4.3 router 双维度（能力可用性 L3→L2→L1 降级 + N_eff 分档带 ±20% 迟滞）。

**Files:**
- Create: `smart-livestock-server/ai-platform/app/capability/__init__.py`
- Create: `smart-livestock-server/ai-platform/app/capability/base.py`
- Create: `smart-livestock-server/ai-platform/app/capability/router.py`
- Create: `smart-livestock-server/ai-platform/tests/test_router.py`

- [ ] **Step 1: 写失败测试**

`tests/test_router.py`:
```python
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
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_router.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: 实现 base.py**

`app/capability/__init__.py`（空）。`app/capability/base.py`:
```python
"""Capability 同构契约（design §5.1）。"""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Optional

from app.schemas import CapabilityLevel, PredictRequest, PredictResponse


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
    def predict(self, req: PredictRequest, ctx: CapabilityContext) -> PredictResponse: ...


class CapabilityRegistry:
    """capability 门面：注册 + 按可用性选最高就绪层（design §3 registry+router）。"""

    def __init__(self):
        self._caps: dict[CapabilityLevel, Capability] = {}

    def register(self, cap: Capability) -> None:
        self._caps[cap.level] = cap

    def select_available(self, ctx: CapabilityContext) -> Optional[Capability]:
        for level in (CapabilityLevel.L3, CapabilityLevel.L2, CapabilityLevel.L1):
            cap = self._caps.get(level)
            if cap is not None and cap.is_available(ctx):
                return cap
        return None
```

- [ ] **Step 4: 实现 router.py**

```python
"""L1 内部 router：按 N_eff 分档选算法（design §4.3）+ ±20% 迟滞。"""
from app.config import settings


def route_by_neff(n_eff: int, state: dict | None = None) -> str:
    """返回算法名：rules / mahalanobis / iforest。

    state: 可变 dict {"current": <algo>}，用于跨次调用保持迟滞。无 state 则无迟滞（纯阈值）。
    升档需 N_eff ≥ 上阈，降档需 N_eff < 下阈（下阈 = 上阈 × (1 - hyst)）。
    """
    hi_iforest = settings.neff_iforest_min                  # 200
    lo_iforest = int(hi_iforest * (1 - settings.neff_hysteresis))  # 160
    hi_maha = settings.neff_mahalanobis_min                 # 30
    lo_maha = int(hi_maha * (1 - settings.neff_hysteresis))  # 24

    current = (state or {}).get("current")

    # 无迟滞状态：纯阈值
    if current is None:
        if n_eff < hi_maha:
            return "rules"
        if n_eff < hi_iforest:
            return "mahalanobis"
        return "iforest"

    # 有迟滞：仅在跨出迟滞带时切换
    if current == "rules":
        return "mahalanobis" if n_eff >= hi_maha else "rules"
    if current == "mahalanobis":
        if n_eff >= hi_iforest:
            new = "iforest"
        elif n_eff < lo_maha:
            new = "rules"
        else:
            new = "mahalanobis"
        return new
    if current == "iforest":
        return "mahalanobis" if n_eff < lo_iforest else "iforest"
    # 未知 current，退回纯阈值
    return route_by_neff(n_eff, state=None)
```

- [ ] **Step 5: 跑测试确认通过**

Run: `pytest tests/test_router.py -v`
Expected: 6 passed

- [ ] **Step 6: Commit**

```bash
git add smart-livestock-server/ai-platform/app/capability/ smart-livestock-server/ai-platform/tests/test_router.py
git commit -m "feat(ai-platform): capability 契约 + N_eff 路由迟滞（Task 9）"
```

---

## Task 10: L1 health capability + L2/L3 占位

L1 编排 features + detectors + fusion；L2/L3 占位 `is_available=False`。L1 内 N_eff<30 降级到"纯规则 + 群体基线"档（design §4.3 冷启动）。

**Files:**
- Create: `smart-livestock-server/ai-platform/app/capability/health_l1.py`
- Create: `smart-livestock-server/ai-platform/app/capability/dl_l2.py`
- Create: `smart-livestock-server/ai-platform/app/capability/llm_l3.py`
- Create: `smart-livestock-server/ai-platform/tests/test_health_l1.py`

- [ ] **Step 1: 写失败测试**

`tests/test_health_l1.py`:
```python
import pytest
from app.capability.base import CapabilityContext, CapabilityLevel
from app.capability.health_l1 import HealthAnomalyL1
from app.capability.dl_l2 import DeepLearningL2
from app.capability.llm_l3 import LlmL3
from app.schemas import PredictRequest


def _make_req():
    return PredictRequest(tenant_id=1, farm_id=2, livestock_ids=[10])


def test_l1_is_available_when_has_data():
    cap = HealthAnomalyL1()
    ctx = CapabilityContext(n_eff=120)
    assert cap.is_available(ctx) is True
    assert cap.level == CapabilityLevel.L1


def test_l1_predict_normal_returns_low_score(normal_series):
    cap = HealthAnomalyL1()
    resp = cap.predict_series(_make_req(), normal_series, cohort_baselines=[])
    assert 0.0 <= resp.anomaly_score <= 1.0
    assert resp.anomaly_type in ("normal", "circadian_disruption", "abrupt_change", "multivariate")
    assert resp.capability_used == "health_l1"


def test_l1_predict_anomaly_scores_higher(anomaly_series, normal_series):
    cap = HealthAnomalyL1()
    normal_resp = cap.predict_series(_make_req(), normal_series, cohort_baselines=[])
    anomaly_resp = cap.predict_series(_make_req(), anomaly_series, cohort_baselines=[])
    assert anomaly_resp.anomaly_score > normal_resp.anomaly_score


def test_l1_cold_start_low_neff_still_returns(normal_series):
    cap = HealthAnomalyL1()
    ctx = CapabilityContext(n_eff=10)
    assert cap.is_available(ctx) is True  # L1 始终可用（内部降级到规则档）
    resp = cap.predict_series(_make_req(), normal_series.tail(48 * 3), cohort_baselines=[])
    assert resp.model_meta.get("router") == "rules"


def test_l2_l3_unavailable():
    assert DeepLearningL2().is_available(CapabilityContext()) is False
    assert LlmL3().is_available(CapabilityContext()) is False
```

> 注：`predict_series` 是测试友好的入口（直接传 DataFrame，绕过 db）；HTTP 层（Task 13）用 db 取数后调它。`predict(req)` 内部转调 predict_series。

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_health_l1.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: 实现 health_l1.py**

```python
"""L1 health_anomaly capability（design §4 ★核心）。编排 features + detectors + fusion。"""
import numpy as np
import pandas as pd

from app.capability.base import Capability, CapabilityContext, CapabilityLevel
from app.capability.router import route_by_neff
from app.l1.features import (compute_neff, robust_baseline, cohort_baseline,
                             build_feature_vector, _DIM_NAMES)
from app.l1.detectors import stl_layer_score, cusum_score, fit_mahalanobis, mahalanobis_distance
from app.l1.fusion import (normalize_stl, normalize_cusum, normalize_mahalanobis,
                           fuse, decide_anomaly_type)
from app.schemas import Contributions, PredictRequest, PredictResponse

from app.config import settings


class HealthAnomalyL1(Capability):
    """L1 无监督健康异常检测（design §4）。"""

    @property
    def level(self) -> CapabilityLevel:
        return CapabilityLevel.L1

    def is_available(self, ctx: CapabilityContext) -> bool:
        # L1 始终可用：N_eff<30 内部降级到"纯规则 + 群体基线"档（design §4.3 冷启动）
        return True

    def predict(self, req: PredictRequest, ctx: CapabilityContext) -> PredictResponse:
        # HTTP 层负责取数后调 predict_series；predict 在 engine 透传链路保留
        raise NotImplementedError("Use predict_series with pre-fetched window data")

    def predict_series(self, req: PredictRequest, slots_df: pd.DataFrame,
                       cohort_baselines: list[tuple[float, float]]) -> PredictResponse:
        livestock_id = req.livestock_ids[0] if req.livestock_ids else 0
        n_eff = compute_neff(slots_df)
        router_state: dict = {}
        algo = route_by_neff(n_eff, state=router_state)

        # 个体基线（每维），冷启动用群体兜底
        baselines: dict[str, tuple[float, float]] = {}
        for dim in _DIM_NAMES:
            med, mad = robust_baseline(slots_df[dim].to_numpy())
            if np.isnan(med) and cohort_baselines:
                med, mad = cohort_baseline(cohort_baselines)
            baselines[dim] = (med, mad)

        # L1a STL（温度维主导节律剥离分数；三维取均值增强信号）
        stl_scores = [stl_layer_score(slots_df[d]) for d in _DIM_NAMES]
        stl_raw = float(np.mean(stl_scores))

        # L1b CUSUM（温度残差变点）
        from app.l1.features import stl_residual
        cusum_raw = cusum_score(stl_residual(slots_df["temperature"]))
        # 历史最大（用基线窗口自身的 CUSUM 滚动估计，简化为当前值的 2 倍作上限）
        history_max = max(cusum_raw * 2.0, 1.0)

        # L1c Mahalanobis（按 algo；rules 档跳过）
        joint_norm = 0.0
        df_keep = 0
        if algo != "rules":
            # 滚动构造历史特征矩阵（24h 滑窗步长 12h）
            feats = []
            win = settings.detection_window_hours * 2
            for start in range(0, max(1, len(slots_df) - win), 12):
                window = slots_df.iloc[start:start + win]
                if len(window) >= win // 2:
                    v, _ = build_feature_vector(window, baselines)
                    feats.append(v)
            if len(feats) >= 2:
                X = np.array(feats)
                model = fit_mahalanobis(X)
                if model is not None:
                    cur, _ = build_feature_vector(slots_df, baselines)
                    d2 = float(mahalanobis_distance(model, cur.reshape(1, -1))[0])
                    df_keep = int(model["keep_mask"].sum())
                    joint_norm = normalize_mahalanobis(d2, df=df_keep)

        stl_norm = normalize_stl(stl_raw)
        cusum_norm = normalize_cusum(cusum_raw, history_max)
        score = fuse(stl_norm, cusum_norm, joint_norm)
        atype = decide_anomaly_type(stl_norm, cusum_norm, joint_norm)

        return PredictResponse(
            livestock_id=livestock_id,
            anomaly_score=score,
            anomaly_type=atype,
            contributions=Contributions(stl=stl_norm, cusum=cusum_norm, joint=joint_norm),
            capability_used="health_l1",
            n_eff=n_eff,
            model_meta={"router": algo, "weights": [settings.w_stl, settings.w_cusum, settings.w_joint]},
        )
```

- [ ] **Step 4: 实现 dl_l2.py / llm_l3.py（占位）**

`app/capability/dl_l2.py`:
```python
"""L2 深度学习 capability（Phase A 占位，design §3 is_available=False）。"""
from app.capability.base import Capability, CapabilityContext, CapabilityLevel
from app.schemas import PredictRequest, PredictResponse


class DeepLearningL2(Capability):
    @property
    def level(self) -> CapabilityLevel:
        return CapabilityLevel.L2

    def is_available(self, ctx: CapabilityContext) -> bool:
        return False  # Phase A 未实现

    def predict(self, req: PredictRequest, ctx: CapabilityContext) -> PredictResponse:
        raise NotImplementedError("L2 deep learning not available in Phase A")
```

`app/capability/llm_l3.py`:
```python
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
```

- [ ] **Step 5: 跑测试确认通过**

Run: `pytest tests/test_health_l1.py -v`
Expected: 5 passed

- [ ] **Step 6: Commit**

```bash
git add smart-livestock-server/ai-platform/app/capability/health_l1.py smart-livestock-server/ai-platform/app/capability/dl_l2.py smart-livestock-server/ai-platform/app/capability/llm_l3.py smart-livestock-server/ai-platform/tests/test_health_l1.py
git commit -m "feat(ai-platform): L1 health capability + L2/L3 占位（Task 10）"
```

---

## Task 11: engine 层（透传 → capability 门面）

design §3 engine 透传：TaskPlan → registry.select_available → predict。

**Files:**
- Create: `smart-livestock-server/ai-platform/app/engine.py`
- Create: `smart-livestock-server/ai-platform/tests/test_engine.py`

- [ ] **Step 1: 写失败测试**

`tests/test_engine.py`:
```python
import pytest
import pandas as pd
from app.engine import Engine
from app.capability.health_l1 import HealthAnomalyL1
from app.capability.base import CapabilityRegistry
from app.schemas import PredictRequest


def test_engine_routes_to_l1(normal_series):
    reg = CapabilityRegistry()
    reg.register(HealthAnomalyL1())
    engine = Engine(registry=reg)
    req = PredictRequest(tenant_id=1, farm_id=2, livestock_ids=[10])
    resp = engine.predict_series(req, slots_df=normal_series, cohort_baselines=[])
    assert resp.capability_used == "health_l1"


def test_engine_returns_none_when_no_capability(monkeypatch):
    reg = CapabilityRegistry()  # 空
    engine = Engine(registry=reg)
    req = PredictRequest(tenant_id=1, farm_id=2, livestock_ids=[10])
    df = pd.DataFrame()
    assert engine.predict_series(req, slots_df=df, cohort_baselines=[]) is None
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_engine.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: 实现 engine.py**

```python
"""engine 执行层（design §3 Phase A 透传：TaskPlan → capability 门面）。

Phase A 透传是为固定 engine→capability 调用协议，Phase B/C 填多 agent 不破坏调用方。
"""
import pandas as pd

from app.capability.base import CapabilityContext, CapabilityRegistry
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
```

- [ ] **Step 4: 跑测试确认通过**

Run: `pytest tests/test_engine.py -v`
Expected: 2 passed

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/ai-platform/app/engine.py smart-livestock-server/ai-platform/tests/test_engine.py
git commit -m "feat(ai-platform): engine 透传层（Task 11）"
```

---

## Task 12: db.py（直连 PostgreSQL 只读查询时序窗口）

design §9.1 方案 A：直连 PG 只读，按 livestock_ids + window 查 temperature_logs/rumen_motility_logs/activity_logs。

**Files:**
- Create: `smart-livestock-server/ai-platform/app/db.py`
- Create: `smart-livestock-server/ai-platform/tests/test_db.py`

- [ ] **Step 1: 写失败测试（mock psycopg，验证 SQL 与映射，不依赖真实 PG）**

`tests/test_db.py`:
```python
import pandas as pd
import pytest
from datetime import datetime, timezone
import app.db as dbmod


class FakeCursor:
    def __init__(self, rows_by_table):
        self._rows = rows_by_table
        self._last_sql = ""
    def execute(self, sql, params=None):
        self._last_sql = sql
    def fetchall(self):
        return self._rows.pop(0) if self._rows else []
    def __enter__(self): return self
    def __exit__(self, *a): return False


class FakeConn:
    def __init__(self, rows_by_table):
        self._rows = rows_by_table
        self.queries = []
    def cursor(self):
        c = FakeCursor(self._rows)
        return c
    def close(self): pass


def test_fetch_window_returns_three_series(monkeypatch):
    temp_rows = [(10, 38.5, datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc)),
                 (10, 38.6, datetime(2026, 6, 1, 0, 30, tzinfo=timezone.utc))]
    mot_rows = [(10, 3.0, datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc))]
    act_rows = [(10, 50.0, datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc))]
    fake = FakeConn([temp_rows, mot_rows, act_rows])
    monkeypatch.setattr(dbmod, "_connect", lambda: fake)

    series_map = dbmod.fetch_window(livestock_id=10, window_hours=24)
    assert set(series_map.keys()) == {"temperature", "motility", "activity"}
    assert isinstance(series_map["temperature"], pd.Series)
    assert len(series_map["temperature"]) == 2


def test_fetch_window_handles_empty(monkeypatch):
    fake = FakeConn([[], [], []])
    monkeypatch.setattr(dbmod, "_connect", lambda: fake)
    series_map = dbmod.fetch_window(livestock_id=999, window_hours=24)
    assert len(series_map["temperature"]) == 0
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_db.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: 实现 db.py**

```python
"""直连 PostgreSQL 只读数据访问层（design §9.1 方案 A）。

仅 SELECT temperature_logs / rumen_motility_logs / activity_logs 三表（字段契约 design §7.3）。
只读账号由 Plan 2 V38 创建；Phase A 临时用配置账号。
"""
import pandas as pd
import psycopg

from app.config import settings

# design §7.3 字段契约
_QUERIES = {
    "temperature": (
        "SELECT livestock_id, temperature, recorded_at FROM temperature_logs "
        "WHERE livestock_id = %s AND recorded_at >= NOW() - (%s || ' hours')::interval "
        "ORDER BY recorded_at"),
    "motility": (
        "SELECT livestock_id, frequency, recorded_at FROM rumen_motility_logs "
        "WHERE livestock_id = %s AND recorded_at >= NOW() - (%s || ' hours')::interval "
        "ORDER BY recorded_at"),
    "activity": (
        "SELECT livestock_id, activity_index, recorded_at FROM activity_logs "
        "WHERE livestock_id = %s AND recorded_at >= NOW() - (%s || ' hours')::interval "
        "ORDER BY recorded_at"),
}
_VALUE_COL = {"temperature": "temperature", "motility": "frequency", "activity": "activity_index"}


def _connect():
    return psycopg.connect(
        host=settings.db_host, port=settings.db_port, dbname=settings.db_name,
        user=settings.db_user, password=settings.db_password,
    )


def fetch_window(livestock_id: int, window_hours: int) -> dict[str, pd.Series]:
    """查询单头家畜的三维时序窗口，返回 {dim: Series(index=recorded_at)}。"""
    result: dict[str, pd.Series] = {}
    conn = _connect()
    try:
        for dim, sql in _QUERIES.items():
            with conn.cursor() as cur:
                cur.execute(sql, (livestock_id, str(window_hours)))
                rows = cur.fetchall()
            if rows:
                values = [r[1] for r in rows]
                idx = pd.to_datetime([r[2] for r in rows], utc=True)
                result[dim] = pd.Series(values, index=idx, name=dim)
            else:
                result[dim] = pd.Series([], dtype=float, name=dim)
    finally:
        conn.close()
    return result
```

- [ ] **Step 4: 跑测试确认通过**

Run: `pytest tests/test_db.py -v`
Expected: 2 passed

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/ai-platform/app/db.py smart-livestock-server/ai-platform/tests/test_db.py
git commit -m "feat(ai-platform): PG 只读数据访问层（Task 12）"
```

---

## Task 13: FastAPI 端点（orchestration）

design §5.2：POST /ai/health/analyze（批量）、POST /ai/health/analyze/{id}（单头）、GET /ai/health/live（探活）。

**Files:**
- Create: `smart-livestock-server/ai-platform/app/main.py`
- Create: `smart-livestock-server/ai-platform/tests/test_main.py`

- [ ] **Step 1: 写失败测试（FastAPI TestClient，mock db/engine）**

`tests/test_main.py`:
```python
import pytest
import pandas as pd
from fastapi.testclient import TestClient
from app.main import app


@pytest.fixture
def client():
    return TestClient(app)


def test_live_endpoint(client):
    r = client.get("/ai/health/live")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_analyze_single(client, normal_series, monkeypatch):
    # mock db 返回三维 series
    import app.main as mainmod
    monkeypatch.setattr(mainmod, "_fetch", lambda lid, h: {
        "temperature": normal_series["temperature"],
        "motility": normal_series["motility"],
        "activity": normal_series["activity"],
    })
    r = client.post("/ai/health/analyze/10", json={"tenant_id": 1, "farm_id": 2, "window_hours": 24})
    assert r.status_code == 200
    body = r.json()
    assert body["request_id"]
    assert len(body["results"]) == 1
    assert 0.0 <= body["results"][0]["anomaly_score"] <= 1.0


def test_analyze_batch(client, normal_series, monkeypatch):
    import app.main as mainmod
    monkeypatch.setattr(mainmod, "_fetch", lambda lid, h: {
        "temperature": normal_series["temperature"],
        "motility": normal_series["motility"],
        "activity": normal_series["activity"],
    })
    r = client.post("/ai/health/analyze",
                    json={"tenant_id": 1, "farm_id": 2, "livestock_ids": [10, 11], "window_hours": 24})
    assert r.status_code == 200
    assert len(r.json()["results"]) == 2


def test_analyze_single_handles_missing_data(client, monkeypatch):
    import app.main as mainmod
    monkeypatch.setattr(mainmod, "_fetch", lambda lid, h: {
        "temperature": pd.Series([], dtype=float),
        "motility": pd.Series([], dtype=float),
        "activity": pd.Series([], dtype=float),
    })
    r = client.post("/ai/health/analyze/10", json={"tenant_id": 1, "farm_id": 2, "window_hours": 24})
    # 无数据时返回 normal 兜底，不报 5xx
    assert r.status_code == 200
    assert r.json()["results"][0]["anomaly_score"] == 0.0
```

- [ ] **Step 2: 跑测试确认失败**

Run: `pytest tests/test_main.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: 实现 main.py**

```python
"""orchestration 入口（design §3/§5.2）。FastAPI 端点 → engine → capability。"""
import uuid

import pandas as pd
from fastapi import FastAPI
from fastapi.responses import JSONResponse

from app.capability.base import CapabilityRegistry
from app.capability.health_l1 import HealthAnomalyL1
from app.capability.dl_l2 import DeepLearningL2
from app.capability.llm_l3 import LlmL3
from app.engine import Engine
from app.l1.features import resample_to_slots
from app.schemas import AnalyzeResponse, PredictRequest, PredictResponse
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
    # 空数据兜底（design 实现纪律：按真实数据流程，无数据则返回 normal）
    if all(s.empty for s in series.values()):
        return PredictResponse(
            livestock_id=livestock_id, anomaly_score=0.0, anomaly_type="normal",
            contributions={"stl": 0.0, "cusum": 0.0, "joint": 0.0},
            capability_used="health_l1", n_eff=0, model_meta={"reason": "no_data"},
        )
    slots_df = resample_to_slots(series["temperature"], series["motility"], series["activity"])
    resp = _engine.predict_series(req, slots_df=slots_df, cohort_baselines=[], n_eff=0)
    if resp is None:
        return PredictResponse(
            livestock_id=livestock_id, anomaly_score=0.0, anomaly_type="normal",
            contributions={"stl": 0.0, "cusum": 0.0, "joint": 0.0},
            capability_used="none", n_eff=0, model_meta={"reason": "no_capability"},
        )
    return resp


@app.get("/ai/health/live")
def live():
    return {"status": "ok"}


@app.post("/ai/health/analyze", response_model=AnalyzeResponse)
def analyze_batch(req: PredictRequest):
    results = [_predict_one(req, lid) for lid in req.livestock_ids]
    return AnalyzeResponse(request_id=str(uuid.uuid4()), results=results)


@app.post("/ai/health/analyze/{livestock_id}", response_model=AnalyzeResponse)
def analyze_single(livestock_id: int, req: PredictRequest):
    req.livestock_ids = [livestock_id]
    results = [_predict_one(req, livestock_id)]
    return AnalyzeResponse(request_id=str(uuid.uuid4()), results=results)
```

- [ ] **Step 4: 跑测试确认通过**

Run: `pytest tests/test_main.py -v`
Expected: 4 passed

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/ai-platform/app/main.py smart-livestock-server/ai-platform/tests/test_main.py
git commit -m "feat(ai-platform): FastAPI 端点 orchestration（Task 13）"
```

---

## Task 14: docker-compose 集成 + 合成注入端到端测试

将 ai-platform 加入 `smart-livestock-server/docker-compose.yml`，并加 design §8「合成注入」端到端评估测试（异常序列分数显著高于正常序列）。

**Files:**
- Modify: `smart-livestock-server/docker-compose.yml`
- Create: `smart-livestock-server/ai-platform/tests/test_e2e_synthetic.py`

- [ ] **Step 1: 写端到端合成注入测试**

`tests/test_e2e_synthetic.py`（design §8 合成注入：注入已知异常曲线验证召回）:
```python
"""端到端合成注入评估（design §8）。验证正常/异常序列的分数区分度。

注意（design §8.1）：合成数据上的指标只验证代码路径自洽性，不等于真实数据效果。
真实评估留待 #55 接入后（Plan 2 联调 + Phase B）。
"""
import pytest
from app.capability.base import CapabilityRegistry
from app.capability.health_l1 import HealthAnomalyL1
from app.engine import Engine
from app.schemas import PredictRequest


@pytest.fixture
def engine():
    reg = CapabilityRegistry()
    reg.register(HealthAnomalyL1())
    return Engine(registry=reg)


def _score(engine, series):
    req = PredictRequest(tenant_id=1, farm_id=2, livestock_ids=[1])
    resp = engine.predict_series(req, slots_df=series, cohort_baselines=[])
    return resp.anomaly_score


def test_synthetic_anomaly_scores_higher_than_normal(engine, normal_series, anomaly_series):
    normal_score = _score(engine, normal_series)
    anomaly_score = _score(engine, anomaly_series)
    assert anomaly_score > normal_score
    # 异常注入序列应越过告警阈值的下界（区分度）
    assert anomaly_score > 0.3


def test_score_distribution_self_consistent(engine, rng):
    """design §8 自洽性：多个正常序列分数应集中且偏低。"""
    from tests.conftest import make_triplet_series
    scores = []
    for seed in range(10):
        r = __import__("numpy").random.default_rng(seed)
        s = make_triplet_series(r, days=14, inject_anomaly=False)
        scores.append(_score(engine, s))
    # 正常序列分数均值 < 0.5
    assert sum(scores) / len(scores) < 0.5
```

- [ ] **Step 2: 跑测试确认通过**

Run: `cd smart-livestock-server/ai-platform && pytest tests/test_e2e_synthetic.py -v`
Expected: 2 passed

> 若 `test_synthetic_anomaly_scores_higher_than_normal` 因合成数据区分度不足失败，调整 `conftest.make_triplet_series` 的异常注入幅度（升温幅度/活动降幅）或 `fusion` 权重，**不得在检测代码里针对合成数据加分支**（实现纪律）。

- [ ] **Step 3: 修改 docker-compose.yml，加入 ai-platform 服务**

在 `smart-livestock-server/docker-compose.yml` 的 `services:` 下、`app:` 服务之后追加：

```yaml
  ai-platform:
    build:
      context: ./ai-platform
    ports:
      - "18000:8000"
    environment:
      AI_DB_HOST: postgres
      AI_DB_PORT: 5432
      AI_DB_NAME: smart_livestock
      # Phase A 临时用 postgres 账号；Plan 2 V38 创建只读账号后切换 AI_DB_USER
      AI_DB_USER: ${AI_DB_USER:-postgres}
      AI_DB_PASSWORD: ${AI_DB_PASSWORD:-postgres}
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped
```

同时在 `app:` 服务的 `depends_on:` 下追加 `ai-platform: condition: service_started`（使 Java 端联调时 ai-platform 已起，Plan 2 联调时生效）。

- [ ] **Step 4: 构建镜像并启动（本地 Docker 可用时）**

Run: `cd smart-livestock-server && docker compose build ai-platform && docker compose up -d ai-platform`
Expected: 容器启动

- [ ] **Step 5: 探活验证**

Run: `curl -s http://localhost:18000/ai/health/live`
Expected: `{"status":"ok"}`

> 若本地无 Docker（参照 memory `project-testcontainers-local-docker`），跳过 Step 4/5，在 README 记录部署命令，由部署阶段验证。

- [ ] **Step 6: Commit**

```bash
git add smart-livestock-server/docker-compose.yml smart-livestock-server/ai-platform/tests/test_e2e_synthetic.py
git commit -m "feat(ai-platform): docker-compose 集成 + 合成注入端到端测试（Task 14）"
```

---

## 全量验证

- [ ] **Step 1: 跑全部测试**

Run: `cd smart-livestock-server/ai-platform && pytest -v`
Expected: 全部 passed（约 45 个测试，覆盖 schemas/features/detectors/fusion/router/health_l1/engine/db/main/e2e）

- [ ] **Step 2: 静态检查（无类型检查器依赖，跳过或可选 mypy）**

Run: `python -c "import app.main"` （确认无 import 错误）
Expected: 无输出（成功）

- [ ] **Step 3: 最终 Commit（若有未提交改动）**

```bash
git status
git add -A smart-livestock-server/ai-platform/
git commit -m "chore(ai-platform): Phase A 收尾"
```

---

## Self-Review（计划自检）

**Spec 覆盖（design doc 章节 → Task）：**
- §3 数据流（TelemetryEventConsumer 接入、去抖）→ Plan 2（Java 侧）；Plan 1 提供 `/ai/health/analyze` 端点 → Task 13 ✅
- §4.2 特征工程（基线/STL/10特征/`baseline_temp` 边界）→ Task 4/5 ✅；边界"不回写 baseline_temp"在 Task 4 注释 + README ✅
- §4.3 N_eff 定义 + 路由迟滞 → Task 3（N_eff）+ Task 9（路由迟滞）✅
- §4.4 融合归一化 + 权重 → Task 8 ✅
- §5.1 capability 契约 → Task 9/10 ✅
- §5.2 端点 → Task 13 ✅
- §9.1 数据访问（直连 PG 只读）→ Task 12 ✅；只读账号归 Plan 2 V38（边界已注明）✅
- §8 评估（合成注入/自洽性）→ Task 14 ✅
- §10 前向兼容（L2/L3 占位、model_meta、N_eff router）→ Task 7/9/10 ✅

**类型一致性自检：** `predict_series(req, slots_df, cohort_baselines)` 签名在 health_l1/engine/test_main 一致；`route_by_neff(n_eff, state)` 在 router/test_router 一致；`PredictResponse` 字段（anomaly_score/anomaly_type/contributions/capability_used/n_eff/model_meta）在 schemas/health_l1/test 一致。

**已知简化（非占位符，是 Phase A 有意范围）：**
- CUSUM 手写而非 ruptures（Task 6 说明）。
- iForest 档路由返回但未实现（design §4.3 明确 Phase B 激活），Mahalanobis 档实心。
- `history_max`（CUSUM 归一化）用简化估计（当前值 ×2），真实数据积累后标定（design §4.4 同精神）。

---

## 执行交接

Plan 完成并保存于 `docs/superpowers/plans/2026-06-20-ai-platform-phase-a.md`。两种执行方式：

1. **Subagent-Driven（推荐）** — 每个 Task 派一个新 subagent，任务间评审，快速迭代。
2. **Inline Execution** — 本会话内用 executing-plans 批量执行，检查点评审。

选哪种？
