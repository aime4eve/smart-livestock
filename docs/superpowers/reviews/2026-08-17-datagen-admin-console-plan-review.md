# 仿真控制管理界面实施计划评审

| 字段 | 值 |
|---|---|
| 评审对象 | [2026-08-17-datagen-admin-console-plan.md](../plans/2026-08-17-datagen-admin-console-plan.md) |
| 配套 spec | [2026-08-17-datagen-admin-console-design.md](../specs/2026-08-17-datagen-admin-console-design.md)（修订后 750 行） |
| 评审日期 | 2026-08-17 |
| 评审人 | opencode Agent |
| 结论 | **有条件通过** — P1 项（视觉保真命令固定 + 在途消息默认 source 决策）在 Task 0/6 启动前修订即可执行 |

---

## 评审总结

计划质量高，与修订后的 spec 完全对齐：上一轮 spec 评审的 P0/P1 全部在计划中得到落实——旧全局端点收紧（Task 3.1）、`alerts` CHECK 重建（Task 1.1）、`audit_logs` 增列（Task 1.1 + 4.2 直写 `AuditLogRepository`）、assignment 历史归属替代"当前活跃安装"（Task 1.2/7.1）、初始化 `enabled=false` + scenario RUNNING 幂等（Task 1.2/4.1）。任务分解、TDD 前置、部署后集成验证的顺序均符合 AGENTS.md 工作流。

发现的问题集中在**执行层面**而非设计层面：视觉保真闭环依赖的 `prototype-to-flutter-fidelity` 不在本环境技能表内、计划未固定其命令与截图宽度参数；另有 3 个 P2（updateControl 行锁、新建 farm 的 control 行缺失、跨 farm 设备迁移的清理越界）和若干 P3 补全项。没有发现与 spec 冲突或不可实施的点。

**按严重度排列的发现**：

| 级别 | 编号 | 标题 |
|---|---|---|
| P1 | F1 | 视觉保真 skill 路径与命令未固定（含对比脚本默认宽度不符） |
| P2 | F2 | 在途消息缺 source 默认 `AGENTIC_PLATFORM` 与 spec"不猜测"原则冲突 |
| P2 | F3 | updateControl 未声明 farm control 行锁 |
| P2 | F4 | 迁移后新建 farm 无 control 行，updateControl 需 upsert 未明说 |
| P2 | F5 | 跨 farm 设备迁移导致清理按 device 归属越界，未 ack |
| P3 | F6 | 操作记录读回（按 farm+role）测试缺失 |
| P3 | F7 | Task 8.2 clear preview DTO 未枚举 estrus/anomaly/unattributable 字段 |
| P3 | F8 | 依赖图缺 Task 3→4（DatagenOperatorContext） |
| P3 | F9 | 重新启用 farm 时 `nextDueByDevice` 陈旧时间可能延迟首个 tick 产数 |

---

## P1 — 高优先级（启动前修订）

### F1：视觉保真 skill 路径与命令未固定

**位置**：计划头部 "REQUIRED SKILL"、Task 0、Task 10.7

**问题**：

1. `prototype-to-flutter-fidelity` **不在本 opencode 环境技能表内**（该 skill 位于 `~/.codex/skills/prototype-to-flutter-fidelity/`，属 Codex 技能目录）。执行 Agent 不会自动加载它，仅靠计划头部一行"REQUIRED SKILL"无法触发。
2. 计划 Task 0 说"运行 prototype token 提取脚本"、Task 10.7 说"运行 prototype-to-flutter-fidelity skill 保存对比结果"，但**没有给出脚本路径与参数**。参考 NIX-60 计划（Task 0.1）已固定为：
   ```bash
   python3 ~/.codex/skills/prototype-to-flutter-fidelity/scripts/extract_design_tokens.py \
     docs/marketing/datagen-console-prototype.html --out docs/design-tokens-datagen.md
   ```
3. `compare_screenshots.py` 默认 `--target-width 390`（iPhone 14），而本原型是**桌面管理台布局**（Task 0 已声明 tablet/desktop 对齐）。若不传 `--target-width`，对比会拿 390px 宽度比桌面截图，误报失配。

**建议**：Task 0 补充两条具体命令（token 提取 + 输出路径），Task 10.7 补充对比命令并明确 `--target-width`（与基线截图一致的 tablet/desktop 宽度，如 `1440`），并注明 `compare_screenshots.py` 依赖 Pillow。同时在计划头部写明 skill 绝对路径。

---

## P2 — 中优先级

### F2：在途消息缺 source 默认 `AGENTIC_PLATFORM` 与 spec"不猜测"原则冲突

**位置**：Task 6.1（"兼容在途消息：consumer 缺 source 时按 `AGENTIC_PLATFORM` 处理"）

