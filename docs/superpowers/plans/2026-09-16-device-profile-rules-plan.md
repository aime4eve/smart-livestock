# 设备配置（TB Profile）规则管理 · 实施计划（plan）

> 状态：待用户确认（阶段 3/4）
> 工单：NIX-214
> spec：`docs/superpowers/specs/2026-09-16-device-profile-rules-spec.md`（已锁定）
> 原型：`docs/prototypes/nix-214-device-profile-rules-prototype.html`（已确认）
> 约定：每个含 UI 的 Task 完成后做一次**保真对照**（Flutter 页面 vs 原型对应屏），偏差记录进提交说明；全部 Task 完成后统一走 dev 部署 + 冒烟。
> 分支：从 master 拉 `nix/214-device-profile-rules`。

---

## Task 0 · 视觉保真准备
- 从原型提取规格卡（本文件附录 A）：token 映射（spec §1，零新增）、三屏组件清单与尺寸/字号/色值速查（spec §6）；
- 逐一核对 Flutter 侧颜色已存在（AppColors.estrus=0xFFC25689 复用为胶囊徽标，不新增 AppColors 项）；
- 保真验证：无 UI，跳过。

## Task 1 · 后端：迁移 + 实体/仓库
1. `V20260916100000__create_device_profile_rules.sql`：建表（spec §3.1 DDL）+ 两条种子（现行白名单，行为不变）；
2. `DeviceProfileRule` 实体（iot/domain/model）：id/profileName/deviceType/enabled/remark/createdBy/updatedBy/createdAt/updatedAt；
3. `DeviceProfileRuleRepository` port + JPA 实现：`findAllByOrderByProfileNameAsc`、`existsByProfileName`、`findEnabledAsMap`（或 service 内存组装）。
- 验证：compileJava + 全新库迁移冒烟（本地空库 Flyway 跑通、种子两行存在）。保真验证：无 UI，跳过。

## Task 2 · 后端：规则服务 + 错误码
1. `DeviceProfileRuleService`（iot/application）：`create/update/delete/list`（唯一校验→DUPLICATE 409、类型枚举校验、notFound 校验、`recordAudit` CREATED/UPDATED/DELETED）+ `resolveActiveTypeMap()`（enabled 行一次查询 → Map<profileName,DeviceType>）；
2. `ErrorCode` + `messages_zh/en.properties` 新增：`iot.profileRule.duplicate / notFound / invalidDeviceType / nameRequired`、`iot.tb.profilesUnavailable`。
- 验证：compileJava + service 单测（唯一冲突/枚举非法/停用不参与映射）。保真验证：无 UI。

## Task 3 · 后端：TbDeviceProvisioningService 改造
1. 删常量 `CAPSULE_PROFILE`/`TRACKER_PROFILE` 与静态 `deviceTypeForProfile`；
2. `tbInventory(eui, profiles, ruleMap)` 加参；`reconcile`/`importDevices` 方法头各加载一次映射下传；`preflight`/`provision` 方法头各加载一次；
3. `profileValid = ruleMap.containsKey(profileName)` 语义等价替换；`deviceType` 取映射值。
- 验证：compileJava + 既有 TB provisioning 相关测试全绿（种子保证行为不变，失败集合对比 19 个既有基线不扩大）。保真验证：无 UI。

## Task 4 · 后端：Controller + TB 透传
1. `DeviceProfileRuleController`（iot/interfaces/admin）：`/api/v1/admin/device-profile-rules` 类级 `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")`；GET 列表 / POST / PUT /{id}（忽略 profileName）/ DELETE /{id}；GET `/tb-profiles` 透传 `TbClient.fetchDeviceProfiles()`，TB 失败 → `iot.tb.profilesUnavailable`（业务异常可捕获，不 500 裸抛）；
2. DTO：`DeviceProfileRuleDto(id,profileName,deviceType,enabled,remark,updatedAt)` + `TbProfileDto(id,name)`。
- 验证：compileJava + MockMvc 层权限测试（OWNER/WORKER 403，PLATFORM_ADMIN/B2B_ADMIN 200）。保真验证：无 UI。

## Task 5 · 后端：集成测试（Testcontainers 真库，经验 #19/#20）
1. CRUD 全路径 + 重名 409 + PUT 改名被忽略 + DELETE notFound；
2. **preflight 联动**：TRACKER 种子规则 → preflight 正常；UPDATE enabled=false → `PENDING_TB_DEVICE`；重新启用 → 恢复；DELETE → `PENDING_TB_DEVICE`；
3. reconcile/importDevices 使用停用规则时 `SKIPPED_TB_INVALID` 语义不变；
4. 全新库迁移测试：表存在、种子两行 enabled=true。
- 验证：目标测试全绿；对比既有失败基线不扩大。

