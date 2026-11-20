# 追溯矩阵（Traceability Matrix）

> 唯一权威源：本文件由 docs/traceability-matrix.md.gen.mjs 生成（node docs/traceability-matrix.md.gen.mjs），基线 2026-11-21。
> 需求编号体系：docs/requirements/srs-smart-livestock.md（REQ-<域>-NNN，80 条）+ srs-requirements-debt.md（REQ-DEBT-001~010）。
> 用例编号体系：testing/test-cases/（TC-<域>-NNN，2604 条 / 357 文件；域 RCH/IOT/HLT/IDT/CMC/PLT/JRY）。
> 映射口径：TC→REQ 为 testing/test-cases 分册的自动映射列（关键词映射，人工校对后升级为定稿口径）。

## 一、覆盖统计

| 指标 | 值 |
|---|---|
| REQ 需求条目 | 80 |
| 有 TC 覆盖的 REQ | 33 |
| 无 TC 覆盖的 REQ | 47（见 §四） |
| TC 用例总数 | 2604 |
| 映射到 REQ 的 TC 引用 | 8853 |
| 未映射到任何 REQ 的 TC 引用 | 21 |

## 二、REQ ↔ TC 全量映射表

TC 编号每 REQ 最多列 20 条，超出以「…共 N 条」汇总，全清单见对应分册。

