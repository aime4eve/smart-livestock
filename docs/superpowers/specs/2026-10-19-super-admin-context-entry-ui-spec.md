# 超管选角色进入系统 — UI Spec（视觉规格）

- 日期：2026-10-19
- 状态：**令牌已锁定（2026-10-19 用户确认）**
- 原型：`docs/prototypes/2026-10-19-super-admin-context-picker-prototype.html`（7 屏 + 规格面板，已确认）
- 架构设计：`docs/superpowers/specs/2026-10-19-super-admin-context-entry-design.md`（含 5 项裁决）
- 保真验证：编码阶段用 `prototype-to-flutter-fidelity` skill 对照本文件逐项核对

---

## 1. 设计令牌表

### 1.1 新增令牌（4 对角色识别色，全部为既有色板家族复用，无新造色相）

| Token | CSS 值 | Flutter | 用途 |
|---|---|---|---|
| `--role-platform` | `#4A7F9D` | `Color(0xFF4A7F9D)` | 平台管理员识别色（=info） |
| `--role-platform-soft` | `#E2EDF3` | `Color(0xFFE2EDF3)` | 平台管理员图标底/软底 |
| `--role-b2b` | `#8D6E4F` | `Color(0xFF8D6E4F)` | 租户管理员识别色（=digestive） |
| `--role-b2b-soft` | `#F0E9E0` | `Color(0xFFF0E9E0)` | 租户管理员软底 |
| `--role-owner` | `#2F6B3B` | `Color(0xFF2F6B3B)` | 牧场主识别色（=primary） |
| `--role-owner-soft` | `#E3F0E4` | `Color(0xFFE3F0E4)` | 牧场主软底（=primary-soft） |
| `--role-worker` | `#8BA95A` | `Color(0xFF8BA95A)` | 牧工识别色（=accent） |
| `--role-worker-soft` | `#EFF3E7` | `Color(0xFFEFF3E7)` | 牧工软底 |

> 落点：`core/theme/app_colors.dart` 新增 8 个常量（或 4 对），命名对齐既有风格。

### 1.2 复用令牌（不新增，引用 `core/theme/app_colors.dart` / `app_spacing.dart`）

| Token | 值 | 本功能用途 |
|---|---|---|
| `--color-primary/-dark/-soft` | `#2F6B3B/#244F2D/#E3F0E4` | 选中态边框/对勾/主按钮/头像底 |
| `--color-warning` + `-soft` | `#D28A2D`/`#F7ECDC` | 代登横幅、停用警示、警示主按钮 |
| `--color-info` + `-soft` | `#4A7F9D`/`#E2EDF3` | 审计提示 note-box、"平台级"chip |
| `--color-danger` + `-soft` | `#C2564B`/`#F6E4E2` | "到期"chip、登出链接 |
| `--color-success` + `-soft` | `#4C9A5F`/`#E3F0E4` | "正常"chip |
| `--color-surface/-white/-border`、`--color-text-primary/-secondary` | 既有 | 页面底/卡面/描边/文字 |
| `--space-xs/sm/md/lg` | 4/8/16/24 | 间距 |
| `--radius-lg/md/sm` | 16/12/8 | sheet 顶角/卡片/小件 |
| `--shadow-card/-sheet` | 既有 | 卡片/底部弹层 |

---

## 2. 组件视觉规格

### 2.1 角色选择页（新路由 `/select-context`，原型①）

- 结构：导航栏（无返回，标题"选择进入身份"）→ 登录者卡 → 审计提示 → 4 张角色卡 → 页脚（版本 + 退出登录，danger 色链接）。
- **登录者卡 who-card**：白底 radius-md + shadow-card，padding 12；左 40px 圆形头像（primary 底白字"超"）；名称行 14/700（显示 `Admin@HKT`）+ `role-platform` chip"超级管理员"；副文 11px secondary"登录成功，请选择本次会话的进入身份"。
- **note-box（审计提示）**：info-soft 底 radius-sm，padding 9×10；图标 ⓘ 13px info 色；文案 10.5px info 色："进入后的页面与数据范围，与所选角色的真实用户完全一致；全程记录审计日志。"
- **role-card**：白底 radius-md + shadow-card，padding 12，列表间距 10，透明 2px 边框；
  - 左：40×40 radius-sm 图标方块（角色 soft 底 + 角色色前景，17px 图标）；
  - 中：标题 13/700 + 描述 10.5px secondary（行高 1.45）；
  - 右：scope chip——平台管理员=`info` 样式"平台级 · 免选租户"，其余=对应角色色样式"需选租户"；
  - **选中态**：边框变 2px primary + 最右 20px 对勾圆点（primary 底白勾）。
