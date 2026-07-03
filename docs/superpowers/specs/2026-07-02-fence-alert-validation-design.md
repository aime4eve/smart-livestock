# 围栏预警算法验证方案设计

> 版本: 2.0 | 日期: 2026-07-02 | 状态: 待评审
> 前置文档：[datagen 限界上下文设计](./2026-06-26-datagen-context-design.md)、[IoT 遥测接入设计](./2026-06-03-iot-telemetry-ingestion-design.md)
>
> 版本历史：v1.0 基于高德 GCJ-02 标定；v2.0 改为平台 WGS-84 地图标定（dev 环境 changsha.mbtiles 已就绪）

## 1. 背景与目标

### 1.1 背景

平台计划接入 500 台动物 GPS 追踪器，需要在真实设备数据下验证电子围栏预警算法的可靠性。围栏预警链路已完整实现：

```
设备上报 GPS
  -> POST /api/v1/farms/{farmId}/telemetry          [TelemetryController]
  -> TelemetryIngestionService.ingest()              [校验设备 + 安装记录]
  -> GpsLogApplicationService.logGps()               [写 gps_logs + 发 GpsLogUpdatedEvent]
  -> SpringEventPublisher -> RocketMQ "gps-log-updated"
  -> GpsLogEventConsumer.onMessage()                 [围栏检测 + 告警生成]
      -> FenceBreachDetector.isBreaching / isApproaching
      -> insideAnyFence? -> autoResolve
      -> 外出 + buffer 区? -> FENCE_APPROACH (WARNING)
      -> 外出 + 远离?    -> FENCE_BREACH (CRITICAL)
```

围栏判定算法是确定性的几何计算（射线法 point-in-polygon），不是 AI 模型。判定结果完全可预测，误差来源是 GPS 器件精度。

### 1.2 验证目标

| 目标 | 验证内容 | 方法 |
|------|---------|------|
| 目标 1 | GPS 设备硬件精度 | 已知位置静置标定 CEP |
| 目标 2 | 围栏预警算法准确度 | 分层坐标注入 + TP/FP/FN/TN 量化 |
| 目标 3 | 500 设备并发可靠性 | 真实设备流压力验证 |

### 1.3 核心挑战

围栏预警验证的根本困难是：真实设备上报的是牛的实际位置，但牛在哪里跑不可控。要验证算法是否"判得准"，必须有一批"答案已知"的输入来对照——即已知坐标相对围栏边界的位置关系。

---

## 2. 地图环境与坐标系（已就绪）

### 2.1 WGS-84 统一环境

dev 环境 tileserver-gl 已部署长沙地区 WGS-84 瓦片（`changsha.mbtiles`，426MB，OSM 数据源，zoom 10-16，11.8 万瓦片）。覆盖范围：经度 111.4-114.2，纬度 27.5-28.5，长沙 (28.25, 112.85) 在覆盖区内。

验证链路全环节统一 WGS-84，无坐标系偏移风险：

- 地图显示：tileserver-gl 提供 WGS-84 瓦片（OSM 数据源，`© OpenStreetMap contributors`）
- 围栏存储：平台 UI 在 WGS-84 地图上绘制围栏顶点，直接以 WGS-84 存入数据库（`shouldTransformCoordinates()` 返回 false，不触发 GCJ-02 转换）
- 设备上报：GPS 设备输出 WGS-84 原始坐标
- 围栏判定：`Fence.contains()` 拿到的围栏顶点和 GPS 坐标同为 WGS-84

### 2.2 标定方式

所有围栏和测试区域均在平台 WGS-84 地图上标定，读出的坐标即为 WGS-84 坐标，直接用于注入和对比，不需要任何坐标转换。

### 2.3 降级风险

`SmartTileProvider` 三级降级：tileserver-gl（WGS-84） -> MBTiles 离线（WGS-84） -> 高德/OSM。如果 tileserver-gl 和 MBTiles 同时不可用，会降级到高德 GCJ-02 瓦片，此时地图显示与 WGS-84 坐标有偏移。验证前确认 tileserver-gl 健康（`sl-dev-tileserver-1` 状态 healthy），避免降级。

---

## 3. 目标 1：GPS 设备精度标定

### 3.1 目的

获取 GPS 追踪器的真实定位精度（CEP），作为目标 2 围栏设计的输入参数。

### 3.2 方法

在平台 WGS-84 地图上标定 5 个不同大小的正方形区域，将设备放入后静置采集：

