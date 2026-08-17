# 仿真控制管理界面设计

> 日期：2026-08-17 · 状态：已按评审修订，待用户确认
> 原型：`docs/marketing/datagen-console-prototype.html`
> 阶段：feature 流程第 2 步；确认后进入实施计划

## 1. 背景

当前 datagen 已能生成连续、真实的 TRACKER 与 CAPSULE 数据，但控制方式是调用内部 admin API：

- 启停要调用 `/api/v1/admin/datagen/scenarios/{id}/start|stop`
- 设备范围由 `SynthesisService` 扫描全部活跃安装决定，无法手工指定
- 清理仿真数据没有管理入口，也无法安全区分真实数据与仿真派生数据
- 管理端缺少权限边界和数据范围隔离

客户演示与后续运维都需要平台管理员、B2B 管理员在各自工作界面直接控制仿真。

## 2. 已确认目标

1. 平台管理员和 B2B 管理员都可以：
   - 打开/关闭仿真
   - 指定参与仿真的设备
   - 清空仿真数据
2. 平台管理员可管理全部牧场；B2B 管理员只能管理本租户牧场。
3. 牧场主和牧工不可见该功能。
4. 仿真数据仍必须走真实业务链路：GPS 入库、围栏告警、健康日志、设备状态和总览统计都正常联动。
5. 清理真实数据是禁止项；只允许清理带明确 DATAGEN 来源的数据。

## 3. 决策记录

| # | 决策点 | 结论 |
|---|--------|------|
| D1 | 入口 | 共用页面 `/admin/datagen`，名称“仿真控制” |
| D2 | 平台管理员入口 | `_PlatformAdminShell` 侧栏，位于“遥测数据导入”之后 |
| D3 | B2B 管理员入口 | `_B2bAdminShell` 侧栏，位于“瓦片管理”之前 |
| D4 | 权限 | 后端类级 `hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')`，B2B 再按 farm→tenant 校验 |
| D5 | 开关粒度 | 按 farm 控制，不使用全局 scenario 状态作为 UI 开关 |
| D6 | 设备指定 | 只允许选择当前牧场内 ACTIVE 且有活跃安装的 TRACKER/CAPSULE |
| D7 | 清理前置 | 该牧场仿真控制必须先停止 |
| D8 | 清理范围 | 仅清理 `source=DATAGEN` 的数据及其可追踪派生数据 |
| D9 | 旧端点处置 | 旧 scenario/labels/evaluation 端点仅 `PLATFORM_ADMIN` 可访问；B2B 管理员只能访问新控制台端点 |
| D10 | 历史设备归属 | 用持久 assignment 记录设备与牧场的仿真归属，清理不依赖当前活跃安装 |
| D11 | 审计写侧 | 新增 datagen 专用审计服务直接写 `audit_logs`，不依赖当前缺失的全局 AuditLogEventListener |
| D12 | 初始化状态 | 迁移保证 NORMAL 场景可运行，但 farm control 初始全部 `enabled=false` |

## 4. 信息架构与操作流

### 4.1 页面结构

页面采用四段标签：

1. **运行状态**
   - 当前开关状态
   - 已指定设备数
   - 下一批数据时间
   - 今日仿真数据量
   - 最近写入
   - 当前仿真规则摘要
2. **设备范围**
   - 牧场、类型、关键词筛选
   - 设备多选表
   - 单台/批量选择
   - 保存设备范围
3. **数据清理**
   - 时间范围选择：24 小时 / 7 天 / 全部 / 自定义
   - 删除量预估
   - 停止后才允许清理
   - 二次确认输入“清空”
4. **操作记录**
   - 启停、设备范围变更、数据清理记录
   - 操作者角色、时间、牧场、结果

### 4.2 主操作流

#### 启动仿真

1. 管理员选择牧场
2. 在“设备范围”选择设备并保存
3. 打开顶部开关
4. 后端校验设备列表非空且全部合法
5. 后端幂等确保默认 `NORMAL` 场景为 `RUNNING` 且窗口未过期
6. 保存 farm control `enabled=true`
7. Runner 下一个 tick 只为该 farm 已选择设备生成数据

