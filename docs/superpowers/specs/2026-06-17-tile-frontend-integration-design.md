# 瓦片前端接通设计（P3）

## 背景
P1（nginx 404 透传 + SmartTileProvider 恢复三级降级）/ P2（tile-worker 自动生成 mbtiles）已上线。
缺口：前端 SmartTileProvider 用固定 `/tiles/{z}/{x}/{y}.png`（无 region），未接 TileSourceResolver；缺瓦片不触发下载；tile_admin 只读。

## 目标
1. 地图页用自建 region 瓦片。
2. 缺瓦片并行：降级（高德/OSM 即时）+ 触发下载任务（worker 后台）。
3. tile_admin 支持「新建任务」「重新加载」。

## 设计

### 块1 SmartTileProvider 接通 region URL
- 地图页 `create` 前 `TileSourceResolver.resolve(farmId)` 取 region URL 传 SmartTileProvider。
- region 空 → null → 降级 + 触发块2。
- 6 处 create：fence_page / ranch_page / fence_form_page / wizard_step_basic_info / wizard_step_fence_drawing / b2b_worker_detail_page。

### 块2 缺瓦片触发 task
- `GET /farms/{id}/offline-map` 取 coverageRatio；低或 region 空 → `POST /admin/tiles/tasks`（bbox 牧场, zoom 11-15）。
- 并行降级 + POST（不阻塞）。

### 块3 tile_admin 管理
- _TasksTab「新建任务」（对话框 regionName/bbox/zoom → POST）。
- _RegionsTab「重新加载」（worker 自动 restart；按钮提示）。

## 范围
仅前端 Dart。后端 API 已够。高德坐标偏移单独修（memory project-gaode-fallback-coord-offset）。

## 验收
- 自建 region 存在 → 显示自建（WGS-84）。
- 缺失 → 降级 + 自动 task（pending→done）。
- tile_admin 新建任务/看进度。
