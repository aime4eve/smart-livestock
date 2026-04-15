# Plan 文档写作规范

配合 `subagent-driven-development` + Issue 同步流程的实施计划写作要点。

## 文档结构（从上到下）

```markdown
# {功能名} 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [一句话目标]
**Architecture:** [2-3 句方案概述]
**Tech Stack:** [关键技术栈]

**真相来源:** Issue 的 open/closed 以 GitHub 为准；本文件记录范围说明、依赖与关闭后的归档信息。

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | [#{N}](url) | 标题 |

### 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|-----|------|

---

## 文件结构

### 新建

| 文件 | 职责 |
|------|------|

### 重写

| 文件 | 职责 |
|------|------|

### 修改

| 文件 | 变更 |
|------|------|

### 删除

| 文件 |
|------|

---

## Task 1: {组件名}

**Files:**
- Create: `exact/path/to/file.dart`

- [ ] **Step 1: 写失败测试**
...
- [ ] **Step N: Commit**
```

## 写作检查清单

### 结构完整性

- [ ] Header 包含 Goal / Architecture / Tech Stack
- [ ] 有 Issue 索引表（`| 优先级 | Issue | 标题 |`）
- [ ] 有完成记录表（`| 完成日期 | Issue | PR | 备注 |`），初始为空
- [ ] 有文件结构总览（新建/重写/修改/删除四类）
- [ ] 每个 Task 有 `**Files:**` 段列出精确路径

### 任务粒度

- [ ] 每一步是 2-5 分钟的单个动作（不是"重写整个页面"）
- [ ] Task 之间相对独立（后一个 Task 不依赖前一个的运行时输出）
- [ ] 复杂 Task（>50 行代码）拆分为多个子步骤

### 代码完整性

- [ ] 内联完整代码（不是"添加验证逻辑"这种模糊描述）
- [ ] 修改操作标注行号范围（如 `demo_models.dart:22-27`）
- [ ] 删除操作列出完整文件路径

### TDD 模式（推荐）

- [ ] 功能 Task 遵循：写失败测试 → 确认失败 → 写实现 → 确认通过 → Commit
- [ ] 每步有运行命令和预期输出（`Expected: PASS` / `Expected: No issues found`）
- [ ] 重构/删除类 Task 可跳过 TDD，但仍需验证步骤

### Issue 同步

- [ ] 每个 issue 在 plan 中有对应的 `## #N — 标题` 小节
- [ ] 小节包含：目标、涉及文件、验收标准
- [ ] issue 关闭后，完成记录表增加一行

### 可执行性

- [ ] 所有命令可从项目根目录直接运行
- [ ] `flutter analyze` / `flutter test` 命令带完整路径（`cd Mobile/mobile_app && ...`）
- [ ] commit message 遵循 conventional commits（`feat(scope): ...` / `fix(scope): ...`）
- [ ] 没有需要人工判断的模糊步骤（如"根据情况调整"）

## 反模式（不要这样写）

| 反模式 | 正确做法 |
|--------|----------|
| "添加表单验证" | 内联完整的 `validator` 代码 |
| "参考现有代码风格" | 明确写出来（如"使用 `Key('xxx')` 模式"） |
| "确保测试通过" | 写出 `flutter test test/xxx.dart` 和 `Expected: All tests pass` |
| "按需调整" | 给出确定值或明确参数 |
| 一整个 Task 包含多文件重写 | 按文件拆分为多个 Task |
| Task 之间有强数据依赖 | 通过共享接口/模型解耦，或合并为一个 Task |
| `git add -A` | `git add` 指定文件路径 |

## 本项目特定约定

- UI 文本用中文，变量名用英文
- 所有 Widget 必须有 `Key('descriptive-id')`
- 使用主题 token（AppColors/AppSpacing/AppTypography）
- 测试文件中引用 `const DemoApp()` 作为测试入口
- commit message 用英文
- flutter 命令从 `Mobile/mobile_app` 执行
