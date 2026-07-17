# NIX-20 会话-检验模型重构 — 方案设计文档

| 字段 | 值 |
|---|---|
| 工单 | NIX-20 GPS动态检验工具 |
| 优先级 | High |
| 类型 | 架构重构（Refactor） |
| 前置依赖 | NIX-20 第一版（已实施，会话+检验压平为一张表） |
| 设计日期 | 2026-07-17 |
| 状态 | 待评审 |
| 原型 | `docs/marketing/nix20-session-test-model-prototype.html` |

---

## 1. 重构动机

### 1.1 当前模型的问题

第一版将「会话」和「检验」合并为一张表 `gps_quality_tests`，每行 = 一次检验 + 自带时间窗口。问题：

- 同一设备的完整验收过程（静态A → 运动 → 静态B）无法用一个容器描述
- 要在同一批 GPS 数据上做多种分析（不同 RTK 点、不同路线），必须重复创建多条记录、选同样的时间范围
- 设备的 GPS 数据时间窗口与真值参照选择耦合在一起，语义不清

### 1.2 正确的模型

**会话（Session）= 设备 + 时间范围 = 一段 GPS 数据窗口**

设备的验收流程可能跨多个物理状态（静止 → 运动 → 静止），Session 记录整个过程的起止时间。

**检验（Test）= Session 内的子时间段 + 真值参照**

从 Session 时间轴中切出一段，选择对应的真值基准（静态段配 RTK 点，动态段配路线）做分析。一个 Session 可挂多个 Test。

```
Session (DEV-2024-001, 10:00 → 19:15)
  ├── Test 1: 10:00-10:45, STATIC, RTK 5号点     ← 冷启动静止段
  ├── Test 2: 10:45-12:15, DYNAMIC, 路线X        ← 运动段
  └── Test 3: 12:15-19:15, STATIC, RTK 11号点    ← 静止段
```

### 1.3 计算时机

报告**按需计算，不预存**。用户点查看时实时取 GPS 原始数据 + 跑计算。创建 Test 只写记录，不做计算。

### 1.4 不涉及修正

两个 Calculator（静态/动态）都是纯测量函数，对 GPS 原始数据不做任何坐标变换、多径修正、平滑或插值。拿原始上报坐标与真值坐标做距离差，"GPS 报什么就算什么"。

---

## 2. 数据模型

### 2.1 新表：`gps_quality_sessions`（会话 = 数据窗口）

```sql
CREATE TABLE gps_quality_sessions (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,                   -- null = 进行中
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    note TEXT,                              -- 可选备注（如"第3批验收"）
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_gqs_device ON gps_quality_sessions(device_id);
CREATE INDEX idx_gqs_status ON gps_quality_sessions(status);
CREATE UNIQUE INDEX uq_gqs_device_active
    ON gps_quality_sessions(device_id) WHERE status = 'IN_PROGRESS';
```

状态机：`IN_PROGRESS → COMPLETED | CANCELED`

- IN_PROGRESS：设备正在收集 GPS 数据（endedAt 为 null）
- COMPLETED：验收结束，endedAt 已固定
- CANCELED：废弃

### 2.2 改造：`gps_quality_tests`（检验 = 真值参照选择）

现有 `gps_quality_tests` 表去掉 device_id / started_at / ended_at / status（上移到 Session），改为 session_id FK + 自身的子时段。

迁移后最终结构：
- id, session_id (NOT NULL), test_type, rtk_point_id, route_id,
- test_started_at, test_ended_at, note, created_at, updated_at

保留的字段含义：
- `session_id`：所属会话（必填）
- `test_type`：STATIC / DYNAMIC
- `rtk_point_id` / `route_id`：互斥真值参照（CHECK 约束不变）
- `test_started_at` / `test_ended_at`：Session 时间范围内的子区间

Test 本身没有状态机 — 它只是 Session 内的一个分析记录，创建即完成。

### 2.3 不变的表

- `rtk_reference_points`：33 个真值点，CRUD 不变
- `dynamic_test_routes` + `dynamic_test_route_points`：路线定义不变

---

## 3. 数据迁移策略

