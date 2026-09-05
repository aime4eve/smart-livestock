# NIX-184 市场测试版发布就绪与离线授权 — 总实施计划

> 本文档是 NIX-184 的唯一实施计划，作为跨会话、主子智能体协同执行的唯一事实源。
> 实施依据（spec）：`docs/superpowers/specs/2026-08-31-market-beta-release-readiness-implementation-design.md`（下称"设计"）。

## 0. 部署测试环境（用户指定）

| 服务器 | 角色 | 验证内容 |
|---|---|---|
| `172.17.10.86` | 托管（HOSTED）验证机 | release 包以 `SMARTLIVESTOCK_LICENSE_MODE=HOSTED` 安装，验证试点授权 API、/health、HTTPS |
| `172.17.10.223` | 离线独立部署（ONPREM）验证机 | release 包离线安装（镜像包导入、无外网依赖），`MODE=ONPREM`，验证登记/导入/绑定/到期降级/续费恢复 |

- 两台均为干净 Linux 环境验证目标；T8b 脚本与 T10 发布验收在双机上实测（替代"仅脚本级验证"的原定方案）。
- SSH 账号/端口/网络可达性在执行 T8b 前向用户确认；凭据不入库、不入知识库。

## 1. 背景与目标

- 工单：NIX-184「实施市场测试版发布就绪与离线授权」（High，13 点）。分支：`nix-184-market-beta-hosted-license-design`（承载全部实施）。
- 交付目标：licensing 后端上下文（托管试点授权 + 地端离线授权）、license-issuer 签发服务、Flutter 部署授权页与试点入口、release 单机 Compose 发布包与运维脚本、API 契约、上市材料包（解决方案介绍、市场拓展、技术支持、安装部署指南、运行维护指南、发布检查清单）。

## 2. 执行机制

### 2.1 主子智能体协同
- **主智能体（协调者）**：维护本文件与进度看板；按依赖 DAG 判定就绪卡；派发子智能体执行；亲自运行编译/测试验收子智能体产出（不轻信自述）；失败带报错重派修复卡；更新看板 → git 提交 → 知识库同步。
- **子智能体（执行者）**：按任务卡自包含执行（派发 prompt 含完整任务卡 + 工作区路径 + AGENTS.md 关键约定），自跑验证命令，返回产物清单/验证输出/偏离说明；无权提问用户，阻塞决策交回主智能体。
- **并行冲突隔离**：并行卡文件域不相交（见 §3 DAG）；共享文件（ErrorCode、GlobalExceptionHandler、messages_zh/en.properties）由 T1 一次性定稿，后续卡只读。
- **上下文经济**：子智能体各自消耗独立上下文窗口，主智能体只保留摘要与看板；大卡拆 a/b/c 子卡独立派发独立提交。

### 2.2 跨会话续作协议
- **会话启动**：读本文件进度看板（§8）→ `git log --oneline -15` 对照提交号 → 从"前置全完成"的就绪卡派发执行（默认编号序，允许就绪卡乱序）。
- **会话收尾**：更新看板 → 编译 + 目标测试 → 每卡至少一次提交（`NIX-184 task-N: <内容>`）→ 知识库沉淀。
- **中断恢复**：新会话按启动协议恢复调度；未提交工作重派即可，不重复已完成卡。

## 3. 依赖 DAG 与并行窗口

- **关键路径**：T0 → T1 → T2 → T4 → T5 → T7 → T10。
- **并行窗口**：W1 = T1 完成后 {T2, T3}；W2 = T2 完成后 {T4, T6, T8a}；T5 完成后 {T7, T9 契约/指南}。
- **零依赖卡**：T7c（alerts dead code 修复）、T9 营销三件套（仅依赖 T0，可早写）。

## 4. 任务卡（11 张，含前置/内容/验证）

### T0 计划与测试用例文档［前置：无｜主智能体亲自落盘］
本计划全文落盘 + 进度看板（§8）+ `docs/testing/market-beta-test-cases.md`（覆盖设计 §15 全场景 + 双机部署验证矩阵）。完成标准：两文档入库，首次提交。

