# lat/lng 参数代码覆盖分析报告

> 基于 `.understand-anything/knowledge-graph.json` 知识图谱查询生成，2026-05-21

---

## 1. 概述

lat/lng（经纬度）参数贯穿智慧畜牧系统的三个子系统，涉及领域模型、坐标转换、围栏检测、GPS 轨迹、地图渲染等核心业务。

---

## 2. 后端（Spring Boot）

### 领域模型

| 文件 | 类/方法 | 说明 |
|------|---------|------|
| `ranch/domain/model/GpsCoordinate.java` | `GpsCoordinate` | GPS 坐标值对象，封装 lat/lng |
| `ranch/domain/model/Fence.java` | `Fence` | 围栏聚合根，vertices 存储 lat/lng 顶点列表 |
| `ranch/domain/model/Livestock.java` | `Livestock` | 牲畜聚合根，含 lastKnownLocation（GpsCoordinate） |
| `identity/domain/model/Farm.java` | `Farm` | 牧场聚合根，含中心点 lat/lng 和面积 |
| `iot/domain/model/GpsLog.java` | `GpsLog` | GPS 日志实体，记录 lat/lng + timestamp |

### 业务逻辑

| 文件 | 类/方法 | 说明 |
|------|---------|------|
| `ranch/domain/service/FenceBreachDetector.java` | `FenceBreachDetector` | 越界检测：判断 lat/lng 是否在围栏多边形内 |
| `iot/application/service/GpsSimulator.java` | `GpsSimulator` | GPS 模拟器：生成随机 lat/lng 轨迹 |
| `iot/application/GpsLogApplicationService.java` | `GpsLogApplicationService` | GPS 日志应用服务：接收/查询 lat/lng |
| `ranch/application/FenceApplicationService.java` | `FenceApplicationService` | 围栏应用服务：CRUD 含坐标验证 |

### 基础设施层

| 文件 | 类/方法 | 说明 |
|------|---------|------|
| `ranch/infrastructure/persistence/entity/FenceJpaEntity.java` | `FenceJpaEntity` | JPA 实体，vertices 存为 JSON（lat/lng 数组） |
| `ranch/infrastructure/persistence/mapper/FenceMapper.java` | `FenceMapper` | 坐标序列化/反序列化（vertices JSON ↔ 坐标列表） |
| `ranch/interfaces/FenceController.java` | `FenceController` | 围栏 REST 接口，请求/响应含 lat/lng |
| `ranch/interfaces/MapController.java` | `MapController` | 地图接口：牲畜位置、轨迹 |
| `iot/interfaces/GpsLogController.java` | `GpsLogController` | GPS 日志接口：写入/查询 lat/lng |
| `iot/interfaces/open/OpenGpsController.java` | `OpenGpsController` | Open API GPS 写入 |

### 数据库表

| 迁移文件 | 表名 | lat/lng 字段 |
|----------|------|-------------|
| `V1__create_identity_tables.sql` | `farms` | `center_lat`, `center_lng` |
| `V2__create_ranch_tables.sql` | `fences` | `vertices JSONB`（坐标数组） |
| `V2__create_ranch_tables.sql` | `livestock` | `last_lat`, `last_lng` |
| `V3__create_iot_tables.sql` | `gps_logs` | `latitude`, `longitude` |

---

## 3. 前端（Flutter）

### 核心地图层

| 文件 | 类/方法 | 说明 |
|------|---------|------|
| `core/map/coord_transform.dart` | `CoordTransform` | WGS-84 ↔ GCJ-02 坐标转换 |
| `core/map/map_config.dart` | `MapConfig`, `MapPreset` | 6 个城市预设 lat/lng 中心点 |
| `core/map/smart_tile_provider.dart` | `SmartTileProvider` | 三级瓦片降级，坐标自动转换 |
| `core/map/mbtiles_tile_provider_io.dart` | `MBTilesTileProvider` | 离线瓦片读取 |

