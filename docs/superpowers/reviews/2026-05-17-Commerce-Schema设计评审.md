# Commerce 数据库 Schema（Section 2）设计评审

**评审对象**: Section 2 — 数据库 Schema（Commerce 上下文新增表）
**日期**: 2026-05-17

---

## 一、总体评价

表结构设计扎实，字段类型、约束、索引覆盖合理。与 Section 1 模型对应关系清晰。以下为需调整和建议优化的项目。

---

## 二、需修改

### 2.1 revenue_periods 双方确认机制

**现状**: `confirmed_by_platform` + `confirmed_by_partner` 两个布尔值做双方确认
**问题**: 缺少状态机防护——settled_at 已填充但 confirmed_by_partner 仍为 false 时数据不一致
**建议**: 去掉两个布尔值，改用 status 状态机统一管控：

```
pending → platform_confirmed → partner_confirmed → settled
```

或保留布尔值但加 CHECK 约束：

```sql
CHECK (settled_at IS NULL OR (confirmed_by_platform AND confirmed_by_partner))
```

### 2.2 updated_at 自动更新机制

**现状**: `DEFAULT NOW()` 仅在 INSERT 时生效，UPDATE 时不自动更新
**建议**: 明确选择以下方案之一：
- **方案A（数据库层）**: Flyway 中创建触发器函数
- **方案B（应用层）**: JPA `@PreUpdate` 注解处理

```sql
-- 方案A 触发器
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
```

涉及表：subscriptions、contracts、subscription_services

---

## 三、建议修改

### 3.1 subscriptions.billing_cycle 加默认值

**现状**: `billing_cycle VARCHAR(20)` 允许 NULL
**问题**: direct 模式的 Standard/Premium 订阅没有明确计费周期
**建议**:

```sql
billing_cycle VARCHAR(20) NOT NULL DEFAULT 'monthly',
```

Enterprise 允许为空，通过应用层校验而非数据库 NULL。

### 3.2 contracts 加 contract_number

**现状**: 仅 BIGSERIAL id
**问题**: 纯数字 id 不适合 B2B 商务沟通场景
**建议**:

```sql
contract_number VARCHAR(30) NOT NULL, -- CT-YYYY-NNNN
CONSTRAINT uq_contracts_number UNIQUE (contract_number)
```

### 3.3 subscriptions 补充索引

```sql
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_expires ON subscriptions(expires_at) WHERE status = 'active';
```

后者是部分索引，用于定时任务扫描即将过期的订阅。

---

## 四、文档对齐说明

### 4.1 feature_gates 存储层与 domain 层差异

Section 1 中 FeatureGate 是 Subscription 聚合根下的值对象，Section 2 中 feature_gates 是独立全局配置表。这不是错误——实现比模型更合理：

- **存储层**: feature_gates 是全局配置表，按 tier 定义能力模板
- **domain 层**: FeatureGate 作为 Subscription 的值对象，通过 tier 查询 feature_gates 表构建

建议在文档中明确这个映射关系。

---

## 五、可选优化

### 5.1 subscription_services.service_key_prefix

存 SHA-256 hash 后无法反查原始 key，如果需要展示 key 片段（如 `sk-****-abcd`）：

```sql
service_key_prefix VARCHAR(8), -- 存 "sk-abcd" 前缀用于展示
service_key_hash VARCHAR(64) NOT NULL,
```

如无此需求可忽略。

---

## 六、评审结论

| 严重度 | 项目 | 位置 |
|--------|------|------|
| 需修改 | revenue_periods 确认机制 | 2.1 |
| 需修改 | updated_at 自动更新 | 2.2 |
| 建议改 | billing_cycle NOT NULL DEFAULT | 3.1 |
| 建议改 | contracts 加 contract_number | 3.2 |
| 建议改 | subscriptions 补充索引 | 3.3 |
| 文档对齐 | feature_gates 两层说明 | 4.1 |
| 可选 | service_key_prefix | 5.1 |

其余表结构（subscriptions、feature_gates、contracts、revenue_periods、subscription_services、tenant ALTER、种子数据）无问题。
