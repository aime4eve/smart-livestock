# 智慧畜牧项目 — Claude Code 提示词模板

面向 `aime4eve/smart-livestock` 项目的 Claude Code 提示词速查手册。
每个模板可直接复制使用，替换 `{占位符}` 即可。

---

## 全流程总览

```
需求/想法
  ↓ ① 头脑风暴
设计规格 (specs/*.md)
  ↓ ② 写实施计划
实施计划 (plans/*.md)
  ↓ ③ 创建 Issues
GitHub Issues
  ↓ ④ 执行计划 + Issue 同步
功能分支 + PR
  ↓ ⑤ 完成分支 / Code Review
合并到 master
```

---

## ① 头脑风暴：需求 → 设计规格

**何时用**: 有新功能想法、要修改现有行为、需要做技术决策时。**任何创造性工作前必须先用此模板。**

```
/brainstorming
我需要实现 {功能描述}。

背景：
{补充上下文：用户角色、使用场景、技术约束}

相关文件：
{列出你知道的相关代码路径或文档}

请帮我：
1. 探索现有代码，理解当前实现
2. 提出设计方案选项（至少 2 个）
3. 讨论权衡后确定方案
4. 输出设计规格文档，保存到 docs/superpowers/specs/
```

**实际示例**:

```
/brainstorming
我需要给围栏页面增加完整的 CRUD 功能，目前地图和围栏是两个独立页面。

背景：
- 当前有独立的地图页（MapPage）和围栏页（FencePage），围栏页只能查看
- 想合并为统一入口：全屏地图 + 底部抽屉列表，支持新建/编辑/删除围栏
- 数据在会话期间以内存列表维持，不需要持久化

相关文件：
- lib/features/pages/fence_page.dart
- lib/features/pages/map_page.dart
- lib/features/fence/domain/fence_repository.dart
- lib/core/data/demo_seed.dart
```

---

## ② 写实施计划：设计规格 → 实施计划

**何时用**: 设计规格批准后，需要拆解为可执行的 Task 列表时。

```
/writing-plans
基于以下设计规格，编写实施计划：

- 设计规格：{SPEC_FILE_PATH}
- 关联 Issue：#{ISSUE_NUMBER}（如已有）

要求：
1. 按 Plan 文档写作规范（见 docs/superpowers/templates/plan-writing-checklist.md）
2. 包含 Issue 索引表和完成记录表
3. 每个 Task 遵循 TDD 模式（写测试 → 确认失败 → 实现 → 确认通过 → Commit）
4. 每步 2-5 分钟粒度，内联完整代码
5. 保存到 docs/superpowers/plans/YYYY-MM-DD-{name}.md
```

**实际示例**:

```
/writing-plans
基于以下设计规格，编写实施计划：

- 设计规格：docs/superpowers/specs/2026-04-10-fence-crud-design.md
- 关联 Issue：#10

要求：
1. 按 Plan 文档写作规范（见 docs/superpowers/templates/plan-writing-checklist.md）
2. 包含 Issue 索引表和完成记录表
3. 每个 Task 遵循 TDD 模式
4. 每步 2-5 分钟粒度，内联完整代码
5. 保存到 docs/superpowers/plans/2026-04-10-fence-crud.md
```

---

## ③ 创建 Issues：计划 → GitHub Issues

**何时用**: 实施计划写好后，需要把 Task 或 Issue 组创建到 GitHub。

```
根据计划文件 {PLAN_FILE_PATH} 的 Issue 索引表，创建 GitHub Issues。

要求：
1. 每个 Issue 标题格式：`[P{N}] {scope}: {简要描述}`
2. Issue 正文包含：
   - 目标（从 plan 对应小节的「目标」复制）
   - 涉及文件列表
   - 验收标准
   - 关联 plan 文件链接
3. 创建后更新 plan 文件的 Issue 索引表，填入实际 issue 编号和链接
4. 按优先级从高到低创建
```

**实际示例**:

```
根据计划文件 Mobile/docs/superpowers/plans/2026-04-09-demo-data-followups.md 的 Issue 索引表，
创建 GitHub Issues。

要求：
1. 每个 Issue 标题格式：[P{N}] demo-data: {简要描述}
2. Issue 正文包含目标、涉及文件、验收标准、plan 文件链接
3. 创建后更新 plan 文件的 Issue 索引表
4. 按优先级从高到低创建
```

---

## ④ 执行计划 + Issue 同步（核心模板）

**何时用**: Plan 已写好，Issue 已创建，开始实际编码时。

```
/subagent-driven-development
执行实施计划并同步 GitHub Issue：

- 计划文件：{PLAN_FILE_PATH}
- GitHub Issue：#{ISSUE_NUMBER}（{ISSUE_URL}）

要求：

1. 开始前：用 `gh issue edit {ISSUE_NUMBER} --add-assignee aime4eve` 认领 issue；
   从 master 创建功能分支 `feat/{ISSUE_NUMBER}-{brief-slug}`
2. 按 plan 中的 Task 顺序逐个执行（subagent dispatch + spec review + code review 三阶段）
3. 每完成一个 Task，用 `gh issue comment {ISSUE_NUMBER}` 追加进度评论：
   ✅ Task N: [标题] — 完成
   Commit: {hash}
   说明: {一句话说明改了什么}
4. 如果某个 Task 失败，评论标记 ❌ 并说明原因，等待指示
5. 全部 Task 完成后：
   - 运行 `flutter analyze` + `flutter test` 全量验证
   - 更新计划文件的「完成记录」表，增加一行（日期、PR 链接、备注）
   - 创建 PR，正文包含 `Closes #{ISSUE_NUMBER}`
   - 标题格式：`feat(scope): {简要描述} (#{ISSUE_NUMBER})`
