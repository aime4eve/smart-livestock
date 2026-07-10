# P0 剩余待办事项（挂起）

> **状态**: 挂起，待后续启动
> **核实日期**: 2026-04-07
> **复审日期**: 2026-05-01 — 三项均继续挂起，详见各小节更新

## 已完成（无需再跟踪）

| 事项 | 完成情况 |
|------|---------|
| GoRouter 路由改造 | ✅ `go_router ^17.1.0`，ShellRoute + 命名路由 + 路径参数 + 认证守卫 |
| 状态管理 Riverpod 改造 | ✅ `flutter_riverpod ^3.3.1`，10 个模块均用 Notifier + Repository 模式 |
| 真地图替换 | ✅ `flutter_map ^8.2.2` + OSM 瓦片，支持围栏/轨迹/标记，保留列表回退 |

## 待办事项

### 1. 鉴权与菜单单一事实来源

**当前状态**: ⚠️ 继续挂起
- `RolePermission` 仍硬编码 `DemoRole` 枚举判断（`role_permission.dart`，48 行，6 种角色）
- `AppSession` 已有 `accessToken`/`refreshToken`/`expiresAt`/`activeFarmTenantId` 字段，但无 `permissions` 数组
- `SessionController.loginWithToken()` 仍通过 mock-token 前缀硬编码映射角色

**2026-05-01 复审结论**: 继续挂起。此改造与 API 版本认证迁移 spec（`2026-04-26-api-version-auth-migration-design.md`）绑定 —— 需等真实后端上线、JWT claims 中包含 permissions 时才有实际价值。当前 mock 模式 6 种角色硬编码完全够用。

**目标**（不变）:
- 权限以登录后 `/api/me` 返回的 `role` / `permissions` 为准
- `AppSession` 扩展 permissions 字段
- 前端 `RolePermission` 改为读取 session 中的权限数据

### 2. DemoShell 职责拆分

**当前状态**: ⚠️ 降级为低优先级重构（实际已接近完成）
- 登录已独立为 `LoginPage` + 路由守卫 ✅
- `DemoShell.build()` 已实现三条分支：`platformAdmin → 裸 Scaffold`、`b2bAdmin → _B2bAdminShell`、`owner/worker → 牧场业务壳（底部导航 + FarmSwitcher）` ✅
- `AppSession` 已有 `activeFarmTenantId` 字段 ✅
- FarmSwitcher 提供牧场上下文切换 ✅

**2026-05-01 复审结论**: 壳拆分功能上已完成，当前 `DemoShell` 一个 Widget 管三条分支（约 200 行）。可拆成 `BusinessShell` / `PlatformAdminShell` / `B2bAdminShell` 三个独立文件以改善代码组织，但非功能缺口，降级为低优先级重构。

**目标**（降级后）:
- 将 `DemoShell` 拆分为三个独立 Shell Widget 文件（纯代码组织改进）

### 3. FastAPI 后端替换 Mock Server

**当前状态**: ❌ 继续挂起
- 仍为 Node.js Express 5 Mock Server（`backend/`，端口 3001）
- 无任何 Python 文件

**2026-05-01 复审结论**: 继续挂起。Mock Server 已支撑完整 Demo 开发（含 Phase 2a B2B 管理后台），代码整洁、与 Flutter 端对齐良好。需要战略决策：保持 Mock Server / 升级 Node.js + SQLite / FastAPI 全量重写（三种方案，工作量 0 ~ 8 周不等）。待决策后再启动。

**目标**（不变）:
- 真实后端（技术栈待定）
- PostgreSQL + 时序数据接口抽象
- MQTT 实时通信（EMQX/Mosquitto）
- 遵循分层架构
- 云端部署：所有业务表包含 `tenant_id`
