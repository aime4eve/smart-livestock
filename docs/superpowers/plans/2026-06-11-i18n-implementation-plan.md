# 国际化（i18n）实施计划

> **关联设计**：`docs/superpowers/specs/2026-06-11-i18n-design.md`（R2 已评审）
> **范围**：Flutter App（`Mobile/mobile_app`）+ Spring Boot 后端（`smart-livestock-server`）；PC/Angular 与 Mock Server 不做
> **创建日期**：2026-06-11
> **重写日期**：2026-06-12（基于代码核对，反映真实进度）
> **状态**：阶段 0 完成 / 阶段 1 完成 / 阶段 2 进行中

---

## 进度总览

| 阶段 | Task | 状态 | 说明 |
|---|---|---|---|
| 阶段 0 基础设施 | 1–7 | ✅ 1–6 完成，Task 7 待验证 | 后端 MessageSource + 异常改造 + Handler 收敛；前端 gen-l10n + LocaleController + 切换 UI |
| 阶段 1 后端消息迁移 | 8–10 | ✅ 全部完成 | 189 throw 点全部 messageKey 化（0 中文）；properties zh/en 各 100 key |
| 阶段 2 前端文案抽取 | 11–12 | ❌ 待实施 | arb 仅 16 个 `common.*` 骨架 key；434 处 `Text()` 中文未迁移 |
| 阶段 3 收尾 | 13 | ❌ 待实施 | CI key 完整性 + 术语校对 + glossary + 全链路验证 |

---

## Issue 索引表

> 实施时创建 GitHub Issue。编号为计划内引用，待 Issue 创建后回填实际 GitHub Issue 号。

| 优先级 | 计划 ID | 标题 | 依赖 |
|---|---|---|---|
| P0 | `i18n-t7` | 阶段 0 端到端验证（后端 Accept-Language + 前端切换 + 回归） | 1–6 |
| P1 | `i18n-t11` | 前端 AppRoute labelKey + 枚举显示名表 | — |
| P1 | `i18n-t12` | 前端 30 模块 Text() 抽取（434 处 → arb） | `i18n-t11` |
| P1 | `i18n-t13` | 收尾：CI key 完整性 + 术语校对 + glossary + 全链路验证 | `i18n-t12` |

---

## Task Dependency Graph（当前）

```
阶段 0（已完成）        阶段 1（已完成）
  Task 1–6 [x]           Task 8–10 [x]
       ↓
  Task 7 [ ] 端到端验证（阶段 0/1 收口）
       ↓
阶段 2 前端文案抽取（剩余主体）
  Task 11 [ ] AppRoute labelKey + 枚举显示名表
       ↓
  Task 12 [ ] 30 模块 Text() 抽取（9 个 Step，按模块优先级）
       ↓
阶段 3 收尾
  Task 13 [ ] CI key 完整性 + 术语校对 + glossary + 全链路验证
```

Task 11 → 12 串行（12 依赖 11 的 arb key 命名规范和 helper 就位）。Task 7 应在阶段 2 启动前完成（确认链路通畅）。

---

## 阶段 0 — 基础设施

### Task 1：后端 MessageSource + properties 骨架 + Locale 配置 `[x]`

**Files:**
- Create: `messages.properties`、`messages_zh.properties`、`messages_en.properties`
- Modify: `application.yml`（加 `spring.messages.basename=messages`）
- Create: `LocaleConfig.java`（注册 `AcceptHeaderLocaleResolver`，fallback `zh-CN`）

- [x] Step 1：创建 3 个 properties 文件，含示例 key
- [x] Step 2：配置 basename + LocaleResolver
- [x] Step 3：编译验证

### Task 2：后端异常类改造 + GlobalExceptionHandler 收敛 + resolve helper `[x]`

**Files:**
- Modify: `ApiException.java`、`DomainException.java`
- Modify: `GlobalExceptionHandler.java`
- Create: `MessageResolver.java`

- [x] Step 1：改造 ApiException（新增 `messageKey + args` 构造，**保留 legacy `(ErrorCode, String)` 构造**委托新构造）
- [x] Step 2：DomainException 同构改造
- [x] Step 3：创建 `MessageResolver`（`resolve(key, args, locale)`，fallback = key 本身）
- [x] Step 4：改造 GlobalExceptionHandler（注入 MessageResolver，所有 handler 用 resolve 翻译）
- [x] Step 5：编译 + 单元测试
- [x] Step 6：验证 legacy throw 点不受影响（旧构造 args=null，resolve 时 key 即中文原文）

