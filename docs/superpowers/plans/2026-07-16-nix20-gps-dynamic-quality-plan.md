# NIX-20 GPS 动态检验工具 — 实施计划

| 字段 | 值 |
|---|---|
| 工单 | NIX-20 GPS动态检验工具 |
| spec | `docs/superpowers/specs/2026-07-16-nix20-gps-dynamic-quality-spec.md` |
| 原型 | `docs/marketing/nix20-gps-dynamic-quality-prototype.html` |
| 计划日期 | 2026-07-16 |
| 状态 | 待评审 |

> 设计文档已确认。本计划将 spec 拆解为可独立编译验证的有序 Task，遵循「编码 → 编译验证 → 部署 → 集成测试」流程。

---

## 改造范围盘点

| 层 | 文件 | 改动性质 |
|---|---|---|
| **Flyway** | 新增 1 个迁移 | 新建 3 表 + 旧表数据迁移 |
| **后端 Domain** | `RtkCalibrationSession` → `GpsQualityTest`；新增 `DynamicTestRoute` + `DynamicTestRoutePoint` | 重构（改名+加字段） |
| **后端 Repository** | `RtkCalibrationSessionRepository` → `GpsQualityTestRepository`；新增 2 个 route 仓储 | 重构 + 新增 |
| **后端 Application** | `RtkCalibrationSessionService` → `GpsQualityTestService`；新增 `DynamicTestRouteService` + `DynamicQualityReportService` | 重构 + 新增 |
| **后端 Domain Service** | 新增 `DynamicQualityCalculator`（路线匹配算法） | 新增 |
| **后端 Interfaces** | `GpsQualityAdminController` 加 route/test 端点；新增 `DynamicQualityReportDto` + route DTO | 重构 + 新增 |
| **前端 Domain** | `CalibrationSession` → `GpsQualityTest`；新增 `DynamicRoute` model | 重构 + 新增 |
| **前端 Data** | `gps_quality_api_repository.dart` 加 route/test 端点 | 重构 + 新增 |
| **前端 Presentation** | `rtk_calibration_tab.dart` 改为统一会话列表；`batch_create_session_dialog.dart` 支持 testType；新增 `dynamic_report_tab.dart` | 重构 + 新增 |
| **i18n** | `app_zh.arb` / `app_en.arb` 新增 ~20 个 key | 新增 |

---

## 测试策略（贯穿全程）

> **原则**：对现有功能的修改，必须先有自动化测试钉住行为，再动手改，全程测试保持绿色。

### 现状（保护网缺口）

| 层 | 现有测试 | 缺口 |
|---|---|---|
| 后端 Domain Service | GpsQualityCalculatorTest（19 用例，纯函数） | 充分 |
| 后端 会话 CRUD/Service/Controller | **无** | 统一表迁移零保护网 |
| 后端 集成测试基座 | AbstractJourneyTest（Testcontainers + 登录 helper） | 可复用 |
| 前端 GPS 质量 | **0 个测试** | 会话列表/批量创建零保护网 |

### 测试顺序（TDD for refactor）

1. **阶段零**：先写覆盖现有静态会话行为的集成测试，改造前确认全绿（钉住回归基线）
2. **改造全程**：每个 Task 编译验证必须附带 ./gradlew test 全绿
3. **新增功能**：动态匹配算法单元测试 + 动态报告集成测试，TDD 编写

---

## 实施阶段

### 阶段零：回归测试基线（改造前先钉住现有行为）

**目标**：在动任何代码前，用测试钉住现有静态会话的 CRUD + 报告行为，作为统一表迁移的回归基准。

#### Task 0: 后端静态会话集成测试（回归基线）
- 新增 GpsQualityJourneyTest.java（继承 AbstractJourneyTest）
- 覆盖现有静态会话完整链路：
  - 创建 RTK 点 → 创建静态会话（device + rtkPoint + 时间窗）
  - 结束会话 / 取消会话（状态机）
  - 查询会话列表（过滤）
  - 生成静态报告（验证 mean/p50/p95/jitter 等关键字段非空且合理）
  - 多设备 comparison
  - 一设备仅一个 IN_PROGRESS 的约束
