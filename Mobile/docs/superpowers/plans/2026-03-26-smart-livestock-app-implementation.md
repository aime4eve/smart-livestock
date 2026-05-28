# 智慧畜牧 App 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从零搭建智慧畜牧跨平台应用与后端服务，先交付可上线的 MVP（定位、围栏、告警、轨迹），再逐步扩展健康监测和行为分析能力。  

**Architecture:** 采用 Flutter 前端 + FastAPI 后端 + MQTT 实时推送 + PostgreSQL（业务）+ 时序数据接口抽象（先用 PostgreSQL 表模拟，后续可平滑切换 TDengine）。后端按领域模块拆分（animals/fences/alerts/health/behavior），前端按功能页拆分，围绕统一 DTO 与 API 契约实现。  

**Tech Stack:** Flutter、Dart、FastAPI、Python、PostgreSQL、SQLAlchemy、Alembic、Pytest、MQTT（EMQX/Mosquitto）、Docker Compose

---

## 0. 文件结构（先定边界）

**Create:**
- `mobile_app/pubspec.yaml`
- `mobile_app/lib/main.dart`
- `mobile_app/lib/core/network/api_client.dart`
- `mobile_app/lib/core/models/`（`animal.dart`、`fence.dart`、`alert.dart`）
- `mobile_app/lib/features/dashboard/`
- `mobile_app/lib/features/map/`
- `mobile_app/lib/features/fence/`
- `mobile_app/lib/features/alert/`
- `mobile_app/test/`
- `backend/app/main.py`
- `backend/app/core/config.py`
- `backend/app/core/database.py`
- `backend/app/models/`（`animal.py`、`device.py`、`fence.py`、`alert.py`、`health_record.py`、`behavior.py`）
- `backend/app/schemas/`（同领域 DTO）
- `backend/app/api/routes/`（`animals.py`、`fences.py`、`alerts.py`、`health.py`、`behavior.py`）
- `backend/app/services/`（`alert_engine.py`、`trajectory_service.py`、`health_service.py`、`behavior_service.py`）
- `backend/tests/`
- `backend/alembic/`
- `infra/docker-compose.yml`
- `infra/mosquitto/`
- `.editorconfig`
- `README.md`

**文件职责约束：**
- `models/*` 只负责持久化结构；`schemas/*` 只负责接口契约。
- `api/routes/*` 只做参数校验和调用 service，不写业务规则。
- `services/*` 负责规则、聚合与领域逻辑。
- 前端 `features/*` 每个 feature 独立：页面 + 状态 + API 访问封装。

---

### Task 1: 初始化工程与基础运行环境

**Files:**
- Create: `README.md`
- Create: `.editorconfig`
- Create: `infra/docker-compose.yml`
- Create: `backend/requirements.txt`
- Create: `mobile_app/pubspec.yaml`
- Test: `backend/tests/test_smoke.py`

- [ ] **Step 1: 写失败测试（后端健康检查）**

```python
def test_health_endpoint(client):
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd backend && pytest tests/test_smoke.py::test_health_endpoint -v`  
Expected: FAIL（应用入口或路由不存在）

- [ ] **Step 3: 最小实现使测试通过**

```python
# backend/app/main.py
from fastapi import FastAPI

app = FastAPI(title="Smart Livestock API")

@app.get("/healthz")
def healthz():
    return {"status": "ok"}
```

- [ ] **Step 4: 复测**

Run: `cd backend && pytest tests/test_smoke.py::test_health_endpoint -v`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add README.md .editorconfig infra/docker-compose.yml backend mobile_app
git commit -m "chore: bootstrap smart livestock app workspace"
```

---

### Task 2: 建立核心数据模型与迁移（MVP）

**Files:**
- Create: `backend/app/models/animal.py`
- Create: `backend/app/models/device.py`
- Create: `backend/app/models/fence.py`
- Create: `backend/app/models/alert.py`
- Create: `backend/alembic/versions/0001_init_mvp_tables.py`
- Modify: `backend/app/core/database.py`
- Test: `backend/tests/test_models_mvp.py`

- [ ] **Step 1: 写失败测试（模型建表与关键字段）**

```python
def test_alert_table_has_status_column(inspector):
    cols = [c["name"] for c in inspector.get_columns("alerts")]
    assert "status" in cols
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd backend && pytest tests/test_models_mvp.py::test_alert_table_has_status_column -v`  
Expected: FAIL（表结构未创建）

- [ ] **Step 3: 最小实现（模型 + 迁移）**

```python
# 关键字段对齐规格：alerts.status in [pending, acknowledged, resolved, archived]
```

- [ ] **Step 4: 复测**

Run: `cd backend && pytest tests/test_models_mvp.py -v`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add backend/app/models backend/alembic backend/tests/test_models_mvp.py
git commit -m "feat: add MVP domain models and initial migration"
```

