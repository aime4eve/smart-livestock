# 瓦片前端接通实施计划（P3）

参考 spec: docs/superpowers/specs/2026-06-17-tile-frontend-integration-design.md

## Task 1 — 块1 SmartTileProvider 接通 region URL
- 1.1 fence_page.dart：create 前 `TileSourceResolver.resolve(farmId)` 取 region URL 传 SmartTileProvider；region 空→null。
- 1.2 同步改 5 处 create：ranch_page / fence_form_page / wizard_step_basic_info / wizard_step_fence_drawing / b2b_worker_detail_page。
- 1.3 flutter analyze + 冒烟（自建/降级两条路径）。

## Task 2 — 块2 缺瓦片触发下载任务
- 2.1 地图页检测 region 空 / coverageRatio<阈值 → `POST /admin/tiles/tasks`（bbox 牧场, zoom 11-15），不阻塞渲染。
- 2.2 验证：无自建瓦片时 tile_admin Tasks 出现 pending→done。

## Task 3 — 块3 tile_admin 管理加载
- 3.1 _TasksTab「新建任务」FAB（对话框 regionName/bbox/zoom → POST task）。
- 3.2 _RegionsTab「重新加载」按钮（worker 自动 restart；提示/调 reload）。

## 执行顺序：Task 1 → Task 3 → Task 2

## 完成记录
| 日期 | Task | commit | 备注 |
|------|------|--------|------|
| 2026-06-18 | Task 1 | 535cc012 | 6 处接通 region URL（owner 3 resolve + wizard 2 null + b2b 核对）+ resolver ['data']→['value'] bug 修复 |
| 2026-06-18 | Task 3 | be59b075 | tile_admin FAB「新建任务」+ _RegionsTab「重新加载」+ 对话框（i18n zh/en 同步） |
| 2026-06-18 | Task 2 | 703c4676 | TileAutoTrigger helper + b2b_worker_detail_page region 空→自动 POST task（owner 端 403 静默，后端 owner 端点留后续） |
