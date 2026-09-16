# 设备配置（TB Profile）规则管理 · 设计规格（spec）

> 状态：待确认（阶段 2，2026-09-16）
> 工单：NIX-214
> 原型：`docs/prototypes/nix-214-device-profile-rules-prototype.html`（2026-09-16 用户已确认）
> 本 spec 批准后令牌与口径表锁定，实施阶段不再变更视觉与口径。
> 背景：开通向导 preflight 的 TB profile 白名单硬编码在 `TbDeviceProvisioningService`（常量 `CAPSULE_PROFILE`/`TRACKER_PROFILE`），新增接入链路需改码发版。本功能将白名单改为平台管理者可 CRUD 的配置表。

---

## 1. Design Tokens（零新增，全部复用现有）

| Token | 值 | Flutter 对应 |
|---|---|---|
| --primary / --primary-dark / --primary-soft | #2F6B3B / #244F2D / #E3F0E4 | AppColors.primary / primaryDark / primarySoft |
| --surface / --surface-alt / --surface-muted | #F8F6F0 / #FFFFFF / #F2F0EA | AppColors.surface / surfaceAlt / surfaceMuted |
| --border | #D7D2C6 | AppColors.border |
| --text-primary / --text-secondary | #263126 / #617061 | AppColors.textPrimary / textSecondary |
| --success / --success-soft | #4C9A5F / #E4F3E8 | AppColors.success / successSoft |
| --warning / --warning-soft | #D28A2D / #FFF2DE | AppColors.warning / warningSoft |
| --danger / --danger-soft | #C2564B / #FBE8E6 | AppColors.danger / dangerSoft |
| --info / --info-soft | #4A7F9D / #E7F1F6 | AppColors.info / infoSoft |
| --capsule（类型徽标用） | #C25689（soft #F9E6EF） | AppColors.estrus（同名值复用，不新增 AppColors 项） |
| --xs..--xxl | 4/8/12/16/24/32 | AppSpacing.xs..xxl |
| --radius-sm/md/lg | 8/12/16 | BorderRadius 8/12/16 |
| --shadow-card / --shadow-modal | 0 1px 3px rgba(38,49,38,.06) / 0 12px 40px rgba(38,49,38,.22) | 现有卡片阴影 / Dialog 阴影 |

---

## 2. 口径定义表（锁定）

| 概念 | 口径 |
|---|---|
| 规则生效 | `enabled = true` 的行参与 preflight / provision / import / reconcile 校验；`enabled = false` 仅保留记录、跳过校验（表现为"等待 TB 设备"） |
| 配置名唯一 | `profile_name` 全表唯一（含停用行）；重名 = DUPLICATE 错误 |
| 配置名不可变 | 编辑仅允许改 deviceType / enabled / remark；改名 = 删除重建（前端锁死输入） |
| TB 来源角标 | 前端对比 `GET /tb-profiles` 结果：配置名存在于 TB → 标「TB」；不存在或 TB 不可达 → 标「手动」 |
| 删除 | 物理删除，无业务引用表；删除后立即失去校验资格 |
| 设备类型 | 复用 `DeviceType` 枚举（EAR_TAG/TRACKER/CAPSULE），列存枚举名，不加 DB CHECK（未来加类型免迁移约束），应用层校验 |

---

## 3. 数据模型

### 3.1 Flyway 迁移 `V20260916100000__create_device_profile_rules.sql`

```sql
CREATE TABLE device_profile_rules (
    id           BIGSERIAL PRIMARY KEY,
    profile_name VARCHAR(128) NOT NULL UNIQUE,
    device_type  VARCHAR(32)  NOT NULL,
    enabled      BOOLEAN      NOT NULL DEFAULT TRUE,
    remark       VARCHAR(255),
    created_by   BIGINT,
    updated_by   BIGINT,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

INSERT INTO device_profile_rules (profile_name, device_type, enabled, remark) VALUES
('瘤胃胶囊-OC-配置-v2',  'CAPSULE', TRUE, '现行 OC 链路（自硬编码白名单迁移）'),
('牛羊追踪器-OC-配置-v2', 'TRACKER', TRUE, '现行 OC 链路（自硬编码白名单迁移）');
```

- 平台级表，无 tenant_id（与 TB 单租户部署、瓦片区域表同级）。
- 种子保证上线后 preflight 行为与现状完全一致（行为不变迁移）。

---

## 4. 端点契约

前缀 `/api/v1/admin/device-profile-rules`，类级 `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")`（与 `TileAdminController` 一致）。非 farm-scoped，不走 farmGet/farmPost。