> **与 spec 决策偏离**：spec §3.2 定"一次性迁移"（旧构造签名变化 → 编译期强制改造）。实际采用**增量式**（新构造 + 保留 legacy 旧构造），好处是渐进迁移不阻断编译，最终结果一致（189 throw 全迁，0 中文残留）。计划 §Assumptions 记录此偏离。

### Task 3：前端 gen-l10n 接入 `[x]`

- [x] `pubspec.yaml` 加 `flutter_localizations` + `intl`，开 `generate: true`
- [x] 创建 `l10n.yaml`（`arb-dir: lib/l10n`, `template-arb-file: app_zh.arb`, `output-class: AppLocalizations`）
- [x] 创建 `app_zh.arb` + `app_en.arb`（骨架 key — 约 16 个 `common.*` 通用词汇）
- [x] 验证 gen-l10n 生成

### Task 4：前端 LocaleController + SharedPreferences 持久化 `[x]`

- [x] 创建 `LocaleController`（Riverpod Notifier），持有 `Locale`
- [x] 暴露 `localeProvider`
- [x] 持久化到 `SharedPreferences`；初始值读 SP，无则跟随系统 `PlatformDispatcher.locale`
- [x] locale→header 映射：`Locale('zh')` → `'zh-CN'`，`Locale('en')` → `'en'`

### Task 5：前端 ApiClient.setLocale + Accept-Language + fallback 消息抽取 `[x]`

- [x] 加 `_locale` 字段 + `setLocale(String?)` 方法
- [x] `_headers()` 注入 `Accept-Language: <_locale>`
- [x] 4 处硬编码 fallback 中文（"认证失败"/"服务器异常"/"租户已禁用"/"登录失败"）改 `.arb` key

### Task 6：前端 MaterialApp locale 集成 + "我的"页语言切换 UI `[x]`

- [x] `DemoApp` 配置 `localizationsDelegates`、`supportedLocales: [Locale('zh'), Locale('en')]`、`locale` watch `localeProvider`
- [x] 语言切换时桥接 `ApiClient.instance.setLocale(...)`
- [x] "我的"页加语言选择器（三选：中文 / English / 跟随系统）
- [x] 编译验证

### Task 7：阶段 0 端到端验证 `[ ]`

> **依赖**：Task 1–6 完成，Task 8–10（阶段 1 后端迁移）也已完成，可一并进行。

- [ ] Step 1：后端验证 — `curl` 带 `Accept-Language: en` / `zh-CN` 请求各限界上下文端点，断言错误响应 message 按语言变化
- [ ] Step 2：前端切换验证 — 手动切换中英，确认框架文案（common.* key）正确切换、ApiClient header 正确携带
- [ ] Step 3：全量回归 — `./gradlew test` 绿色 + `flutter test` 绿色 + `flutter analyze` 绿色

---

## 阶段 1 — 后端消息迁移

### Task 8：throw 迁移 — Identity + Shared `[x]`

### Task 9：throw 迁移 — Commerce + Health + Analytics `[x]`

### Task 10：throw 迁移 — Ranch + IoT + properties 补全 + key 完整性 `[x]`

**实际成果**（代码核对，2026-06-12）：

- 189 throw 点（170 `throw ApiException` + 19 `throw DomainException`）全部迁移为 `messageKey+args`，**中文残留 = 0**
- `messages_zh.properties` / `messages_en.properties` 各 **100 key**，且 key 集合完全一致
- 所有 controller 直接出口已收敛：
  - `TenantController`（spec 原列 2 处直接 `ApiResponse.error`）→ 改 `throw ApiException(code, "identity.noTenantAffiliation")`
  - `OpenDeviceRegisterController`（spec 原列 1 处）→ 改 `throw ApiException(code, "validation.serialNo.required")`
  - `PortalAppController`（原 4 处）→ 全部 throw messageKey
  - `PortalAdminController`（原 3 处）→ 全部 throw messageKey
  - `TelemetryController`（原 2 处）→ 全部 throw messageKey
  - `FenceController:102` → catch + `messageResolver.resolve(...)` 收敛
  - `AlertController:147` → 空 catch 吞掉（无需处理）
