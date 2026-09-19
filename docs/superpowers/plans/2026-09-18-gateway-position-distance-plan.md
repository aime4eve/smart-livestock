# 网关位置与通讯距离应用 — 实施计划（Plan）

- **日期**: 2026-09-18
- **状态**: 执行中（用户授权：plan 后直接执行）
- **需求正本**: `docs/superpowers/specs/2026-09-18-gateway-position-distance-requirements.md`（v1，含论文溯源 §4.5）
- **关联工单**: NIX-219（主）、NIX-220（治理一期）、NIX-9（抖动主线，不在本 plan）
- **执行约定**: 每个任务完成后编译验证（后端 `./gradlew compileJava`，前端 `flutter analyze`）；全部完成后 `deploy.sh dev` + 冒烟。用户已授权按 plan 直接执行，P4 与外部依赖项显式排除，不做静默裁剪。

## 0. 范围裁决

**本轮执行**: 治理一期（NIX-220）+ NIX-219 P1/P2/P3 全部功能（F1–F6、F9、F10）。
**不在本轮**（防遗留显式登记）:
- F7 饮水辅助 → 等 NIX-157 水源围栏（P4）
- F8 覆盖诊断地图 → P4
- F4 发情交叉完整逻辑 → 预埋字段，交叉待 NIX-156 发情模块对接
- NIX-9 抖动/野点统计治理管道 → 独立主线
- 31号点种子数据 → gateway_id ↔ 点位对账未完成，迁移只建表不插种子

## 1. 任务分解

| # | 任务 | 内容 | 需求/论文引用 | 验证 |
|---|------|------|--------------|------|
| T1 | 数据库迁移 | `V20260918100000__gateway_registry_and_governance.sql`：`gateway_registry`（gateway_id 全局唯一 UK、lat/lng DECIMAL(10,7)、marked_by/marked_at/source）、`gateway_distance_profiles`（逐网关分位数表 JSONB、样本量、窗口）、`gps_quality_flags`（device_id/report_time/rule/reason 天级聚合）；时间戳分区表遵循 PartitionMaintenanceService 兼容（前两者小表不分区，flags 表小表不分区） | F11/F1；实证 | 全新库 Flyway 跑通（Testcontainers 既有基线） |
| T2 | 治理框架一期（NIX-220） | iot 包新增 `governance`：`TelemetryValidationRule` 接口（pass/flag(reason)）、`GpsCoordRangeRule`/`GpsNoFixRule`/`GatewayPresentRule`、`GpsDataGovernanceService`（按帧判定+flag 落库+计数）；接入点：`TelemetryIngestionService`/GPS 路径消费前过滤；指标查询端点（admin，按设备/规则/天） | F11；实证（842/897、(0,0)、空 gateway 3020） | 单测：越界/0,0/正常帧三分支；真库集成测试（经验 #19） |
| T3 | 网关注册与发现 | `GatewayRegistryJpaEntity/Repository`；`GatewayRegistryController`：①GET 本牧场通联网关（聚合 device_telemetry_logs gateway_id：最后通信时间、帧数、标记状态）②PUT 标记坐标（全局唯一 upsert，已有坐标时响应携带原标记人/时间供前端弹覆盖确认）③admin 对账端点：登记清单/未标记清单/标记率 | F1/F10 | compileJava + 端点单测（farm 权限、覆盖语义） |
| T4 | 距离计算 | `GatewayDistanceService`：帧级距离（消费治理 pass 帧，Haversine）；设备距离端点：按网关分组（最新/30 天中位/P95）+ 最近网关派生；过滤 (0,0)/越界/无坐标网关 | F2；P1 WiMOB19 GPS 锚点；实证 | 单测（Haversine 已知距离对）+ 留出法脚测 |
| T5 | 链路分档与预警 | `DeviceLinkQualityService`：设备×网关 30 天滑窗 rssi/snr → stable(≥-90)/weak(-100~-90)/edge(<-100) 三档；edge 档接 `detectDeviceAlerts` 同管道建 LINK_QUALITY 告警（复用去重+自动解除） | F3；P2 Fargas（分档而非测距）；9/15 前兆实证 | 单测分档边界；告警建单/解除集成测试 |
| T6 | 动态映射（方案 B） | 每日 Job `GatewayDistanceProfileJob`：治理 pass 且 GPS 有效帧 → 逐网关 RSSI→距离分位数表（P50/P90 per 5dB 桶，时间加权）写 `gateway_distance_profiles`；推断服务：无 GPS 帧查表给 [P50,P90] 档位；回退链 = 映射表→log-distance(>100m 段，参数参照 P1 n=4.2/PL0=42dB 可配)→unknown | F2/方案B；**P1 WiMOB19**；P4 Rappaport；P6 参数 | 留出法 80/20：档位一致率 ≥80%、区间覆盖 ≥90%（测试断言） |
| T7 | 场景规则层 | ①F4 离群：日任务按群当日基线（最近网关距离中位数+3×MAD 或绝对阈值 max(1.5km)，可配）出离群事件（独立去重窗口，事件表预埋 estrus_score 字段）；②F5 归牧：可配时刻（默认 19:30 本地）+阈值（默认 200m）扫未归头数→提醒；③F6 游走半径：日聚合 max/mean 距离入画像表 | F4/F5/F6；**P1**（聚群假设）；F4 交叉预埋待 NIX-156 | 单测基线判定；阈值配置端点 |
| T8 | App 前端 | features/mine 新增"网关位置"：列表（发现+标记状态）→ 标记页（geolocator 定位+精度圈+地图拖动微调（复用 flutter_map 围栏交互）+覆盖确认弹窗）；设备详情新增"通讯距离"卡片（按网关分组+分档徽标+unknown 文案 F9）；FarmScoped 基类约定（§AGENTS 5） | F1/F2/F9 | flutter analyze + gen-l10n 无缺失 |
| T9 | App admin 视图 | admin 区新增"网关登记"页：清单+未标记对账+标记率（消费 T3 admin 端点） | F10 | flutter analyze |
| T10 | i18n | app_*.arb 中英同步；后端 messages_zh/en 同步（告警文案/质量指标） | 验收 §6 | 双语 key 对齐检查 |
| T11 | 收口 | `./gradlew test` 目标测试集（对比 19 失败基线不扩大）；`deploy.sh dev`；冒烟（登录 200/迁移应用/端点 401→token 200）；知识库+工单回填 | 全部 | 判据按 AGENTS #23 |

