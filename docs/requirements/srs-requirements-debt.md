# SRS 需求债专项盘点（REQ-DEBT）

> 盘点对象：docs/superpowers/_archive/reviews/ 48 份评审的待定/P1/P2 项。方法：只读代码核实状态，不修债；已闭环的引用终评，未闭环的列 REQ-DEBT-NNN。
> 核实基线：master b10492b3（2026-11-20）。

## 一、重点评审逐项核实

### 1.1 2026-05-07-mvp-backend-design-deep-review.md（I8–I14）

| 来源编号 | 问题 | 代码核实（2026-11-21） | 债务编号与状态 |
|----------|------|------------------------|----------------|
| I8（P1） | gps_logs 缺 livestock 相关查询路径索引 | **已闭环**：V3__create_iot_tables.sql L53 有 idx_installations_livestock；L66 有 idx_gps_logs_device_time(device_id, recorded_at DESC)；轨迹查询经 active installation 关联（经验 #14 治理） | 闭环，引用本评审+迁移证据 |
| I9（P2） | 分层约束无强制执行机制（ArchUnit） | **未闭环**：代码库无 ArchUnit 测试 | REQ-DEBT-004（P2） |
| I10（P2） | 共享内核职责边界不清（ApiResponse、RedisCacheService 不应入 shared/） | **部分闭环**：已重组为 com.smartlivestock.shared 模块（含 shared/domain），原始边界争议未逐类复核 | REQ-DEBT-005（P2） |
| I11（P2） | updated_at 更新策略不明确 | **未闭环**：无成文触发规则（元数据 vs 运行时状态） | REQ-DEBT-006（P2） |
| I12（P2） | Tenant/Farm/UserFarmAssignment 域模型测试缺口 | **未闭环**（抽查未见对应专项域测试；历史失败基线内未见补齐记录） | REQ-DEBT-007（P2） |
| I13（P2） | 跨上下文引用一致性校验步骤未成文 | **未闭环**（InstallationApplicationService 无成文校验说明） | REQ-DEBT-009（P2，低风险） |
| I14（P2） | 时间戳类型不统一（TIMESTAMP+LocalDateTime → TIMESTAMPTZ+OffsetDateTime） | **部分闭环**：迁移中 TIMESTAMPTZ 98 处 vs 裸 TIMESTAMP 134 处并存；Java 侧 OffsetDateTime 仅 2 文件、LocalDateTime 仍 7 文件；gps_logs 已专项修复（V20260710160000） | REQ-DEBT-003（P2，收口范围待定） |

### 1.2 2026-06-19-ai-health-roadmap-review.md（AI 路线图待定项）

| 来源问题 | 代码核实 | 债务编号与状态 |
|----------|----------|----------------|
| router 按 N_eff 分档阈值未定义（决策 #5，评审 high 项） | anomaly_scores/HealthAnomalyService 已带 n_eff 字段与告警文案，但**无分档路由实现** | REQ-DEBT-001（P2，Phase B 前置）：定义分档阈值（评审建议量级：小样本 Mahalanobis / 大样本 iForest） |
| N_eff 极小时冷启动兜底未定义（评审 medium 项） | 无冷启动路由策略代码 | REQ-DEBT-002（P2）：极小样本兜底（规则档降级 or "数据不足"返回）须与 REQ-HLT-032 一并设计 |
| 模拟器数据分布 ≠ 真实数据风险（评审 high 项） | **已闭环**：AGENTS §2 AI 仿真过渡红线 + REQ-HLT-020/021 验收口径（仿真数字不得表述为真实效果、真实数据到位后 real-only 复核）已制度化为需求条款 | 闭环，引用 AGENTS §2 与 2026-11-06 用户裁决 |
| Phase B/C 触发/退出条件缺失（评审 medium 项） | PRD §10.6 已加 as-built 注（前置部分交付、监督训练与 real-only 评估仍规划），**触发条件仍为定性"数百头牛×数月"** | 并入 REQ-DEBT-001 备注（设计 Phase B 时补触发/退出条件） |

## 二、其余评审家族处置

