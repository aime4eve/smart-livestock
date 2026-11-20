# SRS 模块：Ranch 与 IoT（REQ-RCH / REQ-IOT）

## 一、Ranch 域（RCH）：牲畜 · 围栏 · 告警

| 编号 | 需求 | 来源 | 优先级 | 验收标准 | 实现状态 |
|------|------|------|--------|----------|----------|
| REQ-RCH-001 | 牲畜档案 CRUD：品种/性别/出生日期（推月龄）等字段，支持分层统计 | S1 backend §3.2、S2 PRD §6.7 | P0 | 字段齐备；breed/gender/birthDate 支撑饮水/行为分层口径 | 已实现 |
| REQ-RCH-002 | 实时地图：牧场全景 + 牲畜位置展示 | S2 PRD §6.3.1、S3 虚拟围栏需求分析 §四/§五 | P0 | 地图加载并显示最新定位；逐瓦片智能路由 | 已实现（§4.12 瓦片基础设施 + NIX-237 逐瓦片坐标变换） |
| REQ-RCH-003 | 虚拟电子围栏：围栏 CRUD、越界告警 | S3 2026-03-27（谱系源）、S2 PRD §6.3.2/§6.3.3 | P0 | 围栏 CRUD + 越界事件触发改告警；后端越界检测规则与 S1 §六一致 | 已实现 |
| REQ-RCH-004 | 围栏预警缓冲带：50m 预警带画在围栏外侧、带洞挖除、仅聚焦选中显示，几何单源于后端 JTS bufferPolygon | S2 审计 #2（NIX-412，#153/156–160） | P0 | 前端仅消费后端几何；聚焦选中才渲染 | 已实现 |
| REQ-RCH-005 | 围栏从设备轨迹生成：三候选包络 + 顶点编辑 + 生成元数据 + 三校准参数滑杆 | S2 审计 #3（#148/150/151） | P1 | 生成→编辑→保存链路可用；元数据落库 | 已实现 |
| REQ-RCH-006 | 围栏面积真实值与 WGS-84/GCJ-02 坐标体系 | S1（NIX-200）、S2 审计 #9 | P0 | 面积按真实几何计算；坐标体系按 PRD §4.12.4 | 已实现 |
| REQ-RCH-007 | 历史轨迹查询：按牲畜/时段查询轨迹 | S2 PRD §6.3.4 | P0 | 轨迹查询返回与 gps_logs 一致；时间格式正确 URL 编码（经验 #14） | 已实现 |
| REQ-RCH-008 | 告警状态机（V26 重设计）：active/resolved + 读状态管理 | S1 backend §六、S2 PRD §6.5.2 | P0 | 状态机迁移正确；读状态测试债见 REQ-DEBT-008 | 已实现（AlertReadStatus mock 债未清） |
| REQ-RCH-009 | 告警中心：告警类型齐全（越界/体温/离体/发情/分娩/饮水/设备），状态机+通知 | S2 PRD §6.5 | P0 | 告警类型清单与 PRD §6.5.1 对齐 | 已实现 |
| REQ-RCH-010 | 告警 UI/UX 统一（ranch panel） | S1（2026-06-11 评审，终评闭环） | P1 | UI 统一规范落地 | 已实现（引用终评） |
| REQ-RCH-011 | 轨迹巡检（track line inspection，NIX-68） | S1（2026-07-28 spec 评审闭环） | P1 | 巡检规格与终评一致 | 已实现 |
| REQ-RCH-012 | 牧场牲畜生命周期管理（入场/离场/死亡/出售） | S1 backend §3.2 | P1 | 生命周期事件可追溯 | 已实现 |
| REQ-RCH-013 | 无人机巡检（Drone Patrol） | S2 PRD §6.14（P2）、S3 谱系 | P2 | —（PRD US-12/16） | 规划未实现（代码无 drone/DJI 命中，2026-11-18 审计核实） |
| REQ-RCH-014 | 离线地图与离线围栏编辑（移动端弱网可用） | S1 frontend、2026-05-27/28 offline-map 评审系列（终评闭环） | P1 | 离线瓦片下载/引用计数/围栏离线同步按终评方案落地 | 已实现（offline-map 三 plan 终评 + code review v2 收口） |

