# 客户旅程文档（Customer Journey）

> 本文档描述智慧畜牧系统（App 国际品牌 **BoviScout**，2026-10-21 定名）中各角色从入驻到日常使用的完整旅程链，以及角色间的权限边界。
> **基线**：2026-11-01，按 `master` 代码核实（上一版 2026-09-23，NIX-245 计价对齐）。本次差异主要来自：超管上下文切换（NIX-306）、多标识登录（PR #132）、告警模型 V26 重设计、订阅到期治理（NIX-323/324/325）、网关定位与饮水检测（NIX-219/220、NIX-256）。权限/路由以代码为准；登录认证细节见 [`user-journey-guide.md`](./user-journey-guide.md)（2026-11-01 基线）。

---

## 1. 角色总览

系统定义 **6 种角色**（`Role.java` / 前端 `user_role.dart`，V20261019100000 新增 SUPER_ADMIN），分属三个操作端：

| 角色 | 操作端 | Shell 类型 | 说明 |
|------|--------|-----------|------|
| **SUPER_ADMIN**（超管 root） | `/select-context` 选择角色进入 | 随所选角色 | 平台根账号（无租户归属），经 switch-context 重签 act token 以所选身份进入系统（NIX-306），操作记 `AUTH_CONTEXT_SWITCHED` 审计 |
| **platform_admin**（平台管理员） | 平台后台 `/ops/admin` | 无 Shell，纯 Scaffold | 平台级管理，无租户归属 |
| **b2b_admin**（B端管理员） | B端控制台 `/b2b/admin` | 左侧 NavigationRail | 管理旗下牧场、牧工、合同 |
| **owner**（牧场主） | 移动端 App | 底部导航栏 | 管理牧场全部业务 + 订阅（后台管理入口已移除，见 §5） |
| **worker**（牧工） | 移动端 App | 底部导航栏（4 Tab） | 查看告警、围栏，可关闭（dismiss）与标记已读告警 |
| **api_consumer**（API 开发者） | Open API（`/api/v1/open/**`，API Key） | — | 仅 API 访问，无 App 端 |

---

## 2. 旅程链

### 2.1 平台入驻旅程

```
超管 root 登录（Admin@hkt.com，凭据见 docs/reference/deployment.md）
  → /select-context 选择进入身份（NIX-306；或直接以 platform_admin 账号登录）
  → 创建租户（TenantCreatePage）+ 免费试点授权（统一截止日 2027-09-30，可按租户指定当地日期）
  → 进入租户详情（TenantDetailPage）
  → 新增用户（b2b_admin / owner / worker；默认密码 Default@123，首登强制改密）
  → 管理租户启停、License 调整、租户/牧场时区配置
  → 设备跨租户移交（/admin/devices/transfer，EUI 归属核查 + 审计）
  → 订阅健康总览（到期分组 + 运营动作列，NIX-324/334）+ 数据导出监管（NIX-325）
  → 查看合同管理、对账看板、订阅服务管理
  → /admin/deployment-license 部署授权（NIX-184）
  → 审批 API 授权申请
```

### 2.2 B端管理旅程

```
b2b_admin 登录（自动重定向到 /b2b/admin；到期横幅可"稍后提醒"）
  → 概览看板（B2bDashboardPage）
  → 创建牧场 → 分配给 owner（B2bFarmListPage）
  → 查看合同信息（B2bContractPage）
  → 查看对账 / 分润明细（B2bRevenuePage → RevenueDetailPage）
  → 管理旗下牧工（B2bWorkerManagementPage → WorkerDetailPage）
  → 例外放行：/admin/tiles 瓦片管理、/admin/datagen 仿真控制台
```

### 2.3 牧场主旅程