| 区域 | 尺寸 | 预期用途 |
|------|------|---------|
| 区域 A | 10m x 10m（如可标定） | 高精度基准 |
| 区域 B | 20m x 20m | |
| 区域 C | 30m x 30m | |
| 区域 D | 40m x 40m | |
| 区域 E | 50m x 50m | |

### 3.3 设备分配

每个区域放置 10-20 台设备（不是 100 台），原因：

- 10m x 10m 内放 100 台设备间距不到 1 米，GPS 天线互相遮挡产生多径效应
- 测出来的不是器件精度而是天线互扰
- 10-20 台已有足够统计样本量
- 5 个区域共 50-100 台，剩余设备用于目标 2

### 3.4 采集周期

每个区域静置 10 个数据采集周期（例如 10 x 30 分钟 = 5 小时），覆盖卫星几何变化。

### 3.5 统计指标

不用离心率，改用 GPS 行业标准指标：

**CEP（Circular Error Probable，圆概率误差）**：50% 的落点落入的圆半径。

计算方法：

```
对每台设备 i:
  收集 N 个 GPS 采样点 (lat_i_j, lng_i_j)
  计算均值中心 (mean_lat_i, mean_lng_i)
  计算每个采样点到均值的距离 d_i_j
  CEP_i = median(d_i_j)  （该设备的 CEP）

区域 CEP = 所有设备 CEP 的平均值
```

同时记录二维 RMS（2DRMS）作为参考：2DRMS 约 = 2.4 x CEP。

### 3.6 运动修正

目标 1 是静置标定，但目标 2 的牛是运动的。运动状态下 GPS 精度通常比静置差 30%-50%（多径效应、卫星切换、滤波延迟）。

**修正公式**：有效误差 = CEP x 安全系数（1.3-1.5）

建议安全系数取 1.5，即如果静置 CEP = 30m，运动有效误差 = 45m。

---

## 4. 目标 2：围栏预警算法准确度验证

### 4.1 前置条件

- 目标 1 完成，获得 CEP 值
- 围栏以 WGS-84 坐标创建，buffer polygon 已设置

### 4.2 围栏设计

假设目标 1 测出 CEP = 30m，运动安全系数 1.5，则有效误差 sigma = 45m。

在开发环境平台地图上创建一个正方形围栏（WGS-84 坐标），中心点设为测试基准点，边长 L 根据误差确定：

```
L = 200m（参考值，确保安全区宽度 >> 3 x sigma）
```

围栏 buffer polygon 在围栏外扩 bufferDistance（当前默认 50m，可根据 CEP 调整）。

### 4.3 区域分层设计

以围栏中心为原点，按距围栏边界距离分 5 层。每层放 50-80 台设备：

| 区域 | 物理范围（相对围栏边界） | 围栏判定 | 期望告警 |
|------|------------------------|---------|---------|
| 安全区 | 围栏内，距边界 > 3 sigma | insideAnyFence=true | 无告警 |
| 边界内侧 | 围栏内，距边界 < 3 sigma | 可能抖动 | 可能误报 |
| buffer 区 | 围栏外，buffer polygon 内 | isApproaching=true | FENCE_APPROACH |
| 越界区 | 围栏外，buffer polygon 外，距边界 < 3 sigma | isBreaching=true | FENCE_BREACH |
| 远离区 | 围栏外，距边界 > 3 sigma | isBreaching=true | FENCE_BREACH（稳定） |

> 注：3 sigma = 3 x 45m = 135m。安全区和远离区距边界超过 135m，GPS 噪声几乎不会导致跨区域误判。边界内侧和越界区距边界小于 135m，GPS 噪声可能导致跨区域抖动——这正是要测的。

### 4.4 注入方式

通过真实接口注入已知坐标：

```json
{
  "deviceId": "<设备ID>",
  "readings": [
    { "latitude": "<WGS-84 纬度>", "longitude": "<WGS-84 经度>", "recordedAt": "2026-07-02T10:00:00Z" }
  ]
}
```

请求路径：`POST /api/v1/farms/{farmId}/telemetry`

每个区域的设备注入对应坐标，数据流经过完整链路（TelemetryController -> GpsLogEventConsumer -> FenceBreachDetector），与真实设备数据走完全相同的路径。

### 4.5 评估指标

采集 10 个周期后，查 alerts 表统计：

| 指标 | 计算 | 含义 |
|------|------|------|
| Precision（精确率） | TP / (TP + FP) | 告警中正确的比例 |
| Recall（召回率） | TP / (TP + FN) | 应告警中实际告警的比例 |
| F1 | 2 x P x R / (P + R) | 综合指标 |

各区域定义：

