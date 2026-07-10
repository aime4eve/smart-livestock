# Phase 2a 实施计划与设计规格符合性评审

**评审日期：** 2026-04-29
**评审人：** AI 代理（Claude Opus 4.7）
**实施计划：** `docs/superpowers/plans/2026-04-29-unified-business-model-phase2a.md`
**对照规格：** `docs/superpowers/specs/2026-04-29-unified-business-model-phase2a-design.md` (v1.3)
**评审方法：** 双文件逐节对照 + 交叉核验当前代码（`backend/data/seed.js`、`backend/data/tenantStore.js`、`backend/middleware/*`、`mobile_app/lib/core/models/demo_models.dart`、`mobile_app/lib/features/{alerts,fence,dashboard,subscription}/`、`mobile_app/lib/core/api/api_cache.dart` 等）

---

## 一、评审结论摘要

> 计划整体覆盖了规格定义的 **E1（技术债清理）、E2（多 farm 支持）、E3（B 端管理后台）** 三个 Epic 的主体范围，任务划分合理、依赖顺序正确（E1 先于 E2/E3）、TDD 节奏（先写测试再实现）符合项目规范。**但存在 3 个 P0 编译/运行时错误、5 个 P1 与规格语义偏差、若干 P2 文档与一致性瑕疵**，建议在执行前修订计划。

| 维度 | 评价 |
|------|------|
| 范围覆盖 | ★★★★☆（覆盖 E1–E3 主体；遗漏 `mock_stats_repository`、动态 owner 创建逻辑） |
| 与规格语义一致 | ★★★☆☆（URL 结构、createTenant 返回值、动态 owner 用户登录路径偏离） |
| 代码可执行性 | ★★☆☆☆（`DashboardMetric.id`、`tenantStore.createTenant` 等关键 API 不匹配现状） |
| 测试覆盖 | ★★★★☆（store 单元测试齐全；workers CRUD HTTP 集成测试缺失） |
| 文档完整性 | ★★★★☆（任务边界清晰；个别步骤编号重复、未实现细节留白） |

**总体评价：** 建议状态 **「需修订后再执行」**——P0 问题会导致 build/test 直接失败，P1 偏差会破坏规格契约。

---

## 二、问题汇总（按优先级）

### P0 — 阻塞执行（必修）

#### P0-1. `DashboardController` 中引用了不存在的 `DashboardMetric.id` 字段

**位置：** Task 4 Step 6（dashboard 接通 shaping）

**问题：** 计划代码：

```dart
final itemMaps = data.metrics.map((m) => <String, dynamic>{
  'id': m.id,
}).toList();
```

但 `lib/core/models/demo_models.dart` 中 `DashboardMetric` 实际只有 `widgetKey / title / value` 三个字段，**没有 `id` 字段**。直接 `flutter analyze` 会报 `The getter 'id' isn't defined`，编译失败。

**建议修复：** 改为 `'id': m.widgetKey`，或为 shaping 引入更通用的 key（如直接传 `index`）。同时建议在计划该步增加 "字段对齐检查" 子步骤。

---

#### P0-2. `tenantStore.createTenant` 返回值结构与计划假设不符

**位置：** Task 14 Step 3（`backend/routes/b2bDashboard.js` 的 `POST /b2b/farms`）

**问题：** 计划代码：

```javascript
const newFarm = tenantStore.createTenant({...});
if (!newFarm) {
  return res.fail(500, 'INTERNAL_ERROR', '创建牧场失败');
}
res.ok(newFarm);
```

但 `backend/data/tenantStore.js` 当前 `createTenant` 的实际签名是：

```javascript
function createTenant(body) {
  // ...
  if (!name) return { error: 'name_required' };
  if (nameExists(name)) return { error: 'name_conflict' };
  // ...
  return { tenant };  // 成功返回 { tenant }，失败返回 { error }
}
```

按计划写法：
- 错误情况下 `newFarm = { error: 'name_conflict' }`，`!newFarm` 为 `false`，**错误被静默吞没**，仍返回 `res.ok({ error: 'name_conflict' })`
- 成功情况下 `res.ok({ tenant: {...} })`，前端按 `data.id` 取不到 ID（被多包了一层 `tenant`）

**建议修复：**

```javascript
const result = tenantStore.createTenant({...});
if (result.error) {
  if (result.error === 'name_conflict') return res.fail(409, 'CONFLICT', '牧场名称已存在');
  return res.fail(400, 'VALIDATION_ERROR', result.error);
}
res.ok(result.tenant);
```

---

