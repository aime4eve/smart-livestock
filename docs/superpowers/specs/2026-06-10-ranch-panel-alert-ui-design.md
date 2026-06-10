# 牧场面板告警 UI 设计规格

> 日期：2026-06-10
> 范围：Flutter 前端 `Mobile/mobile_app/` 牧场 Tab（RanchPage + HealthBottomSheet）
> 关联：后端 Ranch 限界上下文（告警状态机调整）、IoT 限界上下文（GPS 上报）

---

## 1. 背景与问题

owner 登录后在"牧场"Tab 上划拉起的底部面板（`HealthBottomSheet`）存在严重的体验问题：

1. **信息重复**：牲畜数、健康率、告警数在 peek 条、统计卡片、告警标题三处重复出现；场景芯片（发热/消化/发情/疫病）与告警列表是摘要↔明细关系，又重复一遍。
2. **业务主线不清**：概况、告警、待办三个板块平铺在一个长列表里，没有优先级和钻取层次。
3. **状态机错位**：告警沿用 `PENDING → ACKNOWLEDGED → HANDLED → ARCHIVED`，但系统并不能"处理"健康问题（体温异常要靠 owner 线下治牛），HANDLED 状态名不副实。
4. **围栏告警薄弱**：作为核心业务，围栏告警只有"越界"一种，缺乏专业的接近预警和重点区域监控，且无专门的详情页。

## 2. 核心定位

本系统是畜牧领域的**专业告警管理系统**，围绕两条业务主线：

- **围栏告警**（电子围栏）— 基于位置的空间告警
- **健康告警**（畜牧健康状态）— 基于生理指标的告警

**关键认知**：系统**只负责通知，不负责解决**。体温异常时，系统能做的是"通知 owner"，治牛是 owner 线下的事。因此用**通知中心模型**（已读/未读）替代处理流程状态机。

**业界参考**（联网调研）：
- **EarthRanger 双边界**：Warning Boundary（琥珀，进入缓冲带触发）+ Critical Boundary（红色，越过触发）。缓冲带设在外侧。→ 对应"接近围栏"vs"越过围栏"。
- **Nofence 分层预警**：音频警告（接近）→ 电脉冲（越界）→ 牛群本能自行返回，**返回不惩罚**。→ 印证"自动解除"设计的正确性。

## 3. 设计目标

1. **业务主线清晰**：打开面板 → 看状态 → 处理告警，自上而下一条线。
2. **消除信息重复**：每个数据点只出现一次。
3. **钻取式架构**：按需深入，不被无关信息干扰。
4. **预防性预警**：围栏在真正越界前先通知（缓冲带）。
5. **诚实的能力边界**：明确告知"系统能做什么、需 owner 做什么"。

**核心业务流程**：

两条业务主线、一个统一模型：

**围栏告警（空间驱动）**：

```
GPS 上报 → 牲畜进入缓冲带(50m) → FENCE_APPROACH(WARNING)                                    										↓ 继续外移 
           →FENCE_BREACH(CRITICAL) 
                ↓ 牲畜自行返回 
          → 自动解除(AUTO_RESOLVED)
```

**健康告警（指标驱动）**：

```
IoT 上报指标 → 体温/蠕动/发情/疫病超阈值 → ACTIVE 告警                                                                  ↓ 后续指标回到正常
                → 自动解除(AUTO_RESOLVED)
```

统一的通知中心模型把两条线汇到同一个面板交互流：

```
peek 条（头数 · 归栏率 · 健康率）  
↓ 上划卡片仪表盘（围栏/健康分组，0 的隐藏） 
↓ 点击卡片告警列表（未读加粗 · 已读淡化 · 自动解除折叠）  
↓ 点开详情 → 自动标已读围栏=地图型 / 健康=图表型
```

一句话：**系统只负责通知，不负责解决**。围栏靠 GPS 事件驱动自动解除，健康靠指标事件驱动自动解除，owner 的操作只有"知道了（已读）"和"不用管了（忽略）"。

## 4. 告警状态模型（通知中心模型）

废弃旧的 `PENDING/ACKNOWLEDGED/HANDLED/ARCHIVED`，采用通知中心模型：

