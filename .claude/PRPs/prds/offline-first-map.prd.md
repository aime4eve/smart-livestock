# 离线优先地图设计（PRD）

## Problem Statement

牧场主和牧工在骑马/开车巡栏时经常进入无信号区域（山谷、密林），此时 App 依赖在线瓦片的地图功能完全不可用——围栏边界消失、牲畜位置无法查看、围栏编辑无法进行。在目标市场（阿根廷潘帕斯草原、南非草原、巴西南部），40-60% 的巡栏时间处于离线状态。地图是电子围栏功能的基础设施，地图不可用等于围栏功能不可用。

## Evidence

- Issue #48 基于竞品 TraceX 数据：南亚/非洲牧区 40-60% 时间离线，目标市场面临同样问题
- CRM 数据：目标客户集中在阿根廷（37）、智利（7）、巴西（23）、南非——均为大范围牧场，网络覆盖差
- 竞品 Ceres Tag、HerdDogg 在无信号时 App 基本白屏，这是可利用的差异化优势
- 产品定位要求：这不是"锦上添花"，是"没有就不用"的硬需求

## Proposed Solution

采用 **MBTiles 离线瓦片包 + 自定义 TileProvider 优先级链** 方案。后端使用自建 tileserver-gl + OSM Planet 数据按牧场区域预生成 MBTiles 文件，App 通过 API 下载到本地存储。flutter_map 使用自定义 MBTilesTileProvider（在线瓦片失败时自动回退到本地 MBTiles），实现无感在线/离线切换。围栏数据和牲畜最后位置持久化到本地，离线时直接渲染。

选择此方案而非 FMTC（客户端自动缓存）的原因：服务端预生成可控性强、合规（不经过 OSM CDN 批量下载）、可预装入牧场初始数据、支持增量更新对比。

### 2026-07 更新：逐瓦片智能路由

项目明确**主要面向国际市场**（欧洲、美洲、大洋洲）后，瓦片优先级从"自建 tileserver 优先"翻转为**逐瓦片智能路由**：

```
getImage(z, x, y):
  1. 本机已下载的 mbtiles 有这张瓦片？→ 本地读取（零延迟、零网络）
  2. OSM 在线加载（全缩放、全球覆盖、WGS-84）
  3. OSM 无网 → 项目服务器 tileserver 兜底（z12-15）
```

核心变化：去掉全局模式切换，每个瓦片独立判断来源。有网时流畅不受离线瓦片缩放范围限制，无网时本机瓦片秒加载。详见 `docs/superpowers/specs/2026-07-04-smart-tile-routing-design.md`。

## Key Hypothesis

我们相信 **离线可用的地图体验** 将 **消除牧场主在无信号场景下的核心使用障碍**，使 **阿根廷/南非/巴西的目标牧场客户** 愿意付费。
我们将知道我们的方向是正确的，当 **试点牧场主在离线场景下的 App 周活跃天数不低于在线场景的 70%**。

## What We're NOT Building

- **离线围栏绘制/编辑** — 需要离线冲突解决机制（多人同时编辑同一围栏），复杂度高，推迟到 v1.1
- **离线 GPS 轨迹回放** — 需要本地轨迹存储 + 增量同步，数据量大，推迟到 v1.2
- **离线地图标注/POI** — 功能明确但非核心路径，推迟到 v1.2
- **离线搜索/地址解析** — Nominatim 需在线服务，离线实现需额外数据包，推迟到 v2
- **矢量瓦片/样式定制** — MBTiles 矢量方案复杂度远高于栅格，长期规划
- **卫星影像离线** — 存储量巨大（单牧场 GB 级），且 OSM 无卫星源，不做

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|--------------|
| 离线场景下地图可用率 | ≥ 95%（有预载瓦片的区域） | App 端埋点：tile_load_success / tile_load_total，按在线/离线分组 |
| 离线场景围栏正确渲染 | 100%（有缓存的围栏） | UI 自动化测试：断开网络后验证围栏多边形可见 |
| MBTiles 下载成功率 | ≥ 98%（WiFi 环境） | 后端埋点：download_completed / download_started |
| 首次下载到可用耗时 | ≤ 5 分钟（200MB，WiFi） | App 端计时：从点击下载到瓦片可渲染 |
| 用户感知切换时间 | 用户无感知（无弹窗/闪烁） | 用户测试反馈 + UI 无闪烁检测 |