#### P0-3. b2b_admin 创建子 farm 时未实际创建 owner 用户与 mock token 映射

**位置：** Task 14 Step 3 + Task 13 Step 5

**规格 Section 3.3 明确要求：**
> 若指定 `ownerName`，自动创建 owner 用户并关联：
> - `userId`: `u_${Date.now()}`
> - **`tenantId`: 新创建的 farm ID**
> - **`role: 'owner'`**
> - **`permissions`: 同现有 owner 模板**
> - **`mobile`: 取 `contactPhone` 字段值**
> - **Mock token 自动注册**：在 `TOKEN_MAP` 中添加 `mock-token-{userId}` → `'owner'` 映射，在 `users` 对象中添加对应条目。

**计划实现仅做了：**

```javascript
ownerId: ownerName ? `u_${Date.now()}` : null,
```

`tenantStore.createTenant` 被调用时 `ownerId` 字段被存入 tenant 记录，但：
1. `backend/data/seed.js` 的 `users` 对象中**没有添加新 user 条目**
2. `backend/middleware/auth.js` 的 `TOKEN_MAP` 中**没有添加 token 映射**
3. 该 owner 用户在 Mock 环境下**完全无法登录**（无对应 token），即使前端实现了 "直接输入 Token" escape hatch（Task 2 Step 11），输入 `mock-token-{userId}` 也无法在 `TOKEN_MAP` 中找到映射

**后果：** Demo 演示路径断裂——B 端管理员创建子 farm 后，规格预期可以用动态生成的 token 登录该 owner，但实际无法登录。

**建议修复：** 在 Task 14 Step 3 的路由实现中补全：

```javascript
const userId = `u_${Date.now()}`;
const token = `mock-token-${userId}`;
users[userId] = {
  userId,
  tenantId: result.tenant.id,
  name: ownerName,
  role: 'owner',
  mobile: contactPhone ?? '',
  permissions: [...users.owner.permissions],
};
const { TOKEN_MAP } = require('../middleware/auth');
TOKEN_MAP[token] = 'owner';
res.ok({ ...result.tenant, ownerToken: token });  // 把 token 返给前端用于显示
```

> 注意 `TOKEN_MAP` 在 `auth.js` 中是模块级常量，需要确认是否可在运行时修改（如不可修改，需重构为可变 Map 或函数）。

---

### P1 — 与规格语义偏差（强烈建议修复）

#### P1-1. `mock_stats_repository` 接通 shaping 缺失

**规格 Section 1.2 明确列出 4 个目标 repository：**

| Repository | Feature Key |
|------------|-------------|
| `mock_alert_repository.dart` | `alert_history` |
| `mock_fence_repository.dart` | `fence` |
| `mock_dashboard_repository.dart` | `dashboard_summary` |
| **`mock_stats_repository.dart`** | **`stats`** |

**计划仅实现 3 个**（Task 4 Step 4–6 覆盖 alerts/fence/dashboard），未提及 stats 模块。`mobile_app/lib/features/stats/data/mock_stats_repository.dart` 确实存在，应一并接入。

**建议：** 在 Task 4 中追加 Step "修改 StatsController 接入 shaping"。

---

#### P1-2. workers CRUD 端点 URL 路径与规格不一致

**规格 Section 2.2 定义：**

| 端点 | 方法 |
|------|------|
| `/api/v1/farms/:farmId/workers` | GET / POST |
| `/api/v1/farms/:farmId/workers/:id` | DELETE |

**计划实际挂载（Task 7 Step 5 + Task 8 Step 1）：**

```javascript
app.use(`${prefix}/farm`, farmRoutes);
// 内部 router:
router.get('/farms/:farmId/workers', ...)
router.post('/farms/:farmId/workers', ...)
router.delete('/farms/:farmId/workers/:id', ...)
```

实际生成的 URL 是 **`/api/v1/farm/farms/:farmId/workers`**（多了 `/farm/` 前缀），与规格定义的 `/api/v1/farms/...` 不一致。Task 8 Step 2 的 `ROUTE_DEFINITIONS` 也使用了 `'/farm/farms/:farmId/workers'`，自我一致但偏离规格。

**建议修复二选一：**

A) 拆分路由文件：保持 `farmRoutes` 仅挂在 `/farm` 下处理 `/my-farms`、`/switch-farm`，新建 `workerRoutes.js` 挂在 `/farms` 下处理 worker CRUD。

B) 修订规格：将端点路径标准化为 `/api/v1/farm/farms/:farmId/workers` 并更新 spec。

推荐方案 A（保持规格契约稳定）。