- **验证**：./gradlew test --tests "*GpsQualityJourney*" 全绿（此时测的是旧表/旧 API，确认行为被钉住）
- **作用**：阶段一统一表迁移后，此测试无需改动即可验证"静态行为回归一致"


### 阶段一：后端数据层 + 领域模型（Task 1-3）

**目标**：数据库统一 + 领域模型就位，编译通过。

#### Task 1: Flyway 迁移（统一会话 + 路径实体）
- 新建 `V20260716100000__unify_gps_quality_tests.sql`
- 创建 `dynamic_test_routes` + `dynamic_test_route_points` + `gps_quality_tests` 三张表
- 数据迁移：`rtk_calibration_sessions` → `gps_quality_tests`（test_type=STATIC）
- 保留旧表不删除
- **验证**：本地或 dev 执行迁移无报错；`SELECT count(*) FROM gps_quality_tests` 等于旧表行数

#### Task 2: 后端 Domain 模型统一
- `RtkCalibrationSession.java` → `GpsQualityTest.java`：加 `testType` / `routeId` 字段
- 新增 `DynamicTestRoute.java` + `DynamicTestRoutePoint.java` 领域模型
- 新增 `TestType` 枚举（STATIC / DYNAMIC）
- **验证**：`./gradlew compileJava` 通过

#### Task 3: 后端 Repository 层
- `RtkCalibrationSessionRepository` → `GpsQualityTestRepository`：方法签名适配新模型
- `RtkCalibrationSessionJpaEntity` → `GpsQualityTestJpaEntity`：加 test_type/route_id 列映射
- 新增 `DynamicTestRouteRepository` + `DynamicTestRoutePointRepository` + JPA 实现
- **验证**：`./gradlew compileJava` 通过

---

### 阶段二：后端应用层 + 动态报告算法（Task 4-6）

**目标**：统一 Service + 动态匹配算法 + 报告组装，编译通过。

#### Task 4: 后端 Service 层统一 + 路径管理
- `RtkCalibrationSessionService` → `GpsQualityTestService`：CRUD 适配 testType
- 新增 `DynamicTestRouteService`：路径 CRUD + 点位序列整体替换
- **验证**：`./gradlew compileJava` 通过

#### Task 5: 动态匹配领域服务
- 新增 `DynamicQualityCalculator.java`（纯函数，无 IO）
- 实现：路线驱动匹配（逐 route point 找最近 GPS 点）、歧义检测（ambiguity ratio）、覆盖率/inOrder 合规性
- 复用 `GpsQualityCalculator` 的 haversine / percentile 工具
- **验证**：`./gradlew compileJava` 通过；为匹配算法写单元测试

#### Task 6: 动态报告组装 + 报告端点
- 新增 `DynamicQualityReportService`：组装 session→route→routePoints→gpsLogs→calculator→DTO
- `GpsQualityAdminController` 改造：
  - `/sessions/*` → `/tests/*`（加 testType 参数）
  - 新增 `/dynamic-routes/*` CRUD + `/dynamic-routes/{id}/points` 序列管理
  - 新增 `/tests/batch` 批量创建（混合 STATIC/DYNAMIC）
  - 报告端点按 test_type 分发静态/动态
- 新增 `DynamicQualityReportDto` + route 相关 DTO
- 新增 DynamicQualityJourneyTest.java：动态报告集成测试（创建路径→创建动态测试→生成报告→验证覆盖率/误差/inOrder）
- **验证**：./gradlew test 全绿（含 Task 0 回归 + Task 5 单元 + Task 6 动态集成）

---

### 阶段三：后端编译 + 部署（Task 7）

