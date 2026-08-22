# 仿真控制管理界面实施计划

> 日期：2026-08-17
> 状态：已实施并合入 master（`f879ab3c` 主功能，`dddf1499` 清理修复；下方 checkbox 未逐项回填，以迁移/代码/测试/提交为准）
> spec：`docs/superpowers/specs/2026-08-17-datagen-admin-console-design.md`（已按评审修订并确认）
> 原型：`docs/marketing/datagen-console-prototype.html`（已确认）
> REQUIRED SKILL：`/Users/hkt/.codex/skills/prototype-to-flutter-fidelity/SKILL.md`
> 视觉对比依赖：`Pillow`（`compare_screenshots.py` 需要）；对比命令见 Task 0 / Task 10.7

## 目标

为 `PLATFORM_ADMIN` 与 `B2B_ADMIN` 提供统一的仿真控制台：

1. 按牧场启停仿真
2. 手工指定 TRACKER / CAPSULE 设备范围
3. 预览并清理 DATAGEN 原始数据及可追踪派生数据
4. B2B 管理员严格限定本租户牧场
5. 旧全局 datagen 端点收紧为 `PLATFORM_ADMIN`
6. 保留真实来源数据与无法安全归属的历史数据

## 前置约束

- 工作区已有 subscription/commerce/API 文档未提交改动，本任务不得纳入提交。
- 每个后端任务先补失败测试，再实现。
- 所有面向用户文案必须走 i18n。
- 清理功能是不可逆操作，必须先停止、再预览、输入确认词、后端事务删除并写审计。
- 集成测试只能在部署 test 后执行。
- 首版清理归属按 device 的历史 assignment 维度执行；`device_telemetry_logs` / `gps_logs` 没有 farm 字段，设备跨 farm 迁移后的 DATAGEN 行可能随任一历史归属 farm 的清理被删除。此限制只影响 DATAGEN 数据，不影响真实来源数据，需在 UI 与交付说明中明示。

---

## Task 0 — 视觉保真准备

- [ ] 从已确认原型截取并归档基准图：
  - `docs/marketing/datagen-console-prototype/status.png`
  - `docs/marketing/datagen-console-prototype/devices.png`
  - `docs/marketing/datagen-console-prototype/clear.png`
  - `docs/marketing/datagen-console-prototype/operations.png`
  - `docs/marketing/datagen-console-prototype/clear-dialog.png`
  - `docs/marketing/datagen-console-prototype/narrow.png`
- [ ] 运行 prototype token 提取脚本，生成设计令牌核对表：

```bash
python3 /Users/hkt/.codex/skills/prototype-to-flutter-fidelity/scripts/extract_design_tokens.py \
  docs/marketing/datagen-console-prototype.html \
  --out docs/design-tokens-datagen.md
```

- [ ] 基准截图统一使用 desktop viewport `1440x1000`（narrow 另用 `390x1000`）。
- [ ] 为桌面截图创建 custom regions JSON，避免 `compare_screenshots.py` 默认手机分区误导：
  - `docs/marketing/datagen-console-prototype/regions-console.json`
  - 建议 regions：`topbar 0.00-0.07`、`filters 0.07-0.15`、`tabs 0.15-0.22`、`content 0.22-0.95`
- [ ] 确认 Pillow 可用：

```bash
python3 -c "from PIL import Image; print('Pillow OK')"
```
- [ ] 核对并登记 Flutter 侧需要新增的 token：
  - `surfaceMuted #F2F0EA`
  - `successStrong #2F7D44` / `successSoft #E4F3E8`
  - `warningStrong #B36A16` / `warningSoft #FFF2DE`
  - `dangerStrong #B3352C` / `dangerSoft #FBE8E6`
  - `infoStrong #315F79` / `infoSoft #E7F1F6`
