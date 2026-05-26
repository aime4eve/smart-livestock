# Issue #48「离线优先设计」完成情况评估

> 评估日期：2026-05-27
> 分支：feat/flutter-full-adaptation
> 评估范围：代码实现 + 设计文档 + PRD 规划

## 一、总体评估

Issue #48 提出 9 个维度建议，按优先级分为 P0（3）、P1（3）、P2（3）。

| 等级 | 已完成 | 部分完成（有代码/设计但未闭环） | 未开始（无代码无设计） |
|------|--------|------|------|
| P0 | 0 | 1 | 2 |
| P1 | 1 | 2 | 0 |
| P2 | 0 | 0 | 3 |

**结论：P0 硬需求中仅"地图离线"有设计文档（PRD + Tech Spike 已完成），业务数据离线、多语言、首页即地图三项完全未动。整体完成度约 15%。**

---

## 二、逐维度评估

### P0-1：离线优先设计

**Issue 要求**：App 必须支持离线数据缓存、网络恢复后自动同步；牲畜档案创建、围栏绘制、设备扫码绑定离线可用；地图使用离线瓦片包；同步冲突策略以服务端为准。

#### 实际完成情况

| 子项 | 状态 | 证据 |
|------|------|------|
| 地图瓦片离线 | 🟡 有设计，部分实现 | `SmartTileProvider` 三级降级（tileserver-gl → MBTiles → 高德/OSM）已实现；PRD + 多区域瓦片设计规格已完成；Tech Spike Phase 1 已完成；Phase 2-6 待实施 |
| MBTiles 离线渲染 | ✅ 已实现（原生平台） | `mbtiles_tile_provider_io.dart` 可从 SQLite 读取 MBTiles 瓦片；`sample.mbtiles` 已包含长沙 zoom 12-14 数据 |
| 业务数据离线缓存 | 🔴 未开始 | 无 Hive/Isar/sqflite 等本地数据库依赖；`ApiClient` 无缓存层；仅 `shared_preferences` 用于轻量 KV 存储 |
| 离线牲畜创建/围栏绘制/设备绑定 | 🔴 未设计 | PRD 明确标注"离线围栏绘制/编辑推迟到 v1.1"；无离线操作队列代码 |
| 同步冲突策略 | 🔴 未设计 | 无冲突检测/解决代码 |
| 网络状态检测 | 🔴 未集成 | 无 `connectivity_plus` 依赖；无网络变化监听；`ViewState` 枚举有 `offline` 值但仅用于 UI 状态标记 |

#### 相关文档

- `.claude/PRPs/prds/offline-first-map.prd.md` — 完整 PRD，6 阶段实施计划
- `docs/superpowers/specs/2026-05-15-multi-region-map-tiles-design.md` — tileserver-gl + SmartTileProvider
- `docs/tileserver-deployment-guide.md` — 部署运维
- `.claude/PRPs/plans/completed/offline-first-map-phase1-tech-spike.plan.md` — Phase 1 已完成

#### 关键差距

Issue #48 的离线需求是**全局性的**（所有业务操作离线可用），但当前设计和实现仅覆盖**地图瓦片离线**。PRD 明确将业务数据离线标注为 "Won't Build"。这是最大的覆盖缺口。

---

### P0-2：首页即地图

**Issue 要求**：登录后第一屏就是牧场地图+牲畜位置，不是仪表盘或菜单。

#### 实际完成情况

| 子项 | 状态 | 证据 |
|------|------|------|
| owner 登录后首屏 | 🔴 非地图 | `app_router.dart` redirect 逻辑：登录后跳转 `AppRoute.twin`（孪生/Dashboard），非地图 |
| 底部导航栏 Tab 顺序 | 🔴 孪生优先 | `demo_shell.dart`：Tab 顺序为 孪生→围栏→告警→我的→后台；地图仅在围栏 Tab 内 |
| b2b_admin 导航 | 🟡 左侧 Rail | `NavigationRail` 5 个入口：概览/牧场/合同/对账/牧工 |
| platform_admin | 🔴 ComingSoon | `/ops/admin` 仍是占位页 |

#### 相关文档

- `Mobile/docs/superpowers/specs/2026-03-26-smart-livestock-app-design.md` — 角色化界面规则中描述了"首页、地图、围栏、告警"并列，但未强制地图优先
- 无"首页即地图"专项设计

#### 关键差距

当前首页是孪生概览（Dashboard），地图功能嵌入在围栏 Tab 中。要实现"首页即地图"需要：
1. 调整 Tab 顺序（地图优先）
2. 或将登录后 redirect 改为地图路由
3. 地图页面需要同时显示围栏 + 牲畜位置（当前围栏页已有此能力）

