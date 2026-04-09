# 智慧畜牧 App 设计规格

> **版本**: v3.0
> **创建日期**: 2026-03-26
> **状态**: 高保真实现已完成（待联调）
> **作者**: Claude + 用户
> **基线**: v2.0（完整设计规格）

---

## 修订记录

| 版本 | 日期 | 修订内容 |
|------|------|----------|
| v3.0 | 2026-03-30 | 整合高保真 UI/UX 实现状态，更新功能模块进度，补充技术架构实现章节，调整版本路线图 |
| v2.0 | 2026-03-26 | 对齐产品设计大纲，全面补充用户角色、功能模块、设备类型、数据模型、非功能需求 |
| v1.0 | 2026-03-26 | 初始设计文档 |

---

## 一、项目概述

### 1.1 产品定位

面向牧场主/养殖户的牛羊智慧管理移动应用，通过 **GPS追踪器、瘤胃胶囊、加速度计** 三类IoT设备，实现牲畜定位管控、健康预警和行为分析。

### 1.2 目标用户

| 部署模式 | 适用场景 | 特点 |
|----------|----------|------|
| 私有化部署 | 大型养殖场 | 数据完全私有，App 只能在此私有环境中使用 |
| 区域云端部署 | 中小型养殖户 | 多租户共享，App 可在区域范围内使用 |

### 1.3 用户角色

| 角色 | 典型用户 | 核心诉求 |
|------|---------|---------|
| 牧场主/养殖户 | 中大型牧场经营者 | 群体概览、异常预警、减少人工巡栏 |
| 兽医/技术员 | 兽医站、畜牧技术员 | 个体健康分析、历史数据追溯 |
| 牧工/放牧员 | 日常放牧人员 | 实时位置查看、围栏告警处理 |
| 平台运维（仅云端） | 区域云运维团队 | 租户开通、运行监控、故障处理 |

### 1.4 核心功能（按优先级）

1. **GPS定位与虚拟围栏（MVP）**：实时定位、电子围栏、越界告警、历史轨迹
2. **租户管理后台最小能力（MVP，云端）**：租户开通/禁用、设备 licenses 配置与用量查看
3. **角色化界面与权限控制（MVP）**：App 根据登录角色展示差异化功能界面
4. **瘤胃健康监测（V1.5）**：温度监测、蠕动监测、健康推测引擎
5. **步态行为分析（V2.0）**：行为分类、时间统计、异常预警、发情检测

### 1.5 系统规模

- 单场典型规模：500 头以下（小型场）
- 定位技术：LoRaWAN 基站 + 低功耗标签
- 多租户规模（区域云端）：支持 50+ 牧场租户并发接入

---

## 二、系统架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        智慧畜牧 App 架构                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │  Flutter    │     │  Flutter    │     │  Flutter    │       │
│  │  iOS App    │     │ Android App │     │   Web App   │       │
│  └──────┬──────┘     └──────┬──────┘     └──────┬──────┘       │
│         │                   │                   │               │
│         └───────────────────┼───────────────────┘               │
│                             │                                   │
│                             ▼                                   │
│                    ┌────────────────┐                          │
│                    │   API Gateway  │                          │
│                    │   (REST/MQTT)  │                          │
│                    └───────┬────────┘                          │
│                            │                                    │
├────────────────────────────┼────────────────────────────────────┤
│                            │                                    │
│                            ▼                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    数据服务层                             │   │
│  │  ┌─────────────────┐      ┌─────────────────┐          │   │
│  │  │    告警引擎      │      │    分析引擎      │          │   │
│  │  │ ·规则引擎       │      │ ·步态分类ML      │          │   │
│  │  │ ·阈值告警       │      │ ·健康预测ML      │          │   │
│  │  │ ·ML异常检测     │      │ ·时序分析        │          │   │
│  │  └─────────────────┘      └─────────────────┘          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                            ▲                                    │
│                            │                                    │
│                    ┌───────┴────────┐                          │
│                    │   IoT 平台      │                          │
│                    │ ·设备管理      │                          │
│                    │ ·数据接入      │                          │
│                    │ ·OTA升级       │                          │
│                    └───────┬────────┘                          │
│                            │                                    │
│                    ┌───────┴────────┐                          │
│                    │ MQTT Broker    │                          │
│                    └───────┬────────┘                          │
│                            │                                    │
│                    ┌───────┴────────┐                          │
│                    │  LoRaWAN 网关   │                          │
│                    └───────┬────────┘                          │
│                            │                                    │
│         ┌──────────────────┼──────────────────┐                │
│         │                  │                  │                │
│    ┌────┴────┐       ┌────┴────┐       ┌────┴────┐            │
│    │GPS追踪器│       │瘤胃胶囊 │       │加速度计 │            │
│    └─────────┘       └─────────┘       └─────────┘            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 技术选型

| 层级 | 技术选型 | 说明 |
|------|----------|------|
| 前端 | Flutter | 跨平台（iOS/Android/Web），单一代码库 |
| 通信协议 | REST API + MQTT | 配置查询用REST，实时告警用MQTT |
| 定位技术 | LoRaWAN 基站 | 牧场内部署，覆盖围栏区域 |
| 数据存储 | TDengine + PostgreSQL | 时序数据+关系数据 |
| 缓存 | Redis | 会话、热点查询缓存、限流计数 |
| 分析引擎 | ML模型服务 | 步态分类、健康预测 |
| 告警引擎 | 规则引擎 + ML | 阈值告警 + 异常检测 |

### 2.3 设备类型

| 设备类型 | 用途 | 部署方式 | 电池寿命 |
|----------|------|----------|----------|
| GPS追踪器 | 定位 + 步态数据采集 | 项圈佩戴 | 1-2年 |
| 瘤胃胶囊 | 温度 + 蠕动监测 | 口服投喂 | 2-3年 |
| 加速度计 | 步态行为分析 | 项圈/耳标集成 | 1-2年 |

### 2.4 关键设计决策

1. **App 层**：Flutter 单一代码库，编译为 iOS/Android/Web
2. **API 网关**：统一入口，处理认证、限流、日志
3. **双协议设计**：REST 用于配置/查询，MQTT 用于实时告警推送
4. **复用现有平台**：LoRaWAN NS、数据存储、IoT平台
5. **ML能力**：分析引擎提供步态分类和健康预测服务

---

## 三、App 模块设计

### 3.1 模块结构

```
┌────────────────────────────────────────────────┐
│                  智慧畜牧 App                    │
├────────────────────────────────────────────────┤
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  首页    │  │  地图    │  │  围栏    │    │
│  │  Dashboard│  │  视图    │  │  管理    │    │
│  └──────────┘  └──────────┘  └──────────┘    │
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  牲畜    │  │  告警    │  │  设备    │    │
│  │  管理    │  │  中心    │  │  管理    │    │
│  └──────────┘  └──────────┘  └──────────┘    │
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  健康    │  │  行为    │  │  我的    │    │
│  │  监测    │  │  分析    │  │  设置    │    │
│  └──────────┘  └──────────┘  └──────────┘    │
│                                                │
└────────────────────────────────────────────────┘
```

### 3.2 模块职责

| 模块 | 功能 | 优先级 | 实现状态 | 适用角色 |
|------|------|--------|---------|----------|
| **首页 Dashboard** | 总览（牲畜数量、告警数、围栏状态、健康概况） | P0 | ✅ 高保真已完成 | 牧场主 |
| **地图视图** | 实时位置显示、设备状态、围栏边界、历史轨迹 | P0 | ✅ 高保真已完成（地图SDK占位） | 牧工/牧场主 |
| **围栏管理** | 创建/编辑/删除虚拟围栏、时间策略配置 | P0 | ✅ 高保真已完成 | 牧场主 |
| **告警中心** | 越界告警、健康预警、行为异常、告警处理流程 | P0 | ✅ 高保真已完成（P0告警类型） | 牧工/牧场主 |
| **牲畜管理** | 牲畜档案、群组管理、健康档案 | P1 | ⚠️ 部分实现（详情页已完成） | 兽医/牧场主 |
| **设备管理** | 设备列表、状态监控、配置管理 | P1 | ⚠️ 部分实现（列表+状态已完成，绑定流程待实现） | 牧场主 |
| **健康监测** | 瘤胃温度、蠕动监测、健康推测引擎 | P1 | ❌ 未实现（占位） | 兽医/牧场主 |
| **行为分析** | 行为时间统计、异常预警、发情检测 | P1 | ❌ 未实现（占位） | 兽医/牧场主 |
| **我的设置** | 用户信息、告警通知配置、多语言 | P1 | ✅ 高保真已完成 | 所有角色 |
| **租户管理后台（云端）** | 租户开通/禁用、设备 licenses 配置与用量监控 | P0（MVP） | ⚠️ 占位完成 | 平台运维 |