### 3.1 迁移脚本 `V20260717100000__session_test_split.sql`

步骤：
1. 创建 `gps_quality_sessions` 表
2. 从 `gps_quality_tests` 提取每行的 (device_id, started_at, ended_at, status) 创建 Session（1:1 映射，用 test.id 作为 session.id）
3. 给 `gps_quality_tests` 加 session_id / test_started_at / test_ended_at 列
4. 回填：每行 test 的 session_id = 自身 id，子时段 = 原来的时间范围
5. 设置 NOT NULL + 同步 sequence
6. 删除已上移到 Session 的列（device_id, started_at, ended_at, status）
7. 添加新索引 idx_gqt_session
8. 添加 session_id ON DELETE CASCADE 外键

### 3.2 兼容性

- `gps_quality_tests` 表名不改（减少 JPA entity 改动量）
- `rtk_calibration_sessions` 旧表继续保留（已在前一次迁移中保留，不删）
- 前端旧版 `/sessions` API 路径保留别名到新 Session 端点（过渡期）

---

## 4. 后端设计

### 4.1 Domain 模型

**新增 `GpsQualitySession` 聚合根**
- id, deviceId, startedAt, endedAt?, status (IN_PROGRESS/COMPLETED/CANCELED), note?, createdAt, updatedAt
- 方法：`end()` (IN_PROGRESS → COMPLETED), `cancel()` (任意非 CANCELED → CANCELED)

**改造 `GpsQualityTest`（去掉 device/time/status，加 session_id）**
- id, sessionId, testType (STATIC/DYNAMIC), rtkPointId?, routeId?, testStartedAt, testEndedAt?, createdAt, updatedAt

### 4.2 API 端点

**Session CRUD（新增）**

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/sessions` | 会话列表（支持 deviceId / status 过滤） |
| POST | `/sessions` | 创建会话（deviceId + startedAt + endedAt?） |
| PATCH | `/sessions/{id}/end` | 结束会话 |
| DELETE | `/sessions/{id}` | 删除/取消会话 |
| GET | `/sessions/{id}` | 会话详情（含 test 列表） |

**Test CRUD（子资源）**

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/sessions/{id}/tests` | 会话下的检验列表 |
| POST | `/sessions/{id}/tests` | 创建检验（子时段 + 类型 + 真值参照） |
| DELETE | `/tests/{id}` | 删除检验 |

**报告（路径从 /sessions/{id}/report 改为 /tests/{id}/report）**

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/tests/{id}/report` | 静态报告（test_type=STATIC） |
| GET | `/tests/{id}/dynamic-report` | 动态报告（test_type=DYNAMIC） |
| GET | `/tests/{id}/trajectory` | GPS 轨迹点 |

**对比（改造）**

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/comparison?rtkPointId=` | 静态对比（按 RTK 点汇总所有 STATIC tests） |
| GET | `/comparison?routeId=` | 动态对比（按路线汇总所有 DYNAMIC tests） |

**不变的端点**

- RTK 点 CRUD：`/rtk-points/*`
- 路线 CRUD：`/dynamic-routes/*`
- 设备列表：`/devices`

### 4.3 Service 层

**新增 `GpsQualitySessionService`**
- create(deviceId, startedAt, endedAt?)
- end(id), cancel(id), findById(id)
- findFiltered(deviceId?, status?, pageable)

**改造 `GpsQualityTestService`（原 RtkCalibrationSessionService）**
- create(sessionId, testType, rtkPointId/routeId, testStartedAt, testEndedAt?)
- findBySessionId(sessionId)
- 不再管理 device / 时间窗口 / status（这些归 Session）

**报告 Service 不变逻辑，只改数据来源**
- `GpsQualityReportService.generate(testId)`：从 test 取 session_id → 取 session 的 deviceId + test 的子时段 → 取 GPS 数据 → 计算
- `DynamicQualityReportService.generate(testId)`：同理

### 4.4 约束

- 创建 Test 时校验：子时段 testStartedAt 必须在所属 Session 的 [startedAt, endedAt] 范围内
- Session 为 IN_PROGRESS 时（endedAt null），仍可创建 Test（分析已采集的数据）
- 删除 Session 时级联删除其下所有 Test（ON DELETE CASCADE）