---

#### P1-3. workers CRUD HTTP 端点缺集成测试

**位置：** Task 8

Task 6 创建了 `workerFarmStore.test.js`（store 单元测试），Task 7 创建了 `farm-switch.test.js`（覆盖 my-farms / switch-farm）。**但 Task 8 新增的 3 个 workers CRUD HTTP 端点无任何 HTTP 层集成测试**：

- `GET /farms/:farmId/workers`（owner 仅能查自己 farm 的权限分支）
- `POST /farms/:farmId/workers`（409 重复分配分支）
- `DELETE /farms/:farmId/workers/:id`（404 不存在分支）

**建议：** 在 Task 8 后追加 Step "为 workers CRUD 编写集成测试"，覆盖：
- 200 正常路径
- 403 owner 越权访问其他 farm
- 409 重复分配
- 404 删除不存在的分配

---

#### P1-4. `AlertsController` 类型描述错误，可能误导执行者

**位置：** Task 4 Step 4

**计划描述：**
> 注意 `AlertsController` 是 `FamilyNotifier<AlertsViewData, DemoRole>`（通过 `NotifierProvider.family` 定义），`build()` 通过 `arg` 参数获取角色

**实际代码（`alerts_controller.dart`）：**

```dart
class AlertsController extends Notifier<AlertsViewData> {
  AlertsController(this.role);
  final DemoRole role;
  // ...
}

final alertsControllerProvider =
    NotifierProvider.family<AlertsController, AlertsViewData, DemoRole>(
      AlertsController.new,
    );
```

`AlertsController` 实际上是 **`Notifier<AlertsViewData>`**（非 `FamilyNotifier`），role 通过构造函数传入并存为 `final` 字段。**不存在 `arg` 参数**，应使用 `this.role` 字段。

虽然计划提供的 shaping 代码恰好用了 `data.role`（来自 `state.role`），实际可运行，但说明文字会误导执行者去找不存在的 `arg` API。

**建议：** 修正为 "AlertsController 是 Notifier<AlertsViewData>，role 通过构造函数注入并保存为字段，可在 build() 中通过 `role` 字段直接访问"。

---

#### P1-5. 动态 owner 用户登录路径未闭环

**位置：** Task 2 Step 11 + Task 14 Step 3

计划提到为支持 b2b_admin 动态创建的 owner 用户登录，登录页增加 "直接输入 Token" 输入框，调用 `loginWithToken(token)`。但：

1. `SessionController` 当前已有 `loginWithTokens`（复数，要求显式传 role / accessToken / refreshToken / expiresAt），**没有 `loginWithToken(String)` 方法**。计划仅写道 "在 SessionController 中添加 loginWithToken(String token) 方法，解析 token 映射到角色（Mock 环境下的简易实现）"，**未给出实现**。

2. 实际可行的实现需要：
   - 调用 `POST /api/v1/auth/login`（已有端点）通过 token 反查 role？当前后端 auth 路由没有 token 反查接口，只支持按 role 登录。
   - 或在前端硬编码 token → role 的映射（与后端 `TOKEN_MAP` 同步），这种重复维护容易漂移。
   - 或新增后端端点 `GET /api/v1/auth/whoami` 用 token 取角色信息。

**建议：** 在 Task 2 Step 11 中明确给出 `loginWithToken` 的具体实现方案（推荐新增 `whoami` 端点），并在后端 auth 路由中实现配套支持。否则该 escape hatch 形同虚设。

---

### P2 — 文档与一致性瑕疵（建议修复）

#### P2-1. Task 2 中存在两个 "Step 12"

**位置：** Task 2 Step 11 之后

计划同时存在：
- `Step 12: 运行前端测试验证`
- `Step 12: Commit`

应改为 Step 12 / Step 13。同时整个 Task 2 共有 12 个 Step（实际是 13 个），需重新编号。

---

#### P2-2. `seed.js` 中 `u_006_owner` 键名违反现有约定

**位置：** Task 13 Step 5 part 1

```javascript
u_006_owner: {
  userId: 'u_006',
  // ...
}
```

但 `backend/data/seed.js` 现有 `users` 对象按角色名作为 key（`owner`、`worker`、`ops`、`b2b_admin`、`api_consumer`），且 `auth.js` 中使用 `req.user = users[role]` 按 role 字符串查找用户。新增的 `u_006_owner` 这个 key：

1. **永远不会被 `users[role]` 查到**（因为 role 是 `'owner'`，会查 `users.owner` 即 u_001）
2. 该用户没有对应的 mock token 在 `TOKEN_MAP` 中