> **实现状态说明**: ✅ 已完成 | ⚠️ 部分实现/占位 | ❌ 未实现

### 3.3 数据流

```
[传感器设备] → LoRaWAN → [网关] → MQTT → [IoT平台]
                                                  ↓
                                             [数据服务层]
                                            /        \
                                     [告警引擎]   [分析引擎]
                                            \        /
                                             [API网关]
                                                  ↓
                                         [App / Web端]
```

### 3.4 角色化界面与权限策略（MVP）

**设计原则：**
- 登录成功后由 `/api/me` 返回 `role` 与 `permissions`，前端据此动态构建导航与页面入口
- 前端做“可见性控制”，后端做“强权限校验”；禁止仅依赖前端隐藏功能
- 云端部署中，`平台运维` 仅可访问租户管理后台，不进入牧场业务页面

| 角色 | 默认可见模块 | 受限模块 |
|------|--------------|----------|
| 牧场主/养殖户 | 首页、地图、围栏、告警、牲畜、设备、健康、行为、我的设置 | 租户管理后台 |
| 兽医/技术员 | 首页、牲畜、健康、行为、告警、我的设置 | 围栏管理、设备管理、租户管理后台 |
| 牧工/放牧员 | 地图、告警、我的设置 | 围栏策略编辑、租户管理后台、高级分析 |
| 平台运维（云端） | 租户管理后台、系统监控入口 | 牧场业务数据页面（默认不可见） |

#### 3.4.1 权限模型（角色 -> 权限码）

| 角色 | 核心权限码 |
|------|------------|
| 牧场主/养殖户 | `dashboard:view` `map:view` `fence:manage` `alert:handle` `animal:manage` `device:manage` `health:view` `behavior:view` |
| 兽医/技术员 | `dashboard:view` `animal:view` `health:manage` `behavior:view` `alert:view` |
| 牧工/放牧员 | `map:view` `alert:view` `alert:ack` |
| 平台运维（云端） | `tenant:view` `tenant:create` `tenant:disable` `tenant:enable` `license:view` `license:manage` |

#### 3.4.2 菜单映射（权限码 -> menu_key）

| menu_key | 页面/模块 | 显示条件（任一满足） |
|----------|-----------|----------------------|
| `menu.dashboard` | 首页 Dashboard | `dashboard:view` |
| `menu.map` | 地图视图 | `map:view` |
| `menu.fence` | 围栏管理 | `fence:manage` |
| `menu.alert` | 告警中心 | `alert:view` 或 `alert:handle` |
| `menu.animal` | 牲畜管理 | `animal:view` 或 `animal:manage` |
| `menu.device` | 设备管理 | `device:view` 或 `device:manage` |
| `menu.health` | 健康监测 | `health:view` 或 `health:manage` |
| `menu.behavior` | 行为分析 | `behavior:view` |
| `menu.tenant_admin` | 租户管理后台 | `tenant:view` 或 `tenant:create` 或 `license:manage` |
| `menu.settings` | 我的设置 | 登录用户默认可见 |

#### 3.4.3 API 作用域映射（权限码 -> API scopes）

| API Scope | 对应接口前缀/操作 | 最小权限码 |
|-----------|-------------------|------------|
| `scope.animals.read` | `GET /api/animals*` | `animal:view` |
| `scope.animals.write` | `POST/PUT/DELETE /api/animals*` | `animal:manage` |
| `scope.fences.manage` | `/api/fences*` | `fence:manage` |
| `scope.alerts.read` | `GET /api/alerts*` | `alert:view` |
| `scope.alerts.handle` | `POST /api/alerts/{id}/ack|resolve|archive` | `alert:handle` |
| `scope.health.read` | `/api/health/*` | `health:view` |
| `scope.behavior.read` | `/api/behavior/*` | `behavior:view` |
| `scope.tenants.read` | `GET /api/admin/tenants*` | `tenant:view` |
| `scope.tenants.write` | `POST /api/admin/tenants*` | `tenant:create`/`tenant:disable`/`tenant:enable` |
| `scope.licenses.manage` | `GET/PUT /api/admin/tenants/{tenant_id}/licenses` | `license:view`/`license:manage` |

#### 3.4.4 登录后鉴权流程（最小实现）

1. 用户调用 `/api/auth/login` 获取 `access_token` 与 `refresh_token`
2. App 启动后调用 `/api/me` 获取 `role`、`permissions`、`tenant_id`
3. 前端根据权限表生成菜单（无权限菜单不展示）
4. 页面内按钮级操作（如“禁用租户”“修改 license”）按权限码二次校验
5. 后端对每个 API scope 做强校验，不满足时返回 `403 FORBIDDEN`
6. Token 过期后调用 `/api/auth/refresh`，失败则清空会话并回登录页

#### 3.4.5 错误码约定（权限相关）

| 错误码 | HTTP | 含义 | 前端处理建议 |
|--------|------|------|--------------|
| `AUTH_UNAUTHORIZED` | 401 | 未登录/Token 无效 | 跳转登录页 |
| `AUTH_FORBIDDEN` | 403 | 角色无权访问该资源 | 显示“无权限”页或提示 |
| `TENANT_DISABLED` | 403 | 租户已被禁用 | 提示联系平台运维 |
| `LICENSE_EXCEEDED` | 409 | 设备 license 超限 | 提示升级配额或释放设备 |

---

## 四、功能模块详细设计

### 4.1 模块A：GPS定位与虚拟电子围栏

#### 4.1.1 实时地图

**功能点**：
- 牧群/个体在地图上的实时位置显示
- 物联网设备在线状态指示（在线/离线/低电量）
- 地图图层切换：卫星图、地形图、牧场边界

**数据要求**：
- GPS上报频率：5-15min/次（可配置）
- 位置精度：GPS定位误差5-10m

#### 4.1.2 虚拟电子围栏

**围栏创建**：
- 在地图上手绘多边形围栏（牧场围栏、危险区域围栏）
- 围栏模板：矩形、圆形、沿道路快速创建

**围栏类型**：

| 类型 | 说明 | 典型场景 |
|------|------|----------|
| 进入围栏 | 禁止进入特定区域 | 危险区域、施工区域 |
| 离开围栏 | 禁止离开特定区域 | 牧场边界防盗 |
| 区域限制围栏 | 限定在特定区域内活动 | 放牧区域限定 |

**围栏时间策略**：
- 全天生效
- 特定时段生效（如仅白天放牧时段）

#### 4.1.3 告警与通知

**告警推送**：
- App 推送（必选）
- SMS 短信（可选，需配置）

**告警详情**：
- 越界个体（耳标号、位置）
- 越界时间
- 当前位置（实时）
- 越界围栏（名称、类型）

**告警处理流程**：
```
待处理 → 确认 → 已处理 → 归档
```

**告警统计**：
- 按时间段汇总
- 按围栏汇总
- 按个体汇总

#### 4.1.4 历史轨迹

**功能点**：
- 个体/群体历史轨迹回放
- 时间范围筛选（24h/7d/30d/自定义）
- 轨迹热力图（活动密集区域分析）

---

### 4.2 模块B：瘤胃健康监测

#### 4.2.1 瘤胃温度监测

**数据采集**：
- 采集频率：10-30min/次
- 数据来源：瘤胃胶囊

**温度曲线显示**：
- 实时温度
- 24h趋势图
- 7d趋势图
- 30d趋势图

**温度基线自动学习**：
- 个体正常温度范围（自动计算）
- 群体温度基线对比

**温度异常预警**：

| 异常类型 | 预警含义 | 告警级别 |
|----------|----------|----------|
| 体温升高 | 发热/感染预警 | 红色 |
| 体温骤降 | 休克/应激预警 | 红色 |
| 日间波动异常 | 瘤胃功能障碍 | 黄色 |

#### 4.2.2 瘤胃蠕动监测

**数据采集**：
- 采集频率：10-30min/次
- 数据来源：瘤胃胶囊

**蠕动数据展示**：
- 蠕动次数实时统计
- 蠕动频率趋势图
- 正常范围参考（~1-2次/分钟）

**蠕动异常预警**：

| 异常类型 | 预警含义 | 告警级别 |
|----------|----------|----------|
| 蠕动减少 | 瘤胃迟缓/酸中毒 | 黄色 |
| 蠕动停止 | 瘤胃臌气/梗阻 | 红色 |
| 蠕动亢进 | 疼痛反应 | 黄色 |

#### 4.2.3 健康推测引擎

**多指标融合评分**：
- 温度 + 蠕动 + 采食行为 → 综合健康评分（0-100分）

**疾病风险预测**：

| 风险类型 | 预测依据 |
|----------|----------|
| 瘤胃酸中毒风险 | 蠕动减少 + 温度升高 |
| 真胃移位风险 | 采食减少 + 蠕动异常 |
| 产后瘫痪风险 | 温度异常 + 活动减少 |
| 呼吸系统感染风险 | 温度升高 + 活动减少 |

