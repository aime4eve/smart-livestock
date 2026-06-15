# 客户旅程文档（Customer Journey）

> 本文档描述智慧畜牧系统中各角色从入驻到日常使用的完整旅程链，以及角色间的权限边界。

---

## 1. 角色总览

系统定义 5 种角色，分属三个操作端：

| 角色 | 操作端 | Shell 类型 | 说明 |
|------|--------|-----------|------|
| **platform_admin**（平台管理员） | 平台后台 `/ops/admin` | 无 Shell，纯 Scaffold | 平台级管理，无租户归属 |
| **b2b_admin**（B端管理员） | B端控制台 `/b2b/admin` | 左侧 NavigationRail | 管理旗下牧场、牧工、合同 |
| **owner**（牧场主） | 移动端 App | 底部导航栏（4-5 Tab） | 管理牧场全部业务 + 后台 + 订阅 |
| **worker**（牧工） | 移动端 App | 底部导航栏（4 Tab） | 查看告警、围栏，仅确认告警 |
| **api_consumer**（API 开发者） | 开发者门户（Phase 2c 规划中） | — | 仅 API 访问，无 App 端 |

---

## 2. 旅程链

### 2.1 平台入驻旅程

```
platform_admin 登录
  → 创建租户（TenantCreatePage）
  → 进入租户详情（TenantDetailPage）
  → 新增用户（b2b_admin / owner / worker）
  → 管理租户启停、License 调整
  → 查看合同管理、对账看板、订阅服务管理
  → 审批 API 授权申请
```

### 2.2 B端管理旅程

```
b2b_admin 登录（自动重定向到 /b2b/admin）
  → 概览看板（B2bDashboardPage）
  → 创建牧场 → 分配给 owner（B2bFarmListPage）
  → 查看合同信息（B2bContractPage）
  → 查看对账 / 分润明细（B2bRevenuePage → RevenueDetailPage）
  → 管理旗下牧工（B2bWorkerManagementPage → WorkerDetailPage）
```

### 2.3 牧场主旅程

```
owner 登录（重定向到 /twin 数智孪生页）
  → 数智孪生：GPS 地图、牲畜概览、健康预警
  → 告警管理：查看 / 确认 / 处理 / 归档告警
  → 围栏管理：创建 / 编辑 / 删除电子围栏
  → 牲畜详情：个体信息、传感器数据
  → 设备管理：GPS 追踪器、瘤胃胶囊
  → 后台管理（/admin Tab）：租户信息、订阅管理
  → 牧工管理（/mine/workers）：添加 / 移除牧工
  → 订阅升级（SubscriptionPlanPage → CheckoutPage）
  → 数据统计（StatsPage）
  → 离线地图管理（OfflineTileManagementPage）
  → API 授权管理（MineApiAuthPage）
```

### 2.4 牧工旅程

```
worker 登录（重定向到 /twin）
  → 数智孪生：查看地图、牲畜位置
  → 告警：查看 / 确认告警（不可处理/归档）
  → 围栏：仅查看（不可创建/编辑/删除）
  → 我的：个人资料、牧场切换
  ✗ 不可访问：后台管理、牧工管理、订阅管理、设备管理
```

---

## 3. 种子数据登录凭据

> 所有账号密码均为 `123`（后端 BCrypt 哈希，详见 `smart-livestock-server` 的 Flyway 迁移 V4 / V16）。

| 角色 | 手机号 | 密码 | 关联 |
|------|--------|------|------|
| platform_admin（平台管理员） | 13800000000 | 123 | 平台级管理，无租户归属 |
| b2b_admin（B端管理员） | 13900139000 | 123 | Demo 租户 B 端管理员 |
| owner（牧场主） | 13800138000 | 123 | Demo 租户 owner，主牧场 + 南山分场 |
| worker（牧工） | 13800138001 | 123 | Demo 租户牧工，主牧场 |

---

## 4. 路由守卫规则

路由重定向逻辑（`app_router.dart`）：

| 条件 | 行为 |
|------|------|
| 未登录 | 所有页面 → `/login` |
| platform_admin | 仅允许 `/ops/admin/*` 和 `/admin/*`，其余重定向到 `/ops/admin` |
| b2b_admin | 仅允许 `/b2b/admin/*`，其余重定向到 `/b2b/admin` |
| owner | 允许所有 App 页面 + `/admin` + `/mine/workers` |
| worker | 允许 App 页面，拒绝 `/admin`、`/mine/workers`（重定向到 `/twin`） |

---

## 5. 操作权限矩阵

基于 `RolePermission` 定义：

| 操作 | owner | worker | platform_admin | b2b_admin |
|------|:-----:|:------:|:--------------:|:---------:|
| 创建/编辑/删除围栏 | ✅ | ✗ | ✗ | ✗ |
| 确认告警 | ✅ | ✅ | ✗ | ✗ |
| 处理/归档/批量告警 | ✅ | ✗ | ✗ | ✗ |
| 管理租户 | ✅ | ✗ | ✅ | ✗ |
| 创建牧场 | ✅ | ✗ | ✗ | ✗ |
| 管理订阅 | ✅ | ✗ | ✗ | ✗ |
| 查看合同 | ✗ | ✗ | ✗ | ✅ |
| B端看板 | ✗ | ✗ | ✗ | ✅ |
| 管理合同/分润计算 | ✗ | ✗ | ✅ | ✗ |
| 查看对账 | ✗ | ✗ | ✅ | ✅ |
| 管理订阅服务 | ✗ | ✗ | ✅ | ✗ |
| 审批 API 授权 | ✅ | ✅ | ✅ | ✅ |
| 管理旗下牧工 | ✗ | ✗ | ✗ | ✅ |
| 数智孪生繁育操作 | ✅ | ✗ | ✗ | ✗ |

---

## 6. 订阅层级与功能门控

### 6.1 层级定价

| 层级 | 月费 | 牲畜上限 | 超额单价 |
|------|------|---------|---------|
| **basic**（基础版） | 免费 | 50 | ¥3/头 |
| **standard**（标准版） | ¥299 | 200 | ¥2/头 |
| **premium**（高级版） | ¥699 | 1,000 | ¥1/头 |
| **enterprise**（企业版） | 定制 | 不限 | — |

### 6.2 功能门控（Feature Flags）

| 功能 | basic | standard | premium | enterprise |
|------|:-----:|:--------:|:-------:|:----------:|
| GPS 定位 | ✅ | ✅ | ✅ | ✅ |
| 电子围栏 | ≤3 | ≤5 | ≤10 | 不限 |
| 告警历史 | ✗ | ✅ | ✅ | ✅ |
| 历史轨迹 | ✗ | ✅ | ✅ | ✅ |
| 设备管理 | ✅ | ✅ | ✅ | ✅ |
| 数据保留 | 7天 | 30天 | 365天 | 3年 |
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

### 6.3 设备依赖

部分功能需要特定设备才能激活：

| 功能 | 需要设备 |
|------|---------|
| 围栏、历史轨迹 | GPS 追踪器 |
| 温度监测、蠕动监测 | 瘤胃胶囊 |
| 健康评分、发情检测、疫病预警 | GPS + 瘤胃胶囊 |

---

## 7. 告警状态机

```
pending → acknowledged → handled → archived
```

| 转换 | 允许角色 |
|------|---------|
| pending → acknowledged（确认） | owner, worker |
| acknowledged → handled（处理） | owner |
| handled → archived（归档） | owner |
| 非法跳转 | 返回 409 Conflict |

---
