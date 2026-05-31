# 智慧畜牧前端功能清单

> 基于 Mobile/mobile_app 代码分析，更新时间 2026-05-31

## 一、全局基础设施

| 能力 | 说明 |
|------|------|
| **JWT 认证** | 手机号 + 密码登录，对接 Spring Boot 后端 JWT |
| **多角色系统** | 5 种角色：owner、worker、platform_admin、b2b_admin、api_consumer |
| **角色路由守卫** | 未登录→/login，platform_admin→/ops/admin，b2b_admin→/b2b/admin，其余→/twin |
| **多牧场切换** | FarmSwitcher 组件，owner/worker 可在关联牧场间切换 |
| **订阅与功能门控** | 4 级订阅 tier（basic/standard/premium/enterprise），23 个 FeatureFlag 控制功能可见性 |
| **过期提示** | 订阅到期前弹窗提醒（ExpiryPopupHandler） |
| **Material 3 主题** | 统一 token（AppColors/AppSpacing/AppTypography），Roboto + NotoSansSC 本地字体 |
| **离线模式** | 离线围栏缓存 + 离线牲畜位置缓存 + 离线瓦片管理 |
| **地图三级瓦片降级** | tileserver-gl → MBTiles → 高德/OSM，健康检测自动切换 |
| **坐标转换** | WGS-84 ↔ GCJ-02（使用高德降级时自动转换） |
| **状态管理** | flutter_riverpod，ConsumerWidget，ViewState（normal/loading/empty/error/forbidden/offline） |
| **路由** | go_router，46 条路由（AppRoute 枚举为唯一来源） |
| **跨平台** | iOS / Android / Web |

---

## 二、角色 Shell

| 角色 | Shell 类型 | 导航结构 |
|------|-----------|---------|
| **owner（牧场主）** | 底部导航栏（5 Tab） | 孪生 / 围栏 / 告警 / 我的 / 后台 |
| **worker（牧工）** | 底部导航栏（4 Tab） | 孪生 / 围栏 / 告警 / 我的 |
| **platform_admin（平台管理员）** | 无 Shell，纯 Scaffold | 租户管理全屏 |
| **b2b_admin（B端管理员）** | 左侧 NavigationRail（5 项） | 概览 / 牧场 / 合同 / 对账 / 牧工管理 |

---

## 三、功能模块清单（29 个模块）

### 3.1 认证与账户

#### 🔐 登录（auth）
- 手机号 + 密码表单登录
- 11 位手机号格式校验
- JWT token 存储与会话管理
- 登录失败 SnackBar 提示
- SessionController 管理登录状态

#### 👤 我的（mine）
- 个人信息展示（姓名、手机号、角色、账户状态）
- 设备管理入口
- 离线地图管理入口
- 帮助与支持（占位）
- owner 专属：
  - 订阅状态卡片（SubscriptionStatusCard）
  - 订阅管理入口→套餐选择
  - 牧工管理入口
  - API 授权管理入口

---

### 3.2 数智孪生（Twin Overview）

#### 📊 数智孪生首页（twin_overview）
- 看板指标卡片（从后端 Dashboard API 加载）
- 牧场实时概览
- 健康场景导航（4 个入口卡片）：
  - 发热预警
  - 消化管理
  - 发情识别
  - 疫病防控

#### 🌡️ 发热预警（fever_warning）
- 发热牲畜列表（FeverListItem，含体温、增量、状态）
- 状态分级：CRITICAL / FEVER / ELEVATED / 正常
- 下拉刷新
- 点击→发热详情页（fever_detail_page）

#### 🌡️ 发热详情（fever_detail_page）
- 单头牲畜体温异常详情
- 体温趋势图（占位）

#### 🔬 消化管理（digestive）
- 瘤胃蠕动分析列表
- 消化详情页（digestive_detail_page）

#### 💗 发情识别（estrus）
- 行为评分与配种建议列表
- 发情详情页（estrus_detail_page）

#### 🛡️ 疫病防控（epidemic）
- 群体健康监控概览

---

### 3.3 牲畜管理

#### 🐄 牲畜详情（livestock_detail）
- 基本信息（耳标号、品种、月龄、体重）
- 健康状态标签（健康/关注/异常）
- 绑定设备列表（GPS追踪器、瘤胃胶囊、加速度计）
- 健康数据（体温、活动量、反刍频率）
- 体温趋势图（占位）
- 位置信息 + 查看完整轨迹入口

---

### 3.4 围栏管理