---

### Task 3: 实现牲畜与轨迹查询接口（MVP）

**Files:**
- Create: `backend/app/schemas/animal.py`
- Create: `backend/app/api/routes/animals.py`
- Create: `backend/app/services/trajectory_service.py`
- Modify: `backend/app/main.py`
- Test: `backend/tests/test_animals_api.py`

- [ ] **Step 1: 写失败测试（牲畜列表和实时位置）**

```python
def test_get_animals_returns_list(client):
    resp = client.get("/api/animals")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd backend && pytest tests/test_animals_api.py::test_get_animals_returns_list -v`  
Expected: FAIL（路由不存在）

- [ ] **Step 3: 最小实现（3个端点）**
- `GET /api/animals`
- `GET /api/animals/{id}/location`
- `GET /api/animals/{id}/trajectory`

- [ ] **Step 4: 复测**

Run: `cd backend && pytest tests/test_animals_api.py -v`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add backend/app/api/routes/animals.py backend/app/schemas/animal.py backend/app/services/trajectory_service.py backend/tests/test_animals_api.py
git commit -m "feat: implement animals and trajectory query APIs"
```

---

### Task 4: 实现围栏管理与越界规则引擎（MVP）

**Files:**
- Create: `backend/app/schemas/fence.py`
- Create: `backend/app/api/routes/fences.py`
- Create: `backend/app/services/alert_engine.py`
- Test: `backend/tests/test_fences_api.py`
- Test: `backend/tests/test_fence_alert_rules.py`

- [ ] **Step 1: 写失败测试（围栏 CRUD）**

```python
def test_create_fence(client, auth_headers):
    payload = {"name": "北区围栏", "type": "polygon", "fence_type": "cross", "points": []}
    resp = client.post("/api/fences", json=payload, headers=auth_headers)
    assert resp.status_code == 201
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd backend && pytest tests/test_fences_api.py::test_create_fence -v`  
Expected: FAIL

- [ ] **Step 3: 最小实现（围栏 API + 越界判定）**
- `GET /api/fences`
- `POST /api/fences`
- `PUT /api/fences/{id}`
- `DELETE /api/fences/{id}`
- `alert_engine` 中实现 `check_fence_breach(...)`

- [ ] **Step 4: 复测**

Run: `cd backend && pytest tests/test_fences_api.py tests/test_fence_alert_rules.py -v`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add backend/app/api/routes/fences.py backend/app/services/alert_engine.py backend/tests/test_fences_api.py backend/tests/test_fence_alert_rules.py
git commit -m "feat: add fence management and breach rule engine"
```

---

### Task 5: 实现告警中心接口与状态流转（MVP）

**Files:**
- Create: `backend/app/schemas/alert.py`
- Create: `backend/app/api/routes/alerts.py`
- Test: `backend/tests/test_alerts_api.py`

- [ ] **Step 1: 写失败测试（告警状态流）**

```python
def test_alert_acknowledge_flow(client, seeded_alert_id):
    resp = client.post(f"/api/alerts/{seeded_alert_id}/ack")
    assert resp.status_code == 200
    assert resp.json()["status"] == "acknowledged"
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd backend && pytest tests/test_alerts_api.py::test_alert_acknowledge_flow -v`  
Expected: FAIL

- [ ] **Step 3: 最小实现（4个端点）**
- `GET /api/alerts`
- `GET /api/alerts/{id}`
- `POST /api/alerts/{id}/ack`
- `POST /api/alerts/{id}/resolve`

- [ ] **Step 4: 复测**