---

### P0-3：多语言架构（P0 语言：英语 + 西班牙语）

**Issue 要求**：第一天就做多语言架构，界面文本外置为 JSON 语言包。

#### 实际完成情况

| 子项 | 状态 | 证据 |
|------|------|------|
| i18n 框架 | 🔴 未集成 | `pubspec.yaml` 无 `flutter_localizations`/`intl` 依赖 |
| .arb 语言文件 | 🔴 无 | 无 `l10n.yaml`、无 `.arb` 文件 |
| UI 文本外置 | 🔴 全部硬编码中文 | 所有 `Text('中文')` 硬编码在 widget 中 |
| locale 切换 | 🔴 无 | 无 Locale 相关代码 |

#### 相关文档

- `Mobile/docs/superpowers/specs/2026-03-26-smart-livestock-app-design.md` §7.3 — 多语言优先级表（英 P0、西 P0、葡 P1、阿 P2、法 P3），路线图标注 V4.0
- `Mobile/docs/superpowers/specs/2026-04-09-smart-livestock-prd.md` §9.4 — 相同优先级表，V3.0 计划中

#### 关键差距

多语言仅停留在 PRD 路线图描述，无任何代码或设计规格。Issue #48 的要求"第一天就做"意味着所有新增 UI 都应从 i18n 架构开始，而非后续补。当前 26 个功能模块全部中文硬编码，后期改造工作量大。

---

### P1-1：试用期转化漏斗

**Issue 要求**：Day 0-14 转化钩子链（引导创建→首次告警→牧场报告→过期提醒→升级方案）。

#### 实际完成情况

| 子项 | 状态 | 证据 |
|------|------|------|
| 14 天试用机制 | ✅ 后端已实现 | `Subscription.startTrial()`、`trialEndsAt`、14 天自动过期 |
| 试用过期定时任务 | ✅ 后端已实现 | `CommerceScheduler.TrialExpiryJob` 每小时检查 |
| 到期前 7 天提醒 | ✅ 前端已实现 | `SubscriptionRenewalBanner` 显示天数倒计时，≤3 天紧急样式 |
| 到期弹窗 | ✅ 前端已实现 | `ExpiryPopupHandler` 登录后检查 ≤7 天弹窗 |
| Day 0 引导 | 🔴 无 | 无新用户引导流程 |
| Day 1 首次告警 | 🔴 无 | 无自动触发测试告警 |
| Day 3 牧场报告 | 🔴 无 | 无报告生成/推送功能 |
| Day 7 功能对比 | 🔴 无 | 无使用统计/功能对比展示 |
| Day 12 数据报告 | 🔴 无 | 无数据报告作为留存钩子 |

#### 相关文档

- `docs/superpowers/specs/2026-05-18-commerce-context-design.md` — subscription 状态机（TRIAL→ACTIVE/FREE/CANCELLED）
- `docs/subscription-guide.md` — Phase × Tier 模型（SAMPLE 14 天 Premium → BATCH）
- `Mobile/docs/superpowers/specs/2026-04-28-unified-business-model-design.md` — 统一商业模型
- `Mobile/docs/superpowers/specs/2026-05-04-free-tier-clarification-design.md` — free tier 定义

#### 关键差距

后端试用期机制完整（创建→计时→过期→降级），前端有到期提醒。但 Issue #48 的核心是**转化钩子链**（Day 0-14 的行为引导），这部分完全缺失。当前只有"到期提醒"这一个触点。

---

### P1-2：设备生命周期管理

**Issue 要求**：设备上线→运行中→电量预警→离线→更换→退役，6 阶段全生命周期。

#### 实际完成情况

| 子项 | 状态 | 证据 |
|------|------|------|
| 设备状态机（4 态） | ✅ 后端已实现 | `DeviceStatus`: INVENTORY→ACTIVE→OFFLINE→DECOMMISSIONED，带状态守卫 |
| 心跳遥测更新 | ✅ 后端已实现 | `Device.updateRuntimeStatus()` 更新 runtimeStatus/batteryLevel/firmwareVersion |
| 前端设备列表展示 | ✅ 前端已实现 | `HighfiDeviceTile` 显示在线/离线/低电量状态 |
| 电量预警告警 | 🔴 无 | 无低电量自动告警规则 |
| OTA 固件升级 | 🔴 无 | `firmwareVersion` 仅记录，无升级 API |
| 设备更换（解绑旧+绑新） | 🔴 无 | 无批量更换流程 |
| 设备退役归档 | 🟡 部分可做 | `decommission()` 可标记退役，但无归档 UI |
| 设备离线排查引导 | 🔴 无 | 无 24 小时无数据→标记离线→引导排查流程 |