**健康状态分级**：

| 分级 | 分数范围 | 说明 |
|------|----------|------|
| 正常 | 80-100 | 无异常 |
| 关注 | 60-79 | 需关注 |
| 预警 | 40-59 | 需检查 |
| 紧急 | 0-39 | 需立即处理 |

**预警建议**：
- 关联常见病因
- 建议措施（如联系兽医）

#### 4.2.4 个体健康档案

**档案内容**：
- 每头牲畜的健康时间线
- 历史异常事件记录与处理结果
- 兽医备注与诊断记录

**权限控制**：
- 兽医/技术员：可编辑
- 牧场主：可查看
- 牧工：无权限

---

### 4.3 模块C：步态行为分析

#### 4.3.1 加速度计数据处理

**数据采集**：
- 三轴加速度数据实时采集
- 设备端预处理上传（降低带宽）

**步态分类算法**：

| 行为类型 | 特征模式 |
|----------|----------|
| 站立 | 低频微幅振动 |
| 行走 | 周期性中幅振动 |
| 奔跑 | 高频高幅振动 |
| 卧倒 | 持续低幅水平信号 |
| 采食 | 特征性低头+咀嚼振动模式 |
| 反刍 | 规律性小幅振动+静止 |

#### 4.3.2 行为时间统计

**每日行为时间分布**：
- 饼图/柱状图展示
- 分类：采食时间、反刍时间、站立时间、行走时间、卧倒时间

**行为趋势对比**：
- 日趋势对比
- 周趋势对比
- 月趋势对比

**群体行为对比**：
- Top/Bottom 排名
- 异常个体快速识别

#### 4.3.3 异常行为预警

| 异常行为 | 预警含义 | 告警级别 |
|----------|----------|----------|
| 长时间卧倒 | 跛行/疾病预警 | 红色 |
| 采食时间显著减少 | 食欲减退/口腔疾病 | 黄色 |
| 反刍时间异常 | 消化系统问题 | 黄色 |
| 夜间异常活动 | 应激/发情/疼痛 | 黄色 |

#### 4.3.4 发情检测（增值功能）

**检测逻辑**：
- 活动量骤增 + 休息减少 → 发情预警窗口

**功能输出**：
- 发情状态识别
- 最佳配种时间推荐

---

## 五、数据模型

### 5.1 核心实体关系

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Ranch     │────<│   Animal    │>────│   Device    │
│   (牧场)    │     │   (牲畜)    │     │   (设备)    │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ id          │     │ id          │     │ id          │
│ name        │     │ tag_number  │     │ eui         │
│ location    │     │ species     │     │ type        │
│ owner_id    │     │ gender      │     │ status      │
└─────────────┘     │ birth_date  │     │ battery     │
                    │ weight      │     │ firmware    │
                    │ group_id    │     │ animal_id   │
                    │ ranch_id    │     └─────────────┘
                    └─────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Fence      │────<│ FencePoint  │     │   Alert     │
│  (围栏)     │     │  (围栏点)   │     │   (告警)    │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ id          │     │ id          │     │ id          │
│ name        │     │ fence_id    │     │ type        │
│ type        │     │ latitude    │     │ level       │
│ fence_type  │     │ longitude   │     │ animal_id   │
│ time_policy │     │ sequence    │     │ fence_id    │
│ ranch_id    │     └─────────────┘     │ message     │
│ status      │                         │ status      │
└─────────────┘                         │ created_at  │
                                        └─────────────┘

