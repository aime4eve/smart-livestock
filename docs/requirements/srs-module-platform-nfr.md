# SRS 模块：Platform 通知与非功能需求（REQ-PLT / REQ-NFR）

## 一、Platform 域（PLT）

| 编号 | 需求 | 来源 | 优先级 | 验收标准 | 实现状态 |
|------|------|------|--------|----------|----------|
| REQ-PLT-001 | SSE 实时推送信号流 | S2 PRD §4.9 | P0 | 信号流实时触达前端；平台配置可管理 | 已实现 |
| REQ-PLT-002 | APNs 离线推送（iOS）：ApnsPushService + PushDispatchService + UserPushToken，main.dart 注册 | S2 审计 #1（NIX-430，#168） | P0 | iOS 离线可收告警推送；token 注册/失效管理 | 已实现（feat/nix-430-apns-push-ios → master） |
| REQ-PLT-003 | FCM 推送（Android） | S2 PRD §6.3.3/§6.5.3 | P1 | Android 离线可收推送 | 规划未实现（FCM 无代码，审计核实 ⏳） |
| REQ-PLT-004 | SMS 短信 / 邮件通知 | S2 PRD §6.5.3 | P2 | 短信/邮件通道可用 | 规划未实现（无 twilio/JavaMailSender，审计核实 ⏳） |
| REQ-PLT-005 | 通知上下文：跨上下文事件（订阅/合同/分润/Licensed）触达对应角色 | S5 事件风暴 S5/C3/C4/R1–R2/L2 | P0 | 各事件通知触达 owner/合作方/运维 | 已实现 |

## 二、非功能需求（NFR）

| 编号 | 需求 | 来源 | 优先级 | 验收标准 | 实现状态 |
|------|------|------|--------|----------|----------|
| REQ-NFR-001 | 项目总体目标：牛羊追踪+健康监测可售产品（立项书口径），现行口径以 PRD v2.5 商业模式为准 | S3 2026-04-10 立项书（谱系） | P0 | 产品可售、四环境部署链可用 | 已实现（口径以 PRD 为准） |
| REQ-NFR-002 | 性能：接口 P95 时延、时序查询分区裁剪（PRD §8.1 具体指标） | S2 PRD §8.1 | P0 | PRD §8.1 指标达标；分区裁剪生效 | 已实现（GPS outbox 压测报告 2026-08-22 支撑） |
| REQ-NFR-003 | 可靠性：dev/test 双环境部署链、健康检查（actuator+登录 200 判活） | S2 PRD §4.11、AGENTS §1 | P0 | 四环境全量部署链按序可执行；判活口径按经验 #23 | 已实现 |
| REQ-NFR-004 | 安全：JWT+API Key 认证、安全架构（PRD §4.7）、密钥不入库 | S2 PRD §4.7/§8.3 | P0 | 认证链路完整；无明文凭据 | 已实现 |
| REQ-NFR-005 | 国际化：Flutter AppLocalizations 中英同步、后端 MessageSource 双语按 Accept-Language | S2 PRD §8.4、AGENTS §4.1、S3 阿根廷.md（市场准入输入） | P0 | gen-l10n 无缺失 key；properties 双语对齐 | 已实现 |
| REQ-NFR-006 | GDPR 合规 | S2 PRD §8.5、S3 2026-04-02 §八（合规与隐私） | P1 | 数据可导出/删除；隐私声明齐备 | 部分实现（机制部分具备，专项合规审计未做） |
| REQ-NFR-007 | 离线支持：移动端离线地图/围栏/缓存（offline-map 评审系列终评） | S1 frontend、S2 PRD §8.5–8.8 | P1 | 弱网主旅程可用；离线数据一致 | 已实现（与 REQ-RCH-014 同源） |
| REQ-NFR-008 | CI 守护：双流水线常绿、push 前 precheck、master 禁直推（分支+PR） | AGENTS §5b/§5c | P0 | push 后 gh run list 双绿；变更全走 PR | 已实现（流程性需求，持续执行） |
