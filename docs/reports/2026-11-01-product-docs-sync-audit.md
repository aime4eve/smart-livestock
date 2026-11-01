# 产品文档三件套同步刷新对账明细（2026-11-01）

> **任务**：将 docs/product/ 另三份事实源文档（customer-journey / user-journey-guide / system-architecture）按 2026-11-01 master 实现同步刷新（与 PRD v2.4 对账同证据基线，承接 e711551a）。
> **方法**：全文精读 + 逐节陈旧度评估 + 代码/迁移/路由机械复核（断言即核实）；五列表 = 章节 | 原口径 | 实现现状 | 证据 | 动作。
> **范围裁决**：本轮仅三份 md + 联动指针；五张 user-journey 时序图与 telemetry 主图的 archify 重生成另立任务（已在 `docs/diagrams/README.md` 标注待刷新）。

---

## 一、总览

| 文档 | 刷新前基线 | 行数变化 | 本次主要动作 |
|------|-----------|---------|------------|
| `customer-journey.md` | 无版本标记（最后实质更新 2026-09-23） | 226 → ~250 | 补基线头/尾；6 角色；旅程四段重写；凭据脱敏指针化；路由守卫 8 级表；权限矩阵三层对照化；告警状态机整节重写；**§8 33 点表一字未动** |
| `user-journey-guide.md` | 2026-09-20（nix/219 分支） | 642 → ~700 | 基线 → 2026-11-01；6 角色；多标识登录；密码策略 8 位四类；JWT act claim；AppRoute 47→57；7.7 改写为已修复；新增 7.11；订阅治理大块增补 |
| `system-architecture.md` | v1.0 / 2026-06-15 | 951 → ~1010 | **v2.0 逐章对账**：全景图重绘（TB/blade/Nacos/SSE/datagen/licensing）；117 迁移；83 控制器/329 端点；6 张分区表自动维护；ER 六处更正；Topics 17；部署 4 环境；§7.2 八个死链修复 |

**联动改动**：`docs/README.md`（更新日期 + product/ 三行基线）、PRD v2.4（附录 B 三行基线/警告消除 + "5 种角色"→6 角色三处）、`docs/diagrams/README.md`（待刷新注记 + 主图 MQTT 措辞澄清）。

---

## 二、customer-journey.md 对账明细（摘要）

| # | 位置 | 原口径 | 实现现状（证据） | 动作 |
|---|------|--------|----------------|------|
| 1 | 头部 | 无版本/基线 | — | 补基线 2026-11-01 + 差异说明 + footer |
| 2 | §1 | 5 角色；owner"后台+订阅"；worker"仅确认告警" | 6 角色（`Role.java` SUPER_ADMIN，V20261019100000；前端 `user_role.dart:11` superAdmin） | 重写角色表（超管行 + owner 后台入口已移除 + worker dismiss） |
| 3 | §2.1 | 缺超管/试点授权/移交/导出 | entry-contexts/switch-context（`AuthController.java:42/54`）；统一截止日（`application.yml:206`）；`POST /admin/devices/transfer`（`DeviceAdminController.java:46`） | 旅程重写 |
| 4 | §2.3 | owner 落地 /twin；告警确认/处理/归档 | 落地 /ranch（`app_router.dart` redirect）；dismiss 模型 | 重写 |
| 5 | §2.4 | worker 不可 dismiss | 后端 `hasAnyRole('OWNER','B2B_ADMIN','WORKER')`（`AlertController.java:94`） | 更正 + 补网关/覆盖诊断 |
| 6 | §3 | "密码 123"明文 + "V4/V16 迁移" | 密码策略 8 位四类（`PasswordPolicy.java`，2026-10-15 裁决）后已失效；admin bootstrap = V20260907120000 | 凭据指针化（deployment.md）+ 补超管行 + 多标识说明 |
| 7 | §4 | 5 条守卫、owner 允许 /admin | 8 级优先级（改密锁 > 超管 > 角色前缀 > /admin 重定向，`app_router.dart`） | 重写 |
| 8 | §5 | 14 行×4 角色静态矩阵；"创建牧场 owner ✗"、"审批 API 授权全角色 ✅" | 后端 `OWNER\|B2B_ADMIN` 可建场（`FarmController.java:49-60`）；canReviewApiAuthorizations=owner\|platformAdmin | 重写为三层对照矩阵（不一致处标注死权限/前后端缺口），+super_admin 说明 |
| 9 | §6.1 | 仅 USD 定价 | +统一试点截止 2027-09-30 + 7 态 + 降档不拒绝 + 30+30 导出 | 增补 |
| 10 | §6.2 | 13 行门控矩阵 | 门控随迁移演进（V11 → V20260923120000 → V20261005110000 → V20261026000000） | 加演进注记，逐格以种子为准 |
| 11 | §7 | pending→acknowledged→handled→archived | 三态 + alert_read_status（V26）+ 14 类 AlertType + @Deprecated 端点 | 整节重写 |
| 12 | §8 | 33 个 RTK 点 | 被 `docs/superpowers/specs/2026-07-15-gps-quality-check-spec-v2.md:194` 等引用 | **仅加保护提示行，表零改动**（git diff 验证） |

