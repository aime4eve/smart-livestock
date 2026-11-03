# 工单备忘：手机后台推送（FCM/APNs）

- 立单日期：2026-11-03
- 来源：发情/分娩对外答复评审核实（`ai-memory/10-Projects/02-smart-livestock/2026-11-03-发情分娩对外答复与NIX335评审核实.md`）；自 NIX-158/286 需求单"追加 2"拆出独立成单
- 优先级建议：高——横跨发情/疫病/临产/订阅健康横幅多个业务的触达基础设施；"约 15 小时提前预警送不到人就没有价值"
- 状态：待排期，未获批编码（AGENTS §3 硬性规则）

## 现状（代码证据）

- App 内实时提醒依赖 SSE 信号通道（`Mobile/mobile_app/lib/core/sync/signal_transport_web.dart`），**仅 App 前台成立**
- Flutter 端无 firebase_messaging/APNs 集成；用户不在 App 内时收不到任何提醒
- 告警中心为前台 30 秒刷新；无后台/锁屏系统通知

## 需求

1. **端集成**：FCM（Android/Web）+ APNs（iOS）；设备 token 注册/注销与多设备（同一账号手机+平板）管理
2. **服务端**：告警生成链路（`HealthAlertBridgeService` 等）接推送发送端点；按告警优先级映射通知策略（ESTRUS/CALVING_WARNING/FENCE_BREACH 高优先级即时推；低优先级聚合或静默）
3. **通知体验**：点击通知直达对应告警详情（深链）；通知文案走后端 MessageSource 双语（按设备语言）
4. **多环境**：dev/test/86/223 四环境推送证书/密钥配置纳入 compose/env 契约（`.env.example` 键 + check-env 校验），不硬编码
5. **ONPREM 边界**：ONPREM 离线/内网部署下 FCM/APNs 不可达时的降级策略（仅 App 内通知 + 文档声明），需产品确认

## 验收要点

- App 退后台/被杀死后，触发 ESTRUS 告警，真机（Android/iOS 各一）收到系统通知；点击直达详情
- 通知不重复不丢失（告警解除后有回执或撤回机制）
- 与 SSE 前台通道并存不冲突（前台不重复弹系统通知或可配置）
- 推送发送失败可观测（日志/计数，不静默吞）

## 关联

- NIX-158/286 分娩预警需求单（前置依赖）
- NIX-156 发情增强、疫病告警、NIX-324 订阅横幅提醒（同受益）