## 二、IoT 域（IOT）：设备 · License · 安装 · GPS

| 编号 | 需求 | 来源 | 优先级 | 验收标准 | 实现状态 |
|------|------|------|--------|----------|----------|
| REQ-IOT-001 | 设备接入：经 hkt-blade-device 平台采集 CATTLE_TRACKER 数据（REST 拉取） | S2 PRD §4.13、S1 §3.3 | P0 | 已验证端点清单（PRD §4.13.6）全通；数据维度齐全 | 已实现 |
| REQ-IOT-002 | ThingsBoard 直连通道（NIX-179/180/214） | S2 PRD §4.13A | P0 | 直连通道与 blade 通道并存且 source 不混淆 | 已实现 |
| REQ-IOT-003 | GPS 遥测摄取：ingest 事务只写 gps_ingestion_tasks，调度器异步写 gps_logs（outbox 模式） | S2 PRD §4/AGENTS §2 | P0 | ingest 事务无 GPS 直写；异步链路幂等 | 已实现（GpsIngestionTaskScheduler；压测报告 2026-08-22） |
| REQ-IOT-004 | GPS 幂等与去重：以 (device_id, recorded_at) 为幂等键，唯一约束防重 | S1、AGENTS §2 | P0 | 重复摄取零重复行（V20260720120000 唯一约束） | 已实现 |
| REQ-IOT-005 | GPS 质量检测（jitter 治理）：速度阈值过滤（牛 >3 m/s 丢弃/降权）、停留点检测（距离 D≈15m + T 1–1.5h）、围栏事件冷却 2–5 分钟 | S4 gps-jitter 系列（best-practices/5device-validation）、2026-07-13/15 评审（终评闭环） | P0 | 质量检查按终评方案实现；5 机实测验证通过 | 已实现（gps_quality_sessions/tests，NIX-219/220 网关定位与数据质量已交付） |
| REQ-IOT-006 | GPS 写入时间戳统一时区（TIMESTAMPTZ 语义） | S1（V20260710160000 迁移） | P0 | 迁移修复 checksum 一致；跨时区查询正确 | 已实现（部分：全局时间戳统一债见 REQ-DEBT-003） |
| REQ-IOT-007 | MQTT/EMQX 设备接入通道 | S2 PRD §4.6/§4.8/L971 主题表 | P2 | 主题规划表实现；与 REST 通道并存 | 规划未实现（main 源码 0 命中，2026-11-18 审计核实，仅测试文件 1 处） |
| REQ-IOT-008 | 设备 License 管理：授权设备数、到期控制 | S1 §3.3 | P0 | 超授权设备被拒；license 状态可查 | 已实现 |
| REQ-IOT-009 | 安装管理：设备-牲畜安装/拆卸，活跃安装唯一约束 | S1 §3.3、S2 PRD §6.9 | P0 | installations(device_id) WHERE removed_at IS NULL 唯一索引生效（V3 迁移 L52） | 已实现 |
| REQ-IOT-010 | 设备软删除与遗留治理 | S1（2026-07-21 六份评审，终评闭环） | P1 | 软删除后设备数据可追溯且不参与活跃统计 | 已实现（final review 收口） |
| REQ-IOT-011 | 设备健康管理（Phase 3）：健康评分模型、入网旅程、数据分流、datagen 适配 | S2 PRD §4.14 | P1 | 评分模型字段与 PRD §4.14.2 一致；健康表迁移齐备 | 已实现（Phase 3 design review 2026-07-09 闭环） |
| REQ-IOT-012 | 蓝牙断链丢失告警（固件 0xB0/0xB1） | S2 PRD §1.3/§6.5.1 注 | P2 | 固件协议落地后端到端告警 | 规划未实现（无对应枚举/代码，2026-11-18 审计核实） |