#### Task 7: 后端全量编译 + dev 部署
- `./gradlew bootJar -x test` 验证可打包
- `./scripts/deploy.sh dev` 部署到 dev 环境
- **验证**：curl 验证 Flyway 迁移成功 + `/tests` 端点可访问 + 旧 `/sessions` 兼容别名正常

---

### 阶段四：前端适配（Task 8-10）

**目标**：前端适配统一模型 + 动态报告 Tab，编译通过。

#### Task 8: 前端 Domain + Data 层
- `CalibrationSession` → `GpsQualityTest`（加 testType/routeId）
- 新增 `DynamicRoute` / `DynamicRoutePoint` model
- `gps_quality_api_repository.dart`：`/sessions/*` → `/tests/*`，新增 route 端点调用
- `BatchSessionRequest` → `BatchTestRequest`（支持 testType）
- **验证**：`flutter build web` 通过

#### Task 9: 统一会话列表 + 批量创建改造
- `rtk_calibration_tab.dart`：会话列表展示 STATIC + DYNAMIC（类型图标/标签）
- `batch_create_session_dialog.dart`：每行加 testType 选择（STATIC→RTK点下拉 / DYNAMIC→路线下拉）
- Excel 模板增加 testType 列
- 新增 batch_create_test.dart widget 测试：验证 STATIC/DYNAMIC 行切换、校验逻辑
- **验证**：./gradlew test 全绿（后端回归保持）+ flutter build web 通过

#### Task 10: 动态检验报告 Tab（新增）
- 新增 `dynamic_report_tab.dart`：召回概览 + 散点图 + 逐点表 + 静态/动态对比 + 轨迹地图
- `gps_quality_page.dart`：TabController length 2→3，Tab 2 重命名「静态分析」，新增 Tab 3「动态检验」
- i18n：新增 ~20 个 key（中英文同步）
- 新增 dynamic_report_test.dart widget 测试：报告卡片渲染、散点图、逐点表
- **验证**：flutter build web 通过 + flutter gen-l10n 无缺失 key + flutter test 全绿

---

### 阶段五：部署 + 集成测试（Task 11）

#### Task 11: 全栈部署 + 集成验证
- 前端 `./build_web.sh` + 后端确认 dev 部署最新
- curl 验证：
  - 创建路径 + 点位序列
  - 创建 DYNAMIC 测试 → 生成动态报告
  - 批量创建（混合 STATIC/DYNAMIC）
  - 静态报告回归一致
- **验证**：用户确认部署后执行集成测试

---

## 依赖关系

```
Task 0 (回归基线) ── 钉住静态行为，全程保持绿色
       │
       ↓
Task 1 (迁移) ──→ Task 2 (Domain) ──→ Task 3 (Repository)
                                          │
                     ┌────────────────────┘
                     ↓
              Task 4 (Service) ──→ Task 5 (匹配算法) ──→ Task 6 (报告+端点)
                                                              │
                                          ┌───────────────────┘
                                          ↓
                                   Task 7 (后端部署)
                                          │
                     ┌────────────────────┘
                     ↓
              Task 8 (前端Data) ──→ Task 9 (会话列表) ──→ Task 10 (动态Tab)
                                                              │
                                                              ↓
                                                       Task 11 (集成测试)
```

- **Task 0 是所有改造的前提**：先钉住静态行为，再动表结构
- 后端（Task 1-7）必须先完成并部署，前端才能对接真实 API
- 前端 Task 8-10 可在 Task 7 部署后并行开发
- 每个阶段有独立编译验证，可单独提交

---

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| 旧表迁移丢数据 | 迁移后 `SELECT count(*)` 对比 + 保留旧表不删 |
| 静态报告回归不一致 | 静态计算逻辑/阈值完全不动，只改表名映射 |
| 前端 API 路径切换导致 404 | 保留 `/sessions` 兼容别名，前端切完后下迭代移除 |
| 批量创建 Excel 兼容性 | testType 列设为可选，默认 STATIC（向后兼容旧模板） |
