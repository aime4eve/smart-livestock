# 统一商业模型 Phase 2b 实施计划 — R4 评审报告

**评审日期**: 2026-05-02
**评审文档**: `docs/superpowers/plans/2026-05-02-unified-business-model-phase2b.md`
**被实施规格**: `docs/superpowers/specs/2026-05-02-unified-business-model-phase2b-design.md` (v1.2)
**规格评审历史**: R1 (16 问题) → R2 (9 问题) → R3 (6 P2, 通过)
**评审人**: R4
**状态**: **通过（有建议）** — 0 P0 / 2 P1 / 4 P2

---

## 总体评价

规格已经过三轮评审（共 31 个问题，最终 0 P0 / 0 P1 / 6 P2），设计成熟度高。计划结构清晰，依赖关系图正确，Task 拆分粒度合理（每个 Task 3-7 个 Step，可独立验证），测试策略覆盖充分。

本评审聚焦：(1) 计划与当前代码库的落地可行性；(2) R3 遗留 P2 问题在计划中的处理；(3) seed 数据与计算逻辑的一致性。发现 2 个 P1 级问题（分润数据源范围、seed 缺失）和 4 个 P2 级建议。

---

## 新发现问题

### P0 — 阻塞问题

无。

### P1 — 重要问题

### P1-R4-1: E9.2 revenueStore calculate() 数据源范围与规格不一致

**位置**: Task E9.2 Step 3

Task E9.2 Step 3 描述"遍历所有 `billingModel='licensed'` 的 partner tenant"。但规格 4.1 的分润公式是通用的（适用于所有有合同的 partner），不区分 licensed / revenue_share。seed 中 `tenant_p001`（星辰牧业）是 `billingModel: 'revenue_share'`，且有合同 `contract_001`，是分润引擎的主要演示对象。

如果只遍历 `licensed` partner，`tenant_p001` 会被跳过，导致分润引擎在演示时无法产生有效的结算周期。

**建议**: 改为遍历所有有合同（`contractId != null`）的 partner，或同时检查 `'licensed'` 和 `'revenue_share'` 两种 billingModel。

### P1-R4-2: E8.1 seed 缺少 tenant_f_p001_001 的 deviceConfigRatio + livestockCount

**位置**: Task E8.1 Step 1-2

R3 评审 P2-R3-2 已指出：`tenant_f_p001_001`（`tenant_p001` 星辰牧业旗下 farm）缺少 `deviceConfigRatio` 和 `livestockCount` 字段。但计划 E8.1 Step 1 的代码示例只给现有 farm tenant 加了 `null` 占位，没有为 `tenant_f_p001_001` 补充实际值。

`tenant_p001` 是 seed 中唯一的 `revenue_share` partner，其旗下 farm `tenant_f_p001_001` 是分润计算的唯一数据源。缺少这些字段意味着 E4 分润引擎无法计算该 farm 的设备费。

**建议**: 在 E8.1 Step 1 中，为 `tenant_f_p001_001` 添加实际值：
```javascript
deviceConfigRatio: { gpsRatio: 0.8, capsuleRatio: 0.2 },
livestockCount: 150,
```

### P2 — 建议改进

### P2-R4-1: shapingMiddleware apiTier 分叉应提前为 G1 前置

**位置**: Task G1.2 Step 3 "全局中间件适配"

当前 `feature-flag.js` (L10) 逻辑：`if (!farmTenantId) return originalOk(data, message)`。Open API 请求的 `activeFarmTenantId` 为 null（api_consumer 走 else 分支），因此 **shapingMiddleware 会直接跳过所有 Open API 请求**，tier 门控不生效。

计划在 G1.2 Step 3 才处理这个问题，但 G1.1（apiKeyAuth + rateLimit）和 G1.2 Step 1-2（端点实现）都依赖 shaping 正确工作。建议在 E9 完成后、G1 开始前单独处理此修改，或在 G1.1 中一并完成。

**建议**: 将 `feature-flag.js` 的 apiTier 分叉修改提前到 G1.1，作为中间件基础设施的一部分。

### P2-R4-2: contractStore 写操作 const → let 变更不必要

**位置**: Task E9.1 Step 1

当前 `contractStore.js` 使用 `const _contracts = [...]`。Task E9.1 将其改为 `let _contracts`。但 `create()` 方法仅用 `_contracts.push(contract)` 追加元素，不需要重新赋值整个数组。`let` 变量在模块作用域存在被意外重赋值的风险。