Run: `cd backend && pytest tests/test_alerts_api.py -v`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add backend/app/api/routes/alerts.py backend/app/schemas/alert.py backend/tests/test_alerts_api.py
git commit -m "feat: implement alert center APIs and status transitions"
```

---

### Task 6: 接入 MQTT 实时推送（MVP）

**Files:**
- Create: `backend/app/core/mqtt_client.py`
- Modify: `backend/app/services/alert_engine.py`
- Modify: `infra/docker-compose.yml`
- Test: `backend/tests/test_mqtt_publish.py`

- [ ] **Step 1: 写失败测试（触发告警时发布消息）**

```python
def test_publish_alert_event(mqtt_stub, alert_engine):
    alert_engine.emit_alert(...)
    assert mqtt_stub.last_topic.startswith("alerts/")
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd backend && pytest tests/test_mqtt_publish.py::test_publish_alert_event -v`  
Expected: FAIL

- [ ] **Step 3: 最小实现（MQTT publish）**
- 主题：`alerts/{ranch_id}`
- 消息体至少含：`alert_id/type/level/animal_id/created_at`

- [ ] **Step 4: 复测**

Run: `cd backend && pytest tests/test_mqtt_publish.py -v`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add backend/app/core/mqtt_client.py backend/app/services/alert_engine.py infra/docker-compose.yml backend/tests/test_mqtt_publish.py
git commit -m "feat: add mqtt real-time alert publishing"
```

---

### Task 7: Flutter 端 MVP 页面骨架与 API 联调

**Files:**
- Create: `mobile_app/lib/core/models/animal.dart`
- Create: `mobile_app/lib/core/models/fence.dart`
- Create: `mobile_app/lib/core/models/alert.dart`
- Create: `mobile_app/lib/core/network/api_client.dart`
- Create: `mobile_app/lib/features/dashboard/dashboard_page.dart`
- Create: `mobile_app/lib/features/map/map_page.dart`
- Create: `mobile_app/lib/features/fence/fence_page.dart`
- Create: `mobile_app/lib/features/alert/alert_page.dart`
- Modify: `mobile_app/lib/main.dart`
- Test: `mobile_app/test/widget_smoke_test.dart`

- [ ] **Step 1: 写失败测试（底部导航四页存在）**

```dart
testWidgets('shows dashboard map fence alert tabs', (tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('首页'), findsOneWidget);
  expect(find.text('地图'), findsOneWidget);
  expect(find.text('围栏'), findsOneWidget);
  expect(find.text('告警'), findsOneWidget);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/widget_smoke_test.dart`  
Expected: FAIL

