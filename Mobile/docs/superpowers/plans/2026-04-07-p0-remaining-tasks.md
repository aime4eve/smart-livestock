# P0 剩余待办事项（挂起）

> **状态**: 挂起，待后续启动
> **核实日期**: 2026-04-07

## 已完成（无需再跟踪）

| 事项 | 完成情况 |
|------|---------|
| GoRouter 路由改造 | ✅ `go_router ^17.1.0`，ShellRoute + 命名路由 + 路径参数 + 认证守卫 |
| 状态管理 Riverpod 改造 | ✅ `flutter_riverpod ^3.3.1`，10 个模块均用 Notifier + Repository 模式 |
| 真地图替换 | ✅ `flutter_map ^8.2.2` + OSM 瓦片，支持围栏/轨迹/标记，保留列表回退 |

## 待办事项

### 1. 鉴权与菜单单一事实来源

**当前状态**: ⚠️ 未完成
- `RolePermission` 仍硬编码 `DemoRole` 枚举判断
- `AppSession` 仅存 `DemoRole?`，无 token、permissions map、tenant_id
- `ApiCache` 不请求 `/api/me`，`main.dart` 硬编码 `init('owner')`
- live 模式的 profile 数据仅用于展示，未反馈到权限系统

**目标**:
- 权限以登录后 `/api/me`（或等价）返回的 `role` / `permissions` 为准
- `AppSession` 扩展为包含 token、tenant_id、permissions
- 前端 `RolePermission` 改为读取 session 中的权限数据

### 2. DemoShell 职责拆分

**当前状态**: ⚠️ 部分完成
- 登录已独立为 `LoginPage` + 路由守卫 ✅
- ops 角色无独立 Shell，共用裸 `Scaffold`
- 无租户上下文，session 中无 tenant 信息
- shell 与导航逻辑仍合并在单一 `DemoShell` widget 中

**目标**:
- ops 与牧场业务两套壳独立 Scaffold / 路由分支
- 租户上下文纳入 session 管理
- shell 职责拆分：登录态、租户上下文、底部导航、子路由出口分层

### 3. FastAPI 后端替换 Mock Server

**当前状态**: ❌ 未开始
- 仍为 Node.js Express 5 Mock Server（`backend/`，端口 3001）
- 无任何 Python 文件
- 无 `infra/` 目录，无基础设施配置

**目标**:
- FastAPI + Python 替换 Mock Server
- PostgreSQL + 时序数据接口抽象
- MQTT 实时通信（EMQX/Mosquitto）
- 遵循分层：models / schemas / api/routes / services
- 云端部署：所有业务表包含 `tenant_id`