---

## 5. 前端设计

### 5.1 页面结构（3 Tab）

**Tab 1：检验会话**（主工作流）

左侧：Session 列表
- 每项显示：设备名/代码 + 时间范围 + 状态标签 + 静/动检验数量标签
- 点击选中 → 右侧展示详情

右侧三块面板：
1. **会话概览**：设备信息 + 时间范围 + 数据时间轴（蓝=静止段、黄=运动段，标注时长）
2. **检验列表**：该 Session 下所有 Test 的卡片（类型图标 + 名称 + 子时段 + 等级 badge）
3. **分析报告**：选中 Test 后展示对应的静态/动态报告

操作：
- 创建会话（选设备 + 时间范围）
- 在会话内创建检验（选子时段 + 类型 + 真值参照）
- 结束/删除会话
- 删除检验

**Tab 2：真值参照**（数据管理）

左右双栏：
- 左栏：RTK 点 CRUD（33 个真值点的增删改查，逻辑不变）
- 右栏：动态路线 CRUD（路线定义 + 点位序列展示，逻辑不变）

**Tab 3：质量对比**（跨设备分析）

筛选条 + 对比表：
- 类型切换：静态（按 RTK 点分组）/ 动态（按路线分组）
- 静态对比表：同一 RTK 点下多台设备的 P95/P50/有效点/Jitter
- 动态对比表：同一路线下多台设备的 P95/覆盖率/匹配数/漏过数

### 5.2 前端 Domain 模型

新增 `GpsQualitySession` model：id, deviceId, deviceCode, startedAt, endedAt?, status, note?

`CalibrationSession` 改造为 `GpsQualityTest`：id, sessionId, testType, rtkPointId?, routeId?, testStartedAt, testEndedAt?

### 5.3 i18n

新增约 15 个 key（会话相关：创建会话、会话列表、数据时间轴、子时段等），中英文同步。

---

## 6. 不变的部分

| 组件 | 说明 |
|---|---|
| RTK 点表 + CRUD | `rtk_reference_points` 33 个点，管理逻辑完全不变 |
| 路线表 + CRUD | `dynamic_test_routes` + `dynamic_test_route_points`，完全不变 |
| `GpsQualityCalculator` | 静态计算器，纯函数，输入输出不变 |
| `DynamicQualityCalculator` | 动态计算器，纯函数，输入输出不变 |
| GPS 数据来源 | `gps_logs` 表，按 deviceId + 时间范围查询，不变 |
| 报告计算时机 | 按需计算，不预存 |
| 不涉及修正 | 纯测量，无坐标变换/多径修正/平滑/插值 |

---

## 7. 影响范围

| 层 | 改动量 | 说明 |
|---|---|---|
| **Flyway** | 1 个新迁移 | 创建 sessions 表 + tests 表加列 + 数据迁移 |
| **Domain** | 中 | 新增 Session 聚合根 + Test 改字段 |
| **Repository** | 中 | 新增 Session 仓储 + Test 仓储改查询 |
| **Application** | 中 | 新增 SessionService + TestService 改签名 + 报告 Service 改数据来源 |
| **Interfaces** | 中 | 新增 Session 端点 + Test 端点路径调整 |
| **前端 Domain/Data** | 大 | 新增 Session model/repository/provider + Test model 改造 |
| **前端 Presentation** | 大 | Tab 1 完全重写 + Tab 2/3 从现有代码提取 |
| **i18n** | 小 | ~15 个新 key |

---

## 8. 假设

1. 迁移采用 1:1 映射（当前每行 test = 一个 session），迁移后用户可手动合并同设备的 session
2. Test 没有 IN_PROGRESS 状态 — 创建即完成，它是分析记录不是实时监控
3. Session 可以在 IN_PROGRESS 状态下创建 Test（分析已采集的数据）
4. 旧 `/sessions` API 路径在新端点上线后保留一个迭代的兼容别名
5. 前端不做 Session 时间轴的物理状态自动检测（静止/运动分段由用户在创建 Test 时自行定义）