- [ ] **Step 3: 最小实现（导航 + 列表渲染）**
- Dashboard: 数量总览卡片
- 地图页: 列表代替地图占位（先保证数据链路）
- 围栏页: 围栏列表 + 新建入口占位
- 告警页: 告警列表 + 状态标签

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib mobile_app/test mobile_app/pubspec.yaml
git commit -m "feat: scaffold flutter MVP pages and API client"
```

---

### Task 8: 历史轨迹与越界告警端到端验收（MVP 收口）

**Files:**
- Modify: `backend/tests/test_animals_api.py`
- Modify: `backend/tests/test_alerts_api.py`
- Modify: `mobile_app/test/widget_smoke_test.dart`
- Create: `docs/qa/mvp-acceptance.md`

- [ ] **Step 1: 写验收用例（对齐规格“9.2 MVP 验收标准”）**
- 实时地图（占位+数据）
- 虚拟围栏 CRUD
- 越界告警生成与处理
- 历史轨迹查询

- [ ] **Step 2: 执行后端测试**

Run: `cd backend && pytest -v`  
Expected: 全部 PASS

- [ ] **Step 3: 执行前端测试**

Run: `cd mobile_app && flutter test`  
Expected: 全部 PASS

- [ ] **Step 4: 手工联调检查**

Run:
`cd infra && docker compose up -d`  
`cd backend && uvicorn app.main:app --reload`  
`cd mobile_app && flutter run`

Expected: 可完成围栏创建、告警列表刷新、轨迹查询

- [ ] **Step 5: 提交**

```bash
git add backend/tests mobile_app/test docs/qa/mvp-acceptance.md
git commit -m "test: add MVP end-to-end acceptance coverage"
```

---

### Task 9: V1.5 健康监测能力

**Files:**
- Create: `backend/app/schemas/health.py`
- Create: `backend/app/api/routes/health.py`
- Create: `backend/app/services/health_service.py`
- Create: `backend/tests/test_health_api.py`
- Create: `mobile_app/lib/features/health/health_page.dart`
- Create: `mobile_app/test/health_page_test.dart`

- [ ] **Step 1: 写失败测试（温度曲线、蠕动、评分、风险预测）**
- [ ] **Step 2: 运行测试并确认失败**

Run: `cd backend && pytest tests/test_health_api.py -v`  
Expected: FAIL

- [ ] **Step 3: 最小实现**
- `GET /api/health/temperature/{animal_id}`
- `GET /api/health/motility/{animal_id}`
- `GET /api/health/score/{animal_id}`
- `GET /api/health/prediction/{animal_id}`

- [ ] **Step 4: 前端健康页接入并测试**

Run: `cd mobile_app && flutter test test/health_page_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add backend/app/api/routes/health.py backend/app/services/health_service.py backend/tests/test_health_api.py mobile_app/lib/features/health/health_page.dart mobile_app/test/health_page_test.dart
git commit -m "feat: add rumen health monitoring module"
```

---

### Task 10: V2.0 行为分析能力

**Files:**
- Create: `backend/app/schemas/behavior.py`
- Create: `backend/app/api/routes/behavior.py`
- Create: `backend/app/services/behavior_service.py`
- Create: `backend/tests/test_behavior_api.py`
- Create: `mobile_app/lib/features/behavior/behavior_page.dart`
- Create: `mobile_app/test/behavior_page_test.dart`

- [ ] **Step 1: 写失败测试（统计/趋势/排名/发情）**
- [ ] **Step 2: 运行测试并确认失败**

Run: `cd backend && pytest tests/test_behavior_api.py -v`  
Expected: FAIL

- [ ] **Step 3: 最小实现**
- `GET /api/behavior/statistics/{animal_id}`
- `GET /api/behavior/trend/{animal_id}`
- `GET /api/behavior/ranking`
- `GET /api/behavior/estrus/{animal_id}`

- [ ] **Step 4: 前端行为页接入并测试**

Run: `cd mobile_app && flutter test test/behavior_page_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add backend/app/api/routes/behavior.py backend/app/services/behavior_service.py backend/tests/test_behavior_api.py mobile_app/lib/features/behavior/behavior_page.dart mobile_app/test/behavior_page_test.dart
git commit -m "feat: add gait behavior analytics module"
```

---

### Task 11: 非功能需求与发布准备

**Files:**
- Create: `backend/tests/test_performance_baseline.py`
- Create: `mobile_app/lib/core/i18n/`
- Create: `mobile_app/l10n.yaml`
- Create: `docs/release/release-checklist.md`
- Modify: `README.md`

- [ ] **Step 1: 写失败测试（关键 API P95 基线）**
- [ ] **Step 2: 运行并确认失败**

Run: `cd backend && pytest tests/test_performance_baseline.py -v`  
Expected: FAIL 或基线未达标

- [ ] **Step 3: 实现最小可行优化**
- 接口分页
- 查询索引
- 缓存短期热点数据（可选）

- [ ] **Step 4: 多语言与安全基线检查**

Run:
`cd mobile_app && flutter gen-l10n`  
`cd backend && pytest -v`

Expected: i18n 资源可生成，测试全部通过

- [ ] **Step 5: 提交**

```bash
git add backend/tests/test_performance_baseline.py mobile_app/lib/core/i18n mobile_app/l10n.yaml docs/release/release-checklist.md README.md
git commit -m "chore: prepare release baseline for performance i18n and security"
```

---

## 验证与里程碑

- **MVP 里程碑**：Task 1-8 完成，满足规格文档中的 `9.2 MVP 验收标准`。
- **V1.5 里程碑**：Task 9 完成，健康监测端到端可用。
- **V2.0 里程碑**：Task 10 完成，行为分析与发情检测可用。
- **发布里程碑**：Task 11 完成，可进入试点牧场上线。

## 执行建议

- 优先采用 **Subagent-Driven**（逐任务派发、每任务后复核）。
- 每个 Task 结束必须执行测试并提交，避免大批量未验证改动。
- 若中途出现架构偏差，先回改本计划再继续执行，保持计划与实现同步。