```
owner 登录（重定向到 /ranch 牧场页；多标识登录：account / email / 手机号 E.164 任一）
  → 牧场总览：GPS 地图、牲畜概览、健康预警、场景卡
  → 告警管理：标记已读 / 关闭告警（dismiss；ACTIVE→DISMISSED，见 §7）
  → 围栏管理：创建 / 编辑 / 删除电子围栏（GPX 导入，NIX-213）
  → 牲畜详情：个体信息、传感器数据、饮水事件（NIX-256）、生理事件流
  → 设备管理：GPS 追踪器、瘤胃胶囊、TB 开通向导、网关位置与覆盖诊断（NIX-219/220）
  → 牧工管理（/mine/workers）：添加 / 移除牧工
  → 订阅：到期横幅（可稍后提醒）+ 导出权卡倒计时（NIX-324/334）
  → 订阅升级（SubscriptionPlanPage → CheckoutPage）
  → 数据统计（StatsPage）
  → 离线地图管理（OfflineTileManagementPage）
  → API 授权管理（MineApiAuthPage）
  ✗ /admin 前缀被守卫重定向回 /ranch（后台管理 Tab 已移除）
```

### 2.4 牧工旅程

```
worker 登录（重定向到 /ranch）
  → 牧场总览：查看地图、牲畜位置
  → 告警：查看 / 标记已读 / 关闭告警（dismiss，后端允许 WORKER）
  → 围栏：仅查看（不可创建/编辑/删除）
  → 网关/覆盖诊断：可查（NIX-219/220）
  → 我的：个人资料、牧场切换
  ✗ 不可访问：后台管理、牧工管理、订阅管理、设备管理
```

---

## 3. 种子数据登录凭据

> 凭据属部署细节，统一见 **`docs/reference/deployment.md`**（本文不再罗列明文）。历史"密码 123"在密码策略（8 位四类，`PasswordPolicy.java`，2026-10-15 裁决）生效后已失效。admin bootstrap 迁移为 `V20260907120000__admin_bootstrap.sql`（原 V4/V16 世代已演进）。

| 角色 | 登录标识 | 关联 | 说明 |
|------|---------|------|------|
| SUPER_ADMIN（超管 root） | 见 deployment.md（V20261019100000 种子 / V20261020100000 改名） | 平台级 | 首登强制改密；经 /select-context 选择身份进入 |
| platform_admin（平台管理员） | 手机号（见 deployment.md） | 平台级管理，无租户归属 | |
| b2b_admin（B端管理员） | 手机号（见 deployment.md） | Demo 租户 B 端管理员 | |
| owner（牧场主） | 手机号（见 deployment.md） | Demo 租户 owner，主牧场 + 南山分场 | |
| worker（牧工） | 手机号（见 deployment.md） | Demo 租户牧工，主牧场 | |

> 登录标识泛化（PR #132）：account / email / 手机号（E.164，兼容存量裸号）任一 + 密码，大小写不敏感。

---

## 4. 路由守卫规则

路由重定向逻辑（`app_router.dart`，按优先级）：

| 优先级 | 条件 | 行为 |
|------|------|------|
| 1 | 未登录 | 所有页面 → `/login` |
| 2 | `mustChangePassword=true` | 锁定 → `/me/password-change`（NIX-191） |
| 3 | 超管 root | → `/select-context`（NIX-306） |
| 4 | platform_admin | 仅允许 `/ops/admin/*` 和 `/admin/*`，其余重定向到 `/ops/admin` |
| 5 | b2b_admin | `/b2b/admin/*` + 例外放行 `/admin/tiles`、`/admin/datagen`，其余重定向 |
| 6 | owner/worker 访问 `/login`、`/ops/admin` | → `/ranch` |
| 7 | **owner/worker 访问 `/admin` 前缀** | → `/ranch`（管理页仅平台管理员可入，owner 后台 Tab 已移除） |
| 8 | 访问 `/mine/workers` 且非 owner | → `/ranch` |

---

## 5. 操作权限矩阵

基于 `RolePermission`（前端按钮）× 后端方法权限三层对照（不一致处标注，详见 `user-journey-guide.md` §4.3/§7）。super_admin 以所选上下文身份生效，不单独设列。