- [ ] 登记既有偏差：
  - 管理侧栏 `_IconSidebarItem` 选中色当前为系统蓝，全侧栏一致，本任务不单独改色。
  - 原型是桌面管理台布局；Flutter 实现需在 tablet/desktop 宽度下对齐原型，窄屏按 spec 响应式降级。

**验证**：基准截图存在、非空、能作为 Playwright 对比输入；token 表与 spec §6.5 一致。

---

## Task 1 — Flyway：控制表、来源列、审计列与初始化

### 1.1 新增迁移

建议文件：

`V20260817160000__datagen_admin_console.sql`

- [ ] 新增 `datagen_farm_controls`：
  - `id`
  - `tenant_id`
  - `farm_id`
  - `scenario_id`
  - `enabled`
  - `created_at`
  - `updated_at`
  - `UNIQUE(farm_id)`
- [ ] 新增 `datagen_device_assignments`：
  - `id`
  - `control_id`
  - `device_id`
  - `first_assigned_at`
  - `created_at`
  - `removed_at`
  - `UNIQUE(control_id, device_id)`
  - `INDEX(control_id)`
  - 部分唯一索引： active assignment 每设备最多一条
- [ ] 新增控制表索引：
  - `(tenant_id, farm_id)`
  - `(scenario_id)`
- [ ] `audit_logs` 增加：
  - `farm_id BIGINT`
  - `operator_role VARCHAR(20)`
  - `INDEX(farm_id, occurred_at DESC)`
- [ ] `temperature_logs`、`rumen_motility_logs`、`activity_logs` 增加：
  - `source VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN'`
  - 各自独立 CHECK，允许 `AGENTIC_PLATFORM/DATAGEN/HTTP/MANUAL_IMPORT/UNKNOWN`
- [ ] `estrus_scores`、`anomaly_scores` 增加 same source 列与 CHECK。
- [ ] 重建 alerts source CHECK：

```sql
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_source;
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_source
    CHECK (source IN ('RULE', 'AI', 'DATAGEN'));
```

### 1.2 初始化

- [ ] 幂等确保名称为 `默认持续合成` 的 `NORMAL` scenario 存在。
- [ ] 若该 scenario 不是 `RUNNING`，置为 `RUNNING`。
- [ ] 若 `window_end <= NOW()`，更新为 `NOW() + INTERVAL '365 days'`。
- [ ] 为所有 farm 创建 control，`enabled=false`。
- [ ] 从 installations 历史回填 assignment：
  - 当前有效安装且满足 D6 → `removed_at=NULL`
  - 已移除安装 → `removed_at=installations.removed_at`
  - 同一 farm/device 多条安装记录合并为一条 assignment：
    - `first_assigned_at=min(installed_at)`
    - `removed_at=coalesce(max(removed_at), null)`
  - 通过 livestock 解析 farm 归属
- [ ] 存量 DATAGEN 健康数据因新增列默认保持 `UNKNOWN`，不做猜测性回填。

**验证**

- [ ] 本地或 test Flyway migration 成功。
- [ ] `\\d` 核查所有列、约束、索引存在。
- [ ] `SELECT type, count(*) FILTER (WHERE message_key IS NULL)` 无关检查不回归。
- [ ] 所有 farm control `enabled=false`。
- [ ] active assignment 覆盖当前有效 TRACKER/CAPSULE。
- [ ] 历史 removed installation 生成带 `removed_at` 的 assignment。

---

## Task 2 — 后端模型与 Repository

### 2.1 领域模型

- [ ] `datagen/domain/model/DatagenFarmControl.java`
- [ ] `datagen/domain/model/DatagenDeviceAssignment.java`
- [ ] 状态语义：
  - control.enabled
  - assignment.active = `removed_at == null`

### 2.2 JPA Entity + Mapper + Repository

- [ ] `DatagenFarmControlJpaEntity`
- [ ] `DatagenDeviceAssignmentJpaEntity`
- [ ] Mapper 双向转换
- [ ] Repository 方法：
  - `findByFarmId`
  - `findByTenantId`
  - `findAll`
  - `save`
  - active assignments by scenario
  - all historical assignments by farm
  - active assignment count by farm