```
告警发生
  ↓
未读（Unread）— owner 未查看              ← 需要关注
  ↓ owner 点开详情（隐式标记）
已读（Read）— owner 已知悉，异常仍存在     ← 需要关注（已知情）
  ↓ 条件消失 / owner 忽略
  ├→ 已自动解除（Auto-resolved）— 条件自行消失  ← 无需处理（可回溯）
  └→ 已忽略（Dismissed）— owner 手动清除
```

**状态归属**：
- **活跃告警**（需关注）= 未读 + 已读
- **已自动解除**（折叠区）= 条件消失，仅回溯

**自动解除判定**：
- 围栏告警：牲畜位置回到安全区（牛回来了 / 离开缓冲带）
- 健康告警：生理指标回到正常范围（体温恢复 / 蠕动正常）

**已读状态存储（per-user）**：

`read` 不是 Alert 实体字段，而是 **per-user** 状态。同一告警被同一牧场多个用户（owner + worker）看到，每个用户独立维护已读。设计：

```sql
-- 新增关联表（Flyway V19）
CREATE TABLE alert_read_status (
    id            BIGSERIAL PRIMARY KEY,
    alert_id      BIGINT NOT NULL REFERENCES alerts(id),
    user_id       BIGINT NOT NULL REFERENCES users(id),
    read_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(alert_id, user_id)
);
CREATE INDEX idx_alert_read_user ON alert_read_status(user_id);
```

- 查询"未读数"：`SELECT COUNT(*) FROM alerts a WHERE a.farm_id = ? AND a.status = 'ACTIVE' AND NOT EXISTS (SELECT 1 FROM alert_read_status ars WHERE ars.alert_id = a.id AND ars.user_id = ?)`
- 标记已读：`INSERT INTO alert_read_status(alert_id, user_id) VALUES (?, ?) ON CONFLICT DO NOTHING`
- 前端 `RanchAlertData` 增加 `read: bool` 字段，由后端根据当前用户 join 查询填充

### 4a. 状态迁移方案（旧 → 新映射）

生产 DB 已有 Flyway V1-V18。从 4-state 到通知中心模型需要一次性迁移：

| 旧状态 | 新映射 | 说明 |
|--------|--------|------|
| `PENDING` | `ACTIVE` + `unread` | 默认初始状态改为 ACTIVE，已读状态由 `alert_read_status` 关联表决定 |
| `ACKNOWLEDGED` | `ACTIVE` + `read` | 用户已查看但异常仍存在，视为"已读活跃" |
| `HANDLED` | `DISMISSED` | 历史上标为"已处理"的，语义上等同于用户手动忽略 |
| `ARCHIVED` | `AUTO_RESOLVED` | 历史上标为"已归档"的，映射为自动解除 |

**Flyway 迁移策略（V19）**：

```sql
-- 1. alerts 表增加新字段
ALTER TABLE alerts ADD COLUMN resolved_type VARCHAR(20);  -- AUTO / MANUAL_DISMISS
ALTER TABLE alerts ADD COLUMN resolved_at TIMESTAMP WITH TIME ZONE;

-- 2. 创建 alert_read_status 关联表（见上文）

-- 3. 数据迁移：旧状态 → 新状态
UPDATE alerts SET status = 'ACTIVE' WHERE status IN ('PENDING', 'ACKNOWLEDGED');
UPDATE alerts SET status = 'DISMISSED', resolved_type = 'MANUAL_DISMISS', resolved_at = COALESCE(handled_at, acknowledged_at, NOW()) WHERE status = 'HANDLED';
UPDATE alerts SET status = 'AUTO_RESOLVED', resolved_type = 'AUTO', resolved_at = COALESCE(handled_at, acknowledged_at, NOW()) WHERE status = 'ARCHIVED';

-- 4. 对旧 ACKNOWLEDGED 的告警，自动标记为已读（用 acknowledged_by）
INSERT INTO alert_read_status (alert_id, user_id, read_at)
SELECT id, acknowledged_by, COALESCE(acknowledged_at, NOW())
FROM alerts WHERE acknowledged_by IS NOT NULL;

-- 5. 清理旧字段（可选，建议保留一段时间再清理）
-- ALTER TABLE alerts DROP COLUMN acknowledged_by;
-- ALTER TABLE alerts DROP COLUMN acknowledged_at;
-- ALTER TABLE alerts DROP COLUMN handled_by;
-- ALTER TABLE alerts DROP COLUMN handled_at;
```