| 端点 | 说明 |
|---|---|
| `GET /` | 全量列表（含停用），按 profile_name 升序。→ `[{id, profileName, deviceType, enabled, remark, updatedAt}]` |
| `POST /` | body `{profileName, deviceType, enabled, remark}`。重名 → 409 `iot.profileRule.duplicate`；类型非法 → `iot.profileRule.invalidDeviceType` |
| `PUT /{id}` | body `{deviceType, enabled, remark}`（profileName 忽略）。不存在 → `iot.profileRule.notFound` |
| `DELETE /{id}` | 不存在 → `iot.profileRule.notFound` |
| `GET /tb-profiles` | 透传 `TbClient.fetchDeviceProfiles()` → `[{id, name}]`。TB 不可达 → `iot.tb.profilesUnavailable`（前端引导手动输入兜底） |

- 所有写操作记 AuditLog：`DEVICE_PROFILE_RULE_CREATED / _UPDATED / _DELETED`（复用 `recordAudit` 模式，detail 含 id、profileName、变更字段）。
- 响应封套沿用 `ApiResponse`；`GET /tb-profiles` 为字面路径，优先于 `/{id}` 匹配（Spring 字面优先，无冲突）。
- 实施完成后同步 `docs/api-contracts/admin-api.md` + `changelog.md`。

---

## 5. 服务改造（TbDeviceProvisioningService）

1. 删除常量 `CAPSULE_PROFILE` / `TRACKER_PROFILE` 与静态方法 `deviceTypeForProfile`。
2. 新增 `DeviceProfileRuleService`（iot.application）：
   - CRUD 方法（校验唯一、枚举、审计）；
   - `Map<String, DeviceType> resolveActiveTypeMap()` —— 一次查询 enabled 行，返回 profile_name → DeviceType。
3. `TbDeviceProvisioningService` 四个调用路径全部改为注入规则映射（**每事务加载一次，禁止循环内逐行查库**）：
   - `reconcile()`：方法头加载一次，传入 `tbInventory(eui, profiles, ruleMap)`；
   - `importDevices()`：方法头加载一次，传入 `importDevice(..., ruleMap)`；
   - `preflight()` / `provision()`：各在方法头加载一次。
4. `tbInventory` 内 `deviceTypeForProfile(profileName)` → `ruleMap.getOrDefault(profileName, null)`，`profileValid = type != null` 语义不变。
5. preflight 状态机与文案不变：规则缺失/停用 ⇒ `PENDING_TB_DEVICE`（"等待 TB 设备"），无需新状态。

---

## 6. 前端规格（features/admin/device_profile_rules/）

### 6.1 路由与入口
- `AppRoute.platformDeviceProfiles('/admin/device-profile-rules', 'platform-device-profiles', '设备配置')`；
- `main_shell.dart` 平台管理侧栏组挂载（与瓦片管理同组相邻，图标 📡 类，带 NEW 角标首发一版），显隐条件与瓦片管理入口完全一致（PLATFORM_ADMIN / B2B_ADMIN 可见）。

### 6.2 页面结构（对照原型屏 A）
- **hint-bar**：infoSoft 底 + info 边框、圆角 8、padding 8/12、11px infoStrong，说明"此列表决定开通向导认可哪些配置"；
- **工具栏**：左统计行 12px textSecondary（`共 N 条规则 · 启用 X · 停用 Y`）；右「从 TB 刷新」（ghost：白底 primary 字 primary 边框）+「新增规则」（primary 底白字，圆角 8，padding 8/14）；
- **表格卡**：surface-alt 底、圆角 12、border、shadow-card；表头 surfaceMuted 11px textSecondary w600；行 12px、padding 11/12、行分割 surfaceMuted、hover surface；
- **配置名列**：12px w600，超长省略（maxWidth 250）；来源角标「TB」=infoSoft/infoStrong、「手动」=surfaceMuted/textSecondary，9px 胶囊；
- **类型徽标**：10px w700 胶囊 + 6px 圆点：耳标=successSoft/successStrong、追踪器=infoSoft/infoStrong、胶囊=estrus 底色系（#C25689/#F9E6EF）、停用行显示灰「已停用」徽标且整行文字 textSecondary；
- **启停开关**：34×20 胶囊，on=success、off=#C9C4B8，白圆钮 16；点击即调 PUT，成功轻提示（SnackBar），失败回滚并报错；
- **操作列**：编辑（info 色）/删除（danger 色）文字按钮 12px w600。

### 6.3 新增/编辑弹窗（对照原型屏 B）
- Dialog 宽 430、圆角 16、shadow-modal；标题 15px w700 + 右上关闭；
- **TB 设备配置\***：下拉（打开时 GET /tb-profiles，失败顶部提示"TB 暂不可达，可手动输入"）+ 刷新按钮（38×38 ghost）；下拉项 11px，右侧副文案显示 TB 侧信息，已有规则的项置灰标「已添加」；「或 手动输入配置名 →」切换为 TextField（128 上限）；**编辑态此字段只读**；
- **设备类型\***：三分段（耳标/牛羊追踪器/瘤胃胶囊），选中 primarySoft 底 primary 字，附小图标与枚举说明 help 行；
- **启用开关行**：开关 + "启用" 12px w600 + help 说明（停用的效果）；
- **备注**：TextArea 2 行，255 上限，placeholder "选填，如：旧链路配置，仅兼容存量设备"；
- 底部右对齐「取消」（neutral）+「保存」（primary）；重名校验：提交前本地比对 + 后端 409 兜底，行内错误提示。

