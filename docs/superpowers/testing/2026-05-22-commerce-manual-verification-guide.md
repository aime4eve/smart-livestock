# Commerce 限界上下文手工验证测试指南

**目标读者**: 产品经理、QA、开发人员
**前置条件**: 服务已部署在 `http://<HOST>:18080`，数据库含种子数据
**种子账户**:

| 角色 | 手机号 | 密码 | Token 用途 |
|------|--------|------|-----------|
| 牧场主 (owner) | 13800138000 | password123 | App 端操作 |
| 平台管理员 (platform_admin) | 13800000000 | password123 | Admin 端操作 |

**变量约定**: 下文用 `$OWNER` 和 `$ADMIN` 代表对应角色的 JWT Token。

---

## 0. 准备工作

获取 Token（每次部署后需重新获取）：

```bash
# Owner Token
OWNER=$(curl -s -X POST http://<HOST>:18080/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"phone":"13800138000","password":"password123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])")

# Admin Token
ADMIN=$(curl -s -X POST http://<HOST>:18080/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"phone":"13800000000","password":"password123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])")
```

> 下文所有 `curl` 命令可追加 `| python3 -m json.tool` 格式化输出。

---

## 场景 1: B2C 直订阅（核心用户路径）

> 验证：新租户自动获得 14 天 Premium 试用 → 付费升级 → 取消

### 1.1 查看初始订阅（自动创建的试用）

```bash
curl -s http://<HOST>:18080/api/v1/subscription -H "Authorization: Bearer $OWNER"
```

**验证点**:
- `status` = `"TRIAL"`
- `tier` = `"BASIC"`（基础 tier）
- `effectiveTier` = `"PREMIUM"`（试用期间享有 Premium 权益）
- `trialEndsAt` ≈ 注册时间 + 14 天

### 1.2 查看定价方案

```bash
curl -s http://<HOST>:18080/api/v1/subscription/plans -H "Authorization: Bearer $OWNER"
```

**验证点**: 返回 4 个 Tier，价格正确：

| Tier | 月费 | 含牲畜数 | 超出单价 |
|------|------|---------|---------|
| BASIC | $0 | 50 | $0.40/头/月 |
| STANDARD | $14 | 200 | $0.30/头/月 |
| PREMIUM | $28 | 1000 | $0.15/头/月 |
| ENTERPRISE | -1（定制） | -1 | -1 |

### 1.3 付费订阅（Mock 支付）

```bash
curl -s -X POST http://<HOST>:18080/api/v1/subscription/checkout \
  -H "Authorization: Bearer $OWNER" \
  -H "Content-Type: application/json" \
  -d '{"tier":"STANDARD","billingCycle":"monthly"}'
```

**验证点**:
- `status` = `"ACTIVE"`
- `tier` = `"STANDARD"`
- `effectiveTier` = `"STANDARD"`
- `expiresAt` ≈ 当前时间 + 30 天

### 1.4 升级 Tier

```bash
curl -s -X PUT http://<HOST>:18080/api/v1/subscription/tier \
  -H "Authorization: Bearer $OWNER" \
  -H "Content-Type: application/json" \
  -d '{"tier":"PREMIUM"}'
```

**验证点**:
- 不传 `billingCycle` 也能成功（从现有订阅继承）
- `tier` = `"PREMIUM"`
- `billingCycle` 仍为 `"monthly"`

### 1.5 取消订阅

```bash
curl -s -X POST http://<HOST>:18080/api/v1/subscription/cancel \
  -H "Authorization: Bearer $OWNER"
```

**验证点**:
- `status` = `"CANCELLED"`
- `cancelledAt` 有值

### 1.6 取消后操作被拒绝

```bash
curl -s -X PUT http://<HOST>:18080/api/v1/subscription/tier \
  -H "Authorization: Bearer $OWNER" \
  -H "Content-Type: application/json" \
  -d '{"tier":"BASIC"}'
```

**验证点**: 返回 `STATE_CONFLICT`，消息包含 "CANCELLED"

### 1.7 查看用量

```bash
curl -s http://<HOST>:18080/api/v1/subscription/usage -H "Authorization: Bearer $OWNER"
```

**验证点**: 返回当前 tier 的牲畜配额和超量单价

---

## 场景 2: B2B 分润合同

> 验证：合同创建 → 签署 → 月度分润计算 → 三方确认 → 结算

### 2.1 创建合同草稿

```bash
curl -s -X POST http://<HOST>:18080/api/v1/admin/contracts \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{
    "tenantId": 1,
    "contractNumber": "CT-2026-0001",
    "billingModel": "revenue_share",
    "effectiveTier": "premium",
    "revenueShareRatio": 0.85
  }'
```

