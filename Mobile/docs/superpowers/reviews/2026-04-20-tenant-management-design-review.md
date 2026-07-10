# 租户管理设计规格 — 评审报告

**被审文档**：`docs/superpowers/specs/2026-04-20-tenant-management-design.md` v1.0
**评审日期**：2026-04-20
**评审团队**：arch-reviewer（架构）、api-reviewer（API/数据模型）、ui-reviewer（UI/UX）

---

## 综合评审结论：有条件通过

设计文档整体结构完整、功能规划合理、模块划分清晰，但存在 **3 类必须修订的系统性问题** 和若干改进建议，修订后方可进入实施。

---

## 严重问题汇总（必须修订）

### A. 架构层

| # | 问题 | 影响 | 建议 |
|---|------|------|------|
| A1 | **Controller 使用 async 方法**，但现有代码（AlertsController 等）使用同步方法 + ViewData 模式 | 实施时会破坏现有数据流约定 | 改为同步方法，通过 `state =` 更新状态；Repository 保持同步接口，Live 实现通过 ApiCache 预加载 |
| A2 | **TenantState 结构过于复杂**，将列表/详情/设备/日志/统计全部塞进一个 State | 与现有简单 ViewData 模式不一致，且增加不必要的 rebuild | 拆分为多个 Provider：列表 Provider、详情 Provider（`Provider.family`）、设备/日志/统计各自独立 |
| A3 | **未考虑 ApiCache 集成** | Live 模式下数据无法预加载 | 在 ApiCache 中添加租户相关字段，init() 中调用相应 API |

### B. API 层

| # | 问题 | 影响 | 建议 |
|---|------|------|------|
| B1 | **列表响应格式**未使用统一包络 `{ code, message, requestId, data }` | 前端解析会出错 | 响应数据包裹在 `data` 字段中，分页使用 `{ items, page, pageSize, total }` |
| B2 | **调整 License 参数名** `newQuota` vs 现有实现的 `licenseTotal` | 调用失败 | 统一为 `licenseTotal` |
| B3 | **创建租户请求**包含 `contact` 对象，但后端仅接收 `name` + `licenseTotal` | 创建失败 | 扩展后端接口或对齐设计文档 |
| B4 | **状态切换/License 调整响应**未返回完整 tenant 对象 | 前端需额外请求刷新 | 响应应返回更新后的完整 Tenant |
| B5 | **6 个端点尚未实现**（详情/编辑/删除/设备/日志/统计） | 前端无法联调 | 先在 Mock Server 补齐端点 |

### C. UI/UX 层

| # | 问题 | 影响 | 建议 |
|---|------|------|------|
| C1 | **详情页 4-Tab 导航**，但项目无 TabBar 先例 | 与现有垂直卡片堆叠风格不一致 | 方案 a：改用垂直卡片堆叠（参考 livestock_detail_page）；方案 b：如用 Tab，需新增通用 Tab 组件 |
| C2 | **分页组件缺失**，设计多处引用但未设计 | 无法实施 | Phase 1 增加"通用分页组件"设计（上拉加载或底部翻页） |
| C3 | **搜索/过滤/排序交互未细化** | 实施时需重新设计 | 明确搜索框样式、下拉交互方式（DropdownButton vs BottomSheet）、防抖实现 |
| C4 | **删除确认流程过于复杂**（二次确认 + 输入原因 + 警告） | 移动端多弹窗体验差 | 简化为单次 AlertDialog，包含确认文案 + 原因输入 |
| C5 | **图表 30 天数据点在移动端拥挤** | 折线图可读性差 | 复用现有降采样逻辑（twin_series_downsample），30 天降为 7-10 点 |

---

## 改进建议汇总

### 架构

1. **路由枚举位置**：建议使用路径参数模式而非为每个子路由新增枚举值
2. **页面文件位置**：考虑将租户页面放在 `features/tenant/presentation/pages/` 而非 `features/pages/`，与模块内聚
3. **错误重试**：Demo 阶段不建议实现网络自动重试，与现有模式不一致

