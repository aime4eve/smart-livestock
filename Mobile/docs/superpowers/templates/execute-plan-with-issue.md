# 执行计划 + Issue 同步模板

用 `superpowers:subagent-driven-development` 执行实施计划，同时与 GitHub Issue 保持双向同步。

## 使用方法

将下方占位符替换为实际值后，粘贴到 Claude Code 对话中：

```
/subagent-driven-development
执行实施计划并同步 GitHub Issue：

- 计划文件：{PLAN_FILE_PATH}
- GitHub Issue：#{ISSUE_NUMBER}（{ISSUE_URL}）

要求：

1. 开始前：用 `gh issue edit {ISSUE_NUMBER} --add-assignee aime4eve` 认领 issue；从 master 创建功能分支 `feat/{ISSUE_NUMBER}-{brief-slug}`
2. 按 plan 中的 Task 顺序逐个执行（subagent dispatch + spec review + code review 三阶段）
3. 每完成一个 Task，用 `gh issue comment {ISSUE_NUMBER}` 追加进度评论：
   ✅ Task N: [标题] — 完成
   Commit: {hash}
   说明: {一句话说明改了什么}
4. 如果某个 Task 失败，评论标记 ❌ 并说明原因，等待指示
5. 全部 Task 完成后：
   - 运行 `flutter analyze` + `flutter test` 全量验证
   - 更新计划文件的「完成记录」表，增加一行（日期、PR 链接、备注）
   - 创建 PR，正文包含 `Closes #{ISSUE_NUMBER}`，标题格式：`feat(scope): {简要描述} (#{ISSUE_NUMBER})`
6. 不要重命名 issue 标题，PR 合并后 GitHub 会自动关闭 issue

开始执行。
```

## 实际示例

```
/subagent-driven-development
执行实施计划并同步 GitHub Issue：

- 计划文件：Mobile/docs/superpowers/plans/2026-04-10-fence-crud.md
- GitHub Issue：#10（https://github.com/aime4eve/smart-livestock/issues/10）

要求：

1. 开始前：用 `gh issue edit 10 --add-assignee aime4eve` 认领 issue；从 master 创建功能分支 `feat/10-fence-crud`
2. 按 plan 中的 Task 1-12 顺序逐个执行（subagent dispatch + spec review + code review 三阶段）
3. 每完成一个 Task，用 `gh issue comment 10` 追加进度评论：
   ✅ Task N: [标题] — 完成
   Commit: {hash}
   说明: {一句话说明改了什么}
4. 如果某个 Task 失败，评论标记 ❌ 并说明原因，等待指示
5. 全部 Task 完成后：
   - 运行 `flutter analyze` + `flutter test` 全量验证
   - 更新计划文件的「完成记录」表，增加一行（日期、PR 链接、备注）
   - 创建 PR，正文包含 `Closes #10`，标题格式：`feat(fence): 合并地图+围栏，实现完整 CRUD (#10)`
6. 不要重命名 issue 标题，PR 合并后 GitHub 会自动关闭 issue

开始执行。
```

## 设计说明

### 相比原始提示词的优化点

| 原始 | 优化后 | 原因 |
|------|--------|------|
| 直接开始执行 | 先认领 issue + 创建分支 | 符合 Issue 驱动工作流，隔离开发 |
| 只说"按 Task 顺序" | 明确三阶段（dispatch + spec review + code review） | 对齐 subagent-driven-development skill 流程 |
| 全部完成后标记 [Done] | 创建 PR 含 `Closes #N` | GitHub 原生机制自动关闭，无需手动改名 |
| 无 plan 回写 | 更新计划文件完成记录表 | 保持 plan ↔ issue 双向同步 |
| 无分支策略 | 从 master 拉功能分支 | 避免直接在 master 上大改 |

### 适用场景

- 单 Issue 对应单 Plan（最常见）
- Plan 中 Task 之间相对独立，可逐个分派 subagent
- 需要 Issue 进度可追踪（远程协作、客户演示）

### 不适用场景

- 多 Issue 共享一个 Plan → 需要拆分为多个执行会话
- Task 之间强耦合（前一个的输出是后一个的输入）→ 考虑手动执行