- [ ] `DeviceQueryPort` 新增：

```java
List<ActiveInstallationInfo> findActiveInstallationsByScenario(Long scenarioId);
```

查询必须从：

```text
RUNNING scenario
→ enabled farm control
→ active assignment
→ valid device
→ active installation
→ livestock
```

### 2.3 测试

- [ ] Repository SQL/mapper 单测或集成测试：
  - enabled farm 才参与
  - active assignment 才参与
  - 软删设备排除
  - 非 ACTIVE 设备排除
  - 无 active installation 排除
  - 解绑设备历史 assignment 保留

**验证**：`./gradlew test --tests "*Datagen*"` 通过。

---

## Task 3 — 权限收紧与控制台权限模型

### 3.1 旧端点收紧

- [ ] `DataGenAdminController` 每个方法加：

```java
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
```

覆盖：

- create scenario
- list scenarios
- start scenario
- stop scenario
- labels
- evaluation

### 3.2 操作者与租户上下文

- [ ] 新增 `DatagenOperatorContext`：
  - userId
  - tenantId
  - role
- [ ] 从 SecurityContext 与 TenantContext 解析。
- [ ] 若必要信息缺失，返回认证/租户错误。

### 3.3 farm 访问校验

- [ ] `PLATFORM_ADMIN` 可访问任意 farm。
- [ ] `B2B_ADMIN` 只能访问 `farm.tenantId == 当前 tenantId`。
- [ ] 其他角色 403。
- [ ] farm 不存在返回 404。

### 3.4 测试

- [ ] owner 调旧端点 403
- [ ] worker 调旧端点 403
- [ ] B2B_ADMIN 调旧端点 403
- [ ] PLATFORM_ADMIN 调旧端点 200
- [ ] B2B_ADMIN 访问本租户新端点 200
- [ ] B2B_ADMIN 访问跨租户 farm 403

**验证**：`./gradlew test --tests "*DataGen*"` 与 security 相关测试通过。

---

## Task 4 — 控制配置服务与审计写侧

### 4.1 DatagenControlService

新增方法：

```java
DatagenConsoleData getConsole(Long farmId, DatagenOperatorContext operator);
DatagenFarmSummaryList listFarms(DatagenOperatorContext operator);
DatagenControlResponse updateControl(
        Long farmId,
        boolean enabled,
        List<Long> deviceIds,
        DatagenOperatorContext operator);
```

- [ ] 读取 farm、control、scenario、devices、stats、operations。
- [ ] 保存前复验每个 device：
  - 属于目标 farm
  - `status=ACTIVE`
  - 未软删
  - 有 active installation
  - `TRACKER/CAPSULE`
- [ ] `enabled=true` 且设备为空 → `VALIDATION_ERROR`。
- [ ] control 行不存在时执行 upsert：
  - 校验 farm 存在且当前角色可访问
  - 先按 `farm_id` 幂等插入 control（`ON CONFLICT DO NOTHING`），tenant/farm 取目标 farm
  - scenario 指向默认 `NORMAL`
  - 再锁定该行并执行本次配置保存
  - 覆盖迁移后新建 farm 尚无 control 的场景
- [ ] 全量替换 active assignment：
  - 新增缺失 active assignment
  - 保留既有行
  - 未选择设备写 `removed_at=NOW()`
  - 重新选择历史设备时清空 `removed_at`
- [ ] 启用前幂等确保默认 scenario `RUNNING` 且窗口未过期。
- [ ] 启用 farm 时调用 `SynthesisService.clearDeviceSchedules(deviceIds)`，清除相关设备 `nextDueByDevice`，保证重新启用后的下一个调度 tick 可立即产数。
- [ ] 停止 farm 只写 `enabled=false`，不改全局 scenario。
- [ ] 保存 control 与 assignment 在同一事务。
- [ ] 事务内先确保 control 行存在，再 `SELECT ... FOR UPDATE` 锁定该行，最后更新 enabled / assignments；与清理操作互斥，避免并发 upsert 竞态。