- **TP**：越界区/buffer 区设备产生了正确类型的告警
- **FP**：安全区设备产生了告警
- **FN**：越界区/buffer 区设备未产生告警
- **TN**：安全区设备未产生告警

### 4.6 合格标准

| 区域 | 指标 | 合格标准 | 说明 |
|------|------|---------|------|
| 安全区 | FP rate | 0% | 任何误报都是算法 bug |
| 远离区 | Recall | 100% | 远离区必须稳定检出 |
| 越界区 | Recall | >= 95% | 允许 GPS 抖动导致少量漏检 |
| buffer 区 | Recall | >= 90% | approach 更容易因抖动漏检 |
| 边界内侧 | 误报率 | 记录但不判不合格 | 用于量化 GPS 噪声影响 |

### 4.7 方差分析

按各区域距边界的距离分组，计算每组告警判定结果的方差：

```
方差 = Var(实际判定 vs 期望判定)
```

目标：

- 安全区和远离区方差应接近 0（GPS 噪声不足以导致跨区域误判）
- 边界内侧和越界区方差较大（GPS 噪声导致跨区域抖动）
- 方差从接近 0 突然变大的距离拐点 = 算法可靠性的边界

预期拐点出现在距边界约 1-2 倍 CEP 的位置。如果拐点远大于 2 倍 CEP，说明算法实现有 bug（坐标系未对齐、buffer polygon 计算错误等）。

---

## 5. 目标 3：500 设备并发可靠性验证

### 5.1 目的

验证 500 台真实设备持续上报时系统是否稳定，以及告警生命周期是否正确。

### 5.2 真实设备流验证

500 台设备安装到真实牲畜上（或在测试场地移动），持续上报。此时没有已知答案，做合理性检查：

| 验证项 | 方法 | 合格标准 |
|--------|------|---------|
| 告警密度 | 单位时间告警数 | 正常放牧越界是低频事件，短时间大量告警 = 误报 |
| 空间分布 | 告警坐标画图 | 应聚集在围栏边界附近，围栏中心出现 BREACH = 判定 bug |
| 告警去重 | 同设备+围栏+类型的 ACTIVE 告警数 | 去重后每个设备每围栏每类型最多 1 条 ACTIVE |
| 自动解除 | 牲畜回围栏后旧告警状态 | autoResolve 生效，ACTIVE -> RESOLVED |
| 状态升级 | approach -> breach | 旧 APPROACH 告警自动 resolve |
| 消费延迟 | GpsLogEventConsumer 处理时间 vs recordedAt | < 5s（500 设备 x 10s 间隔 = 50 msg/s） |

### 5.3 GPS 抖动告警风暴检查

边界附近设备如果 GPS 高频抖动，可能在围栏内外反复横跳。验证 `createAlertIfNeeded` 的去重逻辑：

```sql
-- 检查是否有同一设备+围栏的重复 ACTIVE 告警
SELECT livestock_id, fence_id, type, COUNT(*) as cnt
FROM alerts
WHERE status = 'ACTIVE'
  AND type IN ('FENCE_BREACH', 'FENCE_APPROACH')
GROUP BY livestock_id, fence_id, type
HAVING COUNT(*) > 1;
```

结果应为空集。

---

## 6. 实施计划

### 6.1 数据准备（用户操作）

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 开发环境创建围栏 | 平台 WGS-84 地图上绘制，设置 buffer polygon |
| 2 | 导入 500 头牛 + 500 台设备 | 含 device-livestock 关联（installations） |
| 3 | 目标 1 场地标定 | 平台 WGS-84 地图标定 5 个区域，直接读出坐标 |
| 4 | 部署设备 | 按区域分配，静置采集 |

### 6.2 工具开发（Agent 实施）

| 工具 | 用途 | 依赖 |
|------|------|------|
| GPS 精度分析工具 | 从 gps_logs 计算 CEP / 2DRMS | 目标 1 数据采集完成 |
| 围栏验证报告生成器 | 从 alerts + gps_logs 统计 TP/FP/FN/TN + 方差 | 目标 2 数据采集完成 |
| 去重检查 SQL | 验证告警去重有效性 | 目标 3 运行中 |

### 6.3 执行顺序

```
目标 1（精度标定）
  -> 获得 CEP
  -> 计算有效误差 sigma = CEP x 1.5
  -> 设计围栏尺寸和区域分层

目标 2（算法验证）
  -> 创建围栏（WGS-84 + buffer）
  -> 分层注入已知坐标
  -> 采集 10 周期
  -> 统计 TP/FP/FN/TN + 方差分析
  -> 确认合格标准

目标 3（并发验证）
  -> 500 真实设备上线
  -> 运行 30 分钟以上
  -> 合理性检查 + 去重检查 + 延迟检查
```