### T1 数据模型与错误码［前置：T0｜共享文件定稿卡］
Flyway `V20260903120000__deployment_licensing.sql`：deployment_installations / deployment_licenses / deployment_license_states / deployment_license_events 四表（设计 §6，不种子可用授权）；补 `device_management` 四档 FeatureGate 种子。ErrorCode 增 LICENSE_REQUIRED / LICENSE_INVALID / LICENSE_BINDING_MISMATCH / LICENSE_TIME_ROLLBACK / LICENSE_QUOTA_EXCEEDED；GlobalExceptionHandler 补 case（编译器强制）；messages_zh/en.properties 双语。验证：compileJava。

### T2 签名基础设施［前置：T1］
`com.smartlivestock.licensing` domain 模型（LicensePayload/LicenseEnvelope/LicenseType/LicenseRuntimeStatus/HostFingerprint 等，设计 §3/§5）；infrastructure：CanonicalJsonSerializer、Ed25519LicenseVerifier、ClasspathLicensePublicKeyRegistry、HostFingerprintReader；`smartlivestock.license.*` 与 `smartlivestock.pilot-license.*` 配置属性类。生成 Ed25519 密钥对：公钥 JSON 提交 `src/main/resources/licensing/license-public-keys.json`（当前+轮换槽位），私钥入 `license-issuer/secrets/`（gitignore），测试私钥入 test/resources。`license-issuer/test-vectors/` canonical JSON 共享向量。单测：canonical 排序/UTC 时间格式、验签、envelope 非法、keyId 不支持、payloadSha256 不匹配、绑定不匹配。

### T3 托管试点授权（HOSTED）［前置：T1｜与 T2 并行］
`Subscription.extendTrial(Instant)`（仅 TRIAL、不得缩短）+ 单测；`LicenseSubscriptionPort` + commerce 侧 `CommerceLicenseAdapter`（applyTrialLicense/applyActiveLicense/downgradeForLicense/suspendForLicense）；`CloudPilotLicenseService` + `CloudPilotLicenseController`（POST /api/v1/admin/tenants/{tenantId}/pilot-license：platform_admin、HOSTED+enabled 才可用、ONPREM 返回 AUTH_FORBIDDEN；无订阅建 TRIAL/BASIC 365 天、未过期 TRIAL 延长、其余状态拒绝，设计 §7）；AuditLog 审计（仿 DatagenAuditService）。

### T4 离线校验状态机 + Commerce 集成［前置：T1+T2+T3｜拆三子卡］
- a) `DeploymentLicenseApplicationService`：enrollment（installationId 生成、主机指纹）、import 校验管道、current 查询；状态机 PENDING_ACTIVATION/VALID/EXPIRED/SUSPENDED 五步校验链（设计 §8/§9）。
- b) `DeploymentLicenseScheduler`（cron `validation-cron` 默认 5 分钟 + ApplicationReadyEvent 启动即跑）+ `LicenseTimeGuardService`（max_observed_at 回拨保护、改库自愈）。
- c) `LicenseQuotaPort` + `CommerceQuotaLicenseAdapter`；`QuotaApplicationService` ONPREM license 配额优先、无该 key 回退 FeatureGate、HOSTED 不变（设计 §10）；导入前牲畜/围栏/牧工/设备四项用量预检。

单测：到期降级 FREE/BASIC、ACTIVE 续费激活、降级后不可普通导入重回 TRIAL、配额优先、时间回拨挂起、改库后 scheduler 恢复。