#### 停止仿真

1. 管理员关闭顶部开关
2. 后端保存 `enabled=false`
3. 不修改全局 scenario 状态，避免影响其他 farm
4. 已在执行中的单次生成会自然结束，不做线程强停
5. 后续 tick 不再生成该 farm 数据

#### 指定设备

1. 列表展示当前牧场全部 TRACKER/CAPSULE
2. 每行显示设备编号、类型、绑定牲畜、运行状态、仿真频率、最近生成
3. 仅可选合法设备：
   - `devices.status=ACTIVE`
   - 存在 `installations.removed_at IS NULL`
   - 绑定牲畜属于当前 farm
   - 设备未删除
4. 保存时后端逐项复验，避免前端绕过

#### 清空仿真数据

1. 管理员先停止该牧场仿真
2. 选择时间范围
3. 后端返回预估删除量
4. 管理员输入“清空”
5. 后端在事务中按来源与时间删除
6. 写入操作审计

## 5. 后端设计

### 5.1 数据模型

新增两张表。第二张表不是临时选择集，而是设备仿真归属历史：设备被移出选择或解绑后记录保留，供统计与清理追溯，不依赖“当前活跃安装”。

```sql
CREATE TABLE datagen_farm_controls (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    scenario_id BIGINT NOT NULL REFERENCES synthesis_scenarios(id),
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_datagen_farm_controls_farm UNIQUE (farm_id)
);

CREATE TABLE datagen_device_assignments (
    id BIGSERIAL PRIMARY KEY,
    control_id BIGINT NOT NULL REFERENCES datagen_farm_controls(id) ON DELETE CASCADE,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    first_assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    removed_at TIMESTAMP,
    CONSTRAINT uq_datagen_assignments_control_device UNIQUE (control_id, device_id)
);

CREATE INDEX idx_datagen_controls_tenant_farm
    ON datagen_farm_controls(tenant_id, farm_id);
CREATE INDEX idx_datagen_controls_scenario
    ON datagen_farm_controls(scenario_id);

CREATE INDEX idx_datagen_assignments_control
    ON datagen_device_assignments(control_id);
CREATE UNIQUE INDEX uq_datagen_active_assignments_device
    ON datagen_device_assignments(device_id)
    WHERE removed_at IS NULL;
```

说明：

- `scenario_id` 首版指向默认 `NORMAL` 场景。
- `enabled` 是 farm 级 UI 开关；全局 scenario 保持 `RUNNING`，避免一个 B2B 管理员影响其他租户。
- 保存配置时服务层必须幂等确保默认 scenario `RUNNING` 且窗口未过期；停止 farm 时不修改 scenario。
- `removed_at IS NULL` 表示当前被选择；设备被移出选择时写 `removed_at`，不物理删除。
- 同一设备可以有多条不同 farm 的历史 assignment；但任一时刻只能有一条 active assignment，由部分唯一索引保证。
- 清理和统计按 assignment 历史归属回查，不按当前活跃安装回查。
- 迁移初始化：
  1. 确保名称为“默认持续合成”的 `NORMAL` 场景存在且为 `RUNNING`；若 `window_end <= NOW()`，延长到 `NOW() + 365 days`。
  2. 为所有 farm 创建 control，初始 `enabled=false`。
  3. 从历史 `installations` 回填设备归属（含已移除安装），用于存量 DATAGEN 数据归属。
  4. 当前仍符合 D6 的设备回填为 active assignment；已解绑/非活跃设备回填为带 `removed_at` 的历史 assignment。

初始化不自动恢复产数；管理员必须在控制台显式打开目标 farm 的开关。

### 5.2 SynthesisService 适配

`DeviceQueryPort` 新增：

```java
List<ActiveInstallationInfo> findActiveInstallationsByScenario(Long scenarioId);
```

查询链路：