- `GlobalExceptionHandler` 全部 handler 注入 `MessageResolver`，按 `LocaleContextHolder.getLocale()` 翻译

---

## 阶段 2 — 前端 UI 文案抽取

> **当前状态**：`app_zh.arb` / `app_en.arb` 仅含约 16 个 `common.*` 通用词汇骨架 key（共 126 行）。434 处 `Text()` 含中文分布在 65 个文件中，待逐文件迁移到 arb。

### Task 11：AppRoute labelKey + 枚举显示名表 `[ ]`

**方案**：采用 spec 推荐的**方案 A（增量式）**—— 新增 `labelKey` 字段，保留中文 `label` 作为 fallback。

**Files:**
- Modify: `lib/app/app_route.dart`（42 枚举项加 `labelKey`）
- Modify: `lib/app/main_shell.dart` 等消费处（`label` → `l10n` 翻译 `labelKey`）
- Modify: `lib/l10n/app_zh.arb`、`app_en.arb`（加 42 个 `nav.*` key + 枚举相关 key）
- Create: `lib/core/l10n/enum_labels.dart`（枚举显示名 helper）

**Steps:**

- [ ] Step 1：`AppRoute` 枚举加 `labelKey` 参数（值如 `'nav.login'`、`'nav.ranch'`...），共 42 个
- [ ] Step 2：arb 加 42 个 `nav.*` key（zh/en 双语），gen-l10n 重新生成
- [ ] Step 3：`main_shell.dart` 等所有 `.label` 消费处改为 `l10n` 翻译 `labelKey`
- [ ] Step 4：创建 `enum_labels.dart` helper，映射方案：`AlertType`/`AlertStatus`/`DeviceType`/`DeviceStatus`/`Role`/`SubscriptionTier`/`SubscriptionStatus`/`ContractStatus`/`Severity`/`HealthStatus` 等 → arb key（`enum.alertType.fenceBreach` 等）
- [ ] Step 5：arb 加所有枚举显示名 key（zh/en 双语，预计 ~60+ key）
- [ ] Step 6：枚举显示消费处改为 `EnumLabels.label(type, l10n)` 或类似 helper
- [ ] Step 7：编译 + gen-l10n 验证无缺 key

**验收**：
- `AppRoute` 所有 label 通过 `labelKey` 翻译，42 路由导航/标题中英切换正确
- 所有面向用户的枚举显示名（告警类型、设备类型、角色、订阅等级等）中英切换正确
- `flutter analyze` 绿色

### Task 12：30 模块 Text() 抽取（434 处 → arb，分 9 个 Step 按优先级） `[ ]`

**策略**：高频页面优先，逐 Step 收敛。每个 Step 验证该组模块中英切换无中文残留。

**通用操作**（每个 Step 重复）：
1. 扫描目标模块所有含中文的 `Text()`（grep `Text('[一-龥]'`）
2. 逐一迁移到 `app_zh.arb`（key 命名：`{模块}.{场景}.{语义}`，如 `alerts.pageTitle`、`fence.createButton`）
3. 同步补 `app_en.arb` 英文翻译（与 zh 的 key 集合严格一致）
4. 该模块消费处改为 `l10n.xxx` 或 `AppLocalizations.of(context)!.xxx`
5. 编译 + 切换英文验证该模块无中文残留

**Step 拆解**：

| Step | 模块 | Text 密度 | 说明 |
|---|---|---|---|
| S1 | `pages/`（dashboard, map, alerts, twin_overview, stats） | 高 | 核心页面，最高频 |
| S2 | `auth/` + `mine/` | 高 | 登录 + 个人中心（含语言切换自身） |
| S3 | `fence/` | 高 | 围栏是最复杂模块（含 widgets 子目录），独立处理 |
| S4 | `alerts/` + `livestock/` + `devices/` | 中 | 告警列表 + 牲畜 + 设备管理 |
| S5 | `admin/` + `b2b_admin/` + `tenant/` | 高 | 管理后台（表格列头、表单标签多） |
| S6 | `subscription/` + `contract_management/` + `revenue/` + `subscription_service_management/` | 中 | 商业模块 |
| S7 | `fever_warning/` + `digestive/` + `estrus/` + `epidemic/` + `highfi/` + `twin_overview/` | 中 | 健康模块 |
| S8 | `farm_creation/` + `farm_switcher/` + `worker_management/` + `api_authorization/` + `offline_fences/` + `offline_livestock/` + `offline_tiles/` + `stats/` | 低 | 辅助模块 |
| S9 | `widgets/`（通用组件）+ 全量扫描 | 低 | 通用 empty_state / metric_card / status_tag / pagination_bar 等 |