## Task 6 · 前端：domain/data 层
1. `features/admin/device_profile_rules/domain/`：`DeviceProfileRule`、`TbProfile` 模型 + repository 抽象；
2. `data/`：API 实现（平台级 `apiGet/apiPost/apiPut/apiDelete`，**不用 farmGet 系列**；fromJson 容错）；controller `AsyncNotifier`（列表加载/刷新/增删改后失效重载，非 farm-scoped、无 watchActiveFarmId）。
- 验证：analyze 零新增；controller 单测（失效重载、TB 不可达错误透出）。保真验证：无 UI。

## Task 7 · 前端：列表页 + 路由入口（保真重点 ①）
1. `AppRoute.platformDeviceProfiles('/admin/device-profile-rules', ...)` + `main_shell.dart` 侧栏挂载（与瓦片管理同组，显隐条件同瓦片入口）；
2. 列表页：hint-bar、工具栏（统计行 + 从 TB 刷新 ghost 按钮 + 新增规则主按钮）、表格卡（表头/行/来源角标/类型徽标/启停开关/操作列），按 spec §6.2；
3. 开关点击即 PUT：成功轻提示、失败回滚；停用行置灰 + 灰徽标；
4. 空态：复用 admin 现有空态样式，文案"暂无规则，点击新增规则创建"。
- **保真验证**：web 构建 dev 页面截图 vs 原型屏 A 逐项核对（hint 配色、徽标三色、开关尺寸 34×20、角标两态、停用行置灰）。

## Task 8 · 前端：新增/编辑 + 删除确认弹窗（保真重点 ②③）
1. 新增/编辑 Dialog（宽 430）：TB 下拉（打开拉 /tb-profiles + 刷新按钮 + 失败顶部提示可手动输入 + 已添加置灰）、「手动输入」切换、编辑态配置名只读；类型三分段；启用开关行；备注 textarea；重名本地比对 + 后端 409 行内提示；
2. 删除确认 Dialog（宽 400）：danger 圆图标 + 目标名加粗 + 警示盒（warningSoft/warning）；确认后 DELETE + 刷新；
3. 全部文案走 l10n。
- **保真验证**：弹窗截图 vs 原型屏 B（下拉展开、占用置灰、分段选中态）/ 屏 C（警示盒配色、按钮排布）。

## Task 9 · l10n + 静态检查 + widget 测试
1. arb 新增 key（zh 模板 + en 同步，spec §7 表，占位符类型一致）+ `flutter gen-l10n`；
2. `flutter analyze` 零新增；
3. widget 测试：列表徽标/停用行断言、新增弹窗重名拦截、编辑态只读、删除确认流；既有 admin 测试回归。
- 保真验证：文案与原型逐字对照（中英双语）。

## Task 10 · 部署 dev + 冒烟
1. `./gradlew compileJava` + TestJava → `build_web.sh` → `deploy.sh dev`（前后端两步，经验 #7）；
2. 冒烟清单：种子两条在列表且开关可切；新建规则（TB 下拉选 + 手动输入各一）→ preflight 认可；停用 → 对应设备开通显示"等待 TB 设备"；删除 → 同上；TB 停服模拟 → 下拉报错可手输兜底；OWNER 账号访问 403/入口不可见；审计日志三条动作落库；
3. i18n 双语切换抽查。
- 验收对照：spec §9 边界逐条 + 原型三屏。

## Task 11 · 收尾
1. 文档同步：`docs/api-contracts/admin-api.md` + `changelog.md`；Linear 工单流转（编码完成评论 + 状态）；
2. 用户 dev 集成测试 → 通过后 git 提交（feature 分支 → PR → merge）+ 知识库沉淀（结论/踩坑）；
3. test 环境部署等用户通知。

---

## 附录 A · 规格卡（Task 0 产物速查）
- hint-bar：infoSoft 底 + info 边框、圆角 8、padding 8/12、11px infoStrong
- 主按钮：primary 底白字 12px w600 圆角 8 padding 8/14；ghost：白底 primary 字 primary 边框；danger 按钮：danger 底白字
- 表格：表头 surfaceMuted 11px textSecondary w600 padding 10/12；行 12px padding 11/12；分割线 surfaceMuted
- 配置名：12px w600 maxWidth 250 省略；来源角标 9px 胶囊（TB=infoSoft/infoStrong、手动=surfaceMuted/textSecondary）
- 类型徽标：10px w700 胶囊 + 6px 圆点（耳标=successSoft/successStrong、追踪器=infoSoft/infoStrong、胶囊=#F9E6EF/#C25689=estrus、停用=灰）
- 开关：34×20 胶囊，on=success、off=#C9C4B8，钮 16px 白
- 弹窗：新增/编辑宽 430 圆角 16；删除宽 400；标题 15px w700；label 12px w600 + 必填 danger 星号；select 38px 高圆角 8；分段选中=primarySoft/primary
- 警示盒：warningSoft 底 + warning 边框、11px warningStrong 圆角 8 padding 8/12
- 统计行/时间列/说明 help：12px / 11px textSecondary