## 2. 需求追溯矩阵（防遗留）

| 需求 | 任务 | 状态 |
|------|------|------|
| F1 标记 | T3+T8 | ☐ |
| F2 距离展示 | T4+T8（推断部分 T6） | ☐ |
| F3 链路预警 | T5 | ☐ |
| F4 离群/盗失 | T7（发情交叉预埋，完整交叉依赖 NIX-156 **登记不在本轮**） | ☐ |
| F5 归牧点名 | T7 | ☐ |
| F6 游走半径画像 | T7 | ☐ |
| F7 饮水辅助 | **不在本轮**（NIX-157） | — |
| F8 覆盖诊断地图 | **不在本轮**（P4） | ☐(P4) |
| F9 未知体验 | T8 | ☐ |
| F10 admin 对账 | T3+T9 | ☐ |
| F11 治理一期 | T2 | ☐ |

## 3. 执行顺序

T1 → T2 → T3 → T4 → T5 → T6 → T7（后端主线，每步编译）→ T8/T9/T10（前端，可并行）→ T11 收口。

## 4. 风险

- 动态映射验收（T6）依赖真实数据距离动态范围（当前 0–300m）：远档在 test 环境可能无法达到 ≥80% 一致率——验收按"近中档达标+远档区间覆盖达标"口径执行，异常时回报用户而非放宽口径。
- `device_telemetry_logs` 聚合查询需走月分区裁剪，避免全表扫（经验：26 张检验单慢查询教训）。
- 告警管道复用需确认 detectDeviceAlerts 的 farm_id 非空约束路径（9/15 附带发现：未分配牧场设备建告警会 ingest 失败——T5 需防御）。
