# NIX-20 会话-检验模型重构 — 实施计划

| 字段 | 值 |
|---|---|
| 工单 | NIX-20 GPS动态检验工具 |
| spec | `docs/superpowers/specs/2026-07-17-nix20-session-test-model-redesign.md` |
| 原型 | `docs/marketing/nix20-session-test-model-prototype.html` |
| 计划日期 | 2026-07-17 |
| 状态 | 待评审 |

> **硬性约束**：现有质量分析报告展示页面（静态散点图、统计卡片、动态逐点表、等级 badge、轨迹弹窗）在重构后必须继续可用。Calculator 不动，展示组件不动，只改数据来源。

---

## 测试策略

### 保护网

| 层 | 现有测试 | 动作 |
|---|---|---|
| 后端 GpsQualityCalculator（19 用例） | 充分 | 不改，保持绿色 |
| 后端 DynamicQualityCalculator（8 用例） | 充分 | 不改，保持绿色 |
| 后端 GpsQualityJourneyTest（8 用例） | 回归基线 | 改 API 路径适配，行为断言不变 |
| 前端 GPS 质量 | 0 个测试 | 不阻塞（展示组件不变） |

### 每步验证

每个 Task 编译通过后立即提交，后端 Task 末尾 `./gradlew test` 确认 Calculator 测试全绿。

---

## Task 分解

### 阶段一：后端数据层 + 领域模型（Task 1-3）

#### Task 1: Flyway 迁移（拆表）
- 新建 `V20260717100000__session_test_split.sql`
- 创建 `gps_quality_sessions` 表
- `gps_quality_tests` 加 session_id / test_started_at / test_ended_at 列
- 1:1 数据迁移（test.id → session.id，回填 session_id + 子时段）
- 删除 tests 表的 device_id / started_at / ended_at / status 列
- 添加 CASCADE 外键 + 新索引
- **验证**：本地/dev 执行迁移无报错；`SELECT count(*) FROM gps_quality_sessions` = tests 行数

#### Task 2: Domain 模型
- 新增 `GpsQualitySession.java` 聚合根（deviceId, startedAt, endedAt?, status, note?）
- 新增 `SessionStatus` 枚举（IN_PROGRESS / COMPLETED / CANCELED）
- 改造 `GpsQualityTest.java`：去掉 deviceId/startedAt/endedAt/status，加 sessionId/testStartedAt/testEndedAt
- **验证**：`./gradlew compileJava` 通过

#### Task 3: Repository 层
- 新增 `GpsQualitySessionRepository` + `SpringDataGpsQualitySessionRepository` + `GpsQualitySessionJpaEntity`
- 改造 `GpsQualityTestRepository`：查询改为按 sessionId
- 改造 `GpsQualityTestJpaEntity`：去掉旧列映射，加新列
- **验证**：`./gradlew compileJava` 通过

---

### 阶段二：后端应用层 + API（Task 4-6）

#### Task 4: Service 层
- 新增 `GpsQualitySessionService`：create/end/cancel/findById/findFiltered
- 改造 `RtkCalibrationSessionService` → `GpsQualityTestService`：create(sessionId, testType, ...) / findBySessionId
- **验证**：`./gradlew compileJava` 通过

#### Task 5: 报告 Service 改数据来源
- `GpsQualityReportService.generate(testId)`：从 test → session 取 deviceId + test 子时段 → 取 GPS 数据 → 调 Calculator（Calculator 不变）
- `DynamicQualityReportService.generate(testId)`：同理
- `QualityReportDto`：sessionId 字段改名为 testId（前端 model 同步适配）
- **验证**：`./gradlew compileJava` 通过；`./gradlew test` Calculator 测试全绿

#### Task 6: Controller 端点改造
- Session CRUD：GET/POST/PATCH/DELETE `/sessions`
- Test CRUD：GET/POST `/sessions/{id}/tests`，DELETE `/tests/{id}`
- 报告：GET `/tests/{id}/report`，`/tests/{id}/dynamic-report`，`/tests/{id}/trajectory`
- 对比：`/comparison?rtkPointId=` / `?routeId=`
- 改造 GpsQualityJourneyTest 适配新端点路径
- **验证**：`./gradlew test` 全绿

---

### 阶段三：后端编译 + 部署（Task 7）