**验证点**:
- `status` = `"DRAFT"`
- `revenueShareRatio` = `0.85`（合作方获得 85%）
- `signedBy` / `signedAt` 为 null

### 2.2 修改草稿

```bash
curl -s -X PUT http://<HOST>:18080/api/v1/admin/contracts/{id} \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"revenueShareRatio": 0.80}'
```

**验证点**:
- `revenueShareRatio` 更新为 `0.80`
- 仅 DRAFT 状态可修改；ACTIVE 合同修改会返回 `STATE_CONFLICT`

### 2.3 签署合同

```bash
curl -s -X POST http://<HOST>:18080/api/v1/admin/contracts/{id}/sign \
  -H "Authorization: Bearer $ADMIN"
```

**验证点**:
- `status` = `"ACTIVE"`
- `signedBy` 有值
- `signedAt` 有值

### 2.4 计算月度分润

```bash
curl -s -X POST http://<HOST>:18080/api/v1/admin/revenue/calculate \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{
    "contractId": <contractId>,
    "periodStart": "2026-05-01",
    "periodEnd": "2026-05-31",
    "grossAmountCents": 500000
  }'
```

**验证点**:
- 总额 `grossAmount` = 500000（即 $5000.00）
- `platformShare` = 500000 × (1 - 0.80) = 100000
- `partnerShare` = 500000 × 0.80 = 400000
- `status` = `"PENDING"`

### 2.5 平台确认

```bash
curl -s -X POST http://<HOST>:18080/api/v1/admin/revenue/periods/{id}/confirm \
  -H "Authorization: Bearer $ADMIN"
```

**验证点**: `status` = `"PLATFORM_CONFIRMED"`

### 2.6 Partner 确认

```bash
curl -s -X POST http://<HOST>:18080/api/v1/revenue/periods/{id}/confirm \
  -H "Authorization: Bearer $OWNER"
```

**验证点**: `status` = `"PARTNER_CONFIRMED"`

### 2.7 合同状态变更（暂停/恢复/终止）

```bash
# 暂停
curl -s -X PUT http://<HOST>:18080/api/v1/admin/contracts/{id}/status \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"targetStatus":"SUSPENDED","reason":"测试暂停"}'

# 恢复
curl -s -X PUT http://<HOST>:18080/api/v1/admin/contracts/{id}/status \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"targetStatus":"ACTIVE","reason":"恢复"}'
```

**验证点**: 状态机只允许合法转换

---

## 场景 3: Licensed 独立部署服务

> 验证：服务配置 → 创建成功 → 配额调整

### 3.1 配置 Licensed 服务

```bash
curl -s -X POST http://<HOST>:18080/api/v1/admin/subscription-services \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{
    "tenantId": 1,
    "serviceName": "GPS Tracking System",
    "tier": "premium",
    "deviceQuota": 500,
    "serviceKey": "my-license-key-secret"
  }'
```

**验证点**:
- `status` = `"PROVISIONED"`
- `effectiveTier` = `"premium"`（小写，与 DB 约束一致）
- `serviceKeyPrefix` = SHA256 哈希前 8 位
- `deviceQuota` = 500

### 3.2 查看服务列表

```bash
curl -s http://<HOST>:18080/api/v1/admin/subscription-services \
  -H "Authorization: Bearer $ADMIN"
```

### 3.3 调整配额

```bash
curl -s -X PUT http://<HOST>:18080/api/v1/admin/subscription-services/{id}/quota \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"deviceQuota": 1000}'
```

**验证点**: `deviceQuota` 更新为 1000

---

## 场景 4: 功能门控（Feature Gates）

> 验证：4 种 gateType 的配额控制逻辑正确

### 4.1 查看功能门控配置

```bash
curl -s http://<HOST>:18080/api/v1/admin/feature-gates \
  -H "Authorization: Bearer $ADMIN"
```

**验证点**: 返回 28 条种子数据（4 Tier × 7 Feature），每种 gateType 都存在：

| gateType | 含义 | 示例 |
|----------|------|------|
| `NONE` | 不限制 | enterprise 的所有功能 |
| `LOCK` | 开关控制 | basic 的 `health_monitoring` (isEnabled=false) |
| `LIMIT` | 数量限制 | basic 的 `livestock_management` (limitValue=50) |
| `FILTER` | 数据时间范围裁剪 | standard 的 `advanced_analytics` (retentionDays=30) |

### 4.2 修改门控配置

```bash
curl -s -X PUT http://<HOST>:18080/api/v1/admin/feature-gates/{id} \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"limitValue": 100}'
```

**验证点**:
- `limitValue` 更新成功
- `createdAt` 不被清空

### 4.3 关闭功能

```bash
curl -s -X PUT http://<HOST>:18080/api/v1/admin/feature-gates/{id} \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"isEnabled": false}'
```