```text
synthesis_scenarios RUNNING
  → datagen_farm_controls enabled=true
  → datagen_device_assignments removed_at IS NULL
  → devices status=ACTIVE and deleted_at is null
  → installations removed_at is null
  → livestock
```

现有 `findActiveInstallations()` 保留给旧测试或内部评估使用，控制台场景不再走“全部活跃设备”。`SynthesisService` 继续复用现有生成逻辑：TRACKER 5 分钟连续移动、CAPSULE 15 分钟健康数据、围栏事件与健康事件低概率生成。

### 5.3 API 设计

当前 `DataGenAdminController` 没有任何方法级授权，而 URL 层仅要求登录；owner 账号实测可访问 scenario 端点。这是本次必须修复的存量漏洞，不能沿用“控制器仍使用 @PreAuthorize”的错误假设。

新增独立的 `DataGenConsoleController`：

```java
@RequestMapping("/api/v1/admin/datagen")
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')")
```

#### 旧端点处置

现有 `DataGenAdminController` 保留原路径，但每个方法补：

```java
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
```

覆盖：

- `POST /scenarios`
- `GET /scenarios`
- `POST /scenarios/{id}/start`
- `POST /scenarios/{id}/stop`
- `GET /labels`
- `GET /evaluation`

原因：这些端点操作或读取全局 scenario。若放行 B2B 管理员，其可停止全局 NORMAL 场景，间接影响所有租户，破坏 farm 级隔离。B2B 管理员仅使用下面的新控制台端点。

#### 获取牧场列表

`GET /api/v1/admin/datagen/farms`

```json
{
  "items": [
    {
      "farmId": 1,
      "farmName": "Main Ranch",
      "tenantId": 1,
      "tenantName": "Demo 租户",
      "enabled": true,
      "selectedDeviceCount": 16
    }
  ]
}
```

平台管理员返回全部牧场；B2B 管理员仅返回当前租户牧场。

#### 获取控制台数据

`GET /api/v1/admin/datagen/console?farmId=1`

返回：

```json
{
  "farm": { "farmId": 1, "farmName": "Main Ranch", "tenantId": 1 },
  "enabled": true,
  "scenario": { "id": 1, "name": "默认持续合成", "type": "NORMAL" },
  "devices": [
    {
      "deviceId": 5,
      "deviceCode": "0095690a00008aa8",
      "devEui": "0095690a00008aa8",
      "deviceType": "TRACKER",
      "livestockId": 1,
      "livestockCode": "ST-10",
      "runtimeStatus": "online",
      "selected": true,
      "eligible": true,
      "lastGeneratedAt": "2026-08-17T08:00:00Z"
    }
  ],
  "stats": {
    "statsTimeZone": "Asia/Shanghai",
    "selectedTotal": 16,
    "selectedTrackerCount": 8,
    "selectedCapsuleCount": 8,
    "todayTelemetryRows": 3284,
    "todayGpsRows": 1842,
    "todayHealthRows": 812,
    "lastGeneratedAt": "2026-08-17T08:00:00Z"
  },
  "operations": [
    {
      "id": 1,
      "action": "START",
      "operatorId": 3,
      "operatorRole": "B2B_ADMIN",
      "occurredAt": "2026-08-17T08:00:00Z",
      "summary": "启动 Main Ranch 仿真，16 台设备"
    }
  ]
}
```

`today*` 统一按 `Asia/Shanghai` 自然日计算：`Instant.now().atZone(ZoneId.of("Asia/Shanghai")).toLocalDate()`。返回体显式携带 `statsTimeZone`，避免客户端自行猜测。

#### 保存控制配置

`PUT /api/v1/admin/datagen/control/{farmId}`

```json
{
  "enabled": true,
  "deviceIds": [5, 6, 133, 134]
}
```

规则：

- `enabled=true` 时 `deviceIds` 不能为空
- 保存范围与启停可一次请求完成，也可分开提交
- 后端全量替换当前 active assignment：新选择清除/设置 `removed_at=NULL`，未选择设置 `removed_at=NOW()`；历史 assignment 不物理删除
- 设备任一不合法则整次请求 400，不部分保存

