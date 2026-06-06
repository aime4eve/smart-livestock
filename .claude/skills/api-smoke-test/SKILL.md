---
name: api-smoke-test
description: 部署后 API 冒烟测试 — 验证关键端点可用性（认证、健康检查、核心业务）
disable-model-invocation: true
---

# API 冒烟测试

部署后快速验证后端 API 关键端点是否正常工作。

## 参数

- `base_url`（可选）: 默认 `http://172.22.1.123:18080/api/v1`
- `role`（可选）: 测试特定角色的端点，默认 `all`（测试全部角色）

## 步骤

### 1. 健康检查

```bash
curl -sf -o /dev/null -w "%{http_code}" http://172.22.1.123:18080/api/v1/auth/login
```
返回非 000 即表示服务可达。

### 2. 登录获取 Token

逐个角色登录并保存 token：

```bash
# platform_admin
ADMIN_TOKEN=$(curl -sf http://172.22.1.123:18080/api/v1/auth/login \
  -X POST -H 'Content-Type: application/json' \
  -d '{"phone":"13800000000","password":"123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")

# owner
OWNER_TOKEN=$(curl -sf http://172.22.1.123:18080/api/v1/auth/login \
  -X POST -H 'Content-Type: application/json' \
  -d '{"phone":"13800138000","password":"123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")

# b2b_admin
B2B_TOKEN=$(curl -sf http://172.22.1.123:18080/api/v1/auth/login \
  -X POST -H 'Content-Type: application/json' \
  -d '{"phone":"13900139000","password":"123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")
```

### 3. 核心端点验证

使用获取的 token 依次测试：

| 端点 | 角色 | 预期状态码 |
|------|------|-----------|
| `GET /me` | owner | 200 |
| `GET /farms` | owner | 200 |
| `GET /livestock?page=0&size=5` | owner | 200 |
| `GET /fences?page=0&size=5` | owner | 200 |
| `GET /alerts?page=0&size=5` | owner | 200 |
| `GET /dashboard/summary` | owner | 200 |
| `GET /admin/tenants?page=0&size=5` | platform_admin | 200 |
| `GET /admin/users?page=0&size=5` | platform_admin | 200 |
| `GET /b2b/farms` | b2b_admin | 200 |

```bash
curl -sf -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  http://172.22.1.123:18080/api/v1/me
```

### 4. 输出报告

```
## API 冒烟测试报告

### 连通性
- 服务: ✅ 可达 / ❌ 不可达

### 认证（3 个角色）
- platform_admin: ✅ token 获取成功 / ❌ 登录失败
- owner: ✅ token 获取成功 / ❌ 登录失败
- b2b_admin: ✅ token 获取成功 / ❌ 登录失败

### 核心端点（9 个）
- [endpoint]: ✅ 200 / ❌ {status_code}
- ...

### 总结
✅ {n}/9 端点通过 / ❌ {n} 个失败
```

## 规则

- 登录失败时停止后续该角色的端点测试
- 逐一测试，不要并发（避免误判）
- 记录每个失败端点的实际 HTTP 状态码和响应 body 前 200 字符
