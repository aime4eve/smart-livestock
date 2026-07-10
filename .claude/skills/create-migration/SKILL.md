---
name: create-migration
description: 创建新的 Flyway 迁移脚本，自动计算版本号并生成标准头部
disable-model-invocation: true
---

# 创建 Flyway 迁移脚本

## 参数

- `name`（必需）: 迁移描述，snake_case 格式，如 `add_audit_logs`、`alter_livestock_columns`
- `context`（可选）: 限界上下文名，如 Identity、Ranch、IoT、Commerce、Health

## 步骤

1. **扫描现有迁移**
   ```bash
   ls smart-livestock-server/src/main/resources/db/migration/V*.sql | sort
   ```

2. **计算下一个版本号**
   - 找到最高版本号 V{N}
   - 新版本 = V{N+1}
   - 版本号之间不留空隙

3. **创建迁移文件**
   - 路径: `smart-livestock-server/src/main/resources/db/migration/V{N+1}__{name}.sql`
   - 命名规则: `V{version}__{description}.sql`（双下划线）

4. **写入文件头**
   ```sql
   -- Migration: {name}
   -- Date: {YYYY-MM-DD}
   -- Context: {context 或 Unspecified}

   -- 在下方编写 SQL
   ```

5. **提示用户** 文件已创建，并告知版本号和路径

## 规则

- Flyway 迁移文件名必须是 `V{number}__{description}.sql`，双下划线
- 一个迁移文件只做一件事（单一职责）
- 包含 `CREATE TABLE` 时必须同时写 `DROP TABLE IF EXISTS` 的注释
- 新增 NOT NULL 列时必须提供 DEFAULT 值
- 新增外键时注明引用的表和迁移版本