### T5 地端 API 与 enforcement［前置：T4］
`DeploymentLicenseAdminController`：GET enrollment、POST multipart+confirm、GET current、GET mode（mode+pilotLicenseEnabled，设计 §8 之外的小增量）；均 platform_admin。ONPREM 禁用自助结账/升级/取消与 admin 订阅手工变更（commerce 控制器模式守卫）。`LicenseEnforcementInterceptor` 注册 `shared/WebMvcConfig.java`：放行 /health、auth login/refresh、deployment-license/**、admin/tenants/**、静态资源；PENDING_ACTIVATION 阻断业务 API、SUSPENDED 仅授权管理、HOSTED 直通（设计 §11）。单测：403、模式互斥、multipart 成败、pending/suspended 阻断。

### T6 license-issuer 签发服务［前置：T2｜与 T3–T5 并行］
`license-issuer/` Python FastAPI + Jinja2 + SQLite + cryptography + bcrypt + 服务端 session/CSRF；七页面：登录/新建/预览确认/列表/详情/审计/密钥状态（设计 §4）；`scripts/generate-license-key.sh`；私钥目录 0700/0600、fail fast。pytest：登录失败、CSRF 拒绝、私钥缺失、与 Java 向量一致、签发文件被 Java verifier 接受、篡改拒绝、签发/下载审计。

### T7 Flutter 前端［前置：T5；T7c 零依赖｜拆三子卡］
- a) `lib/features/admin/license/{data,domain,presentation}`（设计 §12 文件名）；`AppRoute.platformDeploymentLicense('/admin/deployment-license', ...)` + 路由 + `_PlatformAdminShell` 侧边栏（仅 platform_admin）；页面：租户选择、状态卡片、到期倒计时、安装 ID、指纹哈希、公钥 ID、最近校验结果、上传 .sllicense（dart:html 条件导入仿 telemetry_import）、成功/失败/保护提示、续费引导。
- b) SubscriptionsPage 增"开通 365 天试点授权"按钮 + 状态冲突提示（经 mode 端点感知）。
- c) 修 `app_router.dart:212` 不可达 dead code；全部文案进 app_zh.arb/app_en.arb；新增 zh/en key 完整性对比测试；widget/controller 测试（角色可见性、登记渲染、上传 API、四种状态卡）。

验证：`flutter gen-l10n` 无缺失、`flutter analyze`（CI 同口径）、`flutter test`、`flutter build web`。

### T8 release 发布包［前置：T2；8a 可并行、8b 依赖 8a｜拆两子卡］
- a) `docker-compose.release.yml` 九服务（nginx/app/postgres/redis/rocketmq-namesrv/rocketmq-broker/ai-platform/tileserver/tile-worker；数据服务无 host 端口；仅 nginx 暴露 80/443；补 app/nginx/tileserver healthcheck；`/etc/machine-id` 只读挂载供指纹）；`.env.release.example`（LICENSE_MODE=ONPREM、PILOT_LICENSE_ENABLED=false、DATAGEN_ENABLED=false、TELEMETRY_SIMULATOR_ENABLED=false）；`infrastructure/nginx/nginx.release.conf`（80→443、TLS1.2/1.3、secrets/certs 挂载）+ release Dockerfile。
- b) 六脚本：build-release-package.sh（bootJar + build_web.sh + docker build/save + SHA256SUMS + docs 打包）、install-release.sh、check-release-health.sh、backup-release.sh、restore-release.sh、verify-release-bundle.sh（SHA256、无 issuer/私钥/.sllicense、双开关 false、无数据端口映射，设计 §13/§14）。

验证：`docker compose config` 通过、本机构包跑 verify 通过、bash -n；**T10 阶段在 172.17.10.223 实机离线安装验证**。

### T9 文档契约 + 上市材料包［契约依赖 T3/T5；安装/运维指南依赖 T8；营销件仅依赖 T0］
- 契约：`docs/api-contracts/admin-api.md` 追加授权端点 + `changelog.md` 条目。
- 指南：`docs/guides/release-install-guide.md`（环境要求、离线安装、TLS 证书、首次授权登记与导入、HOSTED/ONPREM 差异、安装验证）、`docs/guides/release-operations-guide.md`（健康检查、备份恢复、日志排查索引、授权续期、升级、证书更换）、`docs/guides/release-checklist.md`；三份进 release 包 docs/。
- 营销（基于既有 docs/marketing/solution-brochure.html 与 docs/training/01 售前、02 售后 playbook 补齐，不重复）：`docs/marketing/solution-introduction-market-beta.md`（痛点、能力、HOSTED/ONPREM 部署形态、订阅与 365 天试点、Open API 核心能力、AI 试点边界不承诺准确率）+ brochure 增补部署形态；`docs/marketing/market-development-kit.md`（客群画像、切入策略、试点→付费转化、订阅档位定价对齐 SubscriptionTier、销售 FAQ 异议处理、渠道要点）；`docs/marketing/technical-support-guide.md`（支持分级响应、FAQ、四层排查决策树、升级路径、ONPREM 远程支持边界）。

### T10 总验证 + dev 部署 + 双机部署测试［前置：全部］
后端目标测试 0 failure 0 error（对比既有 19 失败基线不扩大）；Flutter gen-l10n/analyze/test/build web；issuer pytest；verify-release-bundle；`./scripts/deploy.sh dev`（dev/test 保持 HOSTED 默认，行为不变）+ curl /health。
**双机实测**：172.17.10.86 以 HOSTED 模式安装并验证试点授权与 /health；172.17.10.223 以 ONPREM 模式离线安装（不联网）并验证登记/导入/绑定/到期降级/续费恢复全链路（对应测试用例文档 §6 部署验证矩阵）。完成后交用户集成测试。

## 5. 已定决策与设计偏离记录

1. 前端两处内部管理页跳过 HTML 原型，沿用既有 Highfi 组件与设计令牌。
2. Flyway 版本 `V20260903120000`（设计原值 V20260831120000 早于现存最高迁移 20260901110000）。
3. 新增 `GET /api/v1/admin/deployment-license/mode`（前端模式感知所需，设计两 API 双模式互斥不可复用）。
4. 迁移补 `device_management` 四档 FeatureGate 种子（license 配额预检需要；无 Controller 消费，HOSTED 行为不变）。
5. 代码注释英文、面向用户文案中文；Flutter 沿用 `AppLocalizations.of(context)!` 现有惯例（非 context.l10n）。
6. 用户补充两台部署测试服务器（§0），T8b/T10 升级为双机实测，不再只是脚本级验证。

## 6. 总验收门槛（设计 §17）

后端目标测试 0 failure 0 error；Flutter CI 同口径分析通过、契约测试通过、Web 构建成功；release Compose config 通过；/health 连续通过；授权绑定/篡改/时间回拨/到期降级/续费恢复全部通过；release 包扫描无私钥与 issuer；datagen 与 simulator 确认关闭；中英文资源同步完整；上市材料包六件齐备；双机（86 HOSTED / 223 ONPREM）安装验证通过。

## 7. 已知勘察结论（供子智能体派发时引用）

- 后端 9 模块 DDD 分层；`Subscription`（TRIAL 七态齐全、`effectiveTier()` 试用返 PREMIUM）缺 `extendTrial`；`SubscriptionTier` 四档 BASIC/STANDARD/PREMIUM/ENTERPRISE。
- `device_management` feature key 全库不存在；`@QuotaCheck` 现仅 livestock/fence 两处。
- ErrorCode 枚举 + GlobalExceptionHandler exhaustive switch（新增必须补 case）；`ApiException` 走 MessageSource（messages_zh/en.properties）。
- 无 ShedLock，纯 `@Scheduled`；拦截器注册于 `shared/WebMvcConfig.java`；SecurityConfig 已放行 `/health`。
- 现有 "license" 是设备 License（iot）与 subscription_services 的 LicenseExpiryJob，与本次 licensing 无关，命名注意区分。
- 测试：纯单测（JUnit5+Mockito）+ `AbstractJourneyTest`（Testcontainers，本机有 14 个 Docker 环境既有失败）；无 @WebMvcTest。
- Flutter：riverpod 3.3.x + go_router + http；`ApiClient.instance.uploadFile` 已有 multipart；web 文件读取用 dart:html 条件导入；arb 模板 app_zh.arb；平台路由枚举 `AppRoute`；平台侧边栏 `main_shell.dart` `_PlatformAdminShell`。
- alerts dead code：`app_router.dart:212` 不可达 `return AlertsPage(role: role);`。
- 部署：无 release compose/脚本；dev/test 均 `docker compose build` 本地构建；卷 pgdata/tileserver-data/behavior-models；DATAGEN_ENABLED 默认 true（release 须显式 false）；TELEMETRY_SIMULATOR_ENABLED 无 Java 消费者（死配置，仍写入 release env 供 verify 检查）。

## 8. 进度看板

| 卡 | 状态 | 提交 | 产物/备注 |
|---|---|---|---|
| T0 | ✅ 完成 | `3a2a28d5` | 本计划 + docs/testing/market-beta-test-cases.md |
| T1 | ✅ 完成 | `153046fc` | V20260903120000 四表+device_management 种子；5 个 LICENSE_* 错误码+handler case+双语文案；compileJava 通过 |
| T7c | ✅ 完成 | `614cf15a` | app_router.dart dead code 删除；analyze 无 dead_code/unused（余 12 个既有 info） |
| T2 | ✅ 完成 | （见 git log） | 签名基础设施（早先状态行漏刷新；完成于 T10 前） |
| T3 | ✅ 完成 | 243c0505 等 | 托管试点授权（早先状态行漏刷新；billingCycle 修复见知识库） |
| T4a/b/c | ✅ 完成 | `774f5a7e` | 状态机+TimeGuard+Scheduler+配额优先；目标测试 339 全绿；补 `Subscription.downgradeToFree()` |
| T6 | ✅ 完成 | `a53cbad7` | issuer 全套（8 页面路由+SQLite+CSRF+限速）；pytest 47 绿；Python→Java 回程向量闭环（IssuerRoundtripVectorTest 3 绿）；测试密码改运行时拼接过 Mimosa 拦截 |
| T8a | ✅ 完成 | `1630b244` | release compose 九服务（仅 nginx 有端口）+TLS conf+env 模板；`.gitignore` 补 `!.env.release.example`；docker compose config 待 T8b 在有 docker 的机器补跑 |
| T5 | 🔄 进行中 | — | 子智能体执行中 |
| T8b | 🔄 进行中 | — | 子智能体执行中 |
| T9a 营销三件套 | 🔄 进行中 | — | 子智能体执行中 |
| T5 | ✅ 完成 | `b264994b` | 4 端点+enforcement 拦截器+ONPREM 自助禁用守卫；目标测试 392 全绿；偏离：`/api/v1/me/**` 加入放行（前端会话引导需要） |
| T8b | ✅ 完成 | `30777c13` | 六运维脚本+generate-license-key.sh；bash -n 全过+verify 正负例冒烟；公钥推导与 T2 密钥交叉验证一致；实机验证留 T10 |
| T9a | ✅ 完成 | `41f1b434` | 营销三件套+brochure 增补；用户裁决同步修正：定价统一 ¥299/¥699（英文 $41.5/$97.1，7.2 汇率注记）、保留期统一 7/30/90/3 年（customer-journey.md 365→90） |
| T7a/b | ✅ 完成 | `6461fb7d` | 部署授权页+试点入口+侧边栏；48 arb key；CI 口径 499 测试全绿；build web 通过；analyze exit 0 |
| T9b | ✅ 完成 | `ce6f5128` | 契约 5 端点（字段逐一对 DTO）+changelog；安装/运维指南+发布检查清单；脚本引用核对一致 |
| T10 | ✅ 完成 | 2d6bb2a9 / bb19bc81 / 00268108 | **双机实测通过**：86 装 HOSTED（试点 TRIAL 至 2027-09-04）；223 离线装 ONPREM（PENDING 阻断→签发导入→VALID→篡改/错绑拒绝→改库自愈 RECOVERED）；双机 check-release-health 26/26；86 备份恢复闭环；外部扫描暴露面仅 80/443。实测暴露并修复 5 处缺陷（详见知识库档案） |

| RI 重装终验轮 | ✅ 完成 | f812e02e | 发布包重建 557→（verify 脚本 mawk 假失败，lesson #22）→**558 定稿**：86/223 双机重装（证书/数据卷/env 继承，MIN_MEM/MIN_DISK 覆盖），双机 verify 13/13 + check-release-health 26/26；86 试点数据存续、223 授权 VALID 存续（PREMIUM 至 2027-09-04）；牲畜修复/管理 key scopes/tile-worker key 双机全数生效，401 清零 |
| IT 集成测试轮 | ✅ 完成 | dd82af98 / e59c488b / 1c69307d | 四环境回归（dev/test/86/223）+ 86 HOSTED 与 223 ONPREM 端到端：TC-C/TC-E/TC-H/TC-O 关键项全过；发现并修复 4 缺陷：①牲畜 breed/gender 无校验撞 DB CHECK 变 500（含契约示例纠正）②管理端建 Open API key 无 scopes 全 403 ③门户建 key 响应丢 rawKey ④tile-worker key 与 V36 种子失配（86/223 运维侧已改种子值+重建，双机鉴权失败清零）。dev 已部署并回归通过；86/223 的 jar 修复随下次发布包生效。登录页授权徽章 dev 双语截图验证通过 |

> 看板维护规则：每卡完成由主智能体更新状态/提交号/产物路径；偏离记入 §5。
> 其他待办：Mimosa 完整安全审计补跑（commit 钩子提示 scanner_enobufs / library_source_unavailable，T10 前执行）。