#### 相关文档

- `docs/superpowers/specs/2026-05-06-mvp-backend-design.md` — Device/DeviceLicense 分离设计，`firmware_version` 字段
- `Mobile/docs/superpowers/specs/2026-04-09-smart-livestock-prd.md` — 设备状态监控、OTA 升级描述
- `Mobile/docs/superpowers/specs/2026-05-02-unified-business-model-phase2b-design.md` — Open API 设备查询

#### 关键差距

后端数据模型和状态机扎实（DDD Aggregate Root），覆盖了 6 阶段中的 3 个（上线/离线/退役）。缺的是业务闭环：电量预警告警、OTA 升级 API、设备更换向导、离线排查引导。

---

### P1-3：告警卡片交互

**Issue 要求**：每条告警是可操作卡片（查看详情/标记已处理/忽略），不是列表。

#### 实际完成情况

✅ **已完成**。`AlertsPage` 使用 `HighfiCard` 展示 P0 告警，支持完整状态流转（pending→acknowledged→handled→archived），前端 `flow_smoke_test.dart` 有验证。后端告警状态机带非法跳转保护（409 STATE_CONFLICT）。

---

### P2-1：交叉销售触点

**Issue 要求**：在用户完成操作后自然提示"您还可以…"。

**状态**：🔴 完全未实现。无任何 recommend/upsell/cross-sell 代码。无设计文档。

---

### P2-2：数据导出/合规

**Issue 要求**：一键导出牧场数据（CSV/JSON）；租户注销彻底清除；数据归属告知。

**状态**：🔴 完全未实现。仅 B2B 合同页有"导出 PDF（占位）"文案。PRD 提及 GDPR 合规但无实施设计。

---

### P2-3：语音输入

**Issue 要求**：添加牲畜备注时支持语音转文字。

**状态**：🔴 完全未实现。无 `speech_to_text` 依赖，无语音相关代码或设计文档。

---

## 三、下一步工作建议

### 推荐优先级排序

基于 Issue #48 自身优先级 × 实际覆盖缺口 × 实施投入产出，建议分三批推进：

---

#### 第一批：基础设施（建议立即启动）

这批工作为后续所有功能奠定基础，越早做重构成本越低。

**1. 多语言 i18n 架构搭建**
- **投入**：中（3-5 天）
- **产出**：flutter_localizations + intl 集成、arb 文件结构、locale 切换机制
- **范围**：
  1. 集成 `flutter_localizations` + `intl`，配置 `l10n.yaml`
  2. 创建 `app_en.arb`（英语）作为基础，中文文本迁移到 `app_zh.arb`
  3. 新增 `LocaleProvider` 支持运行时切换
  4. 改造 5 个核心页面（登录、孪生首页、围栏、告警、我的）为 i18n 模式
  5. 其余 21 个模块后续渐进式迁移
- **理由**：26 个模块全部中文硬编码，越晚改成本越高。先搭好架构，新增页面直接用 i18n，旧页面渐进迁移。Issue #48 说"第一天就做"，虽然已经晚了但仍是越早越好。

**2. 首页调整为地图优先**
- **投入**：低（1-2 天）
- **产出**：owner 登录后首屏为地图+牲畜位置
- **范围**：
  1. 调整 `demo_shell.dart` Tab 顺序：地图（原围栏 Tab）→ 告警 → 孪生 → 我的
  2. 或新增独立地图 Tab（含围栏 + 牲畜位置 + GPS 轨迹），将围栏管理保留为子页面
  3. 调整 `app_router.dart` redirect 登录后跳转地图路由
- **理由**：改动量小但用户体验影响大，直接响应 Issue #48 "打开就能看到牛在哪" 的核心诉求。

---

#### 第二批：离线能力建设（建议第一批完成后启动）

**3. 离线地图瓦片实施（Phase 2-5）**
- **投入**：高（2-3 周）
- **产出**：地图离线可用
- **范围**：按已有 PRD 的 Phase 2-5 执行：
  1. Phase 2：后端 MBTiles 生成服务（tileserver-gl + 下载 API）
  2. Phase 3：Flutter 离线瓦片渲染（SmartTileProvider 已有基础，增强回退逻辑）
  3. Phase 4：离线数据持久化（围栏 + 牲畜位置本地缓存）
  4. Phase 5：MBTiles 管理界面（下载/进度/删除）