## 三、user-journey-guide.md 对账明细（摘要）

| # | 位置 | 原口径 | 实现现状（证据） | 动作 |
|---|------|--------|----------------|------|
| 1 | L5/L642 | 基线 2026-09-20（nix/219） | — | 基线 → 2026-11-01（头+尾） |
| 2 | §1 | 5 角色；"其余 4 种归属租户" | 6 角色（SUPER_ADMIN，`user_role.dart:11/20/37/50`） | 枚举/表/getter 更新 |
| 3 | §2.1 | "手机号+密码"；3 端点 | 多标识登录（PR #132，`AuthController.java:29` 注释）；+entry-contexts/switch-context | 表更新 |
| 4 | §2.2 | `{phone, password}`、`findByPhone` | `{identifier, password}`、email→phone(E.164)→account 归一化路由 | 流程重写 |
| 5 | §2.3 | 5 claims、双 Token 语境 | +条件性 `act` claim（`JwtTokenProvider.java:45-54`，RFC 8693）；单 Token + `REFRESH_GRACE_MS=30min` | 补行 + 单 Token 说明 |
| 6 | §2.7 | 恢复不读 mustChangePassword | **已修复**（`main.dart:99` + `:127-130` NIX-191 注释） | 改写 + 补超管入口 |
| 7 | §2.8 | "≥10 位字母+数字" | 8 位四类（`PasswordPolicy.violationKey`） | 更正 |
| 8 | §2.9 | 4 账号明文 123 | 策略后失效 | 脱敏指针化 + 超管行 |
| 9 | §3.1/3.2/3.3 | 7 级守卫无超管；"AppRoute 47 项" | 8 级（/select-context）；**57 项枚举 / 61 GoRoute**（`app_route.dart` L2-66 逐行清点，含 2 个折行成员） | 更新 |
| 10 | §4.2/4.3 | 缺 DeviceAdminController/AlertController dismiss 行；dismiss=`OWNER\|\|B2B_ADMIN` | `DeviceAdminController` requirePlatformAdmin（`:38/:48`）；dismiss 放宽 WORKER（`:94`） | 增行 + 更正 |
| 11 | §5.1–5.4 | 缺超管/试点授权/运营动作/移交/到期横幅/饮水生理 | 同 PRD v2.4 证据 | 旅程增补；凭据明文→指针 |
| 12 | §6.1/6.3/6.4 | 缺超管链；dismiss 旧值；订阅仅 4 行概述 | 同上 | 增补（7 态/CommerceScheduler/统一截止/降档/导出） |
| 13 | §7.4 | "后端 OWNER\|B2B_ADMIN"（dismiss） | 放宽 WORKER | 收窄结论 |
| 14 | §7.7 | 会话恢复不读改密锁（待办） | 已修复 | 改写为 ✅ 已修复 |
| 15 | §7.11（新增） | — | `DataExportAdminController`（/admin/data-export-jobs）无权限注解（全文 grep 零命中）——与 7.6 同款裸奔 | 新增已知不一致点 |
| 16 | §8 | 缺新文件 | — | 补 9 行代码索引（PasswordPolicy/上下文切换/CommerceScheduler/移交/导出/SSE/时区链） |