## Open Questions

- [x] ~~flutter_map_mbtiles 包与 flutter_map 8.x 的兼容性验证~~ → 自写 MBTilesTileProvider（~120 行），无第三方依赖，已验证
- [x] ~~tileserver-gl 部署方案~~ → Docker sidecar（docker-compose 内），nginx 反代 404 透传
- [x] ~~MBTiles 生成策略~~ → tile-worker 后台容器从 OSM Planet 生成，按牧场坐标自动触发
- [x] ~~大文件下载 OOM~~ → 流式下载（http.Client().send 分块写盘），scandinavia 151MB 不崩溃
- [x] ~~瓦片渲染优先级~~ → 逐瓦片智能路由（本地 mbtiles → OSM → tileserver），非全局模式切换
- [x] ~~坐标系统一~~ → 国际用 OSM（WGS-84），离线 mbtiles 也是 WGS-84，无需 GCJ-02 转换
- [ ] MBTiles 增量更新策略：全量替换 vs 差异补丁（当前全量替换，待优化）
- [ ] 多牧场离线瓦片存储上限策略：固定 5 个牧场 vs 按存储空间动态限制
- [ ] 离线围栏/GPS 数据持久化（Phase 4 未实施）

---

## Users & Context

**Primary User**
- **Who**: 牧工/牧场主，年龄 30-55 岁，智能手机基础使用者，工作环境为户外牧场
- **Current behavior**: 在有信号时使用 App 查看围栏和牲畜位置，无信号时完全无法使用地图功能
- **Trigger**: 骑马/开车巡栏时进入山谷、密林等无信号区域，需要查看围栏边界或牲畜位置
- **Success state**: 打开 App 地图始终可用，不关心当前是在线还是离线

**Job to Be Done**
当 骑马巡栏进入无信号区域 时，我想要 在地图上看到围栏边界和牲畜最后位置，以便 确认牛群是否越界并决定下一步行动。

**Non-Users**
- 平台管理员（b2b_admin）— 在办公室使用，网络稳定
- API 开发者（api_consumer）— 通过 API 接口访问，不使用 App 地图
- 城市小牧场主 — 网络覆盖好，离线需求弱

---

## Solution Detail

### Core Capabilities (MoSCoW)

| Priority | Capability | Rationale |
|----------|------------|-----------|
| Must | 离线瓦片渲染（MBTiles） | 地图底图是所有功能的基础，无瓦片则围栏/GPS 不可见 |
| Must | 自动在线/离线无感切换 | 牧工不应感知在线/离线区别，否则体验断裂 |
| Must | MBTiles 按牧场下载与管理 | 预载是离线可用的前提，需要下载 UI 和存储管理 |
| Must | 离线围栏只读显示 | P0 场景：巡栏看围栏边界是最高频需求 |
| Should | 离线牲畜最后位置显示 | P0 场景：确认牲畜是否越界，增强巡栏决策 |
| Should | WiFi 环境自动检查瓦片更新 | 避免消耗移动流量，30 天周期自动刷新 |
| Could | 瓦片下载进度与断点续传 | 大文件下载体验优化 |
| Won't | 离线围栏绘制/编辑 | 需冲突解决机制，v1.1 |
| Won't | 离线 GPS 轨迹 | 数据量大，v1.2 |
| Won't | 离线搜索/POI | 非核心路径，v2 |

### MVP Scope

