# SRS 模块：Identity 与 Commerce（REQ-IDT / REQ-CMC）

> 状态口径与编号规则见 srs-smart-livestock.md。P0=必须、P1=重要、P2=规划。

## 一、Identity 域（IDT）

| 编号 | 需求 | 来源 | 优先级 | 验收标准 | 实现状态 |
|------|------|------|--------|----------|----------|
| REQ-IDT-001 | 多租户隔离：所有业务数据按 tenant 隔离，租户间零可见 | S1 backend §3.1、S3 2026-04-21-backend-infra-requirements | P0 | 跨租户查询返回空且审计无越权记录；Tenant/Farm/UserFarmAssignment 域模型测试齐备 | 已实现（identity 上下文 + farm-scoped API；域测试覆盖债见 REQ-DEBT-005） |
| REQ-IDT-002 | 用户认证：JWT 登录、token 刷新、登出失效 | S1、S2 PRD §2.3/§4.7 | P0 | 种子账号登录 200；API Key 认证链路可用；改密后旧 Key 失效 | 已实现（NIX-337 改密放行已修） |
| REQ-IDT-003 | 牧场归属与切换：用户可属多牧场，切换后全页面数据随 activeFarmId 刷新 | S1 frontend、S2 PRD §2.3.3 | P0 | 所有 farm-scoped Controller 继承 FarmScoped* 基类并在 build() watch activeFarmId（AGENTS §5 checklist）；切牧场后无旧数据残留 | 已实现（flutter farm_scoped_controller.dart）；零星遗漏为持续审查项 |
| REQ-IDT-004 | 角色权限：platform_admin / b2b_admin / owner / worker / api_consumer 五角色，路由守卫+操作权限 | S2 PRD §2.3.4–2.3.7 | P0 | 各角色可达页面与 PRD §2.3.7 权限速览一致；越权访问 403 | 已实现（NIX-416 admin 声明式守卫） |
| REQ-IDT-005 | 租户生命周期：注册→SAMPLE→BATCH 等阶段演进 | S1、S5 事件风暴（S1 事件跨上下文消费） | P0 | SubscriptionCreatedEvent 触发 TenantPhase SAMPLE→BATCH | 已实现（Identity 事件消费） |
| REQ-IDT-006 | API Key 管理：api_consumer 申请/轮换/撤销 Key，按 Key 计频率限制 | S1 backend §3.1/§六、S2 PRD §6.12 | P0 | Key CRUD + 频率限制生效；改密放行回归 | 已实现（NIX-337） |
| REQ-IDT-007 | 种子数据：每环境提供五角色种子账号，BCrypt hash 三步验证 | S2、AGENTS §4.2 | P0 | 部署后 curl 登录 200；scripts/verify-seed-hash.sh 通过 | 已实现（docs/reference/deployment.md） |
| REQ-IDT-008 | 平台支撑上下文：平台级配置、通知承载（Platform 上下文） | S2 PRD §4.2B | P1 | 平台配置表 + admin 端点可读写 | 已实现（platform 上下文；具体能力见 PLT 域） |

## 二、Commerce 域（CMC）

| 编号 | 需求 | 来源 | 优先级 | 验收标准 | 实现状态 |
|------|------|------|--------|----------|----------|
| REQ-CMC-001 | 套餐分层 BASIC/STANDARD/PREMIUM/ENTERPRISE，按头/月计费 | S2 PRD §3.1–3.2、S3 2026-03-24 定价设计（谱系） | P0 | 四档 CRUD + 价格与 PRD §3.2 表一致；定价谱系差异以 PRD v2.5 为准 | 已实现 |
| REQ-CMC-002 | 订阅状态机：试用/激活/暂停/恢复/取消/到期/续费失败恢复 | S5 事件风暴 S1–S6、S1 backend §3.4 | P0 | 状态机迁移与事件（S2–S6）一一对应；跨上下文消费方生效 | 已实现 |
| REQ-CMC-003 | FeatureGate 功能门控：按 tier 门控功能与配额 | S2 PRD §3.9 | P0 | BASIC 档功能门控生效；降级即时限制 | 已实现（配额引擎 + NIX-389 锁定态） |
| REQ-CMC-004 | 三种计费模式端到端：B2C 直订 / B2B 分润 / Licensed 独立部署 | S2 PRD §3.8 | P0 | 三模式各完成一条端到端旅程 | 已实现（B2B/Licensed 见 2026-05  Commerce 评审系列，终评闭环） |
| REQ-CMC-005 | 合同与分润：合同签署→分润周期计算→结算通知 | S5 事件风暴 C1–C4/R1–R2、S1 §3.4 | P0 | 16 个领域事件触发/消费链路绿；结算通知触达 | 已实现（Commerce 领域事件 16 个） |
| REQ-CMC-006 | Licensed 心跳与降级：心跳丢失告警→降级→配额调整→吊销 | S5 事件风暴 L1–L5 | P0 | 心跳丢失触发 ServiceHeartbeatLostEvent，降级后配额降为 BASIC | 已实现 |
| REQ-CMC-007 | 试用期与免费试点双轨 | S2 PRD §3.4 | P1 | 试用与试点互斥且可追溯 | 已实现 |
| REQ-CMC-008 | 订阅健康度临期阈值可配置化（14/7/3 天平台级配置） | S5 2026-10-31-subscription-health-threshold-configurable | P2 | 默认 14/7/3 与现行为一致；阈值表+admin 端点+种子迁移；判定矩阵 #1–#7 回归 | 规划未实现（工单待排期，未获批编码） |
| REQ-CMC-009 | 订阅/计费对设备与牲畜配额的执行 | S2 PRD §3.11、S1 配额引擎 | P0 | 超配额写入被拒且提示明确 | 已实现（订阅配额引擎） |
| REQ-CMC-010 | 商业模式谱系衔接：早期定价设计（2026-03-24 两份）与事件风暴的分歧以 PRD v2.5 §3 为准 | S3+S5 谱系说明 | P0 | 谱系登记于总纲 §5，不产生双口径 | 已实现（本文件即执行） |