| 评审家族 | 处置 |
|----------|------|
| offline-map 系列（2026-05-27/28，11 份） | **已闭环**：三 plan re-review + code-quality-review-v2 逐项 ✅（P1-4~10 已解决，P1-5 部分解决→LIKE 查询子串风险记 REQ-DEBT-010 P2）；遗留 P2（fence_type 语义、坐标转换等）随终评收口或在 REQ-RCH-006 落地 |
| Commerce 系列（2026-05-17/18/22，6 份） | **已闭环**：架构评审与 Plan 修正、配额引擎/API 评审意见在部署质量报告（2026-05-22）收口；遗留问题汇总节逐条销项 |
| flutter-full-adaptation 系列（2026-05-23，2 份） | **已闭环**：P1 逐项修正（ApiClient 注入、token fallback 移除、SubscriptionTier 对齐等）；P2-12/13（统一错误 UI、骨架屏标准）记 REQ-DEBT-010 关联项 |
| 项目总体技术架构评审（2026-05-18） | P1 任务卡已执行（跨上下文依赖 P1.5 耦合风险随事件流改造收口）；P2 任务卡部分转 REQ-DEBT-004/006 |
| ai-platform Phase A（2026-06-20/21） | **已闭环**：code review 意见修正合入；Phase B 前置债即 REQ-DEBT-001/002 |
| device-soft-delete 系列（2026-07-21，6 份） | **已闭环**：final review 收口，legacy governance 单独评审完成 |
| gps-quality 系列（2026-07-13/15，5 份） | **已闭环**：spec/plan review + verification 终评通过（REQ-IOT-005） |
| multi-client-api-contract-review（2026-05-07） | **已闭环**：P1 端点迁移表全部执行（farm-scoped 路由）；P2 Phase 2 项（twin/subscription/b2b/revenue/contracts）已由 Commerce 落地取代 |
| mvp-specs-review（2026-05-07） | **已闭环**：P1/P2 随 MVP 交付销项；读状态 mock 债见 REQ-DEBT-008 |
| 其余 UX/UI/registration 评审（2026-06-11、07-10、07-15 系列） | **已闭环**：各终评通过 |

## 三、REQ-DEBT 台账

| 编号 | 描述 | 来源 | 优先级 | 状态 |
|------|------|------|--------|------|
| REQ-DEBT-001 | N_eff 分档路由阈值未定稿（Phase B 核心算法决策；需同时补 Phase B/C 触发/退出条件） | ai-health-roadmap-review 决策#5/§6 | P2 | 未闭环 |
| REQ-DEBT-002 | N_eff 极小冷启动兜底策略未定义 | 同上 评审意见#6 | P2 | 未闭环 |
| REQ-DEBT-003 | 时间戳类型统一收口（TIMESTAMPTZ 98/134 处；LocalDateTime 7 文件 vs OffsetDateTime 2 文件） | deep-review I14 | P2 | 部分闭环 |
| REQ-DEBT-004 | 缺 ArchUnit 分层约束测试 | deep-review I9、总体架构评审 P2 | P2 | 未闭环 |
| REQ-DEBT-005 | shared 内核职责边界逐类复核（原 I10） | deep-review I10 | P2 | 部分闭环 |
| REQ-DEBT-006 | updated_at 触发规则未成文 | deep-review I11 | P2 | 未闭环 |
| REQ-DEBT-007 | Tenant/Farm/UserFarmAssignment 域模型测试缺口 | deep-review I12 | P2 | 未闭环 |
| REQ-DEBT-008 | AlertReadStatusTest 5 个 mock 债（AGENTS §1 全量测试基线 19 失败的一部分） | mvp-specs-review 关联、AGENTS §1 | P1 | 未闭环 |
| REQ-DEBT-009 | InstallationApplicationService 跨上下文校验步骤未成文 | deep-review I13 | P2 | 未闭环 |
| REQ-DEBT-010 | 前端遗留 P2 集合：TileMeta LIKE 查询子串误匹配风险、TileSourceResolver 缓存持久化 TODO、统一错误 UI/骨架屏标准 | offline-map re-review P2-1/2、flutter adaptation P2-12/13 | P2 | 未闭环 |

> 说明：I8、模拟器数据风险两项核实为已闭环，不占 DEBT 编号；已闭环评审家族不重复展开，终评文件即证据。