- 交互：平台管理员卡点击→直接弹确认（无租户步）；其余→进入租户选择页。

### 2.2 租户选择页（原型②）

- 导航栏：返回 ‹ + 标题"选择租户" + 右侧已选角色 chip（角色色）。
- **搜索框**：白底 + border 描边 radius-sm，padding 9×12，🔍 + placeholder 13px"搜索租户名称"。
- **tenant-card**：白底 radius-md + shadow-card，padding 12，**左 4px 状态色条**（默认 border 灰；选中 primary；停用 warning）；
  - 名称行 13.5/700 + 状态 chip；meta 行 10.5px secondary：阶段（试点/批量）· 牧场数 · 时区（如 `Africa/Johannesburg（UTC+2）`）；
  - 右侧 18px radio（选中=primary 外圈 + 9px primary 内点）；
  - **到期态**：opacity .55、无 radio、不可点；
  - **停用态**：meta 行前缀"⚠ 排障可进入"。
- 页底统计行：11px secondary 居中"共 N 个租户（已删除的不显示）"。

### 2.3 确认进入 sheet（原型③a/③b，底部弹层）

- 遮罩 `rgba(38,49,38,.38)`；sheet 白底、顶角 radius-lg、shadow-sheet、padding 8×16×16；顶部 grabber 36×4 radius-2 border 色。
- 标题 15/700"确认进入身份"。
- **身份块**：surface 底 radius-sm padding 12，横排：租户名 14/700 · 角色名 14/700（角色色）＋（停用时）`warn` chip"已停用"。
- 正文 11px secondary："将以「租户 · 角色」身份进入系统，进入后可随时在顶部横幅切换或退出该身份。"
- **note-box 审计**（info，同 2.1 尺寸）："本次会话内的操作将以该身份记录审计日志（含超管代登标记）。"
- **停用警示 warn-box**（warning 色，同尺寸）："该租户已停用：数据可能不是最新状态，仅建议用于售后排障查看。"——仅停用租户出现。
- 按钮行（等宽 gap10）：取消=ghost（白底 border 描边）；进入=primary；**停用态主按钮换 warning 底白字，文案"仍要进入"**。

### 2.4 超管代登横幅 acting-banner（原型④⑤⑥，三 Shell 通用）

- warning-soft 底 + `1px solid rgba(210,138,45,.45)` 边 + radius-sm，padding 8×10；
- 左：🛡 图标 15px warning 色；
- 文案 10.5/600 warning 色：`超管代登 · 以【租户名 · 角色名】身份操作`（平台身份=`以【平台管理员】身份操作`）；牧场端双行（副行 9.5/400："本次会话操作将记录审计日志"），桌面端单行；
- 右侧两个 mini 按钮（10/700、radius 6、padding 5×10）：**切换**=线框（白底 + warning 描边字）、**退出**=实心（warning 底白字）；
- 渲染条件：仅 `impersonated=true` 的上下文会话；根 token 过期时"切换"禁用并提示重新登录。

### 2.5 快速切换 sheet（原型⑦，横幅"切换"弹出）

- 外壳同 2.3；标题 15/700"切换身份"；当前身份行 11px secondary。
- **quick-row**：白底 + border 描边 radius-sm，padding 11×12；左 10px 角色色圆点；标题 12.5/600 + 副文 10px secondary（"平台级 · 无需选租户"/"最近使用"）。
- "选择其他身份…"行：虚线 border 描边、info 色（返回完整选择器）。
- **danger-link**：居中 12/600 danger"退出全部身份并登出"。
- 页脚 11px secondary 居中："免密切换在登录后 60 分钟内可用，超时需重新登录"。