| 操作 | owner | worker | platform_admin | b2b_admin | 后端实际 |
|------|:-----:|:------:|:--------------:|:---------:|---------|
| 创建/编辑/删除围栏 | ✅ | ✗ | ✗ | ✗ | `OWNER\|B2B_ADMIN`（更新端点无注解，见 guide §7.10） |
| 告警标记已读（read/batch-read） | ✅ | ✅ | ✅ | ✅ | 任意登录用户 |
| 关闭告警（dismiss） | ✅ | ✅（前端按钮 owner；后端已放宽） | ✗ | ✅（后端） | `OWNER\|B2B_ADMIN\|WORKER` |
| 管理租户 | ⚠️ 死权限 | ✗ | ✅ | ✗ | 仅 `PLATFORM_ADMIN`（owner 前端授权但无入口，guide §7.3） |
| 创建牧场 | ✅（后端） | ✗ | ✅（前端） | ✅ | `OWNER\|B2B_ADMIN`（前端 canCreateFarm 未含 owner，guide §7.2） |
| 管理订阅 | ✅ | ✗ | ✗ | ✗ | 订阅端走 `/subscription` |
| 查看合同 | ✗ | ✗ | ✗ | ✅ | `requirePlatformAdmin`（平台侧）/ B 端只读 |
| B端看板 | ✗ | ✗ | ✗ | ✅ | `requireB2bAdmin` |
| 管理合同/分润计算 | ✗ | ✗ | ✅ | ✗ | `requirePlatformAdmin` |
| 查看对账 | ✗ | ✗ | ✅ | ✅ | — |
| 管理订阅服务/FeatureGate | ✗ | ✗ | ✅ | ✗ | `requirePlatformAdmin` |
| 审批 API 授权 | ✅ | ✗ | ✅ | ✗ | `requirePlatformAdmin`（平台侧） |
| 管理旗下牧工 | ✅（/mine/workers） | ✗ | ✅ | ✅ | B 端 `requireB2bAdmin` |
| 数智孪生繁育操作 | ✅ | ✗ | ✗ | ✗ | — |
| 设备跨租户移交 | ✗ | ✗ | ✅ | ✗ | `PLATFORM_ADMIN`（`POST /admin/devices/transfer`） |
| 数据导出监管 | ✗ | ✗ | ✅ | ✗ | `PLATFORM_ADMIN`（NIX-325） |

---

## 6. 订阅层级与功能门控

### 6.1 层级定价（NIX-245：USD 按头/月 + 存栏规模分档）

| 层级 | ＜100 头 | 100–499 头 | ≥500 头 | 牲畜上限 |
|------|---------|-----------|---------|---------|
| **basic**（基础版） | 免费（≤50 头） | — | — | 50 |
| **standard**（标准版） | $2.60/头/月 | $2.15/头/月 | $1.40/头/月 | 不限 |
| **premium**（高级版） | $3.20/头/月 | $2.65/头/月 | $1.75/头/月 | 不限 |
| **enterprise**（企业版） | 定制（买断 ≈36 个月订阅价 + 20%/年维保） | | | 不限 |

> 月费 = 存栏头数 × 所在档单价；物联网设备 $65/台一次性客户自购（设备归客户），网关按牧场另报。
>
> **试用与到期**（2026-10 体系）：注册即 14 天 PREMIUM 自助试用；平台发放免费试点**统一截止日 2027-09-30**（`smartlivestock.trial.ends-at` 默认 `2027-09-30T21:00:00Z` = 2027-10-01 肯尼亚 EAT，可按租户指定当地日期）。订阅状态机 7 态（TRIAL/ACTIVE/FREE/SUSPENDED/RENEWAL_FAILED/CANCELLED/EXPIRED，`SubscriptionStatus.java`）；到期降档不拒绝（遥测/Open 端点按降档窗口继续），终止后 30 天保留 GDPR 自助导出权（NIX-325）。

### 6.2 功能门控（Feature Flags）