**验证点**: `isEnabled` = false

---

## 场景 5: 配额引擎端到端验证

> 验证：订阅不活跃时 Ranch 操作被拒绝

### 前置：确保订阅活跃

```bash
curl -s http://<HOST>:18080/api/v1/subscription -H "Authorization: Bearer $OWNER"
# 如果不是 ACTIVE，通过 checkout 激活：
curl -s -X POST http://<HOST>:18080/api/v1/subscription/checkout \
  -H "Authorization: Bearer $OWNER" \
  -H "Content-Type: application/json" \
  -d '{"tier":"BASIC","billingCycle":"monthly"}'
```

### 5.1 正常创建围栏（配额内）

```bash
curl -s -X POST http://<HOST>:18080/api/v1/farms/<farmId>/fences \
  -H "Authorization: Bearer $OWNER" \
  -H "Content-Type: application/json" \
  -d '{"name":"测试围栏","coordinates":[...]}'
```

**验证点**: 创建成功（BASIC tier 允许 5 个围栏）

### 5.2 挂起订阅后操作被拒

```bash
# Admin 挂起订阅
curl -s -X PUT http://<HOST>:18080/api/v1/admin/subscriptions/{id}/status \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"targetStatus":"SUSPENDED","reason":"测试配额引擎"}'

# 尝试创建围栏 → 应被拒绝
curl -s -X POST http://<HOST>:18080/api/v1/farms/<farmId>/fences \
  -H "Authorization: Bearer $OWNER" \
  -H "Content-Type: application/json" \
  -d '{"name":"应该失败","coordinates":[...]}'
```

**验证点**: 返回 `QUOTA_EXCEEDED` 或 `订阅状态非活跃`

> 测试完毕后记得恢复订阅状态。

---

## 场景 6: 边界与异常测试

### 6.1 非法状态转换

```bash
# 尝试签署已签署的合同
curl -s -X POST http://<HOST>:18080/api/v1/admin/contracts/{id}/sign \
  -H "Authorization: Bearer $ADMIN"
```

**验证点**: 返回 `STATE_CONFLICT`

### 6.2 分润比例越界

```bash
curl -s -X POST http://<HOST>:18080/api/v1/admin/contracts \
  -H "Authorization: Bearer $ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"tenantId":1,"contractNumber":"CT-TEST","billingModel":"revenue_share","effectiveTier":"premium","revenueShareRatio":1.5}'
```

**验证点**: 返回 `INVALID_REVENUE_SHARE_RATIO`（比例必须 > 0 且 < 1）

### 6.3 重复确认结算

```bash
curl -s -X POST http://<HOST>:18080/api/v1/admin/revenue/periods/{id}/confirm \
  -H "Authorization: Bearer $ADMIN"
# 连续调用第二次
curl -s -X POST http://<HOST>:18080/api/v1/admin/revenue/periods/{id}/confirm \
  -H "Authorization: Bearer $ADMIN"
```

**验证点**: 第二次返回 `STATE_CONFLICT`

### 6.4 未认证访问

```bash
curl -s http://<HOST>:18080/api/v1/subscription
```

**验证点**: 返回 401 Unauthorized

---

## 验证清单

完成以上场景后，用此清单确认核心需求：

> **测试日期**: 2026-05-22
> **测试环境**: http://172.22.1.123:18080 (Spring Boot)
> **第一轮（部署前）**: 部署版本未包含 commit `0fc4ed7` 修复 → 8 PASS / 6 FAIL / 2 PARTIAL / 2 SKIP
> **第二轮（重新部署后）**: commit `0fc4ed7` 修复已部署 → 14 PASS / 2 FAIL / 2 PARTIAL
> **第三轮（修复部署后）**: V7 迁移 + SecurityConfig 401 修复 + 注释修正 → 18 PASS

