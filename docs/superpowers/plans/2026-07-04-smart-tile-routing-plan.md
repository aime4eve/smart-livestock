# 智能瓦片路由实施计划（P3）

参考 spec: `docs/superpowers/specs/2026-07-04-smart-tile-routing-design.md`

## Task 1 — MBTilesTileProvider 内存元数据缓存

**目标**：消除逐瓦片 SQLite 查询开销，改为内存边界判断。

- 1.1 新建 `MbtilesMeta` 类（regionName, filePath, minZoom, maxZoom, minLon, minLat, maxLon, maxLat），mbtiles 文件打开时从 metadata 表读取 bounds 和 zoom range 缓存到内存。
- 1.2 `getImage()` 先做内存判断：坐标在 bounds 内且 zoom 在范围内 → 才查 SQLite；否则直接返回 null。
- 1.3 `hasTile()` 同样先做内存边界判断再查 SQLite。
- 1.4 编写单元测试：bounds 内/外的瓦片命中判断；zoom range 边界值。
- **验证**：`flutter test` 通过；`flutter analyze` 无错误。

**文件**：`core/map/mbtiles_tile_provider_io.dart`、`core/map/mbtiles_tile_provider_stub.dart`

## Task 2 — SmartTileProvider 重写为逐瓦片路由

**目标**：去掉全局模式切换，实现逐瓦片优先级路由。

- 2.1 重写 `getImage()`：本机 mbtiles → OSM 在线 → tileserver 兜底。
  - 接收 `List<MBTilesTileProvider>` （用户下载的多个 mbtiles 文件）和 `MBTilesTileProvider?` （内置 sample.mbtiles）。
  - 遍历用户 mbtiles 的 meta，命中即读本地；不命中再查内置 sample.mbtiles；都不命中走在线。
- 2.2 实现连通性缓存：
  - `_online` 布尔值，30 秒 TTL。
  - OSM 请求成功 → `_online = true`，重置计时。
  - 连续 3 次失败 → `_online = false`。
  - `_online = false` 时跳过 OSM，直接走 tileserver；每 30s 后台探测恢复。
- 2.3 去掉 `performHealthCheck()` 阻塞：`create()` 不再 await 健康检查，直接返回 provider。
- 2.4 去掉 `_TileSource` enum 和全局 `_activeSource` 状态。
- 2.5 保留 `onSourceChanged` 回调（连通性切换时触发 setState 刷新围栏渲染，因为坐标转换依赖当前源）。
- **验证**：`flutter analyze` 无错误；`flutter test` 通过。

**文件**：`core/map/smart_tile_provider.dart`

## Task 3 — OfflineTileManager 流式下载 + 多文件管理

**目标**：大文件不 OOM，支持多区域下载。

- 3.1 `startForegroundDownload()` 改为 `http.Client().send()` 流式下载，分块写盘。
- 3.2 下载进度回调 `onProgress(receivedBytes, totalBytes)` 返回字节级百分比。
- 3.3 增加取消下载能力（`CancelToken` 或标志位）。
- 3.4 `getLocalMbtilesFiles()` 方法：扫描 AppDatabase tile_metas 表，返回已下载的 mbtiles 文件路径列表（供 SmartTileProvider 加载）。
- 3.5 `getStorageUsed()` 保持现有逻辑。
- 3.6 编写单元测试：流式下载模拟（mock http stream）；MD5 校验逻辑；取消逻辑。
- **验证**：`flutter test` 通过。

**文件**：`offline_tiles/presentation/offline_tile_manager.dart`

## Task 4 — OfflineTileManagementPage 完整 UI

**目标**：接通下载/进度/存储/删除功能。

- 4.1 分两个区域：**可用区域**（服务端已生成、本机未下载）和**已下载区域**（本机已有）。
- 4.2 可用区域列表：区域名 + 大小 + 缩放范围 + 下载按钮。
- 4.3 已下载区域列表：区域名 + 大小 + 缩放范围 + 删除按钮 + 重新下载（MD5 不匹配时显示）。
- 4.4 下载进度条：当前下载区域显示百分比进度条 + 取消按钮。
- 4.5 存储用量：顶部显示「已用 X MB / 可用 Y GB」。
- 4.6 所有文案 i18n（app_zh.arb + app_en.arb 同步新增 key）。
- 4.7 删除确认对话框。
- **验证**：`flutter analyze` 无错误；`flutter gen-l10n` 无缺失 key。

**文件**：`offline_tiles/presentation/offline_tile_management_page.dart`、`lib/l10n/app_zh.arb`、`lib/l10n/app_en.arb`

## Task 5 — 地图页统一接入新 SmartTileProvider

**目标**：6 处地图页统一创建逻辑，传入用户下载的 mbtiles + tileserver URL。

- 5.1 抽取公共方法 `createSmartTileProvider(ref, farmId)`，封装：加载用户 mbtiles → 获取 tileserver URL → 创建 SmartTileProvider。
- 5.2 改造 6 处：`ranch_page.dart`、`fence_page.dart`、`fence_form_page.dart`、`wizard_step_basic_info.dart`、`wizard_step_fence_drawing.dart`、`b2b_worker_detail_page.dart`。
- 5.3 每处改为调用公共方法，去掉各自的 `_initTileProvider` 内联逻辑。
- 5.4 `map_config.dart`：`tileUrlTemplate` 默认值改为 `overseasFallbackUrl`（OSM），保留 `chinaFallbackUrl` 供中国场景手动切换。
- 5.5 去掉 `TileAutoTrigger`（owner 端 403 的无效自动触发），离线下载改为用户在管理页主动操作。
- **验证**：`flutter analyze` 无错误；`flutter test` 全量通过。

**文件**：`core/map/map_config.dart`、6 处地图页 dart 文件

## Task 6 — 集成验证 + i18n 校验

- 6.1 `flutter gen-l10n` 确认无缺失 key。
- 6.2 `flutter analyze` 全量通过。
- 6.3 `flutter test` 全量通过。
- 6.4 `build_web.sh` 构建通过。
- 6.5 冒烟测试清单（手动验证，记录结果）：
  - [ ] 有网 + 无离线包：OSM 全缩放渲染
  - [ ] 有网 + 有离线包：离线区域本地秒加载，区域外 OSM
  - [ ] 无网 + 有离线包：离线区域本地秒加载，区域外空白
  - [ ] 无网 + 无离线包：tileserver 兜底（z12-15），区域外空白
  - [ ] 离线地图管理页：下载/进度/删除/存储用量

**文件**：全量验证

---

## 执行顺序

Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6

Task 1-2 是核心基础（渲染逻辑），Task 3-4 是离线管理能力，Task 5 是接线，Task 6 是验证。
Task 1 和 Task 3 互相独立，可并行。

## 完成记录

| 日期 | Task | commit | 备注 |
|------|------|--------|------|
| | | | |