**问题**：spec §5.4 的原则是"存量不猜测、不删除、避免误删真实数据"，且 `unattributableHealthRows` 只统计 `UNKNOWN`。Task 6.1 的默认值会：把部署瞬间在途的 DATAGEN 消息的健康派生行永久标记为 `AGENTIC_PLATFORM`——既不是 `DATAGEN`（不可清理），也不是 `UNKNOWN`（**不进入 unattributable 指标**，管理员无从知晓这批残留）。与 spec 的保守哲学不一致，且语义上把仿真数据"洗白"成平台数据。

**建议**：缺 source 时默认写 `UNKNOWN`（与三张健康表 `DEFAULT 'UNKNOWN'` 一致），使其计入 `unattributableHealthRows` 并保持"不猜测"原则；或至少在计划中显式记录"默认 AGENTIC_PLATFORM 的后果与理由"供用户确认。

### F3：updateControl 未声明 farm control 行锁

**位置**：Task 4.1（"保存 control 与 assignment 在同一事务"）

**问题**：spec §7.2 明确"清理与保存配置互斥通过 farm control 行锁实现"；计划只在 Task 7.5（清理）写了锁定，Task 4.1 的 updateControl 未提 `SELECT ... FOR UPDATE`。两个管理员并发保存（全量替换 assignment）+ 与清理并发时，缺少行锁会丢失更新或出现 enabled/device 不一致。

**建议**：Task 4.1 补一句"updateControl 事务内对 farm control 行加 `FOR UPDATE` 行锁"，与 Task 7.5 对齐。

### F4：迁移后新建 farm 无 control 行，updateControl 需 upsert 未明说

**位置**：Task 1.2（只回填"所有 farm"）、Task 4.1

**问题**：初始化迁移只为**迁移时已存在**的 farm 创建 control 行。此后新建的 farm（B2B 创建牧场）没有 control 行，`findByFarmId` 返回空。Task 4.1 若按"读取 farm、control…"直接更新会空指针或 404，未明确 upsert 语义。

**建议**：Task 4.1 明确"control 行不存在时先创建（tenant/farm/scenario 指向默认 NORMAL）"，并补一条测试"新建 farm 首次保存控制配置成功"。

### F5：跨 farm 设备迁移导致清理按 device 归属越界，未 ack

**位置**：Task 7.1/7.3（telemetry/gps 按 "device 曾归属该 farm assignment" 删除）

**问题**：`device_telemetry_logs` / `gps_logs` 无 farm 列，清理只能按 `device_id IN (该 farm 历史 assignment 的 device set) + source=DATAGEN` 删除。若某设备从 farm A 迁移到 farm B（同租户）并继续产生 DATAGEN 数据，清理 farm A 时会把该设备在 farm B 期间产生的 DATAGEN 行一并删除——跨 farm 越界。因仅删 `DATAGEN`，不会删真实数据，但 B2B 管理员清理自己某牧场时可能误清同租户另一牧场的仿真数据。

**建议**：在计划（或回写 spec）中显式 ack 该限制，如"归属按 device 维度、不分 farm 时段；设备跨 farm 迁移的历史 DATAGEN 行会随任一归属 farm 的清理被一并删除，仅影响 DATAGEN 数据"。若需精确到 (device, farm, 时间窗) 需要额外 schema，首版建议接受并记录。

---

## P3 — 低优先级

### F6：操作记录读回（按 farm+role）测试缺失

**位置**：Task 4.3、Task 8.4

**问题**：spec §8 测试第 5 组要求"控制台操作记录能按 farm 查询并显示 operator role"。计划 Task 4.3 只测"每次 action 均写 audit log"（写侧），未覆盖 `getConsole` 的 operations 读回按 `farm_id` 过滤 + `operatorRole` 字段映射。

**建议**：Task 4.3 或 8.4 补一条"operations 按 farm 过滤、字段含 operatorRole、时间倒序"的测试。

### F7：Task 8.2 clear preview DTO 未枚举 estrus/anomaly/unattributable 字段

**位置**：Task 8.2（"Clear preview request/response"）

**问题**：spec §5.3 preview 响应含 `estrusRows / anomalyRows / alertRows / unattributableAlertRows / unattributableHealthRows`，delete 响应含 `estrusRows / anomalyRows`。计划 Task 8.2 仅列"Clear preview request/response"未枚举字段，实施时可能与 spec 漂移，且前端 Task 10.4 需展示 unattributable 计数。

**建议**：Task 8.2 列出 DTO 字段清单，与 spec §5.3 逐字段对齐。

### F8：依赖图缺 Task 3→4

**位置**：任务依赖图