- [PASS] **SC-1** 新租户自动创建 14 天 Premium 试用订阅 — ~~种子数据 ACTIVE/PREMIUM~~ V7 迁移修正试用期 + 重置数据库后 PASS：status=TRIAL, tier=BASIC
- [PASS] **SC-2** 试用期间 effectiveTier = PREMIUM，tier = BASIC — 第三轮验证 PASS：effectiveTier=PREMIUM（试用享有高级权益）
- [PASS] **SC-3** Mock 支付后订阅变为 ACTIVE — checkout STANDARD → ACTIVE，tier/expiresAt 正确
- [PASS] **SC-4** Tier 升降级无需传 billingCycle — ~~返回 VALIDATION_ERROR（修复未部署）~~ 重新部署后 PASS：tier=PREMIUM, billingCycle=monthly 继承正确
- [PASS] **SC-5** 取消订阅后状态为 CANCELLED，后续操作被拒 — cancel → CANCELLED + cancelledAt 有值；changeTier → STATE_CONFLICT
- [PASS] **SC-6** 合同 DRAFT → ACTIVE 完整流程 — 创建 DRAFT → 签署 ACTIVE，signedBy/signedAt 正确
- [PASS] **SC-7** 合同草稿可修改字段 — ~~"not yet implemented"~~ 第三轮验证 PASS：ratio 0.90→0.75 更新成功
- [PASS] **SC-8** 分润计算正确（platformShare + partnerShare = grossAmount） — ~~NoSuchMethodError~~ 重新部署后 PASS：gross=500000, platform=75000, partner=425000, ratio=0.85
- [PASS] **SC-9** 分润三方确认状态机正确流转 — 重新部署后 PASS：PENDING → PLATFORM_CONFIRMED → PARTNER_CONFIRMED
- [PASS] **SC-10** Licensed 服务创建成功，effectiveTier 为小写 — ~~约束违反~~ 重新部署后 PASS：effectiveTier="premium", status=PROVISIONED, serviceKeyPrefix="1eff3852"
- [PASS] **SC-11** Licensed 服务配额可调整 — 重新部署后 PASS：激活服务 → ACTIVE，deviceQuota 500→1000
- [PASS] **SC-12** 28 条 feature_gates 种子数据正确 — 4 Tier × 7 Feature = 28 条
- [PASS] **SC-13** FeatureGate 更新不丢失 createdAt — ~~null constraint~~ 重新部署后 PASS：limitValue=50→100 更新成功
- [PASS] **SC-14** 4 种 gateType 均有种子数据 — NONE/LOCK/LIMIT/FILTER 全部存在
- [PASS] **SC-15** 订阅挂起时 Ranch 操作被 QuotaInterceptor 拦截 — 创建围栏 → `QUOTA_EXCEEDED: 订阅未激活`
- [PASS] **SC-16** 非法状态转换返回 STATE_CONFLICT — 签署已签署合同 → `Cannot sign: expected DRAFT but was ACTIVE`
- [PASS] **SC-17** 分润比例越界返回校验错误 — ratio=1.5 → `INVALID_REVENUE_SHARE_RATIO`
- [PASS] **SC-18** 未认证请求返回 401 — ~~403 Forbidden~~ 第三轮验证 PASS：401 + `AUTH_INVALID_TOKEN`

### 最终统计

| 结果 | 数量 | 项目 |
|------|------|------|
| PASS | **18** | SC-1 ~ SC-18 全部通过 |
| FAIL | 0 | — |
| PARTIAL | 0 | — |

### 三轮测试历程

| 轮次 | PASS | FAIL | PARTIAL | 变更 |
|------|------|------|---------|------|
| 第一轮 | 8 | 6 | 2 | 部署版本不含 0fc4ed7 修复 |
| 第二轮 | 14 | 2 | 2 | 重新部署 0fc4ed7，4 项修复生效 |
| 第三轮 | **18** | 0 | 0 | V7 迁移 + AuthenticationEntryPoint + 注释修正 |

### 部署备注

重新部署过程中发现 `COPY build/libs/*.jar` 在多个 JAR 存在时 Docker 可能选中旧版本。已清理旧 JAR，仅保留最新版。建议优化 Dockerfile 指定精确文件名。

### 待修复项

~~全部已修复。无剩余待修复项。~~

---

## 常用操作速查

```bash
# 重置订阅为 ACTIVE（调试用，需直接操作数据库）
docker exec smart-livestock-server-postgres-1 psql -U postgres -d smart_livestock \
  -c "UPDATE subscriptions SET status='active', cancelled_at=null WHERE id=1;"

# 重置订阅为 TRIAL（验证试用功能）
docker exec smart-livestock-server-postgres-1 psql -U postgres -d smart_livestock \
  -c "UPDATE subscriptions SET status='trial', tier='basic', cancelled_at=null WHERE id=1;"

# 查看所有订阅状态
docker exec smart-livestock-server-postgres-1 psql -U postgres -d smart_livestock \
  -c "SELECT id, tenant_id, tier, status, billing_model FROM subscriptions;"

# 清空 Commerce 测试数据（保留种子）
docker exec smart-livestock-server-postgres-1 psql -U postgres -d smart_livestock \
  -c "TRUNCATE revenue_periods, contracts, subscription_services RESTART IDENTITY CASCADE;"
```

---

*适用版本: 0fc4ed7 (feat/flutter-springboot-adaptation)*
*部署版本: b14（包含 0fc4ed7 修复 + V7 迁移 + AuthenticationEntryPoint）*
*设计规格: `docs/superpowers/specs/2026-05-18-commerce-context-design.md`*
*测试报告: 2026-05-22 — 三轮测试，最终 18/18 PASS*