**建议**: 保持 `const _contracts`，`push()` 操作在 const 数组上完全合法。同时 `_nextId` 的自增也可用 `let _nextId` 单独声明，不影响数组绑定。

### P2-R4-3: 开发者门户静态托管路径需使用 __dirname

**位置**: Task E5.1 Step 3

R3 评审 P2-R3-5 已指出 `express.static('../../developer-portal/dist')` 的相对路径问题。Node.js 的相对路径基于 `process.cwd()`（工作目录），而非模块文件位置。

**建议**: 改为 `path.join(__dirname, '../../developer-portal/dist')`，确保无论从哪个目录启动 server.js 都能正确解析。

### P2-R4-4: E9.3 subscriptionServiceStore SHA-256 依赖确认

**位置**: Task E9.3 Step 3

规格要求 serviceKey 使用 SHA-256 哈希存储（为真实环境预演）。Mock 环境中增加了一定复杂度但无安全收益。`crypto` 模块在 Node.js 18+ 中是内置的，项目应确认兼容。

**建议**: 确认项目 Node.js 版本要求（`package.json` engines 或 `.nvmrc`），如低于 Node 18 需注意 `crypto` 可用性。不阻塞实施。

---

## R3 遗留问题处理验证

| R3 编号 | 计划中的处理 | 评价 |
|---------|------------|------|
| P2-R3-1 (effectiveTier 恢复来源) | Task E9.3 未明确说明 | ⚠️ 建议实施时在 subscriptionService 模型中保留 `effectiveTier` 为购买 tier，另用 `currentStatus` 表运行状态 |
| P2-R3-2 (tenant_f_p001_001 缺 seed) | 未在 E8.1 中补充 | ❌ 提升为本评审 P1-R4-2 |
| P2-R3-3 (shapingMiddleware 无 apiTier 分叉) | G1.2 Step 3 处理 | ⚠️ 建议提前到 G1.1，见 P2-R4-1 |
| P2-R3-4 (accessibleFarmTenantIds 注入) | 计划 apiKeyAuth 代码已包含 | ✅ 已处理 |
| P2-R3-5 (express.static 路径) | 未修正 | ⚠️ 见 P2-R4-3 |
| P2-R3-6 (farmContext 显式分支) | 计划 G1.2 Step 3 已描述 | ✅ 已处理 |

---

## 计划结构与质量评估

| 方面 | 评价 |
|------|------|
| 依赖关系图 | ✅ 正确：E8→E9→E4/E5/E6/G1→G3/G2，E7 仅依赖 E8 |
| Task 拆分粒度 | ✅ 每个 Task 3-7 个 Step，可独立验证 |
| 测试策略 | ✅ 后端 TDD（先写测试→验证失败→实现→验证通过），覆盖充分 |
| 文件清单 | ✅ 新建 27+ 文件 + 修改 13+ 文件，全部列出 |
| Commit 粒度 | ✅ 每个 Task 单独 commit，消息格式规范 |
| 回归策略 | ✅ INT.1-INT.5 全量测试 + 手动端到端验证 |
| R3 遗留问题跟进 | ⚠️ 部分 P2 问题未在计划中显式处理 |

---

## 问题汇总

| 级别 | 数量 | 编号 |
|------|------|------|
| P0 | 0 | — |
| P1 | 2 | P1-R4-1, P1-R4-2 |
| P2 | 4 | P2-R4-1 ~ P2-R4-4 |
| **总计** | **6** | |

---

## 建议的实施顺序微调

当前顺序 E8→E9→E6→E7→E5→E4→G1→G3→G2 正确，建议：

1. **E8.1**: 为 `tenant_f_p001_001` 补充 `deviceConfigRatio` + `livestockCount`（P1-R4-2）
2. **E9.2**: revenueStore `calculate()` 遍历有合同的 partner，不限于 `licensed`（P1-R4-1）
3. **G1.1**: 提前处理 `feature-flag.js` apiTier 分叉（P2-R4-1）
4. **E5.1**: 开发者门户托管路径使用 `path.join(__dirname, ...)`（P2-R4-3）

---

## 结论

**计划通过，可进入实施阶段。** 建议 在开始实施前 修正 2 个 P1 问题（分润数据源范围、seed 缺失），4 个 P2 问题可在实施过程中逐步处理。计划整体结构优秀，依赖关系清晰，测试策略完整。

---

**文档结束**