## 四、system-architecture.md 对账明细（摘要）

| # | 位置 | 原口径 | 实现现状（证据） | 动作 |
|---|------|--------|----------------|------|
| 1 | 头部/页脚 | v1.0 / 2026-06-15 | — | **v2.0 / 2026-11-01**（头尾同步） |
| 2 | §1.2 全景图 | 仅 6 上下文 + RocketMQ | +TB/blade/Nacos/SSE/datagen/licensing/sp-monitoring | mermaid 重绘 |
| 3 | §1.3 | "Flyway 30 个（V1–V30）"、"JWT 双 Token" | **117 个**迁移；单 Token + 30min 宽限（`JwtTokenProvider` 仅 accessExpiration + REFRESH_GRACE_MS） | 更正 + 补 Nacos/Prometheus 行 |
| 4 | §2.2 | 5 角色；租户仅阶段/类型 | 6 角色；生命周期 status=active\|disabled + deleted_at 软删除（`V20261012140000` 头注释原文） | 更新 |
| 5 | §2.3 流程一 | `IOT->>DB: 写入 gps_logs` 直写 | outbox：`gps_ingestion_tasks` → `GpsIngestionTaskScheduler` 异步落库（AGENTS.md §2 固化） | 时序更正 |
| 6 | §2.3 流程二 | 单源胶囊 | `TelemetrySource` 5 值多源 | 更正 |
| 7 | §2.4 | "7 个 feature key" | 门控演进 4 批迁移 | 注记 + 订阅生命周期段 |
| 8 | §3.1/3.2 | 7 上下文；控制器 9/8/7/5/7/4/1 | 9 上下文（+datagen/licensing）；**identity 14 / ranch 16 / iot 21 / health 13 / commerce 8 / analytics 4 / datagen 3 / licensing 3 / shared 2 = 84**（grep 分包计数）；合计 329 端点 | 图 + 表重写 |
| 9 | §3.3 | 链接 system-feature-document.md（已删除）；"Token 自动刷新前端未实现" | 文件已删；刷新已实现（`_withRefreshRetry`） | 注记改指向 api-contracts + 两行更正 |
| 10 | §3.4 | "40 模块 / 36 路由" | **34 目录 / 57 项 61 GoRoute**（`ls features/` 计数；新增 auth/drinking/physiology/ai_anomaly/gateways/subscription_service_management） | 更新 |
| 11 | §4.2 ER×5 | users 5 字段无标识列；tenants 无 timezone/status；devices 含 OFFLINE+ACCELEROMETER；Commerce 4 态；缺新表 | 多标识字段 + must_change_password；timezone/status/deleted_at；3 值类型 + INVENTORY/ACTIVE/DECOMMISSIONED；7 态；+tb_device_bindings/gps_ingestion_tasks/device_telemetry_logs/drinking_events/physiology_events/anomaly_scores | ER 逐处更正 + 增补注记 |
| 12 | §4.3 | 3 张分区表、手工预建 2026_03–08 | **6 张** + `PartitionMaintenanceService` 自动维护（禁手工预建） | 重写 |
| 13 | §4.5 | 7 行机制 | +GDPR 导出/GPS 幂等/租户时区 | 增 3 行 |
| 14 | §4.6 | 表清单止于 V26 | +V38–V41 + 日期序 77 个要点批次；合计 117 | 增补 |
| 15 | §5.1 | 10 topic、消费方多处"预留" | **17 topic**（`Topics.java` 逐项 grep）；`PlatformEventConsumer` 统一聚合 | 图 + 表重写 |
| 16 | §5.3 | 外部集成 5 行无 TB/blade | +blade（OAuth2+Feign+Nacos 下发）/TB（REST 直连）/HTTP/导入；Open API 17 端点含自注册与导出 | 重写 |
| 17 | §5.4 | "Access + Refresh 双 Token" | 单 Token + 宽限；+SSE 信号流 | 更正 |
| 18 | §6.2 | CORS 缺生产域名；开放端点缺 deployment-info | `https://livestock.hkttech.cn`（SecurityConfig:106）+ NIX-184 匿名端点 | 更正 + 补多标识/超管行 |
| 19 | §6.3 | 无时区概念 | 时区三级链（TenantZoneResolver） | 增段 |
| 20 | §6.5 | 单环境 "172.22.1.123:18080"；Refresh Token 7d | 4 环境 + 发布链 + Nacos 下发 + prometheus；宽限 30min；+试点截止/默认时区 env | 重写 |
| 21 | §6.6 | "36 路由 / 40 Feature" | 61 GoRoute / 57 项 / 34 模块 | 更新 |
| 22 | §7.1 | "V1–V30"、SecurityConfig 路径含混 | 117 个；`shared/security/SecurityConfig.java` | 更正 + 补 5 行索引 |
| 23 | §7.2 | 9 链接中 4 个文件已删、4 个路径过时 | 目标核验：`docs/reference/seed-data-landscape.md`、`docs/guides/subscription-guide.md`、`docs/guides/tileserver-deployment-guide.md`、`docs/protocols/` 均存在 | 链接表重写（8 死链清零） |
| 24 | §7.3 | 6 术语 | +TelemetrySource/GPS outbox/SSE/超管上下文 | 增 4 行 |