---

## 7. EvaluationService 评估层缺陷修复

当前 `EvaluationService` 围栏评估只统计了命中率（detected/injected），缺少假阳性（FP）计算。需要修复以支持完整的 TP/FP/FN/TN 四象限评估。

### 7.1 当前问题

```java
// EvaluationService.java 当前逻辑（简化）
long breachHit = injectedBreach.stream().filter(detectedBreach::contains).count();
// 只算了"注入了 breach 的牲畜中有多少被检出"（相当于 recall）
// 没有计算"未注入 breach 的牲畜中有多少被误报"（FP）
```

### 7.2 修复方向

补充 FP 统计：未被注入围栏异常标签的牲畜，如果在评估窗口内产生了 FENCE_BREACH/FENCE_APPROACH 告警，计为假阳性。

```java
// 伪代码
Set<Long> allLivestock = deviceQueryPort.findActiveInstallations()...;
Set<Long> injected = ...; // 从 ground truth 获取
Set<Long> detected = ...; // 从 alerts 获取

int breachTP = injectedBreach.stream().filter(detectedBreach::contains).size();
int breachFN = injectedBreach.size() - breachTP;
int breachFP = detectedBreach.stream().filter(id -> !injectedBreach.contains(id)).size();
int breachTN = allLivestock.size() - injectedBreach.size() - breachFP;

double breachPrecision = (TP + FP) > 0 ? (double) TP / (TP + FP) : 0;
double breachRecall    = (TP + FN) > 0 ? (double) TP / (TP + FN) : 0;
double breachF1        = (P + R) > 0 ? 2 * P * R / (P + R) : 0;
```

对 FENCE_BREACH 和 FENCE_APPROACH 分别计算四象限，与健康评估对齐。

修复后 `EvaluationReport` 新增字段：

```java
public record EvaluationReport(
    // ... 现有字段 ...
    // 新增围栏完整指标
    int fenceBreachTP, int fenceBreachFP, int fenceBreachFN, int fenceBreachTN,
    double fenceBreachPrecision, double fenceBreachRecall, double fenceBreachF1,
    int fenceApproachTP, int fenceApproachFP, int fenceApproachFN, int fenceApproachTN,
    double fenceApproachPrecision, double fenceApproachRecall, double fenceApproachF1
) {}
```

### 7.3 修复时机

在目标 2 执行前修复，使评估报告直接可用，无需手动跑 SQL。

---

## 8. 关键风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| tileserver 降级到高德 | 地图标定偏移 | 确认 sl-dev-tileserver-1 健康，瓦片覆盖长沙 |
| buffer polygon 未设置 | FENCE_APPROACH 不触发 | 创建围栏时确认 buffer 已生成 |
| 设备密度过高 | 多径效应干扰精度标定 | 每区 10-20 台 |
| 静置 != 运动精度 | 目标 2 低估误差 | sigma = CEP x 1.5 |
| RocketMQ 积压 | 告警延迟 | 监控消费延迟，必要时调并发 |
| GPS 抖动风暴 | 重复告警 | createAlertIfNeeded 去重 + 验证 |

---

## 9. 现有系统相关接口

| 接口 | 方法 | 用途 |
|------|------|------|
| `/api/v1/farms/{farmId}/telemetry` | POST | 设备数据上报（真实 + 注入同一入口） |
| `/api/v1/admin/datagen/scenarios` | POST | 创建合成场景 |
| `/api/v1/admin/datagen/scenarios/{id}/start` | POST | 启动场景 |
| `/api/v1/admin/datagen/evaluation` | GET | 评估报告 |
| `/api/v1/admin/datagen/labels` | GET | 查询 ground truth 标签 |

### 关键源文件

| 文件 | 职责 |
|------|------|
| `TelemetryController.java` | 遥测数据入口 |
| `TelemetryIngestionService.java` | 遥测摄入（校验 + GPS 提取） |
| `GpsLogApplicationService.java` | GPS 入库 + 事件发布 |
| `GpsLogEventConsumer.java` | GPS 事件消费 + 围栏检测 + 告警生成 |
| `FenceBreachDetector.java` | 围栏判定（breach / approach / return） |
| `Fence.java` | contains() / containsBuffer()（射线法） |
| `EvaluationService.java` | 评估框架（待修复 FP 计算） |
| `SynthesisService.java` | 合成数据生成（含围栏位移注入） |