**每个 Step 验收**：
- 目标模块页面切换中英无中文残留（grep 验证）
- `flutter analyze` 绿色
- arb zh/en key 集合一致

**最终验收**（全 Step 完成）：
- `flutter test` 全绿（测试固定 `Locale('zh')` 断言中文）
- `grep -rh "Text('[一-龥]" lib --include="*.dart"` = 0
- 全量页面中英切换无 `common.*` 以外的遗漏

---

## 阶段 3 — 收尾

### Task 13：CI key 完整性 + 术语校对 + glossary + 全链路验证 + 文档 `[ ]`

- [ ] Step 1：后端 key 完整性测试 — `MessageKeyIntegrityTest`：`messages_zh.properties` vs `messages_en.properties` key 集合完全相等；不相等则构建失败
- [ ] Step 2：前端 key 完整性 — gen-l10n 编译期保证（缺 key 编译失败）；额外加 lint/script 检查 `app_zh.arb` vs `app_en.arb` key 集合一致
- [ ] Step 3：英文术语人工校对 — 畜牧/IoT 领域术语（rumen capsule / estrus detection / fence breach / ear tag / tracker / herder）逐条确认
- [ ] Step 4：建立 glossary 术语表 — `docs/i18n-glossary.md`，保证全项目术语一致
- [ ] Step 5：全链路验证 — live 模式（连接 Spring Boot 后端）中英切换，覆盖全部角色（owner/worker/platform_admin/b2b_admin）的主要页面流程
- [ ] Step 6：文档 — 更新 `CLAUDE.md` / `Mobile/CLAUDE.md` 的 i18n 相关内容；spec 转终稿状态

**验收**：
- `./gradlew test` 绿色（含 key 完整性测试）
- `flutter test` + `flutter analyze` 绿色
- 中文残留 = 0（前后端）
- glossary 就位

---

## 完成记录表

| 完成日期 | 计划 ID | 说明 |
|---|---|---|
| 2026-06-11 | Task 1–2 | 后端 MessageSource + ApiException/DomainException 改造 + MessageResolver + GlobalExceptionHandler 收敛 |
| 2026-06-11 | Task 3–6 | 前端 gen-l10n + LocaleController + ApiClient.setLocale + MaterialApp + 切换 UI |
| 2026-06-11 | Task 8–10 | 后端 throw 迁移全完成（189 → 0 中文，100 key zh/en 一致）；所有 controller 出口收敛 |
| | Task 7 | |
| | Task 11 | |
| | Task 12 | |
| | Task 13 | |

---

## 关键实现决策

- **增量式构造函数**：`ApiException`/`DomainException` 新增 `messageKey + args` 构造，**保留 legacy `(ErrorCode, String)` 构造**（委托新构造，args=null）。与 spec 的"一次性迁移"有偏离，但最终结果一致（0 中文残留），且渐进式迁移降低风险。
- **locale 映射钉死**：`Locale('zh')` → header `zh-CN`，`Locale('en')` → header `en`。`LocaleController.setLocale` 中做显式转换。
- **AppRoute label 方案 A**（增量式）：新增 `labelKey` 字段，保留中文 `label`。消费处改读 `labelKey` → `l10n` 翻译。diff 小、遗漏面低。
- **枚举显示名放前端 arb**（不做后端枚举改造）。20+ 枚举逐一建 `enum.*` key。

## Assumptions

- 增量式构造函数（legacy 构造保留），已完成的全量迁移证明该策略有效
- Mock 模式中英混杂可接受（出海用 live 模式，不在 scope）
- 阶段 2 Task 12 的 Step 分组基于模块重要性 + Text 密度预估，实施时可按实际 grep 结果微调
- Task 7 端到端验证在阶段 2 启动前完成（阶段 0/1 的收口，确认链路通畅）
- gen-l10n 的 key 命名规范（`{模块}.{场景}.{语义}`）在 Task 11 实施时细化，Task 12 沿用