**Java 枚举变更**：`AlertStatus` 从 `{PENDING, ACKNOWLEDGED, HANDLED, ARCHIVED}` 改为 `{ACTIVE, DISMISSED, AUTO_RESOLVED}`。

**后端兼容**：旧 API 端点 `/alerts/{id}/acknowledge` → 映射为 `/alerts/{id}/read`，`/alerts/{id}/handle` → `/alerts/{id}/dismiss`。建议保留旧端点做 redirect，给前端迁移窗口。

## 5. 告警分类体系

### 5.1 围栏告警

| 类型 | code | 触发条件 | 严重度 | 含义 |
|------|------|---------|--------|------|
| 接近围栏 | `FENCE_APPROACH` | 进入围栏外侧缓冲带（默认 50m，可配） | WARNING | 预防性：可能即将越界 |
| 越过围栏 | `FENCE_BREACH` | 越过围栏边界线 | CRITICAL | 紧急：已经跑出去 |
| 接近重点区域 | `ZONE_APPROACH` | 进入围栏内指定重点区域（水源/产房/危险地形） | INFO/WARNING | 关注：靠近需保护/规避的区域 |

### 5.2 健康告警

| 类型 | code | 触发条件 |
|------|------|---------|
| 发热 | `TEMPERATURE_ABNORMAL` | 瘤胃温度超阈值（基线 +Δ） |
| 消化异常 | `DIGESTIVE_ABNORMAL` | 蠕动指标异常 |
| 发情 | `ESTRUS` | 发情评分高分 |
| 疫病 | `EPIDEMIC` | 疫病异常率超标 |

> **注**：`DIGESTIVE_ABNORMAL` 重命名自现有 `BEHAVIOR_ABNORMAL`，需 Flyway 数据迁移。

## 6. 围栏缓冲带三层空间模型

地图上的围栏不是一条线，而是分层的空间区域：

```
                    ┌── 缓冲带（橙虚线环，默认外扩 50m）
                    │       ↓ 进入即触发"接近围栏"
   ╔════════════════╪═══ 围栏边界（绿实线）
   ║   安全区（绿）  │       ↓ 越过即触发"越过围栏"
   ║                │
   ║  ┌──────┐      │
   ║  │水源🔵│      │   重点区域（蓝虚线圈，围栏内）
   ║  └──────┘      │       ↓ 接近即触发"接近重点区域"
   ║  ┌──────┐      │
   ║  │产房💗│      │   重点区域可多种（水源/产房/危险地形/补饲点）
   ║  └──────┘      │
   ╚════════════════╪═══
```

**牲畜标注颜色随所在区域变化**：
- 安全区（围栏内、非重点区）：🟢 绿色
- 缓冲带（接近围栏）：🟠 橙色 + 光晕脉冲
- 越界（围栏外）：🔴 红色 + 光晕脉冲
- 重点区域内：🔵 蓝色（可选）

> **注**：当前地图只画围栏多边形，缓冲带环和重点区域圈**需新建实现**（见第 9 节）。

**fence_zone 表设计（Flyway V19 同批迁移）**：

```sql
CREATE TABLE fence_zones (
    id            BIGSERIAL PRIMARY KEY,
    fence_id      BIGINT NOT NULL REFERENCES fences(id),
    farm_id       BIGINT NOT NULL,
    name          VARCHAR(100) NOT NULL,       -- "水源区"/"产房"/"危险地形"
    zone_type     VARCHAR(30) NOT NULL,       -- WATER_SOURCE / MATERNITY / DANGER / FEED_POINT
    vertices      JSONB NOT NULL,             -- [{lat, lng}, ...] 多边形
    alert_radius  INTEGER DEFAULT 20,         -- 接近预警半径（米）
    severity      VARCHAR(10) DEFAULT 'INFO', -- INFO / WARNING
    active        BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX idx_fence_zones_fence ON fence_zones(fence_id);
CREATE INDEX idx_fence_zones_farm ON fence_zones(farm_id);
```