┌─────────────┐     ┌─────────────┐
│ HealthRecord│     │  Behavior   │
│ (健康档案)  │     │  (行为数据) │
├─────────────┤     ├─────────────┤
│ id          │     │ id          │
│ animal_id   │     │ animal_id   │
│ timestamp   │     │ timestamp   │
│ temperature │     │ behavior    │
│ motility    │     │ duration    │
│ health_score│     │ confidence  │
└─────────────┘     └─────────────┘
```

### 5.2 实体字段详细定义

#### Ranch（牧场）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | 是 | 主键 |
| name | String(100) | 是 | 牧场名称 |
| location | Point | 是 | 牧场中心坐标 |
| owner_id | UUID | 是 | 所有者用户 ID |

#### Animal（牲畜）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | 是 | 主键 |
| tag_number | String(50) | 是 | 耳标号 |
| species | Enum | 是 | 物种：cattle/sheep |
| gender | Enum | 是 | 性别：male/female |
| birth_date | Date | 否 | 出生日期 |
| weight | Decimal | 否 | 体重（kg） |
| group_id | UUID | 否 | 群组归属 |
| ranch_id | UUID | 是 | 所属牧场 |
| tenant_id | UUID | 是（云端） | 多租户隔离标识，私有化可与 ranch_id 一致 |
| gps_device_id | UUID | 否 | GPS追踪器ID |
| rumen_capsule_id | UUID | 否 | 瘤胃胶囊ID |
| capsule_admin_date | Date | 否 | 胶囊投喂日期 |

#### Device（设备）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | 是 | 主键 |
| eui | String(16) | 是 | 设备EUI |
| type | Enum | 是 | 类型：gps/rumen_capsule/accelerometer |
| status | Enum | 是 | 状态：online/offline/low_battery |
| battery | Integer | 否 | 电池电量百分比 |
| firmware | String(20) | 否 | 固件版本 |
| report_interval | Integer | 否 | 上报频率（分钟） |
| animal_id | UUID | 否 | 绑定牲畜 |

#### Fence（围栏）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | 是 | 主键 |
| name | String(100) | 是 | 围栏名称 |
| type | Enum | 是 | 几何类型：circle/polygon |
| fence_type | Enum | 是 | 围栏类型：enter/leave/stay_in |
| time_policy | JSON | 否 | 时间策略：{"mode":"all_day"} 或 {"mode":"scheduled","ranges":[...]} |
| ranch_id | UUID | 是 | 所属牧场 |
| status | Enum | 是 | 状态：active/inactive |

#### Alert（告警）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | 是 | 主键 |
| type | Enum | 是 | 类型：fence/health/behavior |
| level | Enum | 是 | 级别：warning/critical |
| animal_id | UUID | 是 | 关联牲畜 |
| fence_id | UUID | 否 | 关联围栏（越界告警） |
| message | String(500) | 是 | 告警消息 |
| detail | JSON | 否 | 告警详情（位置、指标等） |
| status | Enum | 是 | 状态：pending/acknowledged/resolved/archived |
| created_at | Timestamp | 是 | 创建时间 |
| acknowledged_at | Timestamp | 否 | 确认时间 |
| resolved_at | Timestamp | 否 | 处理完成时间 |
| tenant_id | UUID | 是（云端） | 多租户隔离标识 |

#### HealthRecord（健康档案）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | 是 | 主键 |
| animal_id | UUID | 是 | 关联牲畜 |
| timestamp | Timestamp | 是 | 采集时间 |
| temperature | Decimal | 否 | 瘤胃温度（℃） |
| motility | Integer | 否 | 蠕动次数（次/分钟） |
| health_score | Integer | 否 | 健康评分（0-100） |
| health_level | Enum | 否 | 健康分级：normal/watch/warning/critical |

#### Behavior（行为数据）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | 是 | 主键 |
| animal_id | UUID | 是 | 关联牲畜 |
| timestamp | Timestamp | 是 | 采集时间 |
| behavior | Enum | 是 | 行为类型：stand/walk/run/lie/eat/ruminate |
| duration | Integer | 否 | 持续时间（秒） |
| confidence | Decimal | 否 | 识别置信度（0-1） |

---

## 六、API 接口设计

### 6.1 接口列表

> 统一约定：除登录接口外，所有接口需携带 `Authorization: Bearer <JWT>`；列表接口默认分页（`page`、`page_size`）并支持时间区间筛选。

#### 认证与租户

| 接口 | 方法 | 说明 | 优先级 |
|------|------|------|--------|
| `/api/auth/login` | POST | 用户登录，返回 access/refresh token | P0 |
| `/api/auth/refresh` | POST | 刷新 access token | P0 |
| `/api/me` | GET | 获取当前用户与角色信息 | P0 |
| `/api/tenants/current` | GET | 获取当前租户上下文（云端） | P0 |

#### 租户管理后台（云端，MVP）

| 接口 | 方法 | 说明 | 优先级 |
|------|------|------|--------|
| `/api/admin/tenants` | GET | 获取租户列表（支持状态筛选） | P0 |
| `/api/admin/tenants` | POST | 开通租户（初始化配额与管理员账号） | P0 |
| `/api/admin/tenants/{tenant_id}/disable` | POST | 禁用租户 | P0 |
| `/api/admin/tenants/{tenant_id}/enable` | POST | 启用租户 | P0 |
| `/api/admin/tenants/{tenant_id}/licenses` | PUT | 更新设备 licenses（按设备类型） | P0 |
| `/api/admin/tenants/{tenant_id}/licenses` | GET | 查询设备 licenses 与使用量 | P0 |

#### 牲畜管理

| 接口 | 方法 | 说明 | 优先级 |
|------|------|------|--------|
| `/api/animals` | GET | 获取牲畜列表 | P0 |
| `/api/animals/{id}` | GET | 获取牲畜详情 | P0 |
| `/api/animals/{id}/location` | GET | 获取实时位置 | P0 |
| `/api/animals/{id}/trajectory` | GET | 获取历史轨迹 | P0 |
| `/api/animals/{id}/health` | GET | 获取健康档案 | P1 |
| `/api/animals/{id}/behavior` | GET | 获取行为数据 | P1 |

#### 围栏管理

| 接口 | 方法 | 说明 | 优先级 |
|------|------|------|--------|
| `/api/fences` | GET | 获取围栏列表 | P0 |
| `/api/fences` | POST | 创建围栏 | P0 |
| `/api/fences/{id}` | PUT | 更新围栏 | P0 |
| `/api/fences/{id}` | DELETE | 删除围栏 | P0 |

#### 告警管理

| 接口 | 方法 | 说明 | 优先级 |
|------|------|------|--------|
| `/api/alerts` | GET | 获取告警列表 | P0 |
| `/api/alerts/{id}` | GET | 获取告警详情 | P0 |
| `/api/alerts/{id}/ack` | POST | 确认告警 | P0 |
| `/api/alerts/{id}/resolve` | POST | 处理告警 | P0 |
| `/api/alerts/{id}/archive` | POST | 归档告警 | P0 |
| `/api/alerts/statistics` | GET | 告警统计 | P1 |

#### 设备管理

| 接口 | 方法 | 说明 | 优先级 |
|------|------|------|--------|
| `/api/devices` | GET | 获取设备列表 | P1 |
| `/api/devices/{id}` | GET | 获取设备详情 | P1 |
| `/api/devices/{id}/config` | PUT | 更新设备配置 | P1 |

#### 健康监测

| 接口 | 方法 | 说明 | 优先级 |
|------|------|------|--------|
| `/api/health/temperature/{animal_id}` | GET | 获取温度曲线 | P1 |
| `/api/health/motility/{animal_id}` | GET | 获取蠕动数据 | P1 |
| `/api/health/score/{animal_id}` | GET | 获取健康评分 | P1 |
| `/api/health/prediction/{animal_id}` | GET | 获取疾病风险预测 | P1 |

#### 行为分析

| 接口 | 方法 | 说明 | 优先级 |
|------|------|------|--------|
| `/api/behavior/statistics/{animal_id}` | GET | 获取行为时间统计 | P1 |
| `/api/behavior/trend/{animal_id}` | GET | 获取行为趋势 | P1 |
| `/api/behavior/ranking` | GET | 获取群体行为排名 | P1 |
| `/api/behavior/estrus/{animal_id}` | GET | 获取发情检测 | P1 |

### 6.2 MQTT 主题设计

| 主题 | 方向 | 说明 |
|------|------|------|
| `alerts/{ranch_id}` | 推送 | 围栏告警实时推送 |
| `health/{animal_id}` | 推送 | 健康预警实时推送 |
| `behavior/{animal_id}` | 推送 | 行为异常实时推送 |
| `location/{ranch_id}` | 推送 | 位置更新实时推送 |

**MQTT可靠性约束：**
- QoS：告警主题使用 QoS 1，位置主题可使用 QoS 0
- 重复消息：客户端按 `alert_id` 做幂等去重
- 离线补偿：客户端重连后拉取最近 24h 未处理告警

---

## 六.5 前端技术架构实现（v3.0 新增）

> 记录高保真阶段已完成的前端技术实现，为后续联调和功能扩展提供参考。

### 6.5.1 状态管理

**技术选型**: flutter_riverpod

| Provider 类型 | 用途 | 示例 |
|--------------|------|------|
| `Provider` | 只读依赖注入 | `dashboardRepositoryProvider` |
| `NotifierProvider` | 可变状态管理 | `dashboardControllerProvider` |
| `appModeProvider` | Mock/Live 模式切换 | 基于 `--dart-define=APP_MODE` |

**使用规范**:
- `build()` 中使用 `ref.watch()` 监听状态变化
- 回调中使用 `ref.read()` 单次读取
- 不使用 `setState` 或 `ChangeNotifier`

### 6.5.2 路由管理

**技术选型**: go_router

| 能力 | 实现 |
|------|------|
| 路由定义 | `AppRoute` 增强枚举（path, label, key） |
| 权限守卫 | `app_router.dart` 中 redirect 逻辑 |
| 角色分流 | 登录后按 `DemoRole` 跳转不同入口 |
| Shell 导航 | `DemoShell` 按角色渲染底部导航 |

### 6.5.3 角色权限控制（已实现）

**角色定义**: `enum DemoRole { owner, worker, ops }`

**权限矩阵**（`RolePermission` 静态方法）:

| 权限方法 | owner | worker | ops |
|---------|-------|--------|-----|
| `canEditFence` | ✓ | ✗ | ✗ |
| `canAddFence` | ✓ | ✗ | ✗ |
| `canDeleteFence` | ✓ | ✗ | ✗ |
| `canAcknowledgeAlert` | ✓ | ✓ | ✗ |
| `canHandleAlert` | ✓ | ✗ | ✗ |
| `canArchiveAlert` | ✓ | ✗ | ✗ |
| `canBatchAlerts` | ✓ | ✗ | ✗ |

**导航可见性**:

| 导航项 | owner | worker | ops |
|-------|-------|--------|-----|
| 看板 | ✓ | ✓ | ✗ |
| 地图 | ✓ | ✓ | ✗ |
| 告警 | ✓ | ✓ | ✗ |
| 我的 | ✓ | ✓ | ✗ |
| 围栏 | ✓ | ✓ | ✗ |
| 后台 | ✓ | ✗ | ✗（直达） |

### 6.5.4 Mock/Live 模式切换

```
Page → Controller → Repository ← appModeProvider
                       ↓              ↓
              MockXxxRepository  LiveXxxRepository
              (本地静态数据)     (真实 API 调用)