#### 清理预估

`POST /api/v1/admin/datagen/clear/preview`

```json
{
  "farmId": 1,
  "rangeType": "LAST_24_HOURS",
  "from": null,
  "to": null
}
```

返回：

```json
{
  "telemetryRows": 3284,
  "gpsRows": 1842,
  "temperatureRows": 612,
  "motilityRows": 96,
  "activityRows": 104,
  "estrusRows": 18,
  "anomalyRows": 0,
  "alertRows": 12,
  "unattributableAlertRows": 4,
  "unattributableHealthRows": 0
}
```

#### 执行清理

`POST /api/v1/admin/datagen/clear`

```json
{
  "farmId": 1,
  "rangeType": "LAST_24_HOURS",
  "from": null,
  "to": null,
  "confirmText": "清空"
}
```

规则：

- `confirmText` 必须等于 `"清空"`；英文界面也使用该确认词，避免误触
- 该 farm `enabled=true` 时返回 `STATE_CONFLICT`
- 删除按事务提交，失败整体回滚
- 返回实际删除量

```json
{
  "telemetryRows": 3282,
  "gpsRows": 1840,
  "temperatureRows": 610,
  "motilityRows": 96,
  "activityRows": 104,
  "estrusRows": 18,
  "anomalyRows": 0,
  "alertRows": 12
}
```

### 5.4 数据来源追踪

为了安全清理，需要补齐派生数据来源。

#### 已有来源

- `device_telemetry_logs.source = DATAGEN`
- `gps_logs.source = DATAGEN`

#### 新增来源

`temperature_logs`、`rumen_motility_logs`、`activity_logs` 增加：

```sql
source VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN'
```

允许值：

`AGENTIC_PLATFORM / DATAGEN / HTTP / MANUAL_IMPORT / UNKNOWN`

每张表分别添加同名 CHECK 约束，禁止共用一个跨表枚举对象；分区表 `ADD COLUMN` 和 `ADD CONSTRAINT` 会自动下推到既有分区。

`estrus_scores`、`anomaly_scores` 也增加相同 `source` 列。`estrus_scores` 会由 telemetry 派生，必须继承来源；`anomaly_scores` 当前由 `processTelemetry` 触发的调用被禁用，但为了未来启用时不留下来源缺口，本次一并补齐。

写入链路：

- `HealthApplicationService.triggerEstrusScoring(..., source)` → `EstrusScore.source`
- `HealthAnomalyService.assess(..., telemetrySource)` → `AnomalyScore.source`（当前调用禁用，接口一并预留）

链路变更：

```text
TelemetryIngestionService
  → TelemetryReceivedEvent 增加 source
  → Health TelemetryEventConsumer 透传 source
  → HealthApplicationService.processTelemetry(..., source)
  → temperature/rumen/activity logs 写入 source
```

`alerts.source` 增加 `DATAGEN`：

- `GpsLogUpdatedEvent.source=DATAGEN` 时，围栏告警写 `alerts.source=DATAGEN`
- 健康事件由 telemetry source 映射告警来源

`alerts.source` 与健康时序表是两套取值域：

```sql
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_source;
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_source
    CHECK (source IN ('RULE', 'AI', 'DATAGEN'));
```

PostgreSQL 不支持直接修改 CHECK 取值集；必须先 drop 再重建。实现中不得把 alerts 与健康表错误地共用同一个枚举约束。

#### 存量数据原则

- 存量 health rows 没有 `DATAGEN` 标记，默认 `UNKNOWN`
- 控制台清理只删除 `source=DATAGEN` 行
- `UNKNOWN` 行不猜测、不删除，避免误删真实数据
- 清理结果中展示 `unattributableHealthRows`，让管理员知道有多少历史数据因缺来源标记而保留
- `unattributableHealthRows` 精确定义：范围内、归属到该 farm 的三张健康时序表中 `source='UNKNOWN'` 的行数。`AGENTIC_PLATFORM/HTTP/MANUAL_IMPORT` 是可归属的真实来源，不计入该指标。
- `unattributableAlertRows` 精确定义：范围内、归属到该 farm 且 `source='RULE'` 的围栏告警行数。历史仿真围栏告警曾统一写 `RULE`，无法可靠区分真实规则告警，因此保守保留并单独计数。