**建议：** 与 P0-3 的修复一并处理——动态创建用户应该直接 push 到 `users` 对象（key 用 `userId`）并同步注册 `TOKEN_MAP`。但这样的话，按 role 反查就需要变成按 token 反查。涉及 auth 重构。

---

#### P2-3. b2b_admin 移除 `tenant:create` 权限缺少显式说明

**位置：** Task 13 Step 5 part 3

当前 `seed.js` 中 b2b_admin permissions：

```javascript
permissions: ['tenant:view', 'tenant:create', 'farm:view_summary'],
```

计划改后：

```javascript
permissions: ['tenant:view', 'farm:view_summary', 'contract:view', 'farm:create', 'b2b:dashboard']
```

`tenant:create` 被悄悄删除（与规格 Section 3.6 一致：b2b_admin 不应有 `tenant:create`）。但**计划文字仅描述新增 3 项**，未提示删除 `tenant:create`。如果 Phase 1 中存在依赖 `b2b_admin` 持有 `tenant:create` 的代码或测试，会回归失败。

**建议：** 在 Task 13 Step 5 part 3 增加显式说明 "**移除 `tenant:create`**（b2b_admin 仅通过 `farm:create` 创建子 farm，规格 Section 3.6）"，并增加 step "搜索代码库中对 b2b_admin 的 `tenant:create` 检查并清理"。

---

#### P2-4. `FarmSwitcherController._loadFromSeed` 硬编码而非读取 `DemoSeed`

**位置：** Task 9 Step 2

```dart
return const FarmSwitcherState(
  farms: [
    FarmInfo(id: 'tenant_001', name: '华东示范牧场', status: 'active'),
    FarmInfo(id: 'tenant_007', name: '张三的第二牧场', status: 'active'),
  ],
  activeFarmId: 'tenant_001',
);
```

虽然 mock 模式可以接受硬编码，但如果未来 seed 数据变更（如 owner 张三改名、farm 数量增减），需要同步修改前端硬编码。**单一真相源原则**建议从 `DemoSeed` 或同等结构读取。

**建议：** 在 `lib/core/data/demo_seed.dart` 中暴露 farm 列表，`_loadFromSeed` 按 role 过滤。

---

#### P2-5. `WorkerListPage` 硬编码 `tenant_001` 作为 farmId

**位置：** Task 12 Step 2

```dart
ref.read(workerControllerProvider.notifier).loadWorkers('tenant_001');
```

计划自己已注释 "Phase 2a: 使用固定 farmId（后续从 FarmSwitcherController 获取）"。问题是：在 owner 切换到 tenant_007 后，牧工管理页仍然加载 tenant_001 的牧工。

**建议：**
- 立即修复：`ref.read(farmSwitcherControllerProvider).activeFarmId ?? 'tenant_001'`
- 或在计划 Task 12 增加 todo 显式标记 "Phase 2b 修复"

---

#### P2-6. ApiCache 扩展描述抽象化，缺少代码细节

**位置：** Task 9 Step 4 + Task 16 Step 3

两处都写道 "在 `api_cache.dart` 中添加 `myFarms / workers / b2bDashboard / b2bContract` 字段，在 `init()` 中根据角色预加载"，但：

1. 现有 `ApiCache.init` 是统一并发预加载（`Future.wait([...])`），未做角色分支
2. 计划未给出 `init()` 改造的具体代码——是新增一个新方法？还是按角色条件添加新的 `_get` 调用？
3. `FarmSwitcherController._loadFromApiCache` 已经引用 `cache.myFarms`（不存在的字段）

**建议：** 在 Task 9 Step 4 给出完整改造范例：

```dart
// 在 init() 内：
if (role == 'owner' || role == 'worker') {
  results.add(_get('/farm/my-farms', headers));
}
if (role == 'b2b_admin') {
  results.add(_get('/b2b/dashboard', headers));
  results.add(_get('/b2b/contract/current', headers));
}
```

并明确字段命名与赋值映射。

---

#### P2-7. `ROUTE_DEFINITIONS` 文件路径未在 Phase 2a 计划中确认

**位置：** Task 7 Step 5、Task 8 Step 2、Task 14 Step 5

计划多次要求修改 `backend/server.js` 的 `ROUTE_DEFINITIONS` 数组，但未截图/引用现有 `server.js` 的 `ROUTE_DEFINITIONS` 上下文，执行者需要自行定位。建议在第一次提到时附上现有数组示例（≤5 行）以减少导航成本。

---