```

**切换方式**:
```bash
flutter run                           # Mock 模式（默认）
flutter run --dart-define=APP_MODE=live  # Live 模式
```

**Repository Provider 模式**（每个模块遵循相同模式）:
```dart
final xxxRepositoryProvider = Provider<XxxRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock: return const MockXxxRepository();
    case AppMode.live: return const LiveXxxRepository();
  }
});
```

**联调指引**: 页面层不包含数据源分叉判断，联调时仅需替换 Repository 实现。详见 `docs/demo/mock-to-live-switch-guide.md`。

### 6.5.5 ViewState 统一规范

```dart
enum ViewState { normal, loading, empty, error, forbidden, offline }
```

每个页面通过 `StateSwitchBar` 支持演示状态手动切换，生产环境中由 Controller 根据实际数据状态自动切换。

### 6.5.6 测试覆盖

| 测试文件 | 覆盖范围 |
|---------|---------|
| `test/highfi/dashboard_highfi_test.dart` | Dashboard 关键块、指标卡、状态芯片 |
| `test/highfi/map_fence_highfi_test.dart` | 地图工具栏、图层控制、牲畜筛选 |
| `test/highfi/alerts_highfi_test.dart` | P0 告警类型、处理流程 |
| `test/theme/highfi_theme_test.dart` | Material 3 主题令牌 |
| `test/role_visibility_test.dart` | 三角色导航与操作权限边界 |
| `test/app_mode_switch_test.dart` | Mock/Live 切换 |

**运行命令**: `cd mobile_app && flutter test`

---

## 七、非功能需求

### 7.1 性能要求

| 维度 | 要求 |
|------|------|
| 数据上报频率 | GPS: 5-15min/次（可配置）；健康数据: 10-30min/次 |
| App 启动时间 | < 3 秒 |
| 地图加载时间 | < 2 秒 |
| API 响应时间 | < 500ms（P95） |
| 告警端到端时延（设备上报→App可见） | < 60秒（P95） |
| MQTT Broker 处理时延（平台内） | < 1秒（P95） |
| 支持 500 头牲畜同时在线 | 是 |

### 7.2 离线支持

| 层级 | 离线策略 |
|------|----------|
| 设备端 | 缓存数据，网络恢复后补传 |
| App端 | 显示最近同步数据，标记数据时间 |
| 网络恢复 | 自动同步，增量更新 |

### 7.3 多语言支持

| 语言 | 面向市场 | 优先级 |
|------|----------|--------|
| 中文 | 国内市场 | P0 |
| 英文 | 国际市场 | P0 |
| 西班牙语 | 拉美/欧洲市场 | P1 |

### 7.4 数据安全

| 维度 | 要求 |
|------|------|
| 传输加密 | TLS 1.3 |
| 存储加密 | AES-256 |
| 认证方式 | OAuth2.1 + JWT（Access 15min + Refresh 7d） |
| GDPR 合规 | 是 |
| 数据脱敏 | 敏感字段脱敏存储 |
| 租户隔离 | 所有业务表包含 tenant_id，查询强制注入租户条件 |

### 7.5 平台兼容性

| 平台 | 最低版本 |
|------|----------|
| iOS | 18.0+ |
| Android | 6.0+ |
| Web | Chrome 80+, Safari 13+ |

---

## 八、部署方案

### 8.1 部署模式

#### 模式一：私有化部署

```
养殖场自建服务器 → 部署IoT平台 → App 内网/VPN访问
```

- **适用**：大型养殖场
- **特点**：数据完全私有，需自维护
- **网络**：内网或 VPN 访问

#### 模式二：区域云端部署

```
云服务器 → 部署IoT平台 → App 公网访问
```

- **适用**：中小型养殖户
- **特点**：多租户，数据隔离
- **网络**：HTTPS 公网访问

---

## 九、版本规划

### 9.1 版本路线图（v3.0 更新）

| 阶段 | 版本 | 核心功能 | 周期 | 状态 |
|------|------|---------|------|------|
| **高保真 UI** | V3.0 | 高保真设计系统 + Dashboard + Map + Alerts + Fence + 角色权限 + Mock/Live 切换 + 6 类 ViewState | 3 周 | ✅ **已完成** |
| **联调准备** | V3.1 | 真实地图 SDK + 真实后端 API + 数据持久化 | 2 周 | ⏳ 待启动 |
| **功能完善** | V3.2 | 设备绑定流程 + 轨迹回放增强 + 报表导出 | 2 周 | 📅 计划中 |
| **增强功能** | V3.3 | 告警推送通知 + 活动热力图 + 数据分析 | 2 周 | 📅 计划中 |
| **健康监测** | V3.4 | 瘤胃温度/蠕动监测 + 健康评分 + 健康档案 | +3 周 | 📅 计划中 |
| **行为分析** | V3.5 | 步态分析 + 行为统计 + 异常预警 + 发情检测 | +3 周 | 📅 计划中 |
| **商业化** | V4.0 | 多语言(中/英/西) + SaaS 多租户增强 + 数据报表导出 | +2 周 | 📅 计划中 |

### 9.2 V3.0 高保真验收标准（新增）

| 功能 | 验收标准 | 状态 |
|------|----------|------|
| 高保真设计系统 | 颜色/字体/间距令牌完整定义并应用到所有页面 | ✅ 通过 |
| Dashboard | 牧场信息头 + 4 指标卡 + 状态芯片 + 六类 ViewState 切换正常 | ✅ 通过 |
| Map | 工具栏(5 个工具) + 图层控制(4 个图层) + 牲畜筛选 + 时间区间切换 | ✅ 通过 |
| Alerts | P0 告警类型(越界/低电/失联) + 处理流程(确认→处理→归档) + 权限控制 | ✅ 通过 |
| Fence | 围栏模板(矩形/圆形/不规则) + 分组 + 创建/编辑/删除权限控制 | ✅ 通过 |
| 角色权限 | owner/worker/ops 三角色导航和操作权限边界正确 | ✅ 通过 |
| Mock/Live | APP_MODE 切换机制正常，Repository 层正确切换 | ✅ 通过 |
| 测试覆盖 | 关键路径测试通过，角色权限测试通过，`flutter analyze` 无错误 | ✅ 通过 |

### 9.3 后续版本验收标准（调整）

**V3.1 联调准备**：
| 功能 | 验收标准 |
|------|----------|
| 真实地图 SDK | 接入高德/百度/Mapbox，地图渲染正常，围栏绘制正常 |
| 真实后端 API | 所有接口联调通过，Mock/Live 切换无问题 |
| 数据持久化 | 本地缓存正常，离线模式正常 |

**V3.2 功能完善**：
| 功能 | 验收标准 |
|------|----------|
| 设备绑定流程 | 扫码/手动输入 SN，选择牲畜耳标，确认绑定正常 |
| 轨迹回放 | 支持 24h/7d/30d 时间范围，回放流畅 |
| 报表导出 | 支持 CSV/PDF 格式，导出范围选择正常 |

**V3.3 增强功能**：
| 功能 | 验收标准 |
|------|----------|
| 告警推送通知 | FCM/APNs 推送正常，点击跳转正确 |
| 活动热力图 | 热力图渲染正常，数据聚合正确 |
| 数据分析 | 统计分析正常，趋势图正确 |

**V3.4-V3.5（原 V1.5/V2.0 需求）**：保持原设计规格不变。

**V4.0 商业化（原 V2.5）**：

| 功能 | 验收标准 |
|------|----------|
| 配额审计 | 可追踪每次 license 变更的操作者、时间、变更前后值 |
| 账单对接 | 可导出租户月度设备用量用于计费系统 |
| 多语言 | 中/英/西核心页面翻译完整，关键术语统一 |

---

## 十、技术风险

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| LoRaWAN 信号覆盖不足 | 定位不准 | 中 | 现场勘测，合理布站 |
| 标签电池续航 | 数据丢失 | 中 | 选择低功耗标签，定期更换 |
| GPS 定位误差（5-10m） | 误告警 | 高 | 设置围栏缓冲区（10m） |
| 瘤胃胶囊排出 | 健康数据丢失 | 低 | 定期检查，及时补充 |
| ML模型准确率 | 误报/漏报 | 中 | 持续训练优化，阈值可调 |
| 跨平台适配问题 | UI 不一致 | 低 | Flutter 原生渲染，优先测试 |
| 多语言翻译质量 | 用户体验差 | 低 | 专业翻译 + 本地化测试 |
| 地图 SDK 选型与离线支持 | 地图功能受限 | 中 | 评估 Mapbox（离线能力强）/ 高德 / 百度，做好占位回退 |

---

## 十一、后续优化方向

1. **AI 增强**：基于历史数据训练更精准的健康预测模型
2. **离线功能**：缓存地图和围栏数据，支持离线查看
3. **数据分析**：更丰富的报表、趋势分析、决策支持
4. **生态对接**：对接养殖管理ERP、兽医服务平台
5. **硬件扩展**：支持更多类型的传感器设备

---

## 十一.5 高保真实现遗留项与后续任务（v3.0 新增）### 待实现功能优先级（重新规划）

| 优先级 | 功能 | 说明 | 建议阶段 |
|-------|------|------|---------|
| **P0** | 真实地图 SDK | 当前为渐变背景占位 + 列表回退 | V3.1 |
| **P0** | 真实后端 API | 当前全部使用 Mock 数据源 | V3.1 |
| **P0** | 数据持久化 | 当前仅内存状态，无本地缓存 | V3.1 |
| **P1** | 设备绑定流程 | 当前仅有展示和解绑，缺少扫码绑定 | V3.2 |
| **P1** | 轨迹回放 | PRD 原标 P2，但为核心差异化功能，建议提升 | V3.2 |
| **P1** | 报表导出 | 运营需要数据支撑，建议提升到 P1 | V3.2 |
| **P2** | 告警推送通知 | 当前仅 App 内展示，需接入 FCM/APNs | V3.3 |
| **P2** | 活动热力图 | 当前占位，需真实数据分析支撑 | V3.3 |
| **P2** | 批量操作增强 | 告警批量处理已实现，围栏/牲畜批量待补 | V3.3 |
| **P3** | 草场消耗估算 | 依赖数据积累，长期功能 | V4.0 |
| **P3** | 多语言(中/英/西) | 商业化阶段功能 | V4.0 |

### 手工验收待执行

- [ ] 使用 `docs/demo/highfi-review-script.md` 完成 10 分钟演示
- [ ] 记录现场反馈和问题
- [ ] 执行 `flutter analyze` 无错误
- [ ] 执行 `flutter test` 全部通过

---

## 十二、UI/UX 设计规范（MVP）

### 12.1 信息架构与导航（v3.0 更新）

**底部主导航（牧场业务端）** — ✅ 已实现：
- `首页`（Dashboard） — key: `nav-dashboard`
- `地图`（定位与轨迹） — key: `nav-map`
- `告警`（告警列表与处理） — key: `nav-alerts`
- `我的`（设置与账号） — key: `nav-mine`

**二级入口（根据角色显示）**：
- 围栏管理 — key: `nav-fence`（owner/worker 可见）
- 租户管理后台 — key: `nav-admin`（仅 owner 可见）
- 首页快捷入口：`围栏管理`、`牲畜管理`、`设备管理`、`健康监测`、`行为分析`
- 平台运维登录后直达 `租户管理后台`（不显示牧场业务导航，无底部导航栏）

### 12.2 关键页面实现状态（v3.0 更新）

| 页面 | 实现状态 | 关键组件 / Key | 备注 |
|------|---------|----------------|------|
| **登录页** | ✅ 高保真 | `role-owner`/`role-worker`/`role-ops`, `login-submit` | 登录后按角色跳转 |
| **首页** | ✅ 高保真 | `dashboard-farm-header`, `dashboard-metric-*`, `dashboard-quick-fence` | 4 指标卡 + 牧场信息头 |
| **地图页** | ⚠️ 占位+列表 | `map-toolbar-draw-fence`, `map-layer-fence-toggle`, `map-animal-filter` | 工具栏+图层+筛选已完成，地图 SDK 占位 |
| **围栏管理页** | ✅ 高保真 | `fence-template-*`, `fence-group-chip`, 围栏模板(矩形/圆形/不规则) | 模板+分组+列表 |
| **围栏创建页** | ✅ 高保真 | `fence-create-name`, `fence-create-type`, `fence-create-area` | 表单+类型选择+告警设置 |
| **告警中心页** | ✅ 高保真 | `alert-type-fence-breach`, `alert-type-battery-low`, `alert-type-signal-lost` | P0 告警类型 + 处理流程 |
| **牲畜详情页** | ✅ 新增 | `livestock-info-card`, `livestock-device-card`, `livestock-health-card` | 个体信息+设备绑定+健康占位 |
| **设备管理页** | ⚠️ 部分 | `HighfiDeviceTile`, `device-status-*` | 列表+状态已完成，绑定流程待实现 |
| **统计概览页** | ✅ 新增 | `stats-health-card`, `stats-alert-card`, `stats-device-card` | 健康趋势+告警统计+设备在线率 |
| **租户管理后台** | ⚠️ 占位 | `admin-tenant-card`, `admin-license-*` | 开通/禁用/license 调整 UI 占位 |
| **我的页面** | ✅ 高保真 | `mine-profile-card`, `mine-device-entry` | 个人卡片+设备入口 |

### 12.3 角色化界面规则（UI层）

| 角色 | 导航可见项 | 页面内操作控制 |
|------|------------|----------------|
| 牧场主/养殖户 | 首页、地图、告警、我的 + 业务快捷入口 | 可编辑围栏、设备、牲畜 |
| 兽医/技术员 | 首页、告警、我的 + 健康/行为入口 | 不显示围栏编辑和设备配置 |
| 牧工/放牧员 | 地图、告警、我的 | 仅可确认告警，不可改围栏策略 |
| 平台运维 | 租户管理后台 | 可开通/禁用租户、维护 licenses |

### 12.4 交互状态规范

- **加载中**：列表骨架屏 + 地图区域 loading 占位，不使用全屏阻塞超过 2 秒
- **空状态**：给出“当前无数据”与下一步动作（如“去创建围栏”）
- **错误态**：显示错误原因 + 重试按钮；网络错误与权限错误文案分离
- **无权限**：统一无权限页（403）并提供返回首页按钮
- **离线态**：顶部条提示“离线数据”，页面展示最近同步时间

### 12.5 视觉与组件基线（v3.0 高保真实现）

**颜色令牌（`AppColors`）**：

| 类别 | 色值 | 用途 |
|------|------|------|
| Primary | `#2F6B3B` | 牧场主绿，主要按钮、导航高亮 |
| PrimaryDark | `#244F2D` | 深绿变体，按下态 |
| PrimarySoft | `#E3F0E4` | 浅绿背景，选中态 |
| Accent | `#8BA95A` | 草绿强调，趋势正向 |
| Surface | `#F8F6F0` | 米白底色，页面背景 |
| SurfaceAlt | `#FFFFFF` | 纯白卡片 |
| Border | `#D7D2C6` | 沙色边框 |
| Success | `#4C9A5F` | 健康/在线/正常 |
| Warning | `#D28A2D` | 关注/低电/警告 |
| Danger | `#C2564B` | 异常/越界/严重 |
| Info | `#4A7F9D` | 信息/加载中 |