验证离线地图瓦片的端到端可行性：后端生成 MBTiles → App 下载 → 离线渲染围栏和牲畜位置 → 网络恢复自动切回在线。覆盖 P0 场景（巡栏看围栏 + 确认牲畜越界）。

### User Flow

```
首次使用:
  App 检测当前牧场无离线瓦片
  → 提示"连接 WiFi 下载牧场地图（约 300MB）"
  → 用户确认下载
  → 后台下载 MBTiles（显示进度条，支持暂停/继续）
  → 下载完成，地图立即可用

日常使用:
  打开 App → 自动加载在线瓦片（优先）+ 本地围栏/牲畜数据
  → 骑马进入无信号区域
  → TileProvider 自动回退到 MBTiles，围栏/牲畜数据从本地读取
  → 用户无感知切换，继续查看地图
  → 回到有信号区域
  → 自动切回在线瓦片，后台检查更新

管理:
  设置 → 离线地图 → 查看已下载牧场列表
  → 每个牧场显示：大小、下载时间、过期状态
  → 可删除不常用的牧场瓦片释放空间
```

---

## Technical Approach

**Feasibility**: HIGH

**Architecture Notes**

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                         │
│                                                         │
    │  ┌─────────────┐    ┌──────────────────────────────┐   │
    │  │ flutter_map  │───▶│ OfflineTileProvider (优先级链) │   │
    │  └─────────────┘    │  1. NetworkTileProvider       │   │
    │                     │  2. MBTilesTileProvider        │   │
    │                     │  → 逐瓦片路由 + 连通性缓存       │   │
    │                     └──────────────────────────────┘    │
│                                                         │
│  ┌─────────────┐    ┌──────────────────────────────┐   │
│  │ 围栏/GPS渲染  │───▶│ LocalDataStore (Hive/SQLite)  │   │
│  └─────────────┘    │  - 围栏多边形数据              │   │
│                     │  - 牲畜最后 GPS 坐标            │   │
│                     └──────────────────────────────┘    │
│                                                         │
│  ┌─────────────┐    ┌──────────────────────────────┐   │
│  │ MBTiles管理   │───▶│ getApplicationSupportDirectory│   │
│  │  下载/过期/删除│    │  /mbtiles/{farmId}.mbtiles    │   │
│  └─────────────┘    └──────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                   Spring Boot Backend                   │
│                                                         │
│  ┌──────────────┐    ┌────────────────────────────┐    │
│  │ tileserver-gl │───▶│ tile-worker (Docker)        │    │
│  │ (Docker sidecar)│   │  按牧场 bbox 从 OSM 生成     │    │
│  └──────────────┘    │  zoom 11-15, PNG 256x256   │    │
│                      └────────────────────────────┘    │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │ GET  /api/v1/farms/{farmId}/offline-map           │   │
│  │   → 下载 MBTiles 文件                              │   │
│  │ POST /api/v1/farms/{farmId}/tile-tasks            │   │
│  │   → owner 触发生成（幂等）                          │   │
│  │ GET  /api/v1/farms/{farmId}/tile-status           │   │
│  │   → 查看已生成区域                                  │   │
│  │ GET  /api/v1/farms/{farmId}/tile-source           │   │
│  │   → tileserver 瓦片 URL                            │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

- **瓦片数据源**：自建 tileserver-gl + OSM Planet 数据，ODbL 许可合规，不经过 OSM CDN 批量下载
- **MBTiles 生成**：按牧场 bounding box 预生成，zoom 11-15，单文件 ≤300MB，超大面积牧场拆分
- **客户端存储**：`getApplicationSupportDirectory()/mbtiles/{regionName}.mbtiles`，避开 Android Scoped Storage 限制
- **逐瓦片路由**：SmartTileProvider.getImage() 每个瓦片独立判断：本地 mbtiles → OSM → tileserver，无全局模式切换
- **连通性缓存**：30s TTL，连续 3 次 OSM 失败 → 切 offline，跳过 OSM 避免每瓦片超时
- **MBTiles 内存缓存**：MbtilesMeta 记录 zoom range + bounds，O(1) 判断瓦片是否在文件范围内，跳过无效 SQLite 查询
- **流式下载**：http.Client().send() 分块写盘，大文件不 OOM
- **围栏/牲畜数据持久化**：复用现有 ApiCache 数据结构，扩展为 Hive/SQLite 持久化存储