### API & 数据模型

4. **seed 数据扩展**：现有 tenants seed 仅含 5 个基础字段，需扩展支持 contact/region/remarks/timestamp
5. **操作日志存储**：Mock Server 当前无日志机制，实施前需先设计存储方案
6. **分页默认值**：文档 15 条 vs Mock Server 20 条，建议统一
7. **过滤排序参数**：Mock Server 仅支持分页，需扩展 status/search/sort/order

### UI/UX

8. **卡片信息密度**：6 个信息项在小屏幕拥挤，建议将创建时间等次要信息移至详情页
9. **统计概览布局**：5 个统计卡片建议用 GridView.count 双列布局
10. **业务规则明确**：编辑时租户名称是否可修改需明确
11. **License 调整验证**：明确错误提示文案，如"新配额不能小于当前已使用量（428）"

---

## 轻微问题

1. Toast → Flutter 中应为 SnackBar，统一术语
2. 骨架屏设计未提供具体占位方案
3. 空状态图标建议复用 `Icons.inbox_outlined` 等
4. 枚举值命名：`TenantOperationType` 可简化为 `TenantOperation`
5. 时间格式混用（相对时间 vs 精确时间），实现时需统一

---

## 与现有代码库对比

### 一致之处

- 模块三层结构（domain/data/presentation）
- Repository 接口 + Mock/Live 双实现
- Provider 根据 AppMode 切换
- Riverpod Notifier Controller
- ViewState 页面状态分支
- RolePermission 静态权限检查
- 主题 Token（AppColors/AppSpacing/AppTypography）
- 颜色/间距/排版规范

### 不一致之处

| 维度 | 设计文档 | 现有代码 |
|------|---------|---------|
| Controller 方法 | async Future | 同步 + ViewData |
| State 结构 | 大一统 TenantState | 简单 ViewData 值对象 |
| 数据预加载 | 未提及 | ApiCache.init() 预加载 |
| 详情页布局 | 4-Tab 导航 | 垂直卡片堆叠 |
| API 响应格式 | 部分未用包络 | 统一包络 |
| 创建请求参数 | contact 嵌套对象 | 扁平 name/licenseTotal |

---

## 实施可行性评估

| Phase | 难度 | 风险 | 前置条件 |
|-------|------|------|---------|
| Phase 1（MVP） | 中等 | 低 | 修订严重问题 A1-A3、B1-B5、C2-C3；Mock Server 补齐端点 |
| Phase 2（高级） | 中高 | 中 | 设计操作日志存储；明确删除/日志交互 |
| Phase 3（可视化） | 中等 | 低 | 复用现有降采样和图表实现 |
| Phase 4（优化） | 低 | 低 | — |

---

## 修订优先级

### P0 — 实施前必须完成

1. 重新设计 TenantController 为同步方法 + ViewData 模式
2. 拆分 TenantState 为多个独立 Provider
3. ApiCache 添加租户数据预加载
4. 修正 API 响应格式遵循统一包络
5. 对齐创建/调整 License 接口参数
6. Mock Server 补齐 6 个缺失端点
7. 明确详情页布局方案（Tab vs 垂直卡片）

### P1 — Phase 1 实施中完成

8. 设计通用分页组件
9. 细化搜索/过滤/排序交互方案
10. 简化删除确认流程
11. 扩展 seed 数据支持完整 Tenant 字段

### P2 — 后续迭代中完成

12. 图表数据降采样策略
13. 统计概览双列布局
14. 操作日志存储机制

---

## 评审人签名

| 角色 | 评审人 | 结论 |
|------|--------|------|
| 架构一致性 | arch-reviewer | 有条件通过 |
| API & 数据模型 | api-reviewer | 有条件通过 |
| UI/UX & 可行性 | ui-reviewer | 有条件通过 |