| 功能 | basic | standard | premium | enterprise |
|------|:-----:|:--------:|:-------:|:----------:|
| GPS 定位 | ✅ | ✅ | ✅ | ✅ |
| 电子围栏 | ≤3 | ≤5 | ≤10 | 不限 |
| 告警历史 | ✗ | ✅ | ✅ | ✅ |
| 历史轨迹 | ✗ | ✅ | ✅ | ✅ |
| 设备管理 | ✅ | ✅ | ✅ | ✅ |
| 数据保留 | 7天 | 30天 | 90天 | 3年 |
| 健康评分 | ✗ | ✗ | ✅ | ✅ |
| 发情检测 | ✗ | ✗ | ✅ | ✅ |
| 疫病预警 | ✗ | ✗ | ✅ | ✅ |
| 步态分析 | ✗ | ✗ | ✗ | ✅ |
| 行为统计 | ✗ | ✗ | ✗ | ✅ |
| API 访问 | ✗ | ✗ | ✗ | ✅ |
| 专属客服 | ✗ | ✗ | ✅ | ✅ |

- 🔒 **lock**：低级 tier 看到升级提示覆盖层
- 📊 **limit**：有数量上限（如围栏 3/5/10/不限）
- 🔄 **filter**：按 tier 过滤数据范围（如数据保留天数）
- ✅ **none**：所有 tier 均可用

> ⚠️ 上表为 2026-09 概览；门控随迁移持续演进——`V11__seed_commerce_data`（初版）→ `V20260923120000__usd_perhead_pricing_gates`（USD 定价门）→ `V20261005110000__seed_drinking_peer_comparison_gate`（饮水同群对照）→ `V20261026000000__seed_telemetry_export_gate`（遥测导出）。逐格值以 feature_gates 迁移种子为准。

### 6.3 设备依赖

部分功能需要特定设备才能激活：

| 功能 | 需要设备 |
|------|---------|
| 围栏、历史轨迹 | GPS 追踪器 |
| 温度监测、蠕动监测 | 瘤胃胶囊 |
| 健康评分、发情检测、疫病预警 | GPS + 瘤胃胶囊 |

---

## 7. 告警状态机（V26 重设计，2026-09）

```
ACTIVE ──手动关闭──→ DISMISSED
ACTIVE ──条件消解──→ AUTO_RESOLVED
```

- 仅 `ACTIVE` 可关闭（dismiss），非法跳转返回 **409 STATE_CONFLICT**；旧 pending→acknowledged→handled→archived 四态模型已废弃，对应端点 `@Deprecated` 保留兼容。
- **已读与状态解耦**：按用户存 `alert_read_status` 表（V26），`POST /alerts/{id}/read`、`/alerts/batch-read` 任意登录用户可调。

| 操作 | 端点 | 允许角色 |
|------|------|---------|
| 标记已读（单条/批量） | `POST /alerts/{id}/read`、`/alerts/batch-read` | 任意登录用户 |
| 关闭告警 | `POST /alerts/{id}/dismiss` | OWNER / B2B_ADMIN / WORKER（`AlertController` @PreAuthorize） |
| ~~acknowledge / handle / archive / batch-handle~~ | `@Deprecated` | 前端批量 dismiss 仍复用 batch-handle（WORKER 调用 403，残留缺口） |

**告警类型**（`AlertType` 枚举 14 值）：FENCE_BREACH / FENCE_APPROACH / ZONE_APPROACH / TEMPERATURE_ABNORMAL / DIGESTIVE_ABNORMAL / ESTRUS / EPIDEMIC / AI_ANOMALY / DEVICE_TAMPER / DEVICE_LOW_BATTERY / DEVICE_OFFLINE / LINK_QUALITY / OUTLIER / RETURN_HOME。

---

## 8. 初始化围栏

> ⚠️ 本节 33 个坐标点被 GPS 质量检验规格引用为 RTK 真值点来源（`docs/superpowers/specs/2026-07-15-gps-quality-check-spec-v2.md` 等），**结构与数值勿改动**。