**Technical Risks**

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| ~~flutter_map_mbtiles 包不兼容~~ | — | ✅ 已自写 MBTilesTileProvider（~120 行），已验证 |
| OSM ToS 限制批量瓦片下载 | M | 自建 tileserver-gl，不经过 OSM CDN |
| MBTiles 生成服务复杂度 | M | tilelive/gdal2tiles 按牧场区域预生成，作为 Docker sidecar 部署 |
| Android Scoped Storage 限制 | L | 使用 getApplicationSupportDirectory()，不涉及外部存储 |
| 首次下载 200MB+ 体验差 | L | 流式下载 + 取消能力 + WiFi 引导 |
| MBTiles 文件 >300MB 性能下降 | L | 按牧场拆分，单文件控制在 300MB 以内 |
| snap Docker 无法 bind mount /data/agentic | — | deploy.sh 中 docker cp 同步到 named volume |

---

## Implementation Phases

<!--
  STATUS: pending | in-progress | complete
  PARALLEL: phases that can run concurrently (e.g., "with 3" or "-")
  DEPENDS: phases that must complete first (e.g., "1, 2" or "-")
  PRP: link to generated plan file once created
-->

| # | Phase | Description | Status | Parallel | Depends | PRP Plan |
|---|-------|-------------|--------|----------|---------|----------|
| 1 | Tech Spike | 验证 flutter_map MBTiles 兼容性或自写 TileProvider | complete | - | - | `.claude/PRPs/plans/completed/offline-first-map-phase1-tech-spike.plan.md` |
| 2 | 后端 MBTiles 生成 | tileserver-gl 部署 + MBTiles 生成 API + 下载端点 | complete | with 3 | 1 | `docs/superpowers/specs/2026-05-15-multi-region-map-tiles-design.md` |
| 3 | Flutter 离线瓦片渲染 | SmartTileProvider 逐瓦片路由 + 连通性缓存 | complete | with 2 | 1 | `docs/superpowers/specs/2026-07-04-smart-tile-routing-design.md` |
| 4 | 离线数据持久化 | 围栏 + 牲畜最后位置本地缓存 + 离线渲染 | pending | - | 2, 3 | - |
| 5 | MBTiles 管理界面 | 下载/进度/取消/存储/删除 UI | complete | - | 3 | `docs/superpowers/plans/2026-07-04-smart-tile-routing-plan.md` |
| 6 | 集成测试与上线 | 端到端离线场景测试 + 性能验证 | pending | - | 5 | - |

### Phase Details

**Phase 1: Tech Spike**
- **Goal**: 验证 MBTiles 在 flutter_map 8.x 中的渲染可行性
- **Scope**:
  - 验证 flutter_map_mbtiles 包与 flutter_map 8.x 兼容性
  - 若不兼容，实现自定义 MBTilesTileProvider（SQLite 读取 + TMS Y 轴翻转 + MemoryImage）
  - 准备一个示例 MBTiles 文件，验证离线渲染效果
  - 验证 TileProvider 优先级链（Network → MBTiles）切换无闪烁
- **Success signal**: 手动断开网络后，flutter_map 能从本地 MBTiles 渲染瓦片，无报错无闪烁