### 4.2 DatagenAuditService

- [ ] 事务内写 `audit_logs`。
- [ ] 记录：
  - tenantId
  - farmId
  - userId
  - operatorRole
  - action
  - details
  - occurredAt
- [ ] action 值：
  - `START`
  - `STOP`
  - `UPDATE_DEVICES`
  - `CLEAR_DATA`
- [ ] 事务回滚时审计同时回滚。
- [ ] 同步扩展 Identity Audit 代码链：
  - `AuditLog` domain 增加 `farmId/operatorRole`
  - `AuditLogJpaEntity` 增加对应列
  - `AuditLogMapper` 双向映射
  - `AuditLogRepository` 增加 `findByFarmIdOrderByOccurredAtDesc(farmId, limit)`
  - `AuditLogController` 读回兼容新增字段

### 4.3 测试

- [ ] 空设备启用被拒绝
- [ ] 非法设备整批拒绝且不改已有选择
- [ ] 移出设备保留历史 assignment
- [ ] 重新加入复用历史 assignment
- [ ] B2B 跨租户拒绝
- [ ] 启用时 scenario 被修复为 RUNNING
- [ ] 停止时 scenario 不变
- [ ] 每次 action 均写 audit log
- [ ] 新建 farm 首次保存控制配置成功
- [ ] 并发 updateControl 与 clear 通过 farm control 行锁互斥
- [ ] `getConsole.operations` 按 farm 过滤、按时间倒序，且包含 `operatorId/operatorRole/action/summary`

**验证**：相关 Service 测试通过；`compileJava` 通过。

---

## Task 5 — SynthesisService 接入设备范围

- [ ] `SynthesisService.generate()` 改为通过 `findActiveInstallationsByScenario(scenarioId)` 获取设备。
- [ ] 新增 `clearDeviceSchedules(Collection<Long> deviceIds)`：
  - 从 `nextDueByDevice` 移除指定设备
  - 供控制台启用 farm 后调用
  - 不清除 `SynthesisState`，避免破坏连续运动和健康事件状态
- [ ] 保持现有 per-device interval：
  - TRACKER 5 分钟
  - CAPSULE 15 分钟
- [ ] 保持现有仿真行为：
  - 连续移动
  - 围栏外出事件
  - 健康事件
  - source=DATAGEN
- [ ] 不再隐式扫描全部 active installations 生成控制台场景数据。
- [ ] 保留旧 `findActiveInstallations()` 方法仅用于兼容测试/评估，不作为控制台路径。

### 测试

- [ ] farm disabled → 不生成
- [ ] farm enabled + active devices → 只生成指定设备
- [ ] 设备移出 → 下一 tick 不生成，历史 assignment 保留
- [ ] 同一 livestock 的 TRACKER + CAPSULE 都可生成
- [ ] 只生成 source=DATAGEN

**验证**：`./gradlew test --tests "*Synthesis*"` 通过。

---

## Task 6 — source 穿透与派生数据标记

### 6.1 Telemetry 事件

- [ ] `TelemetryReceivedEvent` 增加 `source`。
- [ ] `TelemetryIngestionService` 发布事件时传入 `TelemetrySource`。
- [ ] 兼容在途消息：consumer 缺 source 时按 `UNKNOWN` 处理。
  - 不把缺 source 的 DATAGEN 派生行误标为 `AGENTIC_PLATFORM`
  - `UNKNOWN` 会进入 `unattributableHealthRows`，保持“不猜测来源”的保守原则

### 6.2 Health 时序

- [ ] domain/JPA/entity/mapper 增加 source：
  - `TemperatureLog`
  - `RumenMotilityLog`
  - `ActivityLog`