#### 🗺️ 围栏地图页（fence）
- **地图展示**：flutter_map + SmartTileProvider 三级降级
- **围栏浏览**：多边形渲染、呼吸动画高亮选中围栏
- **围栏列表抽屉**：左侧滑出面板，展示牧场围栏列表
- **围栏命中检测**：两级优先级（优先选中围栏 > 包含点围栏，距离排序）
- **候选围栏选择**：多处边界命中时弹出 BottomSheet 让用户选择
- **围栏编辑**（owner 专属）：
  - 顶点移动（moveVertex）
  - 顶点插入（insertVertex，点击边中点）
  - 顶点删除（deleteVertex，最少保留 3 点）
  - 整体平移（translate，拖拽多边形内部）
  - 撤销/重做（undo/redo）
  - 未保存提示对话框
  - 保存调用后端 PUT /fences/:id
- **围栏新建**：跳转 fence_form_page
- **围栏删除**：确认对话框 + 调用后端 DELETE /fences/:id
- **围栏名称标记**：地图上显示围栏名称 Chip
- **多触点防护**：编辑模式下阻止多点触控误操作
- **围栏统计**（fence_analytics）
- **围栏冲突解决**（fence_conflict_page）：离线编辑冲突时展示本地/服务器版本选择

#### 📝 围栏表单页（fence_form_page）
- 新建/编辑围栏信息

---

### 3.5 告警管理

#### 🔔 告警中心（alerts）
- P0 告警展示（围栏越界、设备低电、信号丢失）
- 告警类型筛选 Chips
- 告警状态机：pending → acknowledged → handled → archived
- **按角色权限操作**：
  - worker：仅可确认（acknowledge）
  - owner：确认 + 处理（handle）+ 归档（archive）+ 批量处理
- 告警刷新
- 告警详情行（含耳标、围栏名、距离等信息）

---

### 3.6 设备管理

#### 📱 设备管理（devices）
- 设备概览卡片（总数/在线/离线/低电）
- 设备列表（HighfiDeviceTile）
- **设备安装到牲畜**：弹出对话框选择目标牲畜，调用 POST /installations
- 解绑设备（演示占位）
- 查看位置（演示占位）
- 添加新设备 FAB（演示占位）

---

### 3.7 数据统计

#### 📈 数据统计（stats）
- 统计数据展示

---

### 3.8 订阅与商业化

#### 💳 订阅管理（subscription）
- **套餐选择页**（subscription_plan_page）：4 个 tier 卡片（基础版/标准版/高级版/企业版）
  - 显示当前订阅状态
  - 功能对比表（FeatureComparisonTable）
  - 选择→跳转支付确认页
- **支付确认页**（subscription_checkout_page）：传入 tier + livestockCount
- **订阅状态卡片**（SubscriptionStatusCard）：当前 tier、到期天数、用量进度条
- **升级提示覆盖层**（LockedOverlay）：锁定功能点击时展示升级引导
- **续费横幅**（SubscriptionRenewalBanner）：快到期时提醒

---

### 3.9 平台管理（platform_admin 专属）

#### 🏢 租户管理（tenant）
- **租户列表页**（tenant_list_page）：分页浏览所有租户
- **租户创建页**（tenant_create_page）：新租户注册
- **租户详情页**（tenant_detail_page）：
  - 租户基本信息
  - 关联用户列表（含创建用户功能）
  - 用户启停操作
  - License 调整对话框（license_adjust_dialog）
  - 租户编辑（tenant_edit_page）
  - 租户删除确认（tenant_delete_dialog）
  - 租户趋势图（tenant_trend_chart）
  - 租户骨架屏加载（tenant_skeleton）
- **租户卡片**（tenant_card）

#### 📋 合同管理（admin/contracts_page）
- 平台级合同 CRUD

#### 💰 对账看板（admin/revenue_page）
- 平台级分润对账

#### 📦 订阅服务管理（admin/subscriptions_page）
- 平台级订阅服务管理

#### 🔑 API 授权管理（admin/api_auth_page）
- 平台级 API Key 审批

---

### 3.10 B端管理（b2b_admin 专属）

#### 📊 B端控制台（b2b_admin）
- **B端概览仪表板**（b2b_dashboard_page）：合同状态、统计数据
- **牧场管理**（b2b_farm_list_page）：旗下牧场列表
- **合同信息**（b2b_contract_page）：当前合同详情
- **对账**（b2b_revenue_page）：分润对账概览
- **对账详情**（b2b_revenue_detail_page）：单期对账明细
- **牧工管理**（worker_management_page）：旗下牧场牧工列表
- **牧工详情**（b2b_worker_detail_page）：单牧场牧工管理

---

### 3.11 Owner 后台（admin_page）

- **概览 Tab**：租户数/用户数/牧场数统计
- **租户管理 Tab**：租户列表 + 刷新

---

### 3.12 牧场创建

#### 🌾 创建牧场向导（farm_creation）
- **步骤 1**：基本信息填写（wizard_step_basic_info）
- **步骤 2**：围栏绘制（wizard_step_fence_drawing）
- **步骤 3**：创建完成（wizard_step_complete）
- 步骤间可前进/退出，退出确认对话框

---

### 3.13 牧工管理