6. 不要重命名 issue 标题，PR 合并后 GitHub 会自动关闭 issue

开始执行。
```

---

## ⑤ 单 Issue 快速处理

**何时用**: Issue 比较简单，不需要完整的 subagent 三阶段流程，直接修复即可。

```
处理 GitHub Issue #{ISSUE_NUMBER}。

1. 认领：`gh issue edit {ISSUE_NUMBER} --add-assignee aime4eve`
2. 读取 issue 详情：`gh issue view {ISSUE_NUMBER}`
3. 在 docs/superpowers/plans/ 中搜索对应 plan 小节
4. 从 master 创建分支 `fix/{ISSUE_NUMBER}-{brief-slug}`
5. 按 plan 中的规格实现
6. 验证：`flutter analyze` + `flutter test`
7. 提交并创建 PR（正文含 `Closes #{ISSUE_NUMBER}`）
8. 更新 plan 文件的完成记录表

如果找不到对应 plan，直接根据 issue 描述实现，但完成时在 issue 评论中说明实现方案。
```

---

## ⑥ 系统化调试

**何时用**: 遇到 bug、测试失败、异常行为时。**必须在提出修复方案之前使用。**

```
/systematic-debugging
遇到以下问题：

现象：{错误描述}
错误信息：
{完整的错误输出或堆栈跟踪}

复现步骤：
1. {步骤 1}
2. {步骤 2}

最近变更：{git diff 摘要或相关 commit}

请按四阶段调试：
1. 根因调查（先读代码，不要猜）
2. 模式分析
3. 假设验证
4. 实施修复
```

---

## ⑦ 完成分支

**何时用**: 实现完成、测试通过，准备集成到 master 时。

```
/finishing-a-development-branch
功能分支 {BRANCH_NAME} 的实现已完成。

基础分支：master
所有测试已通过（flutter analyze + flutter test）。

请帮我完成分支集成。
```

---

## ⑧ Code Review

**何时用**: 完成主要功能实现后、合并前，需要质量检查时。

```
/requesting-code-review
请审查以下实现的代码质量：

- 功能分支：{BRANCH_NAME}
- 提交范围：{BASE_SHA}..{HEAD_SHA}
- 实现内容：{一句话描述}
- 需求/计划文档：{PLAN_FILE_PATH}
```

---

## ⑨ 完成前验证

**何时用**: 声称工作完成、准备提交或创建 PR 前。**强制执行，不能跳过。**

```
/verification-before-completion
请验证以下工作确实完成：

1. `cd Mobile/mobile_app && flutter analyze` — 静态分析无问题
2. `cd Mobile/mobile_app && flutter test` — 全部测试通过
3. `cd Mobile/mobile_app && git status` — 无遗留未提交文件
4. 确认关键 Widget Key 存在（如适用）

运行命令并报告实际输出，不要用"应该""大概"。
```

---

## 快速参考：占位符说明

| 占位符 | 说明 | 示例 |
|--------|------|------|
| `{PLAN_FILE_PATH}` | plan 文件相对路径 | `Mobile/docs/superpowers/plans/2026-04-10-fence-crud.md` |
| `{ISSUE_NUMBER}` | GitHub Issue 编号 | `10` |
| `{ISSUE_URL}` | Issue 完整链接 | `https://github.com/aime4eve/smart-livestock/issues/10` |
| `{SPEC_FILE_PATH}` | 设计规格文件路径 | `docs/superpowers/specs/2026-04-10-fence-crud-design.md` |
| `{BRANCH_NAME}` | 功能分支名 | `feat/10-fence-crud` |
| `{BASE_SHA}` | 起始 commit | `a1b2c3d` |
| `{HEAD_SHA}` | 最新 commit | `e4f5g6h` |
| `{brief-slug}` | 分支名简写 | `fence-crud` / `gps-cache-fix` |

---

## 快速参考：skill 触发条件

| Skill | 命令 | 触发条件 |
|-------|------|----------|
| brainstorming | `/brainstorming` | 任何创造性工作前（新功能、修改行为、技术决策） |
| writing-plans | `/writing-plans` | 设计批准后，拆解为可执行 Task |
| subagent-driven-development | `/subagent-driven-development` | 执行已写好的 plan |
| systematic-debugging | `/systematic-debugging` | 遇到 bug、测试失败、异常行为 |
| finishing-a-development-branch | `/finishing-a-development-branch` | 实现完成，准备集成 |
| requesting-code-review | `/requesting-code-review` | 合并前质量检查 |
| verification-before-completion | `/verification-before-completion` | 声称完成前强制验证 |

---

## 快速参考：Plan 文档必备要素

1. Header（Goal / Architecture / Tech Stack）
2. Issue 索引表 + 完成记录表
3. 文件结构总览（新建/重写/修改/删除）
4. Task 2-5 分钟粒度，TDD 循环
5. 内联完整代码，不写模糊描述
6. 命令可执行，带预期输出

完整检查清单：`docs/superpowers/templates/plan-writing-checklist.md`