---

## 五、开放风险（刷新过程顺带发现/复核）

1. **DataExportAdminController 无权限注解**（`/admin/data-export-jobs`，任意登录可查全平台导出任务）——新发现（user-journey-guide §7.11），与 AnalyticsAdminController 同款。
2. **AnalyticsAdminController 无权限注解**——2026-09-20 发现，2026-11-01 复核仍在（guide §7.6）。
3. ~~canHandleAlert 前端 owner-only~~ **更正（同日复核，断言失实）**：`5b715cb4`（NIX-52）已同批放宽前后端（canHandleAlert/canBatchAlerts 均含 worker），我方沿用 09-20 基线过时表格所致；真实残留 = canManageTenants 死权限（owner，零使用点）与 batch-dismiss 端点缺失，两者已由 **NIX-351** 修复。
4. ~~batch-handle 复用 403~~ 已由 NIX-351 终结（新端点 `/alerts/batch-dismiss` 三角色放行，前端已切换）。
5. 五张 user-journey 时序图 + telemetry 主图基于 09-20 基线（本轮已标注待刷新，archify 重生成另立任务）。
6. training/00、training/03、marketing/technical-support-guide 引用三文档的**正文口径**未随本轮刷新（引用路径有效），建议下一轮材料刷新时对齐权限矩阵与告警模型。

## 六、证据索引（关键新增）

- 角色：`identity/domain/model/Role.java`（6 值）、`Mobile/mobile_app/lib/core/models/user_role.dart:11/20/50`、`V20261019100000__super_admin_role_and_seed.sql`、`V20261020100000__rename_super_admin_account.sql`
- 认证：`JwtTokenProvider.java`（accessExpiration + REFRESH_GRACE_MS=30min + act claim :45-54）、`PasswordPolicy.java`（8 位四类）、`main.dart:99/:127`（恢复已读改密锁）、`AuthController.java:29/42/54`
- 路由：`app_route.dart`（57 项枚举，L2-66 逐行清点）、`app_router.dart`（61 GoRoute；/admin 重定向 L141-147）
- 数据：`Topics.java`（17 topic）、`V20261012140000__tenant_lifecycle.sql`（status active|disabled + deleted_at）、`V20261012110000__tenant_timezone.sql`、`V20260907120000__admin_bootstrap.sql`、feature_gates 演进四迁移
- 权限：`FarmController.java:49-60`（OWNER|B2B_ADMIN 建场）、`DeviceAdminController.java:38/48`（requirePlatformAdmin）、`AlertController.java:94`（dismiss 三角色）、`DataExportAdminController.java`（无注解）
- 控制器分包计数：identity 14 / ranch 16 / iot 21 / health 13 / commerce 8 / analytics 4 / datagen 3 / licensing 3 / shared 2（=84 含异常处理器）

*对账执行：ZCode Agent，2026-11-01；与 PRD v2.4 对账（`2026-11-01-prd-v2.4-sync-audit.md`）同一证据基线。*