- [ ] `TelemetryEventConsumer` 解析 source。
- [ ] `HealthApplicationService.processTelemetry` 增加 source 参数。
- [ ] 三类 health log 写入 source。

### 6.3 estrus / anomaly

- [ ] `EstrusScore` 增加 source 并从 telemetry source 继承。
- [ ] `AnomalyScore` 增加 source。
- [ ] `HealthAnomalyService.assess` 接口预留 telemetry source；当前禁用调用不强行启用。

### 6.4 alerts

- [ ] 围栏告警创建时：
  - `GpsLogUpdatedEvent.source=DATAGEN` → `alerts.source=DATAGEN`
  - 其他来源 → `RULE` 或既有逻辑
- [ ] 健康告警按 telemetry source 映射。

### 6.5 测试

- [ ] DATAGEN telemetry → 三类 health source=DATAGEN
- [ ] HTTP / MANUAL_IMPORT / AGENTIC_PLATFORM source 保留
- [ ] 缺 source 的旧消息 → UNKNOWN
- [ ] DATAGEN GPS → alert source=DATAGEN
- [ ] 真实 GPS → alert source=RULE
- [ ] estrus score source 继承正确

**验证**：`./gradlew test --tests "*Telemetry*" --tests "*Health*" --tests "*GpsLogEventConsumer*"` 通过。

---

## Task 7 — 清理服务

### 7.1 归属解析

- [ ] 按目标 farm 的全部历史 assignment 取得 device set。
- [ ] device → livestock set 用于 estrus/anomaly/alert。
- [ ] 不依赖当前 active installation。
- [ ] 显式接受首版限制：
  - `device_telemetry_logs` / `gps_logs` 无 farm 字段，清理按 device + source + 时间范围执行
  - 设备跨 farm 迁移后，其 DATAGEN 行可能随任一历史归属 farm 的清理被删除
  - 仅影响 DATAGEN，不影响真实来源数据
  - preview / clear 响应与 UI 交付说明必须提示该限制

### 7.2 range 解析

支持：

- `LAST_24_HOURS`
- `LAST_7_DAYS`
- `ALL`
- `CUSTOM`

- [ ] `CUSTOM` 必须有 `from/to` 且 `from < to`。
- [ ] 统一使用 Instant 查询数据库 timestamp 原值，不做本地时区换算。

### 7.3 preview

统计范围内 `source=DATAGEN`：

- device_telemetry_logs
- gps_logs
- temperature_logs
- rumen_motility_logs
- activity_logs
- estrus_scores
- anomaly_scores
- alerts

同时统计：

- `unattributableHealthRows = source UNKNOWN`
- `unattributableAlertRows = source RULE`

### 7.4 clear

- [ ] 前置校验 control `enabled=false`，否则 `STATE_CONFLICT`。
- [ ] confirmText 必须等于 `清空`。
- [ ] 事务内按同样条件删除。
- [ ] 返回实际删除量。
- [ ] 写审计。
- [ ] 不删除：
  - health snapshots
  - device runtime snapshot
  - UNKNOWN health rows
  - RULE historical fence alerts
  - AGENTIC_PLATFORM / HTTP / MANUAL_IMPORT
  - gps_quality_track_points
  - contact_traces
  - ground_truth_labels

### 7.5 并发控制

- [ ] 锁定 farm control 行后再清理。
- [ ] 清理期间禁止同 farm control 更新。
- [ ] 清理前再次检查 enabled。

### 7.6 测试

- [ ] running 拒绝清理
- [ ] confirmText 错误拒绝
- [ ] 只删 DATAGEN
- [ ] 保留 UNKNOWN / RULE / HTTP / MANUAL_IMPORT / AGENTIC_PLATFORM
- [ ] 已解绑设备历史 DATAGEN 可删
- [ ] estrus/anomaly 只删 DATAGEN
- [ ] 质检快照保留
- [ ] 事务失败整体回滚
- [ ] 审计写入成功