### 6.4 删除确认（对照原型屏 C）
- Dialog 宽 400；44px dangerSoft 圆形 🗑 图标 + 标题「删除设备配置规则」；
- 正文含目标配置名（w700）+ 警示盒（warningSoft 底、warning 边框、11px warningStrong）：影响说明（开通校验将显示"等待 TB 设备"、不影响 TB 平台设备与遥测）；
- 「取消」+「删除」（danger 底白字）；删除成功后列表刷新。

### 6.5 状态管理
- 列表 `AsyncNotifier`（provider 置于本 feature，非 farm-scoped、不继承 FarmScoped*，无 activeFarmId 依赖——平台级数据切牧场不刷新语义）；
- 弹窗表单为局部 StatefulWidget 状态；TB 下拉数据按需拉取不缓存（每次打开重拉，带 loading）；
- 参照 tile_admin 现有页面组织（data/domain/presentation 三层）。

---

## 7. i18n（key 前缀 `deviceProfileRule`）

| Key | zh | en |
|---|---|---|
| title | 设备配置管理 | Device Profile Rules |
| hint | 此列表决定设备开通向导认可哪些 TB 设备配置；不在列表（或已停用）的设备开通时将显示"等待 TB 设备"。新增接入链路在此添加映射，无需发版。 | ... |
| statLine | 共 {total} 条规则 · 启用 {enabled} · 停用 {disabled} | ... |
| refreshFromTb / addRule / edit / delete | 从 TB 刷新 / 新增规则 / 编辑 / 删除 | ... |
| fieldName / fieldDeviceType / fieldEnabled / fieldRemark | TB 设备配置 / 设备类型 / 启用 / 备注 | ... |
| sourceTb / sourceManual / badgeDisabled / tagTaken | TB / 手动 / 已停用 / 已添加 | ... |
| typeEarTag / typeTracker / typeCapsule | 耳标 / 牛羊追踪器 / 瘤胃胶囊 | ... |
| deleteTitle / deleteBody / deleteWarn | 删除设备配置规则 / 确认删除「{name}」？/ 警示文案（含 {devices} 示例） | ... |
| tbUnavailable / duplicateName / saved / deleted | TB 暂不可达，可手动输入 / 配置名已存在 / 已保存 / 已删除 | ... |

后端 MessageSource 同步新增 5 个错误码双语（duplicate / notFound / invalidDeviceType / profilesUnavailable / 必填校验）。ARB 中英同步，`flutter gen-l10n` 零缺失。

---

## 8. 测试策略

| 层 | 用例 |
|---|---|
| 后端集成测试（Testcontainers 真库，经验 #19） | CRUD 全路径；重名 409；PUT 忽略 profileName；TB 透传失败错误码；**preflight 联动**（种子两条 → TRACKER 设备 status 正常；停用/删除后 → PENDING_TB_DEVICE；恢复后回到原状态）；reconcile/importDevices 使用停用规则时 `SKIPPED_TB_INVALID` 语义不变 |
| 迁移 | 全新库 Flyway 全量跑通（经验 #20）；种子两行存在且 enabled |
| 前端 widget 测试 | 列表渲染（徽标/开关/停用行置灰）；新增弹窗重名拦截；编辑态配置名只读；删除确认流 |
| 回归 | 既有 TbDeviceProvisioning 相关测试全绿（白名单行为由种子保证不变） |

---

## 9. 边界与风险

| 风险 | 处置 |
|---|---|
| 规则被删光 → 所有设备卡"等待 TB 设备" | 属管理者自由裁量；hint-bar 已说明；不设"至少保留一条"硬限制 |
| TB 不可达 | 下拉端点返回明确错误码，前端转手动输入兜底；已保存规则不受影响（校验只依赖本地表） |
| TB 侧改名配置 | 本地表不感知（仍按旧名匹配）；「从 TB 刷新」后该项来源角标变「手动」，提示管理者人工核对 |
| 未来新增设备类型 | device_type 列无 CHECK，加枚举 + 前端选项扩展即可，无需迁移 |
| reconcile 大列表性能 | 规则映射每事务加载一次（行级零额外查询）；TB profiles 仍为每次调用拉全量（现状不变） |

---

## 10. 交付范围

后端：迁移 + 实体/仓库/服务/控制器 + AuditLog + MessageSource + 集成测试；前端：路由/入口 + 列表页 + 两弹窗 + i18n + widget 测试；文档：admin-api.md / changelog 同步。**不含**：遥测 key 约定管理（保持平台固定协议 result/dataHex）、NS 建档管理。