**缓冲带检测性能方案**：

每次 GPS 上报需判定"牲畜是否在缓冲带内"，当 N 头牛 × M 个围栏时计算量显著。方案：

1. **预计算 buffer polygon**：围栏创建/编辑时，在 `fences` 表新增 `buffer_polygon JSONB` 字段，用 JTS `Geometry.buffer()` 预计算外扩 50m 的多边形并持久化，避免每次 GPS 上报实时计算。
2. **应用层判定**：复用现有 `Fence.contains()` 的 ray-casting 算法，对预计算的 buffer polygon 做点-in-多边形检测。当前牧场规模（<500 头牛、<10 个围栏）下应用层性能足够。
3. **未来优化**：若规模增长（>5000 头），迁移到 PostGIS + `ST_DWithin()` 做空间索引查询。

**fences 表扩展**：
```sql
ALTER TABLE fences ADD COLUMN buffer_distance INTEGER DEFAULT 50;  -- 缓冲带距离（米）
ALTER TABLE fences ADD COLUMN buffer_polygon JSONB;                -- 预计算的缓冲带多边形
```

## 7. 面板钻取式架构

四层钻取，每层信息密度递增，用户按需深入：

```
① 收起态（地图为主）
   └─ peek 条：头数 · 归栏率 · 健康率
        ↓ 展开
② 展开态（卡片仪表盘）
   ├─ 围栏情况：[越界N][接近N][重点区N]   （仅 N>0 显示）
   └─ 健康情况：[发热N][消化N][发情N][疫病N]
        ↓ 点击卡片
③ 列表态（该类别告警）
   ├─ 活跃：未读（加粗+实心点）+ 已读（淡化+空心圈）
   └─ 已自动解除（折叠）
        ↓ 点击列表项
④ 详情态（标记已读）
   ├─ 围栏告警 → 空间型详情
   └─ 健康告警 → 数据型详情
```

### 7.1 收起态指标

peek 条仅显示三个核心指标：

```
256头 · 归栏率 98% · 健康率 94%
```

- **头数**：当前牧场牲畜总数
- **归栏率**（新命名）：当前在围栏安全区内的牲畜占比 = 安全区牲畜数 / 总数
- **健康率**：健康状态正常的牲畜占比

> **去掉的内容**：原 peek 条的"未读告警数"、4 个统计卡片（与 peek 条重复）。

### 7.2 展开态卡片仪表盘

两组卡片，**仅数量 > 0 的状态才显示卡片**（如疫病 0 则隐藏）：

- **🚧 围栏情况**：越界 / 接近 / 重点区（每张卡片：图标 + 标签 + 活跃数量）
- **❤️ 健康情况**：发热 / 消化 / 发情 / 疫病

卡片颜色对应告警严重度/类型色。点击卡片进入第③层列表。

### 7.3 列表态

该类别下的告警列表：
- **活跃区**：未读（加粗 + 左侧实心色点）在上，已读（正常字重 + 空心圈）在下，按严重度排序
- **已自动解除区**（折叠）：标"无需处理"，默认收起，可展开回溯

### 7.4 详情态

点开即标记为已读。两类详情分别设计（见第 8 节）。

## 8. 两类告警详情设计

### 8.1 围栏告警详情（空间型·新建）

**视觉焦点**：地图（空间关系）

```
┌─ ← 越界告警 · 牛#045 ──────────────┐
│                                      │
│  [小地图：牲畜位置 + 围栏 + 缓冲带]   │  ← 焦点1
│     标注：←120m→                      │
│                                      │
│  🚧 西区牧场围栏 · 📍 围栏外 120m     │  ← 焦点2（空间信息）
│  🧭 西北侧越界 · ⏱ 15分钟前          │
│  ─────────────────────               │
│  📡 追踪器 电量85% · 信号强 · ✓正常   │  ← 辅助（设备信息）
│  ─────────────────────               │
│  💡 系统能通知你牛已越界，需线下赶回  │  ← 能力边界
│  ✓ 已标记已读                        │
│  [📍 大地图定位]  [忽略此告警]       │
└──────────────────────────────────────┘
```