**问题**：Task 4 的 `DatagenControlService` 方法签名使用 Task 3.2 定义的 `DatagenOperatorContext`，依赖图未画 3→4 边（仅 3→8）。顺序执行无碍，但图不完整。

### F9：重新启用 farm 时 `nextDueByDevice` 陈旧时间可能延迟首个 tick 产数

**位置**：Task 5、Task 13.3（"下一个调度 tick 后只生成指定设备"）

**问题**：`SynthesisService` 的 `nextDueByDevice` 是全局 map。设备曾在选中状态下生成过（nextDue 指向未来时刻），停用一段时间后重新启用，若 `now < nextDue`，首个 tick 不会立即生成，延迟最多一个 interval（TRACKER 5min）。集成验证若期望"下个 tick 立即产数"可能踩到时序。

**建议**：Task 4 启用 farm 时清空该 farm 设备的 `nextDueByDevice`（或 Task 13.3 验证时先确认上次生成时间已过期），保证重新启用即产数。

---

## 已核实正确的引用（无需修改）

以下计划论断经源码/文件系统核实：

- `prototype-to-flutter-fidelity` skill 存在：`~/.codex/skills/prototype-to-flutter-fidelity/`，含 `extract_design_tokens.py`、`compare_screenshots.py`（需 Pillow）✓
- `docs/api-contracts/admin-api.md` 存在，Task 12"增补"成立 ✓
- `TenantContext.getCurrentTenant()` 存在（`shared/tenant/TenantContext.java`），Task 3.2 引用有效 ✓
- `installations` 有 `installed_at TIMESTAMP NOT NULL` 与 `removed_at TIMESTAMP`，且已存在"每设备最多一条 active installation"部分唯一索引（V3:42-52）——Task 1.2 回填的 `min(installed_at)` / `coalesce(max(removed_at),null)` 可执行 ✓
- `estrus_scores`（V20:107）与 `anomaly_scores`（V40:8）均有 `farm_id`，按 farm 归属清理可行 ✓
- 当前 `DataGenAdminController` 无 `@PreAuthorize`（`DataGenAdminController.java:19-21`），Task 3.1 每方法收紧为 PLATFORM_ADMIN 正确 ✓
- `audit_logs`（V18:2-12）确无 farm_id/role 列，Task 1.1 增列必要 ✓；`AuditLogEventListener` 不存在，Task 4.2 直写 `AuditLogRepository.save()` 是正确修正 ✓
- `git status` 证实存在未提交的 subscription/commerce/API 文档改动，Task 14 只 stage 本任务文件约束与现状一致 ✓
- Task 0 基线清单（status/devices/clear/operations/clear-dialog/narrow）与原型 4 tab + dialog + 响应式场景一一对应 ✓
- 计划新表/索引/部分唯一索引命名与修订后 spec §5.1 DDL 完全一致 ✓
- Task 13 采用 `./scripts/deploy.sh test` 与 spec 验收第 10 条一致（本功能依赖 test 环境 datagen）✓

---

## 设计亮点

1. **assignment 历史模型**：`removed_at` + 部分唯一索引解决"已解绑设备数据不可清理"黑洞（spec 评审 F4），且全量替换不物理删除，可逆性好。
2. **Task 1.2 回填逻辑闭环**：从 `installations` 历史回填含已移除安装的归属，`min(installed_at)`/`coalesce(max(removed_at))` 合并规则覆盖"先装-后装-active"场景。
3. **清理服务独立归属解析（Task 7.1）**：不依赖当前活跃安装，telemetry→device、estrus/anomaly→livestock 双链路清晰。
4. **审计直写修正**：计划识别并绕开 `AuditLogEventListener` 缺失的现状（spec 修订已记录），`DatagenAuditService` 与业务同事务，回滚一致。
5. **每任务带验证门 + 部署后集成验证清单**：Task 13.3 覆盖权限边界、产数节奏、清理保留、审计、i18n，验收标准可执行。

---

## 建议的后续行动

1. **[plan 修订] F1（P1）**：Task 0/10.7 固定 skill 脚本路径与命令，明确 `compare_screenshots.py --target-width`（桌面宽度），注明 Pillow 依赖。
2. **[plan 修订] F2（P2）**：在途消息默认 source 决策改 `UNKNOWN`（与 spec"不猜测"一致），或显式记录 AGENTIC_PLATFORM 权衡供确认。
3. **[plan 修订] F3-F5（P2）**：updateControl 补行锁、补新建 farm 的 control upsert、显式 ack 跨 farm 清理越界限制。
4. **[plan 修订] F6-F9（P3）**：operations 读回测试、preview DTO 字段清单、依赖图 3→4、重新启用时清 `nextDueByDevice`。
5. 修订确认后按计划执行，进入 feature 流程第 4 步（编码 + 编译验证 + 视觉保真验证）。