### 5.5 清理范围

按 farm 的 assignment 历史 + 时间范围 + `source=DATAGEN` 删除。不得用“当前活跃安装”作为归属条件；设备解绑或移出仿真后，历史 DATAGEN 数据仍必须可清理。

| 表 | 条件 |
|---|---|
| `device_telemetry_logs` | device 曾归属该 farm assignment，`source=DATAGEN` |
| `gps_logs` | 同上 |
| `temperature_logs` | device/livestock 曾归属该 farm assignment，`source=DATAGEN` |
| `rumen_motility_logs` | 同上 |
| `activity_logs` | 同上 |
| `estrus_scores` | livestock 属于该 farm，`source=DATAGEN` |
| `anomaly_scores` | livestock 属于该 farm，`source=DATAGEN` |
| `alerts` | fence/livestock 属于该 farm，`source=DATAGEN` |

不删除：

- `health_snapshots`：混合来源快照，删除会破坏健康域状态；下一批真实/仿真数据会自然刷新
- `devices` 运行时快照：电量、在线时间、RSSI 等由后续上报覆盖
- `UNKNOWN` 历史健康数据
- 历史 `RULE` 围栏告警：无法可靠区分真实规则告警与旧版仿真告警，保留并计入 `unattributableAlertRows`
- `AGENTIC_PLATFORM / HTTP / MANUAL_IMPORT` 数据
- `gps_quality_track_points`：这是 GPS 质量检查的持久配对快照，设计上明确要求在 `gps_logs` 被清理后仍存活；它属于质检测试产物，不随遥测清理
- `contact_traces`：无 source 字段的接触关系聚合，保守保留，由后续 retention 策略处理
- Flyway schema history、audit logs、ground truth labels

preview 与 delete 的口径：

- preview 仅用于确认提示；删除成功后 UI 必须展示 delete 返回的实际删除量，不用 preview 数覆盖结果
- delete 在事务内重新计算并删除，接受 preview 与实际数因并发写入存在少量差异

### 5.6 操作审计

现状核查：`AuditLogController` 注释声称由 `AuditLogEventListener` 写审计，但源码中不存在该 listener，也没有生产代码调用 `AuditLogRepository.save()`。因此本次不能只发领域事件后假设审计会落库。

方案：

1. `audit_logs` 增列：

```sql
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS farm_id BIGINT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS operator_role VARCHAR(20);
CREATE INDEX IF NOT EXISTS idx_audit_logs_farm_occurred
    ON audit_logs(farm_id, occurred_at DESC);
```

2. 新增 `DatagenAuditService`，在控制配置与清理事务内直接调用 `AuditLogRepository.save()`。
3. `event_id` 使用 UUID，`event_type` 使用 `DATAGEN_CONTROL_CHANGED` / `DATAGEN_DATA_CLEARED`。
4. `details` 继续保存结构化摘要，便于审计详情展示。

记录字段：

- tenant/farm
- operator userId/role
- action：`START / STOP / UPDATE_DEVICES / CLEAR_DATA`
- deviceIds 或清理范围
- 结果摘要

控制台“操作记录”按 `farm_id + occurred_at DESC` 读取，不新建重复日志表。

### 5.7 后端 i18n

`messages_zh/en.properties` 同步新增：

- `error.datagen.farmNotFound`
- `error.datagen.farmForbidden`
- `error.datagen.devicesRequired`
- `error.datagen.deviceInvalid`
- `error.datagen.runningCannotClear`
- `error.datagen.confirmTextMismatch`
- `error.datagen.invalidTimeRange`

接口 `message` 全部使用 key 解析，不硬编码中英文。

## 6. 前端设计

### 6.1 路由与入口

`app_route.dart`：

```dart
platformDatagen(
  '/admin/datagen',
  'platform-datagen',
  '仿真控制',
)
```