**要素**：小地图（空间关系可视化）+ 距围栏 Xm + 方向 + 最近轨迹 + 动物追踪器设备状态。

### 8.2 健康告警详情（数据型·优化现有）

**视觉焦点**：图表（指标趋势）。复用优化 `fever_detail_page.dart` / `digestive_detail_page.dart` / `estrus_detail_page.dart`。

```
┌─ ← 发热告警 · 牛#023 ──────────────┐
│                                      │
│  [当前41.2℃] [基线38.7℃] [状态严重]  │  ← 焦点1（状态对比）
│                                      │
│  📈 72小时温度曲线                    │  ← 焦点2（趋势）
│     （基线虚线 + 实际曲线 + 末端点）  │
│                                      │
│  📋 超基线 +2.5℃ · 持续6小时         │  ← 焦点3（诊断）
│  ⏱ 首次异常 10分钟前                 │
│  ─────────────────────               │
│  💊 瘤胃胶囊 电量72% · 信号中 · ✓正常 │  ← 辅助（设备信息）
│  ─────────────────────               │
│  💡 系统能通知你体温异常，需线下排查  │  ← 能力边界
│  ✓ 已标记已读                        │
│  [📋 完整健康档案]  [忽略此告警]     │
└──────────────────────────────────────┘
```

**要素**：当前值 vs 基线 + 72h 时序曲线（fl_chart）+ 诊断结论 + 瘤胃胶囊设备状态。

### 8.3 设备信息卡片规范（弱化为辅助行）

设备信息**不是视觉焦点**，降级为低调辅助行：

- **样式**：灰色小字单行 + 上方细分隔线，无彩色背景/边框
- **围栏详情**：📡 动物追踪器（GPS 项圈）— 电量 / 信号 / 状态
- **健康详情**：💊 瘤胃胶囊（温度传感器）— 电量 / 信号 / 状态
- **状态升级**：正常时灰色；**故障时才升级为警示色**（⚠ 上报延迟 / 🔴 离线 / ⚠ GPS 漂移）

**电量颜色**：绿(>50%) / 黄(20-50%) / 红(<20%)
**信号强度**：格数表示（▮▮▮▮ 强 / ▮▮▮▯ 中 / ▮▮▯▯ 弱）

**视觉层级**：地图/图表（主）→ 空间信息/诊断（次）→ 设备信息（辅）→ 操作按钮

## 9. 涉及文件与组件

### 9.1 前端组件清单

| 组件 | 文件 | 动作 |
|------|------|------|
| 牧场页面 | `features/pages/ranch_page.dart` | 改造（地图缓冲带渲染） |
| 底部面板 | `features/ranch/presentation/widgets/health_bottom_sheet.dart` | **重构**（钻取式架构） |
| 围栏告警详情 | `features/ranch/presentation/widgets/fence_alert_detail_sheet.dart` | **新建** |
| 健康告警详情 | 复用 `features/pages/fever_detail_page.dart` 等 | **优化**（设备行 + 能力边界 + 标已读） |
| 牲畜快照 | `features/ranch/presentation/widgets/livestock_detail_sheet.dart` | 调整（新状态模型） |
| 告警卡片 | `features/ranch/presentation/widgets/alert_card.dart` | **新建**（未读/已读 + 类型标签） |
| 仪表盘卡片 | `features/ranch/presentation/widgets/status_dashboard_card.dart` | **新建** |
| 缓冲带图层 | `features/ranch/presentation/widgets/fence_buffer_layer.dart` | **新建**（地图 PolygonLayer 扩展） |
| 告警模型 | `features/ranch/domain/ranch_models.dart` | 扩展（read/autoResolved 字段、围栏告警类型、距离/方向） |
| 面板控制器 | `features/ranch/presentation/ranch_controller.dart` | 扩展（钻取状态、标记已读） |
| 仓库接口 | `features/ranch/domain/ranch_repository.dart` | 扩展（新增 `markRead` / `dismiss` 抽象方法） |
| API 仓库 | `features/ranch/data/ranch_api_repository.dart` | 扩展（实现 `markRead` / `dismiss`，对接后端 API） |

