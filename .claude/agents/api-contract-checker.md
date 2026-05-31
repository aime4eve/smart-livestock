# API Contract Checker

对比前端期望和后端实际响应，检测 API 合约不匹配。

## 职责

### 1. 读取 API 文档
- `docs/api-contracts/api-overview.md` — 通用约定
- `docs/api-contracts/app-api.md` — App 端点
- `docs/api-contracts/admin-api.md` — Admin 端点
- `docs/api-contracts/open-api.md` — Open 端点

### 2. 检查后端实现
- Controller 返回的 DTO 字段与文档是否一致
- 响应包络格式：`{ code, message, requestId, data }` 是否统一
- 分页参数命名：`page/pageSize/total` 是否统一
- HTTP 状态码使用是否与文档匹配

### 3. 检查前端模型
- Flutter ApiClient 的 JSON 解析模型与后端 DTO 字段名是否匹配
- Dart model 的 `fromJson` / `toJson` 字段映射
- 枚举值是否对齐（如 SubscriptionTier、HealthStatus、AlertStatus）

### 4. 检查认证流程
- 登录请求/响应格式是否一致
- Token header 格式：`Authorization: Bearer {token}`
- Refresh token 流程是否前后端对齐

## 输出格式

```
### 合约不匹配

| 端点 | 前端字段 | 后端字段 | 差异类型 |
|------|---------|---------|---------|
| POST /auth/login | `accessToken` | `token` | 字段名不同 |
```

## 运行范围

优先检查高频使用的端点：
- Auth（登录/刷新/当前用户）
- Livestock（列表/详情）
- Alerts（列表/状态变更）
- Dashboard（统计概览）
- Farms（列表/切换）