路由守卫调整：

- platform admin 已允许 `/admin/**`
- b2b admin 白名单增加 `/admin/datagen`
- 其他角色仍不可访问

侧栏：

- `_PlatformAdminShell`：遥测数据导入之后
- `_B2bAdminShell`：瓦片管理之前

### 6.2 目录

```text
lib/features/admin/datagen/
├── data/datagen_api_repository.dart
├── domain/datagen_models.dart
└── presentation/
    ├── datagen_controller.dart
    └── datagen_console_page.dart
```

### 6.3 状态设计

`DatagenController`：

```dart
class DatagenConsoleState {
  final List<DatagenFarm> farms;
  final DatagenConsoleData? console;
  final bool isSwitching;
  final bool isSavingDevices;
  final bool isClearing;
  final String? error;
}
```

本页面使用显式 farm 下拉与 `farmId` 查询参数，不调用 `/farms/{activeFarmId}` 形式的 farm-scoped API。因此 Controller 不继承 `FarmScopedNotifier/FarmScopedAsyncNotifier`，也不 `watchActiveFarmId()`；页面牧场切换由自身状态驱动。

交互要求：

- 切换 farm 时重新加载 console
- 开关请求期间禁用开关，避免重复提交
- 设备选择先本地更新，再整批保存
- 清理必须重新调用 preview，不能沿用超过 30 秒的旧预估
- 所有错误用 SnackBar 展示 i18n 文案

### 6.4 视觉规格

#### 顶部

- 标题：仿真控制
- 副标题：环境 + NORMAL 场景
- 右侧状态胶囊：
  - running：success soft 背景，success 文案
  - stopped：surface muted 背景，secondary 文案
- Switch 宽 46px，高 26px，选中 primary

#### 筛选区

四列：

- 租户（平台管理员可见；B2B 固定本租户）
- 牧场
- 设备类型
- 搜索

高度 34px，圆角 6px，focus 时 primary 边框 + primarySoft 光圈。

#### 指标卡

四张：

1. 已指定设备
2. 下一批数据
3. 今日仿真数据
4. 最近写入

数值 22px，标签 11px secondary。

#### 设备表

列：

- checkbox
- 设备编号/EUI
- 类型
- 绑定牲畜
- 运行状态
- 仿真频率
- 最近生成

行高约 42px，编号使用等宽字体。不可选行显示 disabled checkbox 和原因 tooltip。

#### 清理区

- 左侧时间范围单选
- 右侧删除预估与风险提示
- 单独展示“无法归属而保留”的 health / alert 行数，避免管理员误以为所有历史数据已被清空
- running 状态下“清空仿真数据”按钮禁用
- 二次确认对话框要求输入“清空”

#### 操作记录

时间 / 操作 / 摘要 / 角色标签，按时间倒序，默认展示 10 条。

### 6.5 设计令牌表

| 令牌 | 值 | Flutter 对应 |
|---|---|---|
| `--primary` | `#2F6B3B` | `AppColors.primary` |
| `--primary-dark` | `#244F2D` | `AppColors.primaryDark` |
| `--primary-soft` | `#E3F0E4` | `AppColors.primarySoft` |
| `--surface` | `#F8F6F0` | `AppColors.surface` |
| `--surface-alt` | `#FFFFFF` | `AppColors.surfaceAlt` |
| `--surface-muted` | `#F2F0EA` | 新增 `AppColors.surfaceMuted = Color(0xFFF2F0EA)` |
| `--border` | `#D7D2C6` | `AppColors.border` |
| `--text-primary` | `#263126` | `AppColors.textPrimary` |
| `--text-secondary` | `#617061` | `AppColors.textSecondary` |
| `--success` / soft | `#2F7D44` / `#E4F3E8` | 新增 `successStrong` / `successSoft` |
| `--warning` / soft | `#B36A16` / `#FFF2DE` | 新增 `warningStrong` / `warningSoft` |
| `--danger` / soft | `#B3352C` / `#FBE8E6` | 新增 `dangerStrong` / `dangerSoft` |
| `--info` / soft | `#315F79` / `#E7F1F6` | 新增 `infoStrong` / `infoSoft` |
| spacing | 4/8/12/16/24 | `AppSpacing.xs/sm/md/lg/xl` |
| radius | 4/6/8 | `BorderRadius.circular(4/6/8)` |