### 9.2 后端影响（需评估）

告警状态机从 `PENDING/ACKNOWLEDGED/HANDLED/ARCHIVED` 调整为通知中心模型：

- **已读状态**：新增 `alert_read_status` 关联表（per-user，见第 4 节），Alert 实体本身不加 `read` 字段
- **新增字段**：`resolved_type`（VARCHAR: `AUTO` / `MANUAL_DISMISS`）、`resolved_at`（timestamp）
- **新增围栏告警类型**：`FENCE_APPROACH`、`ZONE_APPROACH`
- **自动解除逻辑**：
  - 围栏告警：GPS 上报时，`GpsLogApplicationService` 检测牲畜位置回到安全区（离开缓冲带/回到围栏内）→ 调用 `AlertApplicationService.autoResolve(alertId)`
  - 健康告警：`HealthApplicationService` 每次写入新指标时，检测该牲畜是否仍有活跃告警且指标已回到正常范围 → 调用 `AlertApplicationService.autoResolve(alertId)`
  - 自动解除不依赖定时轮询，由 IoT 上报事件驱动（围栏）和 Health 写入事件驱动（健康）
- **缓冲带配置**：fence 实体增加 `buffer_distance`（默认 50m）
- **重点区域**：新增 `fence_zone`（围栏内重点区域）实体

> 后端改动较大，建议作为独立 Phase 评估，前端可先用 Mock 数据验证 UI。

## 10. 数据流

```
RanchController（FarmScopedAsyncNotifier）
  ├─ loadOverview() → RanchOverview
  │    ├─ overallStats: {totalLivestock, inFenceRate(归栏率), healthyRate}
  │    ├─ fenceAlertSummary: {breach, approach, zoneApproach}  ← 卡片数量
  │    ├─ healthAlertSummary: {fever, digestive, estrus, epidemic}
  │    ├─ alerts: [{type, severity, read, livestockId, distance, direction, ...}]
  │    └─ autoResolvedCount
  │
  ├─ markRead(alertId) → POST /alerts/{id}/read
  ├─ dismiss(alertId) → POST /alerts/{id}/dismiss
  └─ refresh()
```

钻取状态（当前选中类别）由面板本地 State 管理，不污染全局。

### 10a. API 契约

以下为新增/修改的后端 API 端点，详细格式见 `docs/api-contracts/app-api.md`。

**修改端点**：

| 方法 | 路径 | 变更说明 |
|------|------|----------|
| GET | `/api/v1/farms/{farmId}/alerts` | 响应增加 `read` 字段（基于当前用户 join `alert_read_status`）；`status` 使用新枚举 `ACTIVE/DISMISSED/AUTO_RESOLVED` |
| GET | `/api/v1/farms/{farmId}/dashboard` | 响应增加 `inFenceRate`（归栏率）和 `fenceAlertSummary`/`healthAlertSummary` 分组统计 |