**间距令牌（`AppSpacing`）**：

| 级别 | 值 | 用途 |
|------|-----|------|
| xs | 4 | 紧凑间距 |
| sm | 8 | 标准小间距 |
| md | 12 | 标准间距 |
| lg | 16 | 标准大间距（默认卡片内边距） |
| xl | 24 | 标题间距 |
| xxl | 32 | 区块间距 |

**排版（`AppTypography`）**：基于 Material 3 TextTheme，统一字重与行高。

**组件形态**：
- Card 圆角：16px，阴影 elevation 0.8
- Button 圆角：14px，最小高度 48dp
- Chip 圆角：12px（分类）/ 999px（药丸）
- Input 圆角：14px

**高保真组件库（`features/highfi/widgets/`）**：

| 组件 | 文件 | 功能 | 核心属性 |
|------|------|------|----------|
| `HighfiCard` | `highfi_card.dart` | 通用卡片容器 | `child`, `padding` |
| `HighfiStatTile` | `highfi_stat_tile.dart` | 统计指标卡 | `title`, `value`, `caption`, `trend`, `onTap` |
| `HighfiStatusChip` | `highfi_status_chip.dart` | 状态标签/分类芯片 | `label`, `color`, `icon` + `fromViewState()` 工厂 |
| `HighfiEmptyErrorState` | `highfi_empty_error_state.dart` | 空/错/权限状态占位 | `title`, `description`, `icon`, `actionLabel`, `onAction` |
| `HighfiChartPlaceholder` | `highfi_chart_placeholder.dart` | 柱状图占位 | `title`, `data`, `height` |
| `HighfiDeviceTile` | `highfi_device_tile.dart` | 设备列表项 | `device`, `onUnbind`, `onViewLocation` |

### 12.6 可用性与验收补充（UI维度）

- 首次登录后，菜单渲染时间 < 500ms（本地缓存权限时）
- 各角色误显“无权限菜单”的概率为 0（冒烟测试覆盖）
- 关键流程（登录→查看地图→处理告警）3 步内可完成
- 告警处理按钮（确认/处理/归档）在列表页可直达，不强制多级跳转

### 12.7 设计交付物清单（v3.0 更新）

- 高保真页面：登录、首页、地图、围栏管理、围栏创建、告警中心、牲畜详情、设备管理、统计概览、租户后台、我的（11页）
- 高保真组件库：`HighfiCard`、`HighfiStatTile`、`HighfiStatusChip`、`HighfiEmptyErrorState`、`HighfiChartPlaceholder`、`HighfiDeviceTile`
- 交互状态规范：normal/loading/empty/error/forbidden/offline 六类 ViewState
- 角色菜单矩阵：与 `3.4` 权限模型保持一一对应（自动化测试覆盖）
- 测试文件：`dashboard_highfi_test.dart`、`map_fence_highfi_test.dart`、`alerts_highfi_test.dart`、`highfi_theme_test.dart`、`role_visibility_test.dart`

### 12.8 页面级字段清单（联调版）

> 字段命名遵循后端返回 JSON；时间统一为 ISO8601（UTC）并在前端按本地时区展示；列表默认按 `updated_at` 或 `created_at` 倒序。

#### 12.8.1 登录页（`/login`）

| 字段键 | 展示名称 | 类型/格式 | 来源接口 | 规则 |
|-------|---------|----------|---------|------|
| `username` | 账号 | string | 用户输入 | 必填，去首尾空格 |
| `password` | 密码 | string | 用户输入 | 必填，8-32 位 |
| `deploy_mode` | 部署模式 | enum(private/cloud) | 本地配置 | 仅展示，不可编辑 |
| `login_error_code` | 错误码 | string | `POST /api/auth/login` | 登录失败时展示 |

#### 12.8.2 首页（`/dashboard`）

| 字段键 | 展示名称 | 类型/格式 | 来源接口 | 规则 |
|-------|---------|----------|---------|------|
| `animal_total` | 牲畜总数 | integer | `GET /api/animals?page=1&page_size=1`（总量） | 卡片展示 |
| `device_online` | 在线设备数 | integer | `GET /api/devices` | 仅统计 `status=online` |
| `alert_pending` | 未处理告警数 | integer | `GET /api/alerts?status=pending` | 红色高亮 |
| `health_watch_count` | 健康关注数 | integer | `GET /api/health/score/*` 聚合 | 60-79 分计入 |
| `last_sync_at` | 最近同步时间 | datetime | 本地缓存 + 接口返回头 | 无网时显示 |

#### 12.8.3 地图页（`/map`）