#### P2-8. E1 计划 `RolePermission` 中遗留 `DemoRole.ops` 引用

**位置：** Task 2 Step 3

`lib/core/permissions/role_permission.dart` 第 27 行：

```dart
return role == DemoRole.owner || role == DemoRole.ops;
```

计划仅说 "全局替换 `DemoRole.ops` → `DemoRole.platformAdmin`"，未明确告知执行者 RolePermission 中具体涉及哪一行。建议在 Step 3 中明确列出行号或引用具体的 `canManageTenants` 方法。

---

## 三、优秀点（值得保留）

1. **TDD 节奏严格**：Task 6 / 7 / 13 / 14 都遵循 "先写测试 → 确认失败 → 实现 → 确认通过" 节奏，符合项目超能力 `test-driven-development` skill。

2. **依赖关系清晰**：E1 → E2/E3 并行的依赖图，任务编号 1–20 严格按顺序，commit 时机合理。

3. **明确标注 Phase 2a 取舍**：`livestockCount: 0 // Phase 2a: mock`、"Phase 2a: 使用固定 farmId" 等 TODO 注释清晰指向 Phase 2b 边界。

4. **设计决策有据**：Task 4 显式说明 "规格建议修改 applyMockShaping 签名为接受 ViewData，但各模块的 XxxViewData 没有公共基类。方案调整为：在 Controller 层应用 shaping" — 这是负责任的方案变更说明，比照搬规格更工程化。

5. **B 端 Shell 不新建 ShellRoute**：Task 15 Step 3 明确指出 "不要创建独立 ShellRoute — 保持 B 端路由在主 ShellRoute 内部以维持 ExpiryPopupHandler 包装"，体现了对 Phase 1 架构的深度理解。

6. **owner 无 farm 边界处理**：Task 10 Step 2 实现了引导页 "请创建您的第一个牧场"，覆盖了规格 Section 2.1 的边界情况。

---

## 四、修订建议（按执行顺序）

| # | 优先级 | 修订动作 | 影响范围 |
|---|--------|----------|----------|
| 1 | P0 | Task 4 Step 6：`m.id` → `m.widgetKey` | 1 处 |
| 2 | P0 | Task 14 Step 3：修正 `createTenant` 返回值解析（`{tenant, error}`） | 1 处 |
| 3 | P0 | Task 14 Step 3：补全动态 owner 用户创建 + TOKEN_MAP 注册 | 路由 + auth |
| 4 | P1 | Task 4 追加：StatsController 接通 shaping | 新增 1 个 Step |
| 5 | P1 | Task 8 重构：拆分 workerRoutes，URL 路径符合规格 `/api/v1/farms/...` | 新增 1 文件 |
| 6 | P1 | Task 8 追加：workers CRUD HTTP 集成测试 | 新增 test 文件 |
| 7 | P1 | Task 4 Step 4：修正 `AlertsController` 类型描述 | 文档措辞 |
| 8 | P1 | Task 2 Step 11：补全 `loginWithToken` 实现方案（推荐新增 `/auth/whoami`） | 后端新增 1 端点 |
| 9 | P2 | Task 2：修复 Step 12 重号 | 文档 |
| 10 | P2 | Task 13 Step 5：显式说明删除 `tenant:create` + 检查回归点 | 文档 + 搜索 |
| 11 | P2 | Task 9 Step 2：FarmSwitcher 从 DemoSeed 读取（避免硬编码） | 1 处 |
| 12 | P2 | Task 12 Step 2：WorkerListPage 从 FarmSwitcher 取 farmId | 1 处 |
| 13 | P2 | Task 9 Step 4 / Task 16 Step 3：补全 ApiCache 改造代码细节 | 文档 |
| 14 | P2 | Task 2 Step 3：明确指出 RolePermission 第 27 行 | 文档 |

---

## 五、放行条件

如所有 P0 + P1 项已修订（或在执行中由执行者提案修复并经 Spec 作者确认），此计划可放行执行。建议执行流程：

1. 计划作者基于本评审更新 plan 文档（重点修复 P0-1/P0-2/P0-3）
2. Spec 作者确认 P1-2（URL 路径）的取舍方向
3. 用 `superpowers:executing-plans` skill 单独 session 执行
4. 每个 Task 完成后跑 `flutter analyze && flutter test` + 后端 `node --test test/*.test.js`
5. 全量 commit 前再做一次 `feature/unified-business-model-phase2a` 分支与 master 的 diff 对照（参照 `2026-04-29-unified-business-model-phase1-branch-vs-plan-review.md` 的方法）

---

**评审结束**