**新增端点**：

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/farms/{farmId}/alerts/{id}/read` | 标记已读（当前用户） | 无 | `{ data: AlertDto }` |
| POST | `/api/v1/farms/{farmId}/alerts/{id}/dismiss` | 手动忽略 | 无 | `{ data: AlertDto }` |
| POST | `/api/v1/farms/{farmId}/alerts/batch-read` | 批量标已读 | `{ alertIds: ["1","2"] }` | `{ data: { count: 2 } }` |
| GET | `/api/v1/farms/{farmId}/fence-zones` | 列出围栏重点区域 | — | `{ data: { items: [FenceZoneDto] } }` |
| POST | `/api/v1/farms/{farmId}/fence-zones` | 创建重点区域 | FenceZoneCreateDto | `{ data: FenceZoneDto }` |

**AlertDto 新字段**：
```json
{
  "id": 123,
  "type": "FENCE_BREACH",
  "status": "ACTIVE",
  "severity": "CRITICAL",
  "read": true,
  "resolvedType": null,
  "resolvedAt": null,
  "livestockId": 45,
  "fenceId": 3,
  "distance": 120,
  "direction": "NW",
  "message": "牛#045 越过西区围栏",
  "occurredAt": "2026-06-10T08:30:00Z"
}
```

**归栏率（inFenceRate）计算**：后端在 `DashboardApplicationService` 中新增方法，实时查询当前牧场所有牲畜最新 GPS 位置，对每个围栏调用 `Fence.contains()` 判定是否在栏内。`inFenceRate = 围栏内牲畜数 / 有 GPS 位置的牲畜数`。当前牧场规模下应用层计算即可，不依赖 PostGIS。

## 11. 交互细节

- **点开告警详情即标记已读**（隐式，像邮件）
- **未读视觉**：加粗 + 左侧实心色点
- **已读视觉**：正常字重 + 空心圈，整体淡化（opacity 0.7）
- **"全部标为已读"**：列表态顶部提供批量操作
- **自动解除折叠**：默认收起，点击展开，标"无需处理"
- **能力边界说明**：每个详情固定有一行"系统能做什么 / 需 owner 做什么"
- **地图定位**：详情页"大地图定位"按钮跳转地图并聚焦该牲畜

## 12. 明确不做（YAGNI）

- ❌ "待办事项"板块（安装追踪器、围栏年检等任务）— 非当前业务
- ❌ 独立统计卡片（与 peek 条重复）
- ❌ 两行 7 个 filter chips — 卡片仪表盘已按类别分流，列表态无需复杂筛选
- ❌ HANDLED 状态 — 系统不处理健康问题
- ❌ 类型筛选（体温/越界/消化）— 卡片已分类，owner 关心"哪些要处理"而非"哪些是体温异常"

## 13. 测试策略

**关键场景（given-when-then）**：

1. **未读→已读**：
   - Given 一条 ACTIVE 告警，当前用户未读
   - When owner 点开该告警详情
   - Then 调用 `POST /alerts/{id}/read`，`alert_read_status` 写入一条记录，前端 `read` 变为 `true`

2. **围栏告警自动解除**：
   - Given 一条 `FENCE_BREACH` ACTIVE 告警
   - When GPS 上报牲畜位置回到围栏内
   - Then 告警 `status` 变为 `AUTO_RESOLVED`，`resolved_type = AUTO`，前端折叠区显示该告警

3. **健康告警自动解除**：
   - Given 一条 `TEMPERATURE_ABNORMAL` ACTIVE 告警
   - When 新写入的瘤胃温度回到正常范围
   - Then 告警 `status` 变为 `AUTO_RESOLVED`，`resolved_type = AUTO`

4. **手动忽略**：
   - Given 一条 ACTIVE 告警，当前用户已读
   - When owner 点击"忽略此告警"
   - Then 告警 `status` 变为 `DISMISSED`，`resolved_type = MANUAL_DISMISS`

5. **多用户独立已读**：
   - Given owner 和 worker 同属一个牧场，一条 ACTIVE 告警
   - When owner 标记已读
   - Then worker 端该告警仍显示为未读（`alert_read_status` per-user 隔离）

6. **批量标已读**：
   - Given 3 条 ACTIVE 未读告警
   - When owner 点击"全部标为已读"
   - Then 调用 `POST /alerts/batch-read`，3 条全部变为已读

**Widget / UI 测试**：

- **Widget 测试**：每个钻取层级渲染正确（收起/展开/列表/详情）
- **状态模型测试**：未读→已读→自动解除 的转换
- **卡片显示规则**：数量 0 的卡片不显示
- **设备信息测试**：正常态灰色、故障态警示色
- **空状态**：无告警时仪表盘显示空态引导
- **角色权限**：worker 只读（无"忽略"按钮），owner 可操作

## 14. 验收标准

1. owner 打开牧场 Tab，peek 条显示 `头数 · 归栏率 · 健康率`，无重复信息。
2. 上划展开，看到围栏情况 + 健康情况两组卡片，数量 0 的隐藏。
3. 点击卡片进入该类别告警列表，未读/已读视觉区分清晰。
4. 点击告警项进入详情（围栏=地图型 / 健康=图表型），自动标记已读。
5. 围栏地图显示缓冲带环 + 重点区域圈，牲畜标注按区域变色。
6. 设备信息低调显示，不抢视觉焦点。
7. 自动解除的告警在折叠区可回溯。