| 字段键 | 展示名称 | 类型/格式 | 来源接口 | 规则 |
|-------|---------|----------|---------|------|
| `animal_id` | 牲畜ID | uuid | `GET /api/animals` | 作为筛选主键 |
| `tag_number` | 耳标号 | string | `GET /api/animals` | 地图点标签 |
| `latitude`/`longitude` | 实时坐标 | decimal(6) | `GET /api/animals/{id}/location` | 坐标非法时不绘制 |
| `device_status` | 设备状态 | enum | `GET /api/devices` | 映射 `StatusTag` |
| `fence_polygons` | 围栏边界 | geojson/polygon[] | `GET /api/fences` | 按状态区分样式 |
| `trajectory_points` | 轨迹点集 | point[] | `GET /api/animals/{id}/trajectory` | 默认最近24h |
| `trajectory_range` | 回放区间 | enum/custom | 用户选择 | 24h/7d/30d/自定义 |

#### 12.8.4 围栏管理页（`/fences`）

| 字段键 | 展示名称 | 类型/格式 | 来源接口 | 规则 |
|-------|---------|----------|---------|------|
| `fence_id` | 围栏ID | uuid | `GET /api/fences` | 隐藏字段 |
| `name` | 围栏名称 | string | `GET/POST/PUT /api/fences` | 必填，2-50 字 |
| `type` | 几何类型 | enum(circle/polygon) | `GET/POST/PUT /api/fences` | 创建后不可改 |
| `fence_type` | 围栏规则 | enum(enter/leave/stay_in) | `GET/POST/PUT /api/fences` | 必填 |
| `time_policy` | 生效策略 | json | `GET/POST/PUT /api/fences` | 支持 all_day/scheduled |
| `status` | 状态 | enum(active/inactive) | `GET/PUT /api/fences/{id}` | 列表可快速切换 |

#### 12.8.5 告警中心页（`/alerts`）

| 字段键 | 展示名称 | 类型/格式 | 来源接口 | 规则 |
|-------|---------|----------|---------|------|
| `alert_id` | 告警ID | uuid | `GET /api/alerts` | 幂等键 |
| `type` | 告警类型 | enum(fence/health/behavior) | `GET /api/alerts` | 图标区分 |
| `level` | 告警等级 | enum(warning/critical) | `GET /api/alerts` | 颜色语义一致 |
| `animal_id`/`tag_number` | 对象 | uuid/string | `GET /api/alerts` + `GET /api/animals/{id}` | 组合展示 |
| `message` | 告警说明 | string | `GET /api/alerts` | 超长两行截断 |
| `status` | 处理状态 | enum(pending/acknowledged/resolved/archived) | `GET /api/alerts` | 支持筛选 |
| `created_at` | 告警时间 | datetime | `GET /api/alerts` | 默认倒序 |

**排序与刷新规则：**
- 默认排序：`created_at desc`
- 自动刷新：30 秒轮询一次；收到 MQTT 新告警时立即插入列表顶部
- 冲突处理：若本地状态与服务端不一致，以服务端状态覆盖

#### 12.8.6 租户管理后台（`/tenant-admin`）

| 字段键 | 展示名称 | 类型/格式 | 来源接口 | 规则 |
|-------|---------|----------|---------|------|
| `tenant_id` | 租户ID | uuid | `GET /api/admin/tenants` | 主键 |
| `tenant_name` | 租户名称 | string | `GET/POST /api/admin/tenants` | 必填，2-100 字 |
| `tenant_status` | 租户状态 | enum(active/disabled) | `GET /api/admin/tenants` | 可禁用/启用 |
| `admin_account` | 管理员账号 | string | `POST /api/admin/tenants` 返回 | 开通后展示一次 |
| `gps_license_total` | GPS License 总量 | integer | `GET /api/admin/tenants/{tenant_id}/licenses` | >=0 |
| `gps_license_used` | GPS License 已用 | integer | 同上 | 只读 |
| `capsule_license_total` | 胶囊 License 总量 | integer | 同上 | >=0 |
| `accel_license_total` | 加速度计 License 总量 | integer | 同上 | >=0 |
| `license_updated_at` | 配额更新时间 | datetime | `GET /api/admin/tenants/{tenant_id}/licenses` | 倒序展示变更历史 |

**校验规则：**
- 提交 licenses 时：`total >= used`，否则返回 `LICENSE_EXCEEDED` 或 `LICENSE_INVALID`
- 禁用租户前需二次确认（弹窗输入租户名）
- 禁用成功后，该租户 Token 在 5 分钟内全部失效

#### 12.8.7 字段格式与展示统一规则

- `uuid`：小写短横线格式，UI 默认不全量展示（显示前8位）
- `datetime`：显示格式 `YYYY-MM-DD HH:mm:ss`（本地时区）
- `decimal`：坐标保留 6 位小数，温度保留 1 位小数
- `enum`：必须映射成中文文案，不直接显示英文原值
- `null`：统一显示 `--`，不得显示 `null/undefined`

### 12.9 接口响应示例 JSON（联调基线）

#### 12.9.1 登录与用户上下文