**验证**：`./gradlew test --tests "*DatagenClear*"` 通过。

---

## Task 8 — 控制台 API Controller + DTO + i18n

### 8.1 Controller

新增 `DataGenConsoleController`：

```java
@RequestMapping("/api/v1/admin/datagen")
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')")
```

端点：

- `GET /farms`
- `GET /console?farmId=`
- `PUT /control/{farmId}`
- `POST /clear/preview`
- `POST /clear`

统一返回 `ApiResponse`。

### 8.2 DTO

- Farm summary
- Console data
- Device row
- Stats
- Operation
- Control request/response
- Clear preview request/response
- Clear request/response

Clear preview response 必须逐字段对齐 spec：

- `telemetryRows`
- `gpsRows`
- `temperatureRows`
- `motilityRows`
- `activityRows`
- `estrusRows`
- `anomalyRows`
- `alertRows`
- `unattributableHealthRows`
- `unattributableAlertRows`

Clear response 必须包含实际删除量：

- `telemetryRows`
- `gpsRows`
- `temperatureRows`
- `motilityRows`
- `activityRows`
- `estrusRows`
- `anomalyRows`
- `alertRows`

### 8.3 i18n

`messages_zh/en.properties` 同步：

- `error.datagen.farmNotFound`
- `error.datagen.farmForbidden`
- `error.datagen.devicesRequired`
- `error.datagen.deviceInvalid`
- `error.datagen.runningCannotClear`
- `error.datagen.confirmTextMismatch`
- `error.datagen.invalidTimeRange`

### 8.4 测试

- [ ] API contract serialization
- [ ] role authorization
- [ ] tenant/farm authorization
- [ ] validation errors resolve via MessageSource

**验证**：`./gradlew compileJava compileTestJava` 与相关 tests 通过。

---

## Task 9 — 前端模型、API repository、路由与入口

### 9.1 目录

```text
lib/features/admin/datagen/
├── data/datagen_api_repository.dart
├── domain/datagen_models.dart
└── presentation/
    ├── datagen_controller.dart
    └── datagen_console_page.dart
```

### 9.2 model/repository

- [ ] 手写 fromJson/toJson，不用代码生成。
- [ ] repository 方法：
  - loadFarms
  - loadConsole
  - updateControl
  - previewClear
  - clear
- [ ] 错误透传 ApiException / ServerException，不在 repository 层吞异常。

### 9.3 route

- [ ] `AppRoute.platformDatagen('/admin/datagen', 'platform-datagen', '仿真控制')`
- [ ] `app_router.dart` 注册页面
- [ ] B2B admin route whitelist 增加 `/admin/datagen`
- [ ] platform admin 已由 `/admin/**` 覆盖
- [ ] owner/worker 不可达

### 9.4 sidebar

- [ ] `_PlatformAdminShell`：遥测导入后新增仿真控制
- [ ] `_B2bAdminShell`：瓦片管理前新增仿真控制
- [ ] icon 使用 `Icons.model_training_outlined` 或最贴近的 Material 图标

### 9.5 controller

- [ ] 不继承 `FarmScopedNotifier/FarmScopedAsyncNotifier`
- [ ] 显式 selectedFarmId 状态
- [ ] 加载 farms 后默认选第一个 farm
- [ ] farm 切换重新加载 console
- [ ] 保存设备选择后刷新 console
- [ ] 启停期间防重复提交
- [ ] 清理后用 delete 实际结果刷新 UI

### 9.6 i18n

- [ ] `app_zh.arb` / `app_en.arb` 同步 `datagenConsole*`
- [ ] 覆盖页面标题、tab、指标、按钮、状态、确认、错误、操作记录
- [ ] 必须包含跨 farm 清理限制说明 key（如 `datagenConsoleCrossFarmLimit`），中英文语义一致

**验证**

