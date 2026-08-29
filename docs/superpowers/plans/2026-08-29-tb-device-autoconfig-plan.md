# 项目级 TB 设备接入对账与一站式开通实施计划（NIX-180）

> Date: 2026-08-29  
> Spec: `docs/superpowers/specs/2026-08-29-tb-device-autoconfig-design.md`  
> Issue: NIX-180

## Task 0：视觉保真准备

1. 新增 `docs/marketing/2026-08-29-tb-device-autoconfig-wizard.html`，使用现有 App tokens：`--primary #2F6B3B`、`--surface #F8F6F0`、`--surface-alt #FFFFFF`、`--border #D7D2C6`、`--text-primary #263126`、`--text-secondary #617061`、间距 4/8/12/16/24。
2. 提取 token 表，截取原型基线；Flutter 实现后按 390px 宽做视觉比对。
3. 本任务只涉及一个 bottom sheet 向导，不新增页面路由。

## Task 1：NS Client

1. 新增 `NsProperties`：enabled、base-url、username、password、org-id、page-size。
2. 新增 `NsClient.login()`、`listDevices(projectId)`，支持 `x-token`、`code=0`、分页 `page/limit/count/data`。
3. 单测：登录头、失败响应、分页终止、EUI 字段兼容、非 0 code 抛错。

## Task 2：TB 对账客户端能力

1. 扩展 `TbClient.findDevices(eui)`，保留三变体精确匹配并返回 id/name/profileId。
2. 新增 device profile 分页查询和 profileId→name 映射。
3. 新增 latest telemetry 查询，按 epoch ms 输出 `Instant`。
4. 单测覆盖模糊结果过滤、大小写歧义、profile 分页、最新 telemetry 解析。

## Task 3：对账与导入服务

1. 新增 repository 查询：tenant 内按 EUI 包含软删除、provider+external id、provider+EUI。
2. 实现 `reconcile()`：三方差集、profile/telemetry/local/binding/installation 状态和统计。
3. 实现 `import()`：提交时重新校验、幂等创建/复用 device 与 binding、audit log。
4. 单测：dry-run 零写入；重复 wet-run 不新增；TB 身份冲突失败；软删除不自动复活。

## Task 4：单设备预检与开通 API

1. 实现 preflight：EUI 校验、NS 存在性、TB 唯一性/profile/telemetry、本地与 installation 状态。
2. 实现 provision：创建/复用本地 device 与 binding、激活、可选 installation、返回分层结果。
3. 事务提交后触发单设备 TB 拉取；`TbTelemetryChannel` 未启用时返回 `TB_TRIGGER_SKIPPED_DISABLED`。
4. Controller 记录当前用户为 operator，并复用 i18n error key。

## Task 5：Flutter 向导

1. Repository 新增 preflight/provision API 和领域模型。
2. 新增 farm-scoped wizard controller，切换牧场自动重建。
3. 替换设备页新增表单为 EUI 预检、确认信息、选择牲畜/暂不安装、开通结果四状态 UI。
4. 中英 ARB 同步，`flutter gen-l10n` 后检查无缺失 key。
5. `flutter analyze`、`flutter build web --release`，并做 390px 原型/实现截图比对。

## Task 6：文档与运维说明

1. 更新 `business-platform/hkt-blade-device-docking/README.md`：API、dry-run/wet-run、audit 查询、project 89 事实源、失败矩阵。
2. 明确本工具不修改 TB Gateway mapping；project route 仍走备份、管理员审批、受控重载和真实上行验证。

## Task 7：验证与交付

1. 后端：`./gradlew compileJava compileTestJava`。
2. 后端目标测试：NS Client、TbClient、Provisioning Service、Controller 相关测试。
3. Flutter：`flutter gen-l10n`、`flutter analyze`、`flutter build web --release`。
4. dev：`./scripts/deploy.sh dev`，配置 NS/TB env 后执行 project 89 dry-run、少量 wet-run、重复 wet-run、audit/DB 追溯、单设备向导 API 和首次拉取验证。
5. Linear 更新验证证据；test 部署只等待用户通知后执行。

## 2026-08-29 验证记录

1. 后端 `compileJava compileTestJava` 通过；目标测试 `NsClientTest`、`TbClientTest`、
   `TbDeviceProvisioningServiceTest` 通过。
2. Flutter `gen-l10n` 完成；目标 `devices_controller_test` 8/8 通过；
   `flutter analyze --no-fatal-warnings --no-fatal-infos` 无错误（保留既有
   `app_router.dart` dead code warning 与既有 lint）。
3. `build_web.sh` 与 `flutter build web --release` 均通过；dev nginx 镜像包含
   `/devices/tb/preflight` endpoint 和向导文案。
4. dev 已部署，Flyway 校验 86 个迁移通过；TB 既有 tracker 绑定保持 `RESOLVED`、
   397 行 `THINGSBOARD` DTL、游标 `1784724389803`。
5. 使用 dev 种子 B2B 账号调用 reconcile 路由，按预期返回
   `NS 或 ThingsBoard 自动配置开关未启用`，确认路由、认证与安全开关生效。
6. 用户已在 dev `.env.dev` 补充 NS username/password。首次调用发现组织账号设备清单
   必须使用 `/backend/org_api/lora_wan/device/list/`；已修正并增加单 EUI
   `dev_eui` 查询，preflight 从约 35 秒优化到约 0.94 秒。
7. project 89 真实对账结果：NS 30 台、TB 唯一命中 5 台、本地 1 台、RESOLVED 1 台、
   active installation 0 台。差异：25 台 TB 缺失、29 台本地缺失、25 台无最近 telemetry、
   1 台已导入但未安装。
8. 单台 wet-run 导入 `001a0103ff000262`：首次 `IMPORTED`，重复 `ALREADY_BOUND`，
   始终是 device 153 / binding 2，DB 中各只有 1 行。审计 id 3/4 分别记录两次结果。
9. 单设备 provision API 复用设备/绑定，返回 `PENDING_INSTALLATION` 语义和
   `TB_TRIGGERED`；首次拉取后 DTL 15 行，游标 `1787950882885`；installation 仍为 0。
10. Flutter 向导修复 EUI 输入后预检按钮仍禁用的交互缺陷；新增 390px confirm/result
    golden，目标测试 9/9、analyze 和 release web build 通过。
11. test 环境未部署，等待用户通知。test preflight 当前会因远程 `.env` 中 DB_PASSWORD
    和 JWT_SECRET 仍是模板占位值而拒绝部署，属于既有环境安全债。