- **依赖**：需集成 `connectivity_plus` 检测网络状态
- **理由**：PRD 已完成、Tech Spike 已通过，是 Issue #48 离线需求中投入产出比最高的部分。

**4. 业务数据离线缓存基础**
- **投入**：高（1-2 周）
- **产出**：核心数据本地持久化
- **范围**：
  1. 集成 Hive 或 Isar 作为本地数据库
  2. 将 ApiCache 扩展为持久化层：围栏数据、牲畜列表、最后 GPS 坐标离线可读
  3. 网络恢复后自动同步（先拉取服务端数据覆盖本地）
  4. 牲畜查看、围栏查看离线可用（只读）
- **理由**：离线地图瓦片 + 离线数据缓存 = 巡栏场景基本可用。不需要离线创建/编辑，只读即可覆盖 80% 巡栏需求。

---

#### 第三批：生命周期与转化（建议第二批完成后视资源启动）

**5. 试用期转化钩子链**
- **投入**：中（1 周）
- **范围**：
  1. Day 0：新用户引导 Wizard（创建牧场 → 添加设备 → 查看地图）
  2. Day 1：后端触发测试告警（新租户 seed 后自动创建一条围栏越界告警）
  3. Day 7/12：前端展示"试用功能 vs 付费功能"对比面板
- **理由**：后端试用期机制完整，只需补充触点。直接提升转化率。

**6. 设备生命周期补全**
- **投入**：中（1 周）
- **范围**：
  1. 后端：电量 < 20% 自动生成告警（复用现有告警系统）
  2. 后端：24 小时无心跳自动标记 offline + 生成运维通知
  3. 前端：设备详情页增加"更换设备"引导流程
- **理由**：Device 领域模型扎实，增量开发成本低。

**7. 数据导出 MVP**
- **投入**：低（3-5 天）
- **范围**：
  1. 后端：`GET /api/v1/farms/{farmId}/export?format=csv` 导出牲畜+轨迹+告警
  2. 前端：牧场设置页"导出数据"按钮
- **理由**：B2B 客户和政府采购硬性要求，投入不大但合规价值高。

---

### 暂缓项

| 维度 | 理由 |
|------|------|
| 离线围栏绘制/编辑 | 需冲突解决机制，复杂度高，PRD 已标注 v1.1 |
| 离线牲畜创建/设备绑定 | 同上，离线写操作需要完整的同步队列 |
| 语音输入 | 体验加分项，非核心路径 |
| 交叉销售触点 | 需要先有足够多的产品线数据支撑 |

---

## 四、文档覆盖情况汇总

### 有设计文档（可实施）

| 维度 | 文档 | 状态 |
|------|------|------|
| 离线地图瓦片 | `.claude/PRPs/prds/offline-first-map.prd.md` + `2026-05-15-multi-region-map-tiles-design.md` | PRD 完成，Phase 1 完成，Phase 2-6 待实施 |
| 试用期机制 | `2026-05-18-commerce-context-design.md` + `subscription-guide.md` | 后端已实现，前端有提醒 |
| 设备数据模型 | `2026-05-06-mvp-backend-design.md` | 基础字段和状态机已实现 |

### 有 PRD 描述但无实施设计

| 维度 | 文档 | 缺口 |
|------|------|------|
| 多语言 | app-design §7.3、PRD §9.4 | 仅有优先级表，无 i18n 架构设计 |
| 设备 OTA/电量预警 | PRD §5.7 | 仅有功能描述，无 API/UI 设计 |
| 数据导出 | PRD §9.4 路线图 | 仅 V4.0 路线图提及 |
| 首页即地图 | app-design 角色化规则 | 描述了 Tab 布局但未强制地图优先 |

### 完全无文档

| 维度 |
|------|
| 业务数据离线缓存（围栏/牲畜只读） |
| 离线操作队列与同步冲突策略 |
| 试用期转化钩子链（Day 0-14 触点） |
| 交叉销售触点 |
| 语音输入 |
| GDPR 数据导出与租户注销 |

---

## 五、建议的 Issue 管理操作

1. 将 Issue #48 标记为 **Epic**，拆分为独立子 Issue：
   - `#48-1` 多语言 i18n 架构（P0）
   - `#48-2` 首页即地图（P0）
   - `#48-3` 离线地图瓦片（P0）— 已有 PRD
   - `#48-4` 业务数据离线缓存（P0）
   - `#48-5` 试用期转化钩子链（P1）
   - `#48-6` 设备生命周期补全（P1）
   - `#48-7` 数据导出 MVP（P2）
2. 关闭 P1 告警卡片（已完成）
3. 为 `#48-3` 添加 Phase 2-6 的 Task 链接