### 6.6 前端 i18n

中英文同步新增 key，前缀 `datagenConsole*`。

## 7. 安全与边界

### 7.1 授权

后端双层校验：

1. 方法级角色校验
2. service 层 farm 归属校验

```text
PLATFORM_ADMIN → 任意 farm
B2B_ADMIN      → farm.tenantId == TenantContext.getCurrentTenant()
其他角色       → 403
```

### 7.2 并发

- 保存配置使用 farm control 唯一行 + 事务更新
- 设备选择全量替换，避免增量并发造成残留
- 清理前重新读取 enabled；如已重新启动则拒绝
- 清理与保存配置互斥通过 farm control 行锁实现

### 7.3 可逆性

- 启停、设备选择可逆
- 数据清理不可逆，必须 preview + confirmText + 审计
- 不提供物理删除真实数据的入口

## 8. 测试计划

### 后端

1. 权限测试
   - platform admin 可访问
   - b2b admin 本租户可访问
   - b2b admin 跨租户 403
   - owner/worker 403
   - owner/worker 调用旧 scenario 端点 403
   - b2b admin 调用旧 start/stop/create/list/labels/evaluation 端点 403
2. 控制配置
   - 空设备不能启用
   - 非本 farm 设备拒绝
   - 非 ACTIVE/未安装设备拒绝
   - 保存后只生成指定设备
   - 移出选择的设备保留历史 assignment，后续不再生成
3. 仿真执行
   - enabled=false 不生成
   - enabled=true 只生成指定设备
   - 同一头牲畜 TRACKER+CAPSULE 都可生成
4. 清理
   - running 状态拒绝
   - 仅删 DATAGEN
   - 已解绑设备的历史 DATAGEN 行按历史 assignment 清理
   - `estrus_scores/anomaly_scores` 仅删 `source=DATAGEN`
   - 保留 UNKNOWN/HTTP/MANUAL_IMPORT/AGENTIC_PLATFORM
   - 历史 `RULE` 围栏告警保留并计入 unattributable 指标
   - 保留 `gps_quality_track_points` 与 `contact_traces`
   - 事务失败回滚
5. 审计
   - 启停、设备保存、清理均写 audit log
   - 控制台操作记录能按 farm 查询并显示 operator role
   - 事务回滚时审计与业务操作一起回滚

### 前端

1. 两个管理员入口可见
2. owner/worker 不可见且路由被拦截
3. 开关状态与 API 同步
4. 设备选择批量操作与保存
5. running 时清理禁用
6. 确认词错误无法提交
7. 清理结果展示实际删除量和无法归属而保留的数量
8. 中英文无缺失 key

## 9. 实施边界

首版不做：

- 自定义仿真概率、频率、事件强度
- 多场景编辑
- 设备自动编组
- 按 livestock 维度选择（首版按 device 维度）
- 异步清理队列；数据量在当前 test 范围内同步事务可承受

## 10. 验收标准

1. 平台管理员与 B2B 管理员均能从各自侧栏进入“仿真控制”
2. B2B 管理员看不到也无法访问其他租户牧场
3. B2B 管理员调用旧全局 scenario 端点返回 403
4. 部署迁移后所有 farm control 均为 stopped，不自动恢复产数
5. 启停立即影响下一个调度 tick
6. 只有被指定设备持续产生 DATAGEN 数据
7. 清理后 DATAGEN raw/health/estrus/anomaly/alert 数据消失，已解绑设备也能按历史归属清理，真实来源数据、质检快照与接触关系统保留
8. 操作记录可按 farm 追踪并显示操作者角色
9. `flutter gen-l10n`、`flutter analyze`、后端目标测试通过
10. test 部署后完成端到端演示验证
