---
name: seed-verify
description: 验证 Flyway seed 迁移中的 BCrypt 密码 hash — 生成时验证 + 部署后登录验证
---

# Seed 密码验证

验证 seed 数据中的密码 hash 正确性。防止 hash 错误导致部署后无法登录（历史教训：V4→V5→V13 三次 hash 错误）。

## 参数

- `phase`（可选）: `generate` | `deploy` | `all`（默认）
- `migration`（可选）: 指定迁移文件名，如 `V13__seed_data.sql`，不指定则扫描全部 seed 迁移

## 步骤

### Phase 1: 生成时验证（generate）

1. **定位 seed 迁移文件**
   ```bash
   ls smart-livestock-server/src/main/resources/db/migration/V*seed*.sql
   ```

2. **提取所有 BCrypt hash**
   在迁移文件中搜索 `$2a$10$` 或 `$2b$10$` 模式的 hash 值。

3. **逐个验证 hash 与明文密码的匹配**
   使用 Java BCrypt 验证（因为项目使用 Spring Security 的 BCryptPasswordEncoder）：
   ```bash
   cd smart-livestock-server
   ./gradlew compileJava --quiet
   java -cp "build/classes/java/main:$(./gradlew dependencies --configuration runtimeClasspath --quiet | grep -o '/[^ ]*\.jar' | tr '\n' ':')" \
     -e "import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder; ..."
   ```

   如果 Java 方式不方便，用 Python 替代：
   ```bash
   python3 -c "
   import bcrypt
   pairs = [
     ('\$2a\$10\$...', 'password123'),  # 从文件中提取
   ]
   for h, p in pairs:
     print(f'Match: {bcrypt.checkpw(p.encode(), h.encode())}')
   "
   ```

4. **确认全部 hash 匹配** — 如果有任何不匹配，立即报告并停止。

### Phase 2: 部署后验证（deploy）

5. **检查服务器连通性**
   ```bash
   ping -c 1 -W 2 172.22.1.123
   ```

6. **用每个 seed 账号调用登录接口**
   ```bash
   curl -sf http://172.22.1.123:18080/api/v1/auth/login \
     -X POST -H 'Content-Type: application/json' \
     -d '{"phone":"13800000000","password":"123"}' | python3 -m json.tool
   ```
   对以下账号逐一验证：

   | 角色 | 手机号 | 密码 |
   |------|--------|------|
   | platform_admin | 13800000000 | 123 |
   | b2b_admin | 13900139000 | 123 |
   | owner | 13800138000 | 123 |

7. **验证响应** — 每个登录必须返回 `token` 字段且 HTTP 200。返回 401 即为失败。

## 输出

```
## Seed 验证报告

### 生成时验证
- [文件]: V{N}__seed_data.sql
- Hash 1 (role: owner): ✅ 匹配 / ❌ 不匹配
- Hash 2 (role: admin): ✅ 匹配 / ❌ 不匹配

### 部署后验证
- platform_admin (13800000000): ✅ 登录成功 / ❌ 401 Unauthorized
- b2b_admin (13900139000): ✅ 登录成功 / ❌ 401 Unauthorized
- owner (13800138000): ✅ 登录成功 / ❌ 401 Unauthorized

### 结论
✅ 全部通过 / ❌ 存在问题（见上方详情）
```

## 规则

- **不可跳过任何一步** — 生成验证和部署验证都是必须的
- **不可复制旧 hash** — 每次必须重新验证，之前的 hash 可能本身就是错的
- **失败即停** — 任何一个验证失败都应中止并报告