**Phase 2: 后端 MBTiles 生成服务**
- **Goal**: 后端能按牧场区域生成 MBTiles 文件并提供下载
- **Scope**:
  - 部署 tileserver-gl 作为 Docker sidecar（或独立容器）
  - 实现 MBTilesGenerator：按牧场 bbox + zoom 11-15 生成 MBTiles
  - 新增 API 端点：
    - `GET /api/v1/farms/{farmId}/offline-map` — 流式下载 MBTiles（支持 Range header 断点续传）
    - `HEAD /api/v1/farms/{farmId}/offline-map` — 返回文件大小、版本号、MD5、生成时间
    - `POST /api/v1/farms/{farmId}/offline-map/generate` — 触发（重新）生成
  - 牧场创建/更新 bbox 时自动触发 MBTiles 生成（异步任务）
  - 生成的文件缓存，30 天有效期
- **Success signal**: `curl` 能下载到有效的 MBTiles 文件，文件可被 flutter_map 渲染

**Phase 3: Flutter 离线瓦片渲染**
- **Goal**: App 在无网络时能从本地 MBTiles 渲染地图瓦片
- **Scope**:
  - 实现 OfflineTileProvider（Network → MBTiles 回退链）
  - 网络状态监听（connectivity_plus），瓦片加载失败时静默回退
  - 替换现有 TileLayer.urlTemplate 为自定义 TileProvider
  - 按当前 farmId 加载对应 MBTiles 文件
  - 牧场切换时释放旧 MBTiles、加载新 MBTiles
- **Success signal**: 飞行模式下打开 App，地图正常显示（有预载瓦片的区域）

**Phase 4: 离线数据持久化**
- **Goal**: 围栏和牲畜最后位置在离线时可渲染
- **Scope**:
  - 将 ApiCache 中的围栏数据和牲畜最后 GPS 坐标持久化到本地存储
  - 在线时：正常从后端拉取，同时更新本地缓存
  - 离线时：从本地缓存读取围栏多边形和牲畜位置，渲染到地图上
  - 牲畜位置显示"最后更新时间"标签
  - 数据过期策略：超过 24 小时的数据标记为"可能过时"
- **Success signal**: 断网后围栏多边形正确渲染，牲畜最后位置显示正确时间戳

**Phase 5: MBTiles 管理界面**
- **Goal**: 用户能自主管理离线地图瓦片包
- **Scope**:
  - 设置页"离线地图"入口
  - 已下载牧场列表：显示大小、下载日期、过期状态
  - 下载新牧场：WiFi 检测 → 确认对话框 → 进度条 → 断点续传
  - 瓦片过期检查：WiFi 环境自动检查，显示"有更新可用"
  - 删除牧场瓦片：确认对话框，显示可释放空间
  - 首次进入无瓦片牧场时的引导提示
  - 存储空间不足预警（<1GB 可用时提示清理）
- **Success signal**: 用户能独立完成"下载 → 查看 → 更新 → 删除"完整流程

**Phase 6: 集成测试与上线**
- **Goal**: 验证端到端离线体验，确保生产可用
- **Scope**:
  - 飞行模式端到端测试：下载瓦片 → 断网 → 查看围栏 → 查看牲畜位置 → 恢复网络
  - 多牧场切换离线测试
  - MBTiles 文件损坏/不完整时的降级处理
  - 性能测试：300MB MBTiles 加载时间、内存占用、渲染帧率
  - 后端 tileserver-gl 负载测试（多牧场同时请求）
  - 更新用户文档和 CLAUDE.md
- **Success signal**: 所有离线场景测试通过，性能指标达标

### Parallelism Notes

Phase 1（Tech Spike）是所有后续工作的前置依赖，必须先完成。

Phase 2 和 Phase 3 可以并行开发——后端搭建 MBTiles 生成服务的同时，Flutter 端用示例 MBTiles 文件开发离线渲染能力。

Phase 4 依赖 Phase 2（需要后端 API 提供围栏/GPS 数据的离线缓存格式）和 Phase 3（需要离线瓦片渲染就绪才能叠加围栏/牲畜图层）。

Phase 5 依赖 Phase 4（管理界面需要与后端 API 和本地存储交互的完整能力）。