```bash
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter gen-l10n
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
```

---

## Task 10 — 前端控制台页面实现

### 10.1 布局

- [ ] 顶部标题 + 环境/scenario 副标题 + 状态胶囊 + Switch
- [ ] 筛选区：tenant、farm、device type、search
- [ ] 四段 tab：
  - 运行状态
  - 设备范围
  - 数据清理
  - 操作记录

### 10.2 运行状态

- [ ] 四个指标卡
- [ ] 当前规则摘要表
- [ ] statsTimeZone 显示为 Asia/Shanghai
- [ ] “下一批数据”按设备类型与最近生成时间推导

### 10.3 设备范围

- [ ] DataTable / paginated table
- [ ] 列：
  - checkbox
  - 设备编号/EUI
  - 类型
  - 绑定牲畜
  - 运行状态
  - 仿真频率
  - 最近生成
- [ ] eligible=false 行禁选并显示原因
- [ ] 批量选择/清空
- [ ] 本地筛选即时生效
- [ ] 保存调用 updateControl

### 10.4 数据清理

- [ ] range segmented control
- [ ] custom date/time inputs
- [ ] preview 删除量与 unattributable 计数
- [ ] preview 与确认 dialog 展示跨 farm 设备归属限制：
  - “清理按设备历史归属执行；设备迁移过牧场时，其仿真数据可能随任一归属牧场一起清理”
  - “仅清理仿真数据，不会删除真实设备数据”
- [ ] running 状态禁用清理
- [ ] 二次确认 dialog 输入“清空”
- [ ] delete 成功展示实际删除量

### 10.5 操作记录

- [ ] 时间、action、摘要、角色 tag
- [ ] 默认显示 10 条
- [ ] 支持刷新

### 10.6 状态与错误

- [ ] loading skeleton
- [ ] empty state
- [ ] error state + retry
- [ ] SnackBar 展示 i18n 错误
- [ ] 所有异步按钮有 in-progress disabled 状态

### 10.7 视觉保真验证

- [ ] tablet/desktop 截图对照原型 4 个 tab
- [ ] narrow 视口检查无文字溢出/重叠
- [ ] 对照 Task 0 token 表检查颜色、间距、圆角
- [ ] 对每个 tab 运行自动像素对比并保存报告。命令模板：

```bash
python3 /Users/hkt/.codex/skills/prototype-to-flutter-fidelity/scripts/compare_screenshots.py \
  docs/marketing/datagen-console-prototype/status.png \
  build/web-screenshots/status.png \
  --target-width 1440 \
  --regions docs/marketing/datagen-console-prototype/regions-console.json \
  --out build/web-screenshots/status-fidelity.txt
```

- [ ] narrow 截图另用 `--target-width 390` 与自定义 mobile regions，不与 desktop 基线混用。
- [ ] 人工复核报告外再检查文字语义、图标隐喻和可交互状态；像素对比不能替代语义检查。

**验证**

```bash
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter test \
  test/features/admin/datagen/
```

---

## Task 11 — 前端测试

- [ ] `datagen_models_test.dart`
  - fromJson 完整/空值/非法值
- [ ] `datagen_controller_test.dart`
  - farm 加载与默认选择
  - farm 切换刷新
  - 设备选择状态
  - 保存成功/失败
  - 启停防重复
  - clear result 使用实际返回量
- [ ] widget test
  - 入口路由可打开
  - 四个 tab 可切换
  - running 清理禁用
  - 设备批量选择
  - 清理确认词错误无法提交
  - owner/worker 不显示入口
- [ ] i18n key 中英文同步检查

**验证**：Flutter tests 全绿；analyze 无新增问题。

---

## Task 12 — 文档与 API 契约

- [ ] `docs/api-contracts/admin-api.md` 增补：
  - farm list
  - console
  - control update
  - clear preview
  - clear