**`POST /api/auth/login` 成功响应**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "rft_8c8f2f3f3f",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": {
    "user_id": "1f8f2f0a-3c2d-4f7e-a5e0-98cb4b5d3a11",
    "username": "ops_admin",
    "role": "platform_operator",
    "tenant_id": "b3ee2a9f-3f2e-4472-8f16-8f3a7f4c1d22"
  }
}
```

**`GET /api/me` 成功响应**

```json
{
  "user_id": "1f8f2f0a-3c2d-4f7e-a5e0-98cb4b5d3a11",
  "username": "ops_admin",
  "role": "platform_operator",
  "tenant_id": "b3ee2a9f-3f2e-4472-8f16-8f3a7f4c1d22",
  "permissions": [
    "tenant:view",
    "tenant:create",
    "tenant:disable",
    "tenant:enable",
    "license:view",
    "license:manage"
  ]
}
```

#### 12.9.2 首页（Dashboard）

**`GET /api/dashboard/summary` 成功响应（建议聚合接口）**

```json
{
  "animal_total": 428,
  "device_online": 391,
  "alert_pending": 17,
  "health_watch_count": 23,
  "last_sync_at": "2026-03-26T09:12:31Z"
}
```

#### 12.9.3 地图与轨迹

**`GET /api/animals/{id}/location` 成功响应**

```json
{
  "animal_id": "7f4f6f11-99d1-4ab5-b9af-9f0cbb2e0d12",
  "tag_number": "CN-2026-00018",
  "latitude": 31.230416,
  "longitude": 121.473701,
  "device_status": "online",
  "timestamp": "2026-03-26T09:10:00Z"
}
```

**`GET /api/animals/{id}/trajectory?range=24h` 成功响应**

```json
{
  "animal_id": "7f4f6f11-99d1-4ab5-b9af-9f0cbb2e0d12",
  "range": "24h",
  "points": [
    { "latitude": 31.229901, "longitude": 121.472311, "timestamp": "2026-03-26T06:00:00Z" },
    { "latitude": 31.230118, "longitude": 121.472999, "timestamp": "2026-03-26T07:00:00Z" },
    { "latitude": 31.230416, "longitude": 121.473701, "timestamp": "2026-03-26T09:10:00Z" }
  ]
}
```

#### 12.9.4 围栏管理

**`POST /api/fences` 请求示例**

```json
{
  "name": "北区放牧围栏",
  "type": "polygon",
  "fence_type": "stay_in",
  "time_policy": {
    "mode": "scheduled",
    "ranges": [
      { "weekday": [1, 2, 3, 4, 5], "start": "06:00", "end": "18:00" }
    ]
  },
  "points": [
    { "latitude": 31.230111, "longitude": 121.472100, "sequence": 1 },
    { "latitude": 31.231210, "longitude": 121.473120, "sequence": 2 },
    { "latitude": 31.229980, "longitude": 121.474001, "sequence": 3 }
  ]
}
```

**`POST /api/fences` 成功响应**

```json
{
  "id": "d5e0de3e-9623-4f85-a2b5-a2dcdd10c002",
  "name": "北区放牧围栏",
  "type": "polygon",
  "fence_type": "stay_in",
  "status": "active",
  "time_policy": {
    "mode": "scheduled",
    "ranges": [
      { "weekday": [1, 2, 3, 4, 5], "start": "06:00", "end": "18:00" }
    ]
  },
  "created_at": "2026-03-26T09:15:21Z"
}
```

#### 12.9.5 告警中心

**`GET /api/alerts?page=1&page_size=20&status=pending` 成功响应**

```json
{
  "items": [
    {
      "alert_id": "a21f9187-6f30-45e7-a4b4-7f8d3fb2b023",
      "type": "fence",
      "level": "critical",
      "animal_id": "7f4f6f11-99d1-4ab5-b9af-9f0cbb2e0d12",
      "tag_number": "CN-2026-00018",
      "message": "个体越界：已离开北区放牧围栏",
      "status": "pending",
      "created_at": "2026-03-26T09:20:03Z"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 17
  }
}
```

**`POST /api/alerts/{id}/ack` 成功响应**

```json
{
  "alert_id": "a21f9187-6f30-45e7-a4b4-7f8d3fb2b023",
  "status": "acknowledged",
  "acknowledged_at": "2026-03-26T09:21:18Z"
}
```

#### 12.9.6 租户管理后台

**`GET /api/admin/tenants` 成功响应**

```json
{
  "items": [
    {
      "tenant_id": "b3ee2a9f-3f2e-4472-8f16-8f3a7f4c1d22",
      "tenant_name": "华东示范牧场",
      "tenant_status": "active",
      "created_at": "2026-03-01T03:02:11Z"
    }
  ],
  "pagination": { "page": 1, "page_size": 20, "total": 56 }
}
```

**`PUT /api/admin/tenants/{tenant_id}/licenses` 请求示例**

```json
{
  "gps_license_total": 500,
  "capsule_license_total": 300,
  "accel_license_total": 500,
  "reason": "新增牧场设备扩容"
}
```

**`GET /api/admin/tenants/{tenant_id}/licenses` 成功响应**

```json
{
  "tenant_id": "b3ee2a9f-3f2e-4472-8f16-8f3a7f4c1d22",
  "gps_license_total": 500,
  "gps_license_used": 428,
  "capsule_license_total": 300,
  "capsule_license_used": 201,
  "accel_license_total": 500,
  "accel_license_used": 391,
  "license_updated_at": "2026-03-26T09:28:40Z"
}
```

#### 12.9.7 标准错误响应

**401 未登录或 Token 无效（`AUTH_UNAUTHORIZED`）**

```json
{
  "code": "AUTH_UNAUTHORIZED",
  "message": "登录状态失效，请重新登录",
  "request_id": "req_01hrzq9m3r"
}
```

**403 无权限（`AUTH_FORBIDDEN`）**

```json
{
  "code": "AUTH_FORBIDDEN",
  "message": "当前账号无权执行该操作",
  "request_id": "req_01hrzq9p7t"
}
```

**403 租户禁用（`TENANT_DISABLED`）**

```json
{
  "code": "TENANT_DISABLED",
  "message": "当前租户已被禁用，请联系平台运维",
  "request_id": "req_01hrzq9w99"
}
```

**409 配额超限（`LICENSE_EXCEEDED`）**

```json
{
  "code": "LICENSE_EXCEEDED",
  "message": "GPS 设备 license 已达上限（500）",
  "detail": {
    "license_type": "gps",
    "total": 500,
    "used": 500
  },
  "request_id": "req_01hrzqa14d"
}
```

### 12.10 客户需求确认用低保真方案（C 压缩版）

> 目标：在 24 小时内交付可点击 Flutter 低保真 Demo，用于客户确认需求边界，不接真实接口。

#### 12.10.1 信息架构与演示策略

- **导航结构**：
  - 牧场业务端：`首页` / `地图` / `告警` / `我的`
  - 平台运维端：独立 `租户管理后台`（不显示牧场业务导航）
- **角色入口策略（演示开关）**：
  - 登录页提供角色切换：`牧场主` / `牧工` / `平台运维`
  - 登录后按角色跳转并控制菜单可见项，用于现场确认权限边界
- **全局状态承载方式**：
  - 每个核心页面提供状态切换入口：`正常` / `加载` / `空` / `错误` / `无权限` / `离线`
  - 状态切换仅替换页面主体区域，顶部与导航保持稳定，保证演示连贯
- **演示时长目标**：10 分钟内完成“功能入口 + 流程 + 权限 + 异常状态”确认

#### 12.10.2 页面范围与关键交互（Flutter 低保真）

| 页面 | 关键展示 | 关键动作 | 权限差异（演示重点） |
|------|----------|----------|----------------------|
| 登录页 | 账号、密码、部署模式、角色切换 | 登录、失败文案反馈 | 不同角色登录后跳转不同入口 |
| 首页 | 4 张指标卡 + 最近同步时间 | 指标卡下钻到地图/告警/健康 | 牧工仅显示允许操作入口 |
| 地图页 | 实时点位、围栏边界、设备图例 | 个体筛选、时间区间切换、轨迹回放 | 统一可见，操作权限按角色限制 |
| 围栏管理页 | 围栏列表、状态、生效策略 | 新增/编辑/删除围栏 | 牧场主可编辑，牧工隐藏编辑操作 |
| 告警中心页 | 等级、对象、时间、状态、筛选条 | 确认->处理->归档、批量处理 | 牧工仅“确认”，不可“处理/归档” |
| 租户管理后台 | 租户状态、license 总量/已用/剩余 | 开通、禁用/启用、调整 licenses | 仅平台运维可见 |

#### 12.10.3 客户评审关键流程（10 分钟脚本）

1. **登录与角色分流（1 分钟）**
   - 目标：确认角色菜单与入口是否符合客户组织分工
2. **地图查看与轨迹回放（3 分钟）**
   - 目标：确认地图信息密度、回放区间是否满足日常管理
3. **告警处理闭环（3 分钟）**
   - 目标：确认“确认->处理->归档”流程是否合理，是否需补充状态（如误报）
4. **围栏与租户管理（3 分钟）**
   - 目标：确认配置权限归属与租户侧管理边界

#### 12.10.4 评审输出模板（会后冻结范围）

- **保留项**：页面与流程无需调整的内容
- **修改项**：字段、按钮、顺序、权限差异调整
- **新增项**：当前缺失但必须纳入 MVP 的场景
- **冻结项**：客户确认后不再反复变更的 MVP 范围

本次低保真 Demo 的 **运行方式、交付物与变更记录** 以工程目录为准：`mobile_app/`、`docs/demo/change-log.md`。

#### 12.10.5 Demo 与 MVP 边界及后续 ToDo

当前可点击 Demo 使用 **`DemoShell` + 本地假数据** 验证信息架构、流程与角色可见性，**不替代**上线版路由、深链接与以接口为准的权限模型。实现计划在某一阶段可**不必再改 Shell**（例如仅补充页面内流程），仅表示**该阶段任务已在现有外壳内完成**，**不表示** Shell 与权限已终态化。

**从 Demo 走向可联调 / MVP 时，必须在工程上逐项落实的欠账**（含命名路由、`/api/me` 与菜单对齐、`DemoShell` 职责拆分、状态管理与真地图等）已单列维护，避免与「演示够用」混淆：

- 详见：`docs/demo/post-lowfi-follow-ups.md`

#### 12.10.6 Demo 交付物与使用方式

| 交付物 | 路径 | 说明 |
|--------|------|------|
| 可运行 Flutter Demo | `mobile_app/` | 入口：`lib/main.dart` → `DemoApp` → `DemoShell`；先登录页选择 **worker / owner / ops** 再进入业务或后台 |
| 自动化测试 | `mobile_app/test/` | `widget_smoke_test.dart`、`role_visibility_test.dart`、`flow_smoke_test.dart`；验证导航、权限与演示流程 |
| 客户评审脚本 | `docs/demo/lowfi-client-review-script.md` | 约 10 分钟现场流程、六类状态演示说明、**保留项 / 修改项 / 新增项 / 冻结项** 模板 |
| 验收确认单（模板） | `docs/demo/acceptance-checklist.md` | 演示后手工勾选与结论 |
| 变更追溯 | `docs/demo/change-log.md` | Demo 迭代与规格回填记录 |
| Demo→MVP 欠账 | `docs/demo/post-lowfi-follow-ups.md` | Shell、命名路由、接口权限等与终态差异 |

**本地运行（开发机）**：

```bash
cd mobile_app && flutter pub get && flutter run
```

**质量自检（可选）**：

```bash
cd mobile_app && flutter analyze && flutter test
```

---

## 附录A：术语表

| 术语 | 说明 |
|------|------|
| LoRaWAN | 远距离低功耗广域网协议 |
| MQTT | 轻量级消息传输协议 |
| 瘤胃胶囊 | 口服式瘤胃温度/蠕动监测设备 |
| TDengine | 时序数据库 |
| GDPR | 欧盟通用数据保护条例 |
| OTA | 空中升级（Over-The-Air） |

---

## 附录B：参考文档

- 低保真 Demo 客户评审脚本：`docs/demo/lowfi-client-review-script.md`
- 低保真 Demo 验收确认单（模板）：`docs/demo/acceptance-checklist.md`
- 低保真 Demo 之后（Shell / 路由 / 权限）ToDo：`docs/demo/post-lowfi-follow-ups.md`
- 产品设计大纲：`docs/智慧畜牧App-产品设计大纲.md`
- 智能体系统架构：`智能体系统总体架构设计-v5.1.md`
- LoRaWAN NS解码器：`NS对接样例/`