| 序号 | 纬度 (Latitude)  | 经度 (Longitude)   | 位置                 | 设备EUI          | 设备deviceId        |
| ---- | ---------------- | ------------------ | -------------------- | ---------------- | ------------------- |
| 1    | 28°14′43.40730″N | 112°51′02.81475″ E | 宿舍楼顶             |                  |                     |
| 2    | 28°14′43.92397″N | 112°51′02.81050″ E | 宿舍楼顶             |                  |                     |
| 3    | 28°14′44.10350″N | 112°51′02.00862″ E | 宿舍楼顶             |                  |                     |
| 4    | 28°14′43.62516″N | 112°51′01.86561″ E | 宿舍楼顶             |                  |                     |
| 5    | 28°14′43.46774″N | 112°51′01.68914″ E | 西南门               |                  |                     |
| 6    | 28°14′43.42819″N | 112°51′01.80853″ E | 西南门               |                  |                     |
| 7    | 28°14′42.68079″N | 112°51′04.67962″ E | 东南门               |                  |                     |
| 8    | 28°14′42.63059″N | 112°51′04.91937″ E | 东南门               |                  |                     |
| 9    | 28°14′48.47688″N | 112°51′06.17778″ E | 北门                 |                  |                     |
| 10   | 28°14′48.54796″N | 112°51′05.85638″ E | 北门                 |                  |                     |
| 11   | 28°14′47.73855″N | 112°51′05.79753″ E | 一期楼顶             | 00956906000285d8 | 2075561438264500224 |
| 12   | 28°14′47.51023″N | 112°51′05.73050″ E | 一期楼顶             |                  |                     |
| 13   | 28°14′47.55229″N | 112°51′05.56060″ E | 一期楼顶             |                  |                     |
| 14   | 28°14′47.67833″N | 112°51′05.59481″ E | 一期楼顶             |                  |                     |
| 15   | 28°14′47.76873″N | 112°51′05.67371″ E | 一期楼顶             |                  |                     |
| 16   | 28°14′47.88989″N | 112°51′05.20479″ E | 一期楼顶             | 00956906000285d4 | 2075561685921374208 |
| 17   | 28°14′47.96567″N | 112°51′04.87856″ E | 一期楼顶             |                  |                     |
| 18   | 28°14′47.75944″N | 112°51′04.73250″ E | 一期楼顶             |                  |                     |
| 19   | 28°14′47.60719″N | 112°51′04.65308″ E | 一期楼顶             |                  |                     |
| 20   | 28°14′47.63449″N | 112°51′04.28754″ E | 一期楼顶             | 00956906000289f0 | 207556184203336908  |
| 21   | 28°14′47.68915″N | 112°51′04.11207″ E | 一期楼顶             | 00956906000285b9 | 2075561968718127104 |
| 22   | 28°14′47.72115″N | 112°51′03.91449″ E | 一期楼顶             | 0095690600028ed2 | 2075562094404640768 |
| 23   | 28°14′47.73789″N | 112°51′04.77316″ E | 一期楼顶             |                  |                     |
| 24   | 28°14′47.75124″N | 112°51′03.59608″ E | 一期楼顶             |                  |                     |
| 25   | 28°14′47.77310″N | 112°51′03.47320″ E | 一期楼顶             |                  |                     |
| 26   | 28°14′47.88401″N | 112°51′03.79082″ E | 一期楼顶             |                  |                     |
| 27   | 28°14′48.02445″N | 112°51′03.83982″ E | 一期楼顶             |                  |                     |
| 28   | 28°14′47.83858″N | 112°51′03.96926″ E | 一期楼顶             |                  |                     |
| 29   | 28°14′47.80103″N | 112°51′04.15272″ E | 一期楼顶             |                  |                     |
| 30   | 28°14′47.76269″N | 112°51′04.30171″ E | 一期楼顶             |                  |                     |
| 31   | 28°14′47.62195″N | 112°51′05.02028″ E | 一期电梯楼顶（西中） |                  |                     |
| 32   | 28°14′47.36009″N | 112°51′05.65617″ E | 一期电梯楼顶（东中） |                  |                     |
| 33   | 28°14′47.20097″N | 112°51′05.69850″ E | 一期电梯楼顶（东南） |                  |                     |

---

*客户旅程文档基线：2026-11-01 · 按 `master` 代码核实。上一版 2026-09-23（NIX-245 计价对齐）。*