- [ ] 标注权限与 B2B 租户限制。
- [ ] 标注旧 scenario 端点仅 PLATFORM_ADMIN。
- [ ] 更新错误码与 i18n key。
- [ ] 在 clear preview / clear 契约中记录首版跨 farm 设备归属限制。
- [ ] 如实现中发现 spec 偏差，回写 spec 并记录原因。

---

## Task 13 — 构建、部署与集成验证

### 13.1 构建

- [ ] 后端：

```bash
./gradlew compileJava compileTestJava
./gradlew test --tests "*Datagen*" --tests "*Telemetry*" --tests "*Health*" \
  --tests "*GpsLogEventConsumer*"
```

- [ ] 前端：

```bash
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true ./build_web.sh
```

### 13.2 部署

```bash
./scripts/deploy.sh test
```

### 13.3 部署后验证

只能在部署完成后执行。

- [ ] Flyway 迁移成功，应用启动无 ERROR。
- [ ] owner 调旧 scenario endpoint → 403
- [ ] B2B admin 调旧 scenario start/stop → 403
- [ ] platform admin 可列 farm
- [ ] B2B admin 只见本租户 farm
- [ ] B2B admin 访问跨租户 farm → 403
- [ ] 初始所有 farm enabled=false
- [ ] 选择设备并启动：
  - 下一个调度 tick 后只生成指定设备
  - TRACKER 5 分钟
  - CAPSULE 15 分钟
  - device telemetry / gps / health / alert source 正确
- [ ] 停止后立即重新启用：
  - `clearDeviceSchedules` 生效
  - 不因旧 `nextDueByDevice` 延迟首包
  - 首个 tick 后生成一轮数据
- [ ] 移出设备后：
  - 不再生成
  - assignment 保留历史
- [ ] 停止 farm 后不再生成，但 scenario 仍 RUNNING
- [ ] clear preview 数量合理
- [ ] running 状态 clear → 409
- [ ] 停止后 clear：
  - DATAGEN raw/health/estrus/anomaly/alert 删除
  - UNKNOWN/RULE/真实来源保留
  - 已解绑设备历史 DATAGEN 可删
  - audit log 有 CLEAR_DATA
- [ ] 验证跨 farm 设备归属限制已在 preview / clear UI 中展示，且清理仍仅限 `source=DATAGEN`
- [ ] UI 四个 tab 与清理 dialog 视觉验收通过
- [ ] 中英文切换后页面与 API 错误正确本地化

---

## Task 14 — 提交与交付

- [ ] 仅 stage 本任务文件：
  - prototype
  - spec
  - review
  - plan
  - backend datagen/control/clear/source 相关文件
  - frontend datagen 页面与路由文件
  - i18n 文件
  - API contract
- [ ] 不得 stage 现有 subscription/commerce/API 文档无关改动。
- [ ] `git diff --cached --check`
- [ ] commit message 建议：

```text
feat: add datagen admin console
```

- [ ] push master
- [ ] 交付摘要包含：
  - 功能入口
  - 权限验证结果
  - 仿真节奏验证结果
  - 清理验证结果
  - 残余风险

---

## 任务依赖

```text
Task 0 视觉准备
  └── Task 10/11 前端实现与保真

Task 1 迁移
  ├── Task 2 模型/Repository
  │     └── Task 4 控制服务
  └── Task 6 source 穿透
        └── Task 7 清理服务

Task 3 权限/操作者上下文
  └── Task 4 控制服务
        └── Task 8 API

Task 4/5/7/8 后端闭环
  └── Task 13 部署集成

Task 9/10/11 前端闭环
  └── Task 13 部署集成
```

## 完成定义

1. 所有列出的单测、构建、分析、Flutter 测试通过。
2. test 集成验证全部通过。
3. 视觉保真对比通过。
4. B2B 与平台管理员权限边界实测通过。
5. 清理只影响 DATAGEN 可归属数据。
6. 操作审计可见。
7. 相关文档与 i18n 完整。