### 围栏模块

| 文件 | 类/方法 | 说明 |
|------|---------|------|
| `fence/domain/fence_item.dart` | `FenceItem` | 围栏数据模型，含 vertices（lat/lng 列表） |
| `fence/data/fence_dto.dart` | 解析函数 | JSON→FenceItem 解析，含坐标转换 |
| `fence/domain/fence_edit_operations.dart` | `FenceEditOperations` | 围栏编辑操作（顶点增删改） |
| `fence/domain/fence_edit_session.dart` | `FenceEditSession` | 编辑会话，管理 lat/lng 顶点状态 |
| `fence/presentation/widgets/fence_edit_toolbar.dart` | `FenceEditToolbar` | 编辑工具栏 UI |
| `fence/presentation/widgets/fence_template_picker.dart` | `FenceTemplatePreset` | 围栏模板预设（矩形/圆形，含坐标生成） |
| `fence/presentation/fence_controller.dart` | `FenceController` | 围栏 Riverpod Controller |

### 牧场创建

| 文件 | 类/方法 | 说明 |
|------|---------|------|
| `farm_creation/presentation/wizard_step_basic_info.dart` | `_WizardStepBasicInfoState` | 第一步：地图点击选中心 lat/lng |
| `farm_creation/presentation/wizard_step_fence_drawing.dart` | `_WizardStepFenceDrawingState` | 第二步：绘制围栏，保存前 GCJ-02→WGS-84 逆转换 |

### 数据生成

| 文件 | 类/方法 | 说明 |
|------|---------|------|
| `core/data/generators/gps_trajectory_generator.dart` | `GpsTrajectoryGenerator` | GPS 轨迹生成器（围栏内随机 lat/lng 游走） |
| `core/data/demo_seed.dart` | `DemoSeed` | Demo 种子数据，含 GPS 锚点坐标 |

---

## 4. Mock Server（Node.js）

| 文件 | 函数 | 说明 |
|------|------|------|
| `data/fenceStore.js` | `createFence` | 创建围栏，校验坐标有效性 |
| `data/seed.js` | `generateAnimals` | 50 头牲畜 GPS 坐标生成 |
| `utils/geo.js` | `pointInRing` | 射线法判断点是否在多边形内 |
| `utils/geo.js` | `pointInAnyFence` | 判断点是否在任意围栏内 |
| `utils/geo.js` | `boundaryStatusForPoint` | 返回边界状态（inside/outside） |
| `routes/map.js` | 路由处理 | 地图路由：实时位置、轨迹、围栏内检测 |
| `routes/fences.js` | `handleValidationError` | 围栏验证错误处理（坐标缺失、自交叉等） |

---

## 5. 坐标系使用规则

| 场景 | 坐标系 | 说明 |
|------|--------|------|
| 后端存储（DB） | WGS-84 | 所有 lat/lng 均以 WGS-84 存储 |
| 后端 API 传输 | WGS-84 | 请求/响应均使用 WGS-84 |
| Flutter 地图渲染 | GCJ-02 | 高德底图需要 GCJ-02 坐标 |
| Flutter 用户交互 | GCJ-02 → WGS-84 | 用户点击地图（GCJ-02），保存前逆转换为 WGS-84 |
| Mock Server | WGS-84 | 与后端一致 |

---

## 6. 关键数据流

```
GPS 设备 → [lat/lng WGS-84] → GpsLogController → gps_logs 表
                                              → FenceBreachDetector → 越界告警

Flutter 地图点击 → [GCJ-02] → coord_transform.wgs84ToGcj02
                              → FarmController/FenceController → [WGS-84] → DB

DB fences.vertices → [WGS-84 JSON] → FenceMapper → Fence.java → FenceBreachDetector
                                       ↓
                                  Flutter FenceDto → coord_transform → [GCJ-02] → 地图渲染
```

---

*本报告基于知识图谱 1,408 节点 / 1,639 条边自动生成。*