---

## Decisions Log

| Decision | Choice | Alternatives | Rationale |
|----------|--------|--------------|-----------|
| 瓦片缓存方案 | 服务端 MBTiles 预生成 | FMTC 客户端自动缓存 | 可控性强、合规、可预装、支持增量更新 |
| 瓦片数据源 | 自建 tileserver-gl + OSM Planet | MapTiler / Thunderforest 付费源 | OSM 数据免费，ODbL 许可合规，无下载量限制 |
| 离线渲染方案 | 自定义 MBTilesTileProvider | flutter_map_mbtiles 第三方包 | 规避兼容性风险，核心代码仅 ~80 行 |
| 本地存储路径 | getApplicationSupportDirectory() | 外部存储 | Android 11+ Scoped Storage 限制，内部存储无需额外权限 |
| v1 围栏操作 | 只读 | 离线绘制 + 同步 | 离线绘制需冲突解决机制，先验证核心可行性 |
| Zoom 范围 | 11-15 | 更大范围 | 覆盖牧场全景到围栏细节，单牧场 ≤300MB |
| 瓦片渲染优先级 | 逐瓦片路由（本地→OSM→tileserver） | 全局模式切换 | 国际用户缩放不受离线瓦片范围限制，无网时本地秒加载 |
| 在线瓦片源 | OSM（WGS-84） | 高德（GCJ-02） | 国际市场为主，OSM 全球覆盖好，与离线瓦片坐标系一致无需转换 |
| 下载方式 | 流式分块（http.Client().send） | 一次性内存加载（http.get） | 151MB 大文件不 OOM |
| Docker 部署 | named volume + docker cp | bind mount | 服务器 snap Docker 无法 bind mount /data/agentic 路径 |
| 默认区域 | overseas（OSM） | china（高德） | 项目主要面向国际市场 |

---

## Research Summary

**Market Context**
- 竞品 TraceX 数据显示目标市场 40-60% 时间离线
- Ceres Tag、HerdDogg 在无信号时 App 基本白屏，差异化机会明确
- 畜牧管理 App 离线能力是"没有就不用"级别的硬需求

**Technical Context**
- flutter_map 8.x 支持 TileProvider 自定义，可实现优先级链
- MBTiles 是成熟的离线瓦片标准格式（SQLite），工具链完善
- tileserver-gl 是成熟开源项目，Docker 部署简单
- 自写 MBTilesTileProvider 核心代码约 80 行，不依赖第三方包
- 现有 MapConfig（zoom 11-15、30 天有效期）可直接复用为离线配置
- SmartTileProvider 逐瓦片路由已实现，连通性缓存 30s TTL，避免无网时每瓦片超时
- MbtilesMeta 内存缓存 O(1) 判断瓦片是否在文件范围内，跳过无效 SQLite 查询
- 服务器 172.22.1.123 部署了 test（18080）和 dev（19080）两套隔离环境

**Codebase Context**
- flutter_map 8.2.2 已集成，TileLayer 使用 urlTemplate（需改为自定义 TileProvider）
- 围栏渲染使用 PolygonLayer，不依赖网络，离线可直接复用
- ApiCache 内存缓存围栏和 GPS 数据，需扩展为持久化存储
- 后端围栏 API 完整（CRUD + 越界检测），无需修改
- SmartTileProvider 已在 6 处地图页接入（ranch_page / fence_page / fence_form_page / wizard_step_basic_info / wizard_step_fence_drawing / b2b_worker_detail_page）
- OfflineTileManager 支持流式下载 + MD5 校验 + 多文件管理 + 取消能力
- OfflineTileManagementPage 支持下载/进度/存储/删除完整管理功能

---

*Generated: 2026-05-14*
*Updated: 2026-07-05*
*Status: APPROVED — Phase 1/2/3/5 complete, Phase 4/6 pending*
*GitHub Issue: #48*