### 2.6 Chip 规格（全场景统一）

10/600、radius 999、padding 3×8：`normal`=success/success-soft；`warn`=warning/warning-soft；`expired`=danger/danger-soft；`info`=info/info-soft；`role-*`=角色色/角色 soft。

---

## 3. 挂载点盘点（对照原型逐项，收口验证 #25）

| # | UI 元素 | 挂载点 | 可达路径 |
|---|---|---|---|
| 1 | 角色选择页 `/select-context` | 新顶层路由 | 超管登录成功（且改密锁优先）自动重定向 |
| 2 | 确认 sheet（正常/停用两形态） | 选择器流程内 | 选角色（平台级）或选租户后 |
| 3 | 代登横幅 | ① `main_shell.dart` 牧场底导 Shell（AppBar 下）② `_B2bAdminShell` 内容区顶 ③ `_PlatformAdminShell` 内容区顶 | impersonated 会话常驻 |
| 4 | 快速切换 sheet | 横幅"切换"按钮 | 横幅 → 切换 |
| 5 | "我的"页切换入口 | `mine_page.dart`（impersonated 时显示"切换身份"，行为同横幅切换） | 我的 → 切换身份 |
| 6 | 登出清理 | 既有登出触发点全部覆盖（含三 Shell 登出 + 我的页登出） | — |

## 4. 状态矩阵

| 状态 | 租户卡 | 确认 sheet |
|---|---|---|
| 正常租户 | 可选（primary 选中态） | 标准确认（primary"进入"） |
| 停用租户 | 可选（warning 色条 + ⚠ 前缀） | 追加 warn-box，warning"仍要进入" |
| 试点到期 | 置灰 .55 不可选 | —（switch 时即 409，前端提示） |
| 已删除 | 不显示 | — |
| 改密锁 | 优先于一切：先改密后选择 | — |
| 根 token 过期 | 横幅"切换"禁用 + 提示重登；"退出"仍可用（退出后重登） | — |

## 5. i18n key 清单（`lib/l10n/app_zh.arb` / `app_en.arb` 同步；服务端 `messages_zh/en.properties` 另行）

页面类：`superPickerTitle / superPickerSubtitle / superPickerAuditNote / superPickerRolePlatformAdmin / superPickerRoleB2bAdmin / superPickerRoleOwner / superPickerRoleWorker / superPickerScopePlatform / superPickerScopeTenantRequired / superPickerLogout / superTenantTitle / superTenantSearchHint / superTenantCount / superTenantDisabledHint / superTenantTrialExpired / superTenantPhaseTrial / superTenantPhaseBatch`；
确认类：`superConfirmTitle / superConfirmBody / superConfirmAuditNote / superConfirmDisabledWarning / superConfirmEnter / superConfirmEnterAnyway / actionCancel`；
横幅类：`superBannerActingAs / superBannerActingAsPlatform / superBannerAuditSubtext / superBannerSwitch / superBannerExit / superBannerSwitchExpired`；
切换类：`superSwitchTitle / superSwitchCurrent / superSwitchNoTenant / superSwitchRecent / superSwitchMore / superSwitchLogoutAll / superSwitchExpiryHint`；
角色显示名复用既有 role 相关 key（缺则补 `rolePlatformAdminDisplay` 等）。

服务端错误 key：`auth.contextSwitchForbidden / auth.roleNotSelectable / auth.tenantNotFound / auth.tenantTrialExpired`（zh/en 双语）。

## 6. 保真验收标准

1. 内建浏览器对照原型逐屏截图存证：登录 → ①角色选择 → ②选租户 → ③a/③b 确认 → OWNER 进入 → ④横幅 → ⑦快速切换；桌面端 ⑤⑥ 横幅。
2. 颜色/字号/圆角/间距按 §1–§2 令牌逐项核对（`prototype-to-flutter-fidelity` skill）。
3. 中英双语走查无缺 key、无硬编码文案。
4. 挂载点按 §3 全量倒查（每个入口角色+点击次数可达）。