#### 👥 牧工列表（worker_management）
- owner 视角：当前牧场牧工列表
- 牧场切换自动重新加载
- 牧工信息卡片

---

### 3.14 离线模块

#### 📴 离线围栏（offline_fences）
- 围栏本地缓存（fence_sync_service）
- 离线编辑支持
- 同步冲突解决页面（fence_conflict_page）
- 离线编辑横幅提示（offline_edit_banner）

#### 📴 离线牲畜位置（offline_livestock）
- 牲畜位置本地缓存（livestock_position_cache）

#### 📴 离线瓦片管理（offline_tiles）
- 离线瓦片存储状态展示
- 已用存储空间统计
- 区域下载状态列表（ready/downloading）
- OfflineTileManager 管理 MBTiles 数据

---

### 3.15 合同管理

#### 📄 合同管理（contract_management）
- 合同 CRUD Repository + Controller

---

### 3.16 对账分润

#### 💵 对账分润（revenue）
- 分润数据 Repository + Controller
- B端对账 Controller（b2b_revenue_controller）

---

### 3.17 API 授权

#### 🔐 API 授权管理（api_authorization）
- API Key 列表展示
- Key 状态（active/pending）
- Key 前缀与关联租户信息

---

### 3.18 订阅服务管理

#### ⚙️ 订阅服务管理（subscription_service_management）
- 平台级订阅服务配置 Repository + Controller

---

### 3.19 通用 UI 组件（highfi/widgets）

| 组件 | 用途 |
|------|------|
| HighfiCard | 统一卡片容器 |
| HighfiChartPlaceholder | 图表占位 |
| HighfiDeviceTile | 设备列表项 |
| HighfiEmptyErrorState | 空/错误状态 |
| HighfiStatTile | 统计数据 Tile |
| HighfiStatusChip | 状态标签 Chip |

---

## 四、页面统计

| 分类 | 页面数 | 说明 |
|------|-------|------|
| 认证 | 1 | 登录页 |
| 数智孪生 | 7 | 总览 + 发热(列表+详情) + 消化(列表+详情) + 发情(列表+详情) + 疫病 |
| 围栏 | 4 | 围栏地图 + 围栏表单 + 围栏冲突 + 离线编辑横幅 |
| 告警 | 1 | 告警中心 |
| 牲畜 | 1 | 牲畜详情 |
| 设备 | 1 | 设备管理 |
| 统计 | 1 | 数据统计 |
| 我的 | 2 | 个人中心 + API授权 |
| 订阅 | 3 | 套餐选择 + 支付确认 + 订阅状态 |
| Owner 后台 | 1 | 管理后台（概览+租户） |
| 牧工管理 | 1 | 牧工列表 |
| 平台管理 | 6 | 租户列表+创建+详情+编辑 + 合同+对账+订阅+API授权 |
| B端管理 | 6 | 概览+牧场+合同+对账(列表+详情)+牧工(列表+详情) |
| 牧场创建 | 1 | 向导（3 步） |
| 离线 | 1 | 离线瓦片管理 |
| **合计** | **~37** | |

---

## 五、路由统计

AppRoute 枚举定义 46 条路由，覆盖所有角色场景。

---

## 六、订阅 Tier 与 Feature Flag 映射

| Feature | basic | standard | premium | enterprise |
|---------|-------|----------|---------|------------|
| GPS定位 | ✅ | ✅ | ✅ | ✅ |
| 电子围栏 | 3个 | 5个 | 10个 | 不限 |
| 告警历史 | - | ✅ | ✅ | ✅ |
| 数据保留 | 7天 | 30天 | 365天 | 3年 |
| 历史轨迹 | - | ✅ | ✅ | ✅ |
| 设备管理 | ✅ | ✅ | ✅ | ✅ |
| 健康评分 | - | - | ✅ | ✅ |
| 发情检测 | - | - | ✅ | ✅ |
| 疫病预警 | - | - | ✅ | ✅ |
| 步态分析 | - | - | - | ✅ |
| 行为统计 | - | - | - | ✅ |
| API访问 | - | - | - | ✅ |
| 专属客服 | - | - | ✅ | ✅ |
| 数据统计 | ✅ | ✅ | ✅ | ✅ |
| 牲畜详情 | ✅ | ✅ | ✅ | ✅ |

---

## 七、数据流架构

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│  Flutter UI  │────▶│ Riverpod Provider │────▶│ Repository  │
│  (Consumer)  │◀────│ (Controller)      │◀────│ (Interface)  │
└─────────────┘     └──────────────────┘     └──────┬──────┘
                                                     │
                                              ┌──────┴──────┐
                                              │             │
                                         ApiRepository  (live)
                                              │
                                         ApiClient
                                              │
                                         HTTP (JWT)
                                              │
                                      Spring Boot 后端
```

- Live 模式：启动时 ApiCache.instance.init(role) 预加载，Repository 同步读缓存
- 缓存未初始化时自动 fallback