| REQ | 需求摘要 | PRD 章节 / 来源 | 优先级 | 实现状态 | 覆盖 TC 数 | TC 编号（≤20） | 代表测试代码路径 | 工单/PR |
|---|---|---|---|---|---|---|---|---|
| REQ-HLT-001 | 瘤胃温度时序采集与分区存储：5min 展开写入、temperature_lo… | PRD §5.4 | P0 | 已实现 | 120 | TC-PLT-148、TC-PLT-149、TC-PLT-150、TC-PLT-151、TC-PLT-152、TC-PLT-153、TC-PLT-154、TC-PLT-155、TC-PLT-156、TC-PLT-157、TC-PLT-103、TC-IOT-041、TC-HLT-007、TC-RCH-238、TC-RCH-245、TC-IOT-131、TC-IOT-132、TC-IOT-133、TC-IOT-134、TC-IOT-135 …共 120 条 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart` | — |
| REQ-HLT-002 | 体温离体门卫：35–43°C 之外丢弃 | — | P0 | 已实现 | 120 | TC-PLT-148、TC-PLT-149、TC-PLT-150、TC-PLT-151、TC-PLT-152、TC-PLT-153、TC-PLT-154、TC-PLT-155、TC-PLT-156、TC-PLT-157、TC-PLT-103、TC-IOT-041、TC-HLT-007、TC-RCH-238、TC-RCH-245、TC-IOT-131、TC-IOT-132、TC-IOT-133、TC-IOT-134、TC-IOT-135 …共 120 条 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart` | — |
| REQ-HLT-003 | 发热判级：delta ≥1.0°C 或持续 >2h = FEVER（Feve… | — | P0 | 已实现 | 488 | TC-PLT-009、TC-PLT-012、TC-PLT-018、TC-IOT-039、TC-IOT-071、TC-HLT-008、TC-HLT-009、TC-HLT-015、TC-HLT-020、TC-HLT-022、TC-HLT-023、TC-HLT-028、TC-HLT-029、TC-RCH-175、TC-RCH-212、TC-RCH-213、TC-RCH-214、TC-RCH-251、TC-RCH-252、TC-RCH-253 …共 488 条 | `Mobile/mobile_app/test/contract/api_contract_test.dart` | — |
| REQ-HLT-004 | 健康瓷片统一订阅门控 + 分娩预警瓷片与预测页 + 锁定态平台配置 | — | P0 | 已实现 | 141 | TC-RCH-240、TC-RCH-241、TC-PLT-173、TC-PLT-174、TC-PLT-175、TC-PLT-176、TC-PLT-177、TC-HLT-030、TC-HLT-031、TC-HLT-032、TC-HLT-033、TC-HLT-049、TC-HLT-050、TC-HLT-051、TC-HLT-052、TC-HLT-053、TC-HLT-054、TC-HLT-055、TC-HLT-056、TC-HLT-057 …共 141 条 | `Mobile/mobile_app/test/features/pages/calving_page_test.dart` | NIX-389 |
| REQ-HLT-005 | healthStatus 快照派生全读面（NIX-198） | — | P0 | 已实现 | 450 | TC-PLT-009、TC-PLT-012、TC-PLT-018、TC-IOT-039、TC-IOT-071、TC-HLT-008、TC-HLT-009、TC-HLT-015、TC-HLT-020、TC-HLT-022、TC-HLT-023、TC-HLT-028、TC-HLT-029、TC-RCH-212、TC-RCH-213、TC-RCH-214、TC-RCH-251、TC-RCH-252、TC-RCH-253、TC-RCH-254 …共 450 条 | `Mobile/mobile_app/test/contract/api_contract_test.dart` | — |
| REQ-HLT-006 | 时序分区：temperature_logs/rumen_motility_l… | — | P0 | 已实现 | 114 | TC-RCH-001、TC-RCH-002、TC-RCH-003、TC-RCH-006、TC-RCH-007、TC-RCH-041、TC-RCH-042、TC-RCH-043、TC-RCH-044、TC-RCH-045、TC-RCH-046、TC-RCH-047、TC-RCH-048、TC-RCH-242、TC-RCH-243、TC-RCH-244、TC-RCH-252、TC-PLT-262、TC-PLT-266、TC-HLT-170 …共 114 条 | `Mobile/mobile_app/test/features/alerts/alert_detail_sheet_estrus_test.dart` | — |
| REQ-HLT-010 | 饮水事件检测（V 形组合检测器）：判据 A 斜率 fall/Δt ≥ 0.0… | — | P0 | 已实现（L1/L2pre/L3 试点链路；PRD §6.16 NIX-256 已交付） | 0 | 无 | — | NIX-256 |
| REQ-HLT-011 | 饮水频次分层口径：泌乳牛参照 7.3±2.8 次/日（Cardot 2008… | — | P1 | 已实现（泌乳/干奶阶段字段列为可选增强不阻塞） | 0 | 无 | — | — |
| REQ-HLT-012 | DRINKING_ABNORMAL 告警 | — | P2 | 规划未实现（等真实数据） | 0 | 无 | — | — |
| REQ-HLT-013 | 活动阈值修正：ABNORMAL 下调至 <8、LOW 下调至 <18、NOR… | — | P1 | 部分实现（个体相对基线通道已建 REQ-HLT-020；绝对分档调整未落地） | 0 | 无 | — | — |
| REQ-HLT-014 | 反刍行为识别：jerk-RMS 单特征下反刍/休息不可分（P50 30.2 … | — | P2 | 谱系-规划（纳入 AI 路线图 Phase B 语义） | 0 | 无 | — | — |
| REQ-HLT-015 | ML 算法矩阵（追踪/健康监测模型分层、性能指标、部署架构、持续优化） | — | P2 | 谱系-规划（Phase B/C 未启动部分） | 0 | 无 | — | — |
| REQ-HLT-020 | 个体体温基线自动学习：7–14 天滑窗安静态样本加权更新均值±2σ 波动带；… | — | P0 | 已实现（2026-11-04/06 全链闭环；真实数据试点后须 real-only 复核） | 0 | 无 | — | — |
| REQ-HLT-021 | 文献参数仿真评估管道：datagen 仿真生成器（DATAGEN 源 + S… | — | P0 | 已实现（#134，PRD §10.6 as-built 注） | 0 | 无 | — | — |
| REQ-HLT-022 | 发情评分时间窗归一化：绝对水平对比替代纯增幅（个体安静态基线比值/差值），事… | — | P0 | 已实现（#138 已交付，审计 #6） | 0 | 无 | — | NIX-380 |
| REQ-HLT-023 | 发情确认/否认回流：verdict → ALERT_CONFIRM 生理审计… | — | P0 | 已实现 | 0 | 无 | — | NIX-286 |
| REQ-HLT-024 | 发情评分解释 + 行版本列（EstrusScoreExplainer、est… | — | P1 | 已实现 | 0 | 无 | — | NIX-390 |
| REQ-HLT-025 | 分娩预警算法：体温先降后回升 + 活动特征（RRT 24–48h 渐降 + … | — | P0 | 已实现 | 0 | 无 | — | NIX-381 |
| REQ-HLT-026 | 配种→预产期自动推算（gestation 倒计时） | — | P2 | 规划未实现（2026-11-18 审计核实，保持 P2/P3） | 0 | 无 | — | — |
| REQ-HLT-030 | AI 异常检测：anomaly_scores 持久化（Phase A 已交付… | — | P1 | 已实现（Phase A） | 0 | 无 | — | — |
| REQ-HLT-031 | N_eff 分档路由（小样本稳健统计 / 大样本 iForest） | — | P2 | 规划未实现（REQ-DEBT-001） | 0 | 无 | — | — |
| REQ-HLT-032 | 降级链冷启动兜底（N_eff 极小时路由策略：规则档 or 数据不足提示） | — | P2 | 规划未实现（REQ-DEBT-002） | 0 | 无 | — | — |
| REQ-HLT-033 | 健康自动刷新与 API 合并 | — | P1 | 已实现 | 0 | 无 | — | — |
| REQ-IDT-001 | 多租户隔离：所有业务数据按 tenant 隔离，租户间零可见 | — | P0 | 已实现（identity 上下文 + farm-scoped API；域测试覆盖债见 REQ-DEBT-005） | 254 | TC-RCH-040、TC-IDT-001、TC-IDT-014、TC-IDT-016、TC-IDT-017、TC-IDT-018、TC-IDT-019、TC-IDT-020、TC-IDT-021、TC-IDT-022、TC-IDT-023、TC-IDT-024、TC-IDT-025、TC-IDT-026、TC-IDT-027、TC-IDT-030、TC-IDT-031、TC-IDT-032、TC-IDT-033、TC-IDT-034 …共 254 条 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart` | — |
| REQ-IDT-002 | 用户认证：JWT 登录、token 刷新、登出失效 | PRD §2.3/§4.7 | P0 | 已实现（NIX-337 改密放行已修） | 107 | TC-IDT-014、TC-IDT-015、TC-IDT-016、TC-IDT-017、TC-IDT-018、TC-IDT-019、TC-IDT-020、TC-IDT-021、TC-IDT-022、TC-IDT-023、TC-IDT-024、TC-IDT-025、TC-IDT-026、TC-IDT-027、TC-IDT-028、TC-IDT-029、TC-PLT-040、TC-PLT-041、TC-PLT-045、TC-PLT-047 …共 107 条 | `Mobile/mobile_app/test/app/session_logout_farm_state_test.dart` | NIX-337 |
| REQ-IDT-003 | 牧场归属与切换：用户可属多牧场，切换后全页面数据随 activeFarmId… | PRD §2.3.3 | P0 | 已实现（flutter farm_scoped_controller.dart）；零星遗漏为持续审查项 | 227 | TC-RCH-040、TC-IDT-001、TC-IDT-014、TC-IDT-016、TC-IDT-017、TC-IDT-018、TC-IDT-019、TC-IDT-020、TC-IDT-021、TC-IDT-022、TC-IDT-023、TC-IDT-024、TC-IDT-025、TC-IDT-026、TC-IDT-027、TC-IDT-030、TC-IDT-031、TC-IDT-032、TC-IDT-033、TC-IDT-034 …共 227 条 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart` | — |
| REQ-IDT-004 | 角色权限：platform_admin / b2b_admin / owne… | PRD §2.3.4–2.3.7 | P0 | 已实现（NIX-416 admin 声明式守卫） | 114 | TC-IDT-002、TC-IDT-003、TC-IDT-004、TC-IDT-005、TC-IDT-006、TC-IDT-007、TC-IDT-008、TC-IDT-009、TC-IDT-010、TC-IDT-011、TC-IDT-012、TC-IDT-013、TC-PLT-020、TC-PLT-079、TC-PLT-080、TC-PLT-081、TC-PLT-082、TC-PLT-083、TC-PLT-084、TC-PLT-085 …共 114 条 | `Mobile/mobile_app/test/app/route_guard_test.dart` | NIX-416 |
| REQ-IDT-005 | 租户生命周期：注册→SAMPLE→BATCH 等阶段演进 | — | P0 | 已实现（Identity 事件消费） | 0 | 无 | — | — |
| REQ-IDT-006 | API Key 管理：api_consumer 申请/轮换/撤销 Key，按… | PRD §6.12 | P0 | 已实现（NIX-337） | 0 | 无 | — | NIX-337 |
| REQ-IDT-007 | 种子数据：每环境提供五角色种子账号，BCrypt hash 三步验证 | — | P0 | 已实现（docs/reference/deployment.md） | 0 | 无 | — | — |
| REQ-IDT-008 | 平台支撑上下文：平台级配置、通知承载（Platform 上下文） | PRD §4.2B | P1 | 已实现（platform 上下文；具体能力见 PLT 域） | 0 | 无 | — | — |
| REQ-CMC-001 | 套餐分层 BASIC/STANDARD/PREMIUM/ENTERPRISE… | PRD §3.1–3.2 | P0 | 已实现 | 332 | TC-PLT-145、TC-PLT-146、TC-PLT-147、TC-PLT-024、TC-PLT-025、TC-PLT-026、TC-PLT-127、TC-RCH-135、TC-RCH-136、TC-RCH-139、TC-RCH-140、TC-RCH-141、TC-RCH-163、TC-RCH-164、TC-RCH-184、TC-RCH-186、TC-RCH-244、TC-RCH-252、TC-CMC-001、TC-CMC-002 …共 332 条 | `Mobile/mobile_app/test/features/admin/feature_gate_page_test.dart` | — |
| REQ-CMC-002 | 订阅状态机：试用/激活/暂停/恢复/取消/到期/续费失败恢复 | — | P0 | 已实现 | 310 | TC-PLT-145、TC-PLT-146、TC-PLT-147、TC-PLT-024、TC-PLT-025、TC-PLT-026、TC-PLT-127、TC-RCH-244、TC-CMC-001、TC-CMC-002、TC-CMC-003、TC-CMC-004、TC-CMC-005、TC-CMC-006、TC-CMC-007、TC-CMC-008、TC-CMC-009、TC-CMC-010、TC-CMC-011、TC-CMC-012 …共 310 条 | `Mobile/mobile_app/test/features/admin/feature_gate_page_test.dart` | — |
| REQ-CMC-003 | FeatureGate 功能门控：按 tier 门控功能与配额 | PRD §3.9 | P0 | 已实现（配额引擎 + NIX-389 锁定态） | 0 | 无 | — | NIX-389 |
| REQ-CMC-004 | 三种计费模式端到端：B2C 直订 / B2B 分润 / Licensed 独… | PRD §3.8 | P0 | 已实现（B2B/Licensed 见 2026-05  Commerce 评审系列，终评闭环） | 114 | TC-PLT-003、TC-PLT-004、TC-PLT-005、TC-PLT-006、TC-PLT-007、TC-PLT-008、TC-PLT-009、TC-PLT-010、TC-PLT-011、TC-PLT-012、TC-PLT-013、TC-PLT-014、TC-PLT-015、TC-PLT-016、TC-PLT-017、TC-PLT-018、TC-PLT-019、TC-PLT-020、TC-PLT-021、TC-PLT-022 …共 114 条 | `Mobile/mobile_app/test/contract/api_contract_test.dart` | — |
| REQ-CMC-005 | 合同与分润：合同签署→分润周期计算→结算通知 | — | P0 | 已实现（Commerce 领域事件 16 个） | 105 | TC-PLT-003、TC-PLT-007、TC-PLT-009、TC-PLT-010、TC-PLT-011、TC-PLT-012、TC-PLT-013、TC-PLT-014、TC-PLT-015、TC-PLT-016、TC-PLT-017、TC-PLT-018、TC-PLT-019、TC-PLT-020、TC-PLT-021、TC-PLT-023、TC-PLT-024、TC-PLT-025、TC-PLT-026、TC-PLT-027 …共 105 条 | `Mobile/mobile_app/test/contract/api_contract_test.dart` | — |
| REQ-CMC-006 | Licensed 心跳与降级：心跳丢失告警→降级→配额调整→吊销 | — | P0 | 已实现 | 0 | 无 | — | — |
| REQ-CMC-007 | 试用期与免费试点双轨 | PRD §3.4 | P1 | 已实现 | 0 | 无 | — | — |
| REQ-CMC-008 | 订阅健康度临期阈值可配置化（14/7/3 天平台级配置） | — | P2 | 规划未实现（工单待排期，未获批编码） | 220 | TC-PLT-091、TC-IOT-054、TC-CMC-026、TC-CMC-027、TC-CMC-028、TC-CMC-029、TC-CMC-030、TC-CMC-031、TC-CMC-032、TC-CMC-033、TC-CMC-034、TC-CMC-035、TC-CMC-036、TC-CMC-037、TC-CMC-038、TC-CMC-039、TC-CMC-040、TC-CMC-041、TC-CMC-042、TC-CMC-043 …共 220 条 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart` | — |
| REQ-CMC-009 | 订阅/计费对设备与牲畜配额的执行 | PRD §3.11 | P0 | 已实现（订阅配额引擎） | 0 | 无 | — | — |
| REQ-CMC-010 | 商业模式谱系衔接：早期定价设计（2026-03-24 两份）与事件风暴的分歧… | — | P0 | 已实现（本文件即执行） | 0 | 无 | — | — |
| REQ-PLT-001 | SSE 实时推送信号流 | PRD §4.9 | P0 | 已实现 | 170 | TC-RCH-004、TC-RCH-013、TC-RCH-017、TC-RCH-031、TC-RCH-032、TC-PLT-104、TC-PLT-105、TC-PLT-106、TC-PLT-107、TC-PLT-108、TC-PLT-109、TC-PLT-110、TC-PLT-111、TC-IOT-047、TC-IOT-077、TC-RCH-198、TC-IOT-023、TC-RCH-239、TC-RCH-240、TC-CMC-081 …共 170 条 | `Mobile/mobile_app/test/features/alerts/alert_workbench_test.dart` | — |
| REQ-PLT-002 | APNs 离线推送（iOS）：ApnsPushService + PushD… | — | P0 | 已实现（feat/nix-430-apns-push-ios → master） | 131 | TC-RCH-004、TC-RCH-013、TC-RCH-017、TC-RCH-031、TC-RCH-032、TC-PLT-104、TC-PLT-105、TC-PLT-106、TC-PLT-107、TC-PLT-108、TC-PLT-109、TC-PLT-110、TC-PLT-111、TC-IOT-047、TC-IOT-077、TC-IOT-023、TC-RCH-239、TC-RCH-240、TC-CMC-081、TC-CMC-096 …共 131 条 | `Mobile/mobile_app/test/features/alerts/alert_workbench_test.dart` | NIX-430 |
| REQ-PLT-003 | FCM 推送（Android） | PRD §6.3.3/§6.5.3 | P1 | 规划未实现（FCM 无代码，审计核实 ⏳） | 0 | 无 | — | — |
| REQ-PLT-004 | SMS 短信 / 邮件通知 | PRD §6.5.3 | P2 | 规划未实现（无 twilio/JavaMailSender，审计核实 ⏳） | 0 | 无 | — | — |
| REQ-PLT-005 | 通知上下文：跨上下文事件（订阅/合同/分润/Licensed）触达对应角色 | — | P0 | 已实现 | 55 | TC-PLT-104、TC-PLT-105、TC-PLT-106、TC-PLT-107、TC-PLT-108、TC-PLT-109、TC-PLT-110、TC-PLT-111、TC-IOT-077、TC-RCH-239、TC-RCH-240、TC-CMC-096、TC-CMC-097、TC-CMC-098、TC-CMC-099、TC-CMC-100、TC-PLT-174、TC-PLT-175、TC-PLT-176、TC-PLT-204 …共 55 条 | `Mobile/mobile_app/test/core/sync/signal_models_test.dart` | — |
| REQ-NFR-001 | 项目总体目标：牛羊追踪+健康监测可售产品（立项书口径），现行口径以 PRD … | — | P0 | 已实现（口径以 PRD 为准） | 4 | TC-PLT-050、TC-PLT-051、TC-PLT-178、TC-PLT-283 | `Mobile/mobile_app/test/core/database/app_database_shape_migration_test.dart` | — |
| REQ-NFR-002 | 性能：接口 P95 时延、时序查询分区裁剪（PRD §8.1 具体指标） | PRD §8.1 | P0 | 已实现（GPS outbox 压测报告 2026-08-22 支撑） | 4 | TC-PLT-050、TC-PLT-051、TC-PLT-178、TC-PLT-283 | `Mobile/mobile_app/test/core/database/app_database_shape_migration_test.dart` | — |
| REQ-NFR-003 | 可靠性：dev/test 双环境部署链、健康检查（actuator+登录 2… | PRD §4.11 | P0 | 已实现 | 0 | 无 | — | — |
| REQ-NFR-004 | 安全：JWT+API Key 认证、安全架构（PRD §4.7）、密钥不入库 | PRD §4.7/§8.3 | P0 | 已实现 | 0 | 无 | — | — |
| REQ-NFR-005 | 国际化：Flutter AppLocalizations 中英同步、后端 M… | PRD §8.4 | P0 | 已实现 | 0 | 无 | — | — |
| REQ-NFR-006 | GDPR 合规 | PRD §8.5 | P1 | 部分实现（机制部分具备，专项合规审计未做） | 0 | 无 | — | — |
| REQ-NFR-007 | 离线支持：移动端离线地图/围栏/缓存（offline-map 评审系列终评） | PRD §8.5–8.8 | P1 | 已实现（与 REQ-RCH-014 同源） | 0 | 无 | — | — |
| REQ-NFR-008 | CI 守护：双流水线常绿、push 前 precheck、master 禁直… | — | P0 | 已实现（流程性需求，持续执行） | 0 | 无 | — | — |
| REQ-RCH-001 | 牲畜档案 CRUD：品种/性别/出生日期（推月龄）等字段，支持分层统计 | PRD §6.7 | P0 | 已实现 | 1590 | TC-RCH-008、TC-RCH-009、TC-RCH-010、TC-RCH-012、TC-RCH-014、TC-RCH-015、TC-RCH-016、TC-RCH-018、TC-RCH-023、TC-RCH-024、TC-RCH-027、TC-IDT-030、TC-PLT-003、TC-PLT-010、TC-PLT-016、TC-PLT-032、TC-PLT-052、TC-PLT-053、TC-PLT-054、TC-PLT-055 …共 1590 条 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart` | — |
| REQ-RCH-002 | 实时地图：牧场全景 + 牲畜位置展示 | PRD §6.3.1 | P0 | 已实现（§4.12 瓦片基础设施 + NIX-237 逐瓦片坐标变换） | 1189 | TC-RCH-008、TC-RCH-009、TC-RCH-010、TC-RCH-012、TC-RCH-014、TC-RCH-015、TC-RCH-016、TC-RCH-018、TC-RCH-023、TC-RCH-024、TC-RCH-027、TC-IDT-030、TC-PLT-003、TC-PLT-010、TC-PLT-016、TC-PLT-032、TC-PLT-052、TC-PLT-053、TC-PLT-054、TC-PLT-055 …共 1189 条 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart` | NIX-237 |
| REQ-RCH-003 | 虚拟电子围栏：围栏 CRUD、越界告警 | PRD §6.3.2/§6.3.3 | P0 | 已实现 | 366 | TC-IDT-015、TC-PLT-004、TC-PLT-005、TC-PLT-006、TC-PLT-008、TC-PLT-022、TC-PLT-028、TC-PLT-029、TC-PLT-031、TC-PLT-034、TC-PLT-056、TC-PLT-057、TC-PLT-058、TC-PLT-059、TC-PLT-061、TC-PLT-079、TC-PLT-080、TC-PLT-081、TC-PLT-122、TC-PLT-130 …共 366 条 | `Mobile/mobile_app/test/app/session_logout_farm_state_test.dart` | — |
| REQ-RCH-004 | 围栏预警缓冲带：50m 预警带画在围栏外侧、带洞挖除、仅聚焦选中显示，几何单… | — | P0 | 已实现 | 366 | TC-IDT-015、TC-PLT-004、TC-PLT-005、TC-PLT-006、TC-PLT-008、TC-PLT-022、TC-PLT-028、TC-PLT-029、TC-PLT-031、TC-PLT-034、TC-PLT-056、TC-PLT-057、TC-PLT-058、TC-PLT-059、TC-PLT-061、TC-PLT-079、TC-PLT-080、TC-PLT-081、TC-PLT-122、TC-PLT-130 …共 366 条 | `Mobile/mobile_app/test/app/session_logout_farm_state_test.dart` | NIX-412 |
| REQ-RCH-005 | 围栏从设备轨迹生成：三候选包络 + 顶点编辑 + 生成元数据 + 三校准参数滑杆 | — | P1 | 已实现 | 366 | TC-IDT-015、TC-PLT-004、TC-PLT-005、TC-PLT-006、TC-PLT-008、TC-PLT-022、TC-PLT-028、TC-PLT-029、TC-PLT-031、TC-PLT-034、TC-PLT-056、TC-PLT-057、TC-PLT-058、TC-PLT-059、TC-PLT-061、TC-PLT-079、TC-PLT-080、TC-PLT-081、TC-PLT-122、TC-PLT-130 …共 366 条 | `Mobile/mobile_app/test/app/session_logout_farm_state_test.dart` | — |
| REQ-RCH-006 | 围栏面积真实值与 WGS-84/GCJ-02 坐标体系 | — | P0 | 已实现 | 210 | TC-RCH-001、TC-RCH-002、TC-RCH-003、TC-RCH-004、TC-RCH-005、TC-RCH-006、TC-RCH-007、TC-RCH-008、TC-RCH-009、TC-RCH-010、TC-RCH-011、TC-RCH-012、TC-RCH-013、TC-RCH-014、TC-RCH-015、TC-RCH-016、TC-RCH-017、TC-RCH-018、TC-RCH-019、TC-RCH-020 …共 210 条 | `Mobile/mobile_app/test/features/alerts/alert_detail_sheet_estrus_test.dart` | NIX-200 |
| REQ-RCH-007 | 历史轨迹查询：按牲畜/时段查询轨迹 | PRD §6.3.4 | P0 | 已实现 | 194 | TC-RCH-001、TC-RCH-002、TC-RCH-003、TC-RCH-004、TC-RCH-005、TC-RCH-006、TC-RCH-007、TC-RCH-008、TC-RCH-009、TC-RCH-010、TC-RCH-011、TC-RCH-012、TC-RCH-013、TC-RCH-014、TC-RCH-015、TC-RCH-016、TC-RCH-017、TC-RCH-018、TC-RCH-019、TC-RCH-020 …共 194 条 | `Mobile/mobile_app/test/features/alerts/alert_detail_sheet_estrus_test.dart` | — |
| REQ-RCH-008 | 告警状态机（V26 重设计）：active/resolved + 读状态管理 | PRD §6.5.2 | P0 | 已实现（AlertReadStatus mock 债未清） | 0 | 无 | — | — |
| REQ-RCH-009 | 告警中心：告警类型齐全（越界/体温/离体/发情/分娩/饮水/设备），状态机+通知 | PRD §6.5 | P0 | 已实现 | 0 | 无 | — | — |
| REQ-RCH-010 | 告警 UI/UX 统一（ranch panel） | — | P1 | 已实现（引用终评） | 0 | 无 | — | — |
| REQ-RCH-011 | 轨迹巡检（track line inspection，NIX-68） | — | P1 | 已实现 | 0 | 无 | — | — |
| REQ-RCH-012 | 牧场牲畜生命周期管理（入场/离场/死亡/出售） | — | P1 | 已实现 | 0 | 无 | — | — |
| REQ-RCH-013 | 无人机巡检（Drone Patrol） | PRD §6.14（P2） | P2 | 规划未实现（代码无 drone/DJI 命中，2026-11-18 审计核实） | 0 | 无 | — | — |
| REQ-RCH-014 | 离线地图与离线围栏编辑（移动端弱网可用） | — | P1 | 已实现（offline-map 三 plan 终评 + code review v2 收口） | 0 | 无 | — | — |
| REQ-IOT-001 | 设备接入：经 hkt-blade-device 平台采集 CATTLE_TR… | PRD §4.13 | P0 | 已实现 | 146 | TC-PLT-148、TC-PLT-149、TC-PLT-150、TC-PLT-151、TC-PLT-152、TC-PLT-153、TC-PLT-154、TC-PLT-155、TC-PLT-156、TC-PLT-157、TC-PLT-103、TC-IOT-040、TC-IOT-041、TC-HLT-007、TC-RCH-238、TC-RCH-245、TC-IOT-102、TC-IOT-103、TC-IOT-104、TC-IOT-105 …共 146 条 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart` | — |
| REQ-IOT-002 | ThingsBoard 直连通道（NIX-179/180/214） | PRD §4.13A | P0 | 已实现 | 145 | TC-PLT-148、TC-PLT-149、TC-PLT-150、TC-PLT-151、TC-PLT-152、TC-PLT-153、TC-PLT-154、TC-PLT-155、TC-PLT-156、TC-PLT-157、TC-PLT-103、TC-IOT-040、TC-IOT-041、TC-HLT-007、TC-RCH-238、TC-RCH-245、TC-IOT-102、TC-IOT-103、TC-IOT-104、TC-IOT-105 …共 145 条 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart` | — |
| REQ-IOT-003 | GPS 遥测摄取：ingest 事务只写 gps_ingestion_tas… | PRD §4/AGENTS §2 | P0 | 已实现（GpsIngestionTaskScheduler；压测报告 2026-08-22） | 174 | TC-PLT-142、TC-PLT-143、TC-PLT-144、TC-IOT-035、TC-IOT-036、TC-IOT-037、TC-IOT-038、TC-IOT-042、TC-IOT-043、TC-IOT-044、TC-IOT-045、TC-IOT-046、TC-IOT-048、TC-IOT-049、TC-IOT-050、TC-IOT-051、TC-IOT-052、TC-IOT-053、TC-IOT-054、TC-IOT-055 …共 174 条 | `Mobile/mobile_app/test/features/admin/device_profile_rules_page_test.dart` | — |
| REQ-IOT-004 | GPS 幂等与去重：以 (device_id, recorded_at) 为… | — | P0 | 已实现 | 149 | TC-PLT-142、TC-PLT-143、TC-PLT-144、TC-IOT-035、TC-IOT-036、TC-IOT-037、TC-IOT-038、TC-IOT-042、TC-IOT-043、TC-IOT-044、TC-IOT-045、TC-IOT-046、TC-IOT-048、TC-IOT-049、TC-IOT-050、TC-IOT-051、TC-IOT-052、TC-IOT-053、TC-IOT-054、TC-IOT-055 …共 149 条 | `Mobile/mobile_app/test/features/admin/device_profile_rules_page_test.dart` | — |
| REQ-IOT-005 | GPS 质量检测（jitter 治理）：速度阈值过滤（牛 >3 m/s 丢弃… | — | P0 | 已实现（gps_quality_sessions/tests，NIX-219/220 网关定位与数据质量已交付） | 131 | TC-IOT-040、TC-IOT-048、TC-IOT-059、TC-IOT-071、TC-IOT-072、TC-IOT-073、TC-IOT-001、TC-IOT-002、TC-IOT-003、TC-IOT-004、TC-IOT-005、TC-IOT-006、TC-IOT-007、TC-IOT-008、TC-IOT-009、TC-IOT-010、TC-IOT-011、TC-IOT-012、TC-IOT-013、TC-IOT-014 …共 131 条 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart` | NIX-219 |
| REQ-IOT-006 | GPS 写入时间戳统一时区（TIMESTAMPTZ 语义） | — | P0 | 已实现（部分：全局时间戳统一债见 REQ-DEBT-003） | 129 | TC-IOT-040、TC-IOT-048、TC-IOT-059、TC-IOT-071、TC-IOT-072、TC-IOT-073、TC-IOT-001、TC-IOT-002、TC-IOT-003、TC-IOT-004、TC-IOT-005、TC-IOT-006、TC-IOT-007、TC-IOT-008、TC-IOT-009、TC-IOT-010、TC-IOT-011、TC-IOT-012、TC-IOT-013、TC-IOT-014 …共 129 条 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart` | — |
| REQ-IOT-007 | MQTT/EMQX 设备接入通道 | PRD §4.6/§4.8/L971 主题表 | P2 | 规划未实现（main 源码 0 命中，2026-11-18 审计核实，仅测试文件 1 处） | 0 | 无 | — | — |
| REQ-IOT-008 | 设备 License 管理：授权设备数、到期控制 | — | P0 | 已实现 | 0 | 无 | — | — |
| REQ-IOT-009 | 安装管理：设备-牲畜安装/拆卸，活跃安装唯一约束 | PRD §6.9 | P0 | 已实现 | 0 | 无 | — | — |
| REQ-IOT-010 | 设备软删除与遗留治理 | — | P1 | 已实现（final review 收口） | 0 | 无 | — | — |
| REQ-IOT-011 | 设备健康管理（Phase 3）：健康评分模型、入网旅程、数据分流、datag… | PRD §4.14 | P1 | 已实现（Phase 3 design review 2026-07-09 闭环） | 0 | 无 | — | — |
| REQ-IOT-012 | 蓝牙断链丢失告警（固件 0xB0/0xB1） | PRD §1.3/§6.5.1 注 | P2 | 规划未实现（无对应枚举/代码，2026-11-18 审计核实） | 0 | 无 | — | — |

## 三、REQ-DEBT ↔ 评审债映射

| 需求债 | 摘要 | 状态 |
|---|---|---|
| REQ-DEBT-001~010 | N_eff 分档阈值、冷启动兜底、I14 时间戳统一、I9 ArchUnit、I11 updated_at、I12 域测试、AlertReadStatusTest mock 债、I13 校验成文、I10 shared 边界（部分）、前端 P2 集合 | 8 未闭环 + 2 部分闭环，详见 [srs-requirements-debt.md](requirements/srs-requirements-debt.md) |

## 四、覆盖缺口

无 TC 覆盖的 REQ（47 条）：
- REQ-HLT-010 饮水事件检测（V 形组合检测器）：判据 A 斜率 fall/Δt ≥ 0.06 °C/min；判据 B 谷值 ≤ μ(s,d) − 0.5·σ(s,d) − 1.0°C；确认=120min 内回升 ≥0.7×D；merge-gap=15min（已实现（L1/L2pre/L3 试点链路；PRD §6.16 NIX-256 已交付））
- REQ-HLT-011 饮水频次分层口径：泌乳牛参照 7.3±2.8 次/日（Cardot 2008），其他类别以自身近 30 日基线；检测参数不按品种分档（个体基线吸收差异）（已实现（泌乳/干奶阶段字段列为可选增强不阻塞））
- REQ-HLT-012 DRINKING_ABNORMAL 告警（规划未实现（等真实数据））
- REQ-HLT-013 活动阈值修正：ABNORMAL 下调至 <8、LOW 下调至 <18、NORMAL 下线 40→30（jerk-RMS 口径建议值）；长期方向为个体相对基线而非绝对分档（部分实现（个体相对基线通道已建 REQ-HLT-020；绝对分档调整未落地））
- REQ-HLT-014 反刍行为识别：jerk-RMS 单特征下反刍/休息不可分（P50 30.2 vs 30.9），需多特征或个体基线支撑（谱系-规划（纳入 AI 路线图 Phase B 语义））
- REQ-HLT-015 ML 算法矩阵（追踪/健康监测模型分层、性能指标、部署架构、持续优化）（谱系-规划（Phase B/C 未启动部分））
- REQ-HLT-020 个体体温基线自动学习：7–14 天滑窗安静态样本加权更新均值±2σ 波动带；发热样本剔除；冷启动 DEFAULT 38.50 标记 baselineSource，足样本切 LEARNED；存量快照行为不变（已实现（2026-11-04/06 全链闭环；真实数据试点后须 real-only 复核））
- REQ-HLT-021 文献参数仿真评估管道：datagen 仿真生成器（DATAGEN 源 + SYNTHETIC 标签 + 真值基线）按 P1–P16 文献参数；MAE/bias 分层评估；发情 DEFAULT vs LEARNED 同输入对比（已实现（#134，PRD §10.6 as-built 注））
- REQ-HLT-022 发情评分时间窗归一化：绝对水平对比替代纯增幅（个体安静态基线比值/差值），事件量级窗（24–48h 基线窗 vs 6–12h 当前窗）按样本数归一化；70 分阈值与分档结构不改；评分留存算法版本（已实现（#138 已交付，审计 #6））
- REQ-HLT-023 发情确认/否认回流：verdict → ALERT_CONFIRM 生理审计 + 配种联动（已实现）
- REQ-HLT-024 发情评分解释 + 行版本列（EstrusScoreExplainer、estrus_scores 行版本）（已实现）
- REQ-HLT-025 分娩预警算法：体温先降后回升 + 活动特征（RRT 24–48h 渐降 + 末 8h 活动升）（已实现）
- REQ-HLT-026 配种→预产期自动推算（gestation 倒计时）（规划未实现（2026-11-18 审计核实，保持 P2/P3））
- REQ-HLT-030 AI 异常检测：anomaly_scores 持久化（Phase A 已交付），orchestration→engine→capability 三层（Phase A 透传固定契约）（已实现（Phase A））
- REQ-HLT-031 N_eff 分档路由（小样本稳健统计 / 大样本 iForest）（规划未实现（REQ-DEBT-001））
- REQ-HLT-032 降级链冷启动兜底（N_eff 极小时路由策略：规则档 or 数据不足提示）（规划未实现（REQ-DEBT-002））
- REQ-HLT-033 健康自动刷新与 API 合并（已实现）
- REQ-IDT-005 租户生命周期：注册→SAMPLE→BATCH 等阶段演进（已实现（Identity 事件消费））
- REQ-IDT-006 API Key 管理：api_consumer 申请/轮换/撤销 Key，按 Key 计频率限制（已实现（NIX-337））
- REQ-IDT-007 种子数据：每环境提供五角色种子账号，BCrypt hash 三步验证（已实现（docs/reference/deployment.md））
- REQ-IDT-008 平台支撑上下文：平台级配置、通知承载（Platform 上下文）（已实现（platform 上下文；具体能力见 PLT 域））
- REQ-CMC-003 FeatureGate 功能门控：按 tier 门控功能与配额（已实现（配额引擎 + NIX-389 锁定态））
- REQ-CMC-006 Licensed 心跳与降级：心跳丢失告警→降级→配额调整→吊销（已实现）
- REQ-CMC-007 试用期与免费试点双轨（已实现）
- REQ-CMC-009 订阅/计费对设备与牲畜配额的执行（已实现（订阅配额引擎））
- REQ-CMC-010 商业模式谱系衔接：早期定价设计（2026-03-24 两份）与事件风暴的分歧以 PRD v2.5 §3 为准（已实现（本文件即执行））
- REQ-PLT-003 FCM 推送（Android）（规划未实现（FCM 无代码，审计核实 ⏳））
- REQ-PLT-004 SMS 短信 / 邮件通知（规划未实现（无 twilio/JavaMailSender，审计核实 ⏳））
- REQ-NFR-003 可靠性：dev/test 双环境部署链、健康检查（actuator+登录 200 判活）（已实现）
- REQ-NFR-004 安全：JWT+API Key 认证、安全架构（PRD §4.7）、密钥不入库（已实现）
- REQ-NFR-005 国际化：Flutter AppLocalizations 中英同步、后端 MessageSource 双语按 Accept-Language（已实现）
- REQ-NFR-006 GDPR 合规（部分实现（机制部分具备，专项合规审计未做））
- REQ-NFR-007 离线支持：移动端离线地图/围栏/缓存（offline-map 评审系列终评）（已实现（与 REQ-RCH-014 同源））
- REQ-NFR-008 CI 守护：双流水线常绿、push 前 precheck、master 禁直推（分支+PR）（已实现（流程性需求，持续执行））
- REQ-RCH-008 告警状态机（V26 重设计）：active/resolved + 读状态管理（已实现（AlertReadStatus mock 债未清））
- REQ-RCH-009 告警中心：告警类型齐全（越界/体温/离体/发情/分娩/饮水/设备），状态机+通知（已实现）
- REQ-RCH-010 告警 UI/UX 统一（ranch panel）（已实现（引用终评））
- REQ-RCH-011 轨迹巡检（track line inspection，NIX-68）（已实现）
- REQ-RCH-012 牧场牲畜生命周期管理（入场/离场/死亡/出售）（已实现）
- REQ-RCH-013 无人机巡检（Drone Patrol）（规划未实现（代码无 drone/DJI 命中，2026-11-18 审计核实））
- REQ-RCH-014 离线地图与离线围栏编辑（移动端弱网可用）（已实现（offline-map 三 plan 终评 + code review v2 收口））
- REQ-IOT-007 MQTT/EMQX 设备接入通道（规划未实现（main 源码 0 命中，2026-11-18 审计核实，仅测试文件 1 处））
- REQ-IOT-008 设备 License 管理：授权设备数、到期控制（已实现）
- REQ-IOT-009 安装管理：设备-牲畜安装/拆卸，活跃安装唯一约束（已实现）
- REQ-IOT-010 设备软删除与遗留治理（已实现（final review 收口））
- REQ-IOT-011 设备健康管理（Phase 3）：健康评分模型、入网旅程、数据分流、datagen 适配（已实现（Phase 3 design review 2026-07-09 闭环））
- REQ-IOT-012 蓝牙断链丢失告警（固件 0xB0/0xB1）（规划未实现（无对应枚举/代码，2026-11-18 审计核实））

TC 自动映射引用了不存在/未登记的 REQ 编号：
- __UNMAPPED__（引用 21 次）
- REQ-HLT-007（引用 118 次）

## 五、域级对照（REQ 域 ↔ TC 分册）

| TC 分册 | TC 域 | 用例数 |
|---|---|---|
| [test-cases/tc-app-admin-tools.md](../testing/test-cases/tc-app-admin-tools.md) | admin-tools | 16 |
| [test-cases/tc-app-alerts.md](../testing/test-cases/tc-app-alerts.md) | alerts | 48 |
| [test-cases/tc-app-auth-tenant.md](../testing/test-cases/tc-app-auth-tenant.md) | auth-tenant | 41 |
| [test-cases/tc-app-core-infra.md](../testing/test-cases/tc-app-core-infra.md) | core-infra | 139 |
| [test-cases/tc-app-devices.md](../testing/test-cases/tc-app-devices.md) | devices | 44 |
| [test-cases/tc-app-drinking.md](../testing/test-cases/tc-app-drinking.md) | drinking | 29 |
| [test-cases/tc-app-fence.md](../testing/test-cases/tc-app-fence.md) | fence | 178 |
| [test-cases/tc-app-gps-quality.md](../testing/test-cases/tc-app-gps-quality.md) | gps-quality | 34 |
| [test-cases/tc-app-livestock-health.md](../testing/test-cases/tc-app-livestock-health.md) | livestock-health | 51 |
| [test-cases/tc-app-subscription-license.md](../testing/test-cases/tc-app-subscription-license.md) | subscription-license | 83 |
| [test-cases/tc-server-commerce.md](../testing/test-cases/tc-server-commerce.md) | commerce | 258 |
| [test-cases/tc-server-datagen.md](../testing/test-cases/tc-server-datagen.md) | datagen | 117 |
| [test-cases/tc-server-gps-telemetry.md](../testing/test-cases/tc-server-gps-telemetry.md) | gps-telemetry | 152 |
| [test-cases/tc-server-health.md](../testing/test-cases/tc-server-health.md) | health | 424 |
| [test-cases/tc-server-identity.md](../testing/test-cases/tc-server-identity.md) | identity | 87 |
| [test-cases/tc-server-integration.md](../testing/test-cases/tc-server-integration.md) | integration | 265 |
| [test-cases/tc-server-iot-device.md](../testing/test-cases/tc-server-iot-device.md) | iot-device | 142 |
| [test-cases/tc-server-licensing.md](../testing/test-cases/tc-server-licensing.md) | licensing | 171 |
| [test-cases/tc-server-platform-shared.md](../testing/test-cases/tc-server-platform-shared.md) | platform-shared | 31 |
| [test-cases/tc-server-ranch-alert.md](../testing/test-cases/tc-server-ranch-alert.md) | ranch-alert | 66 |
| [test-cases/tc-server-ranch-fence.md](../testing/test-cases/tc-server-ranch-fence.md) | ranch-fence | 93 |
| [test-cases/tc-server-ranch-livestock-overview.md](../testing/test-cases/tc-server-ranch-livestock-overview.md) | ranch-livestock-overview | 135 |

## 六、维护规则

1. 新需求合入：先在 docs/requirements/ 登记 REQ-<域>-NNN（四要素齐备），重跑生成脚本刷新本矩阵。
2. 新用例合入：testing/test-cases/ 分册登记 TC-<域>-NNN 并填 REQ 映射列；生成脚本重跑后矩阵同步。
3. REQ 实现/废弃状态变化：改 SRS 模块文件状态列，不改本矩阵手工内容（本文件除本节外均为生成物）。
4. TC→REQ 自动映射为初稿口径；人工校对后更新分册内映射列即可，本矩阵下次生成自动吸收。
5. 工单关闭/PR 合并不单独改本矩阵；工单号在 SRS 来源列维护。