#### Task 7: 后端编译 + dev 部署
- `./gradlew bootJar -x test` 验证打包
- `./scripts/deploy.sh dev` 部署
- curl 验证：创建 Session → 创建 Test → 生成报告 → 报告字段与重构前一致
- **验证**：curl 确认 Flyway 迁移成功 + `/sessions` + `/sessions/{id}/tests` + `/tests/{id}/report` 可访问

---

### 阶段四：前端适配（Task 8-10）

#### Task 8: 前端 Domain + Data 层
- 新增 `GpsQualitySession` model + `SessionStatus` enum
- 改造 `CalibrationSession` → `GpsQualityTest`（加 sessionId/testStartedAt/testEndedAt）
- 新增 Session repository 方法（fetchSessions/createSession/endSession/deleteSession）
- 改造 Test repository（fetchTestsBySession/createTest/deleteTest + 报告路径 /tests/{id}/report）
- 新增 Session/Test providers
- **验证**：`flutter build web` 通过

#### Task 9: Tab 1 检验会话（主工作流重写）
- 新建 `session_test_tab.dart`：Session 列表 + Session 详情（数据时间轴 + 检验列表 + 报告）
- **复用现有展示组件**：
  - 统计卡片 → 直接复用 quality_report_tab 的 _StatGrid / _StatCard
  - 散点图 → 复用 widgets/scatter_chart.dart
  - 等级 badge → 复用 widgets/quality_grade_badge.dart
  - 轨迹弹窗 → 复用 widgets/session_trajectory_sheet.dart
  - 动态逐点表 → 复用 dynamic_report_tab 的 per-point DataTable
- 创建会话对话框（选设备 + 时间范围）
- 创建检验对话框（选子时段 + 类型 + 真值参照）
- **验证**：`flutter build web` 通过

#### Task 10: Tab 2 真值参照 + Tab 3 质量对比
- Tab 2：从 rtk_calibration_tab.dart 提取 RTK 点 CRUD 部分 + 从 dynamic_report_tab.dart 提取路线 CRUD 部分
- Tab 3：从 quality_report_tab.dart 提取对比表 + 改造查询从 test 级
- gps_quality_page.dart：TabController 3 个 Tab
- i18n：新增 ~15 个 key
- **验证**：`flutter build web` 通过 + `flutter gen-l10n` 无缺失 key

---

### 阶段五：部署 + 集成测试（Task 11）

#### Task 11: 全栈部署 + 集成验证
- 前端 `./build_web.sh` + 后端确认 dev 最新
- **报告展示回归验证**（硬性约束）：
  - 静态报告：散点图渲染正常、统计卡片数值合理、等级 badge 正确
  - 动态报告：逐点表展示正常、覆盖率/匹配数合理
  - 对比表：多设备横向对比数据正确
  - 轨迹弹窗：GPS 轨迹点渲染正常
- **新功能验证**：
  - 创建 Session → 创建多个 Test（静态+动态）→ 切换查看报告
  - Session 时间轴展示
- **验证**：用户确认部署后执行集成测试

---

## 依赖关系

```
Task 1 (迁移) → Task 2 (Domain) → Task 3 (Repository)
                                     │
                    ┌────────────────┘
                    ↓
             Task 4 (Service) → Task 5 (报告改来源) → Task 6 (Controller)
                                                        │
                                    ┌───────────────────┘
                                    ↓
                             Task 7 (后端部署)
                                    │
                    ┌───────────────┘
                    ↓
             Task 8 (前端Data) → Task 9 (Tab1) → Task 10 (Tab2+3)
                                                    │
                                                    ↓
                                             Task 11 (集成测试)
```

---

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| 报告展示组件因数据来源变更而 break | Calculator 不动 + 展示组件只改 provider 引用 |
| 迁移丢数据 | 1:1 映射 + count 对比 + 旧表保留 |
| API 路径变更导致前端 404 | 保留旧 `/sessions` 别名一个迭代 |
| JPA entity 列映射不一致 | 迁移后 `\d gps_quality_tests` 确认列结构 |

---

## 关键不变项（硬性约束核查表）

- [ ] `GpsQualityCalculator` 源文件零改动
- [ ] `DynamicQualityCalculator` 源文件零改动
- [ ] `widgets/scatter_chart.dart` 不改
- [ ] `widgets/quality_grade_badge.dart` 不改
- [ ] `widgets/session_trajectory_sheet.dart` 不改
- [ ] 报告 JSON 结构对前端兼容（字段名可能从 sessionId → testId，前端 model 适配）
- [ ] GPS 数据查询逻辑不变（按 deviceId + 时间范围取 gps_logs）
