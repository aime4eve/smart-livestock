# NIX-324 订阅到期/降档双端提示 — 设计 Spec

> 版本：v1.0（2026-10-27）
> 原型：`docs/prototypes/2026-10-27-subscription-expiry-dual-surface-prototype.html`（**用户已确认**）
> 关联：NIX-323（订阅快照/Open API 档位）、NIX-325（到期导出权）、0237fc9a（RENEWAL_FAILED 补缴链路）
> 裁决依据：2026-10-26 到期行为三条（订阅端降档不拒绝+告警；管理端预警；不将就）+ 2026-10-27 试点授权链核对

---

## 1. 目标与非目标

**目标**：租户端（Flutter App）在订阅临期/到期/降档/待补缴时看到分级提示与正确 CTA；platform_admin 管理端看到全租户订阅健康度预警视图。

**非目标**：邮件/短信/推送外呼；到期导出权本体（NIX-325 已交付，本单只接入其 API）；b2b_admin 全租户视图（b2b_admin 归订阅端，只见本租户）。

## 2. 状态判定规则（全单最高优先级约束）

**禁用裸 `status` 字段做任何 UI 判定。** 统一使用后端计算的订阅健康度聚合（§4），其判定矩阵如下（与 `TenantSubscriptionResolver`/`SubscriptionExportPolicy` 同口径，代码层共享一个判定器）：

| # | 条件（按序判定，命中即停） | 健康度 | 端 | 展示 |
|---|---|---|---|---|
| 1 | `status=TRIAL && trialEndsAt>now` | `trial` | 双端 | 试点中（info 蓝）；剩余 ≤14/7/3 天复用分级色 |
| 2 | `status=RENEWAL_FAILED` | `renewal_failed` | 双端 | 待补缴（warn 橙），CTA=补缴（changeTier 链路）；**无导出权卡** |
| 3 | `status=CANCELLED` | `cancelled` | 双端 | 已取消（danger 红），CTA=重新订阅 |
| 4 | `status=ACTIVE/TRIAL/FREE 且期限列(trialEndsAt|expiresAt)已过` 或 `status=EXPIRED/CANCELLED 后 30 天内` | `expired` | 双端 | 已到期降档（danger 红）+ **导出权卡**（窗口=终止+30d，倒计时进度） |
| 5 | `ACTIVE/TRIAL && 期限剩余 ≤14 天` | `expiring_soon`（含 level=14/7/3） | 双端 | 临期分级横幅（info→warn→danger） |
| 6 | 其余 | `healthy` | 双端 | 无横幅 |

硬规则（评审发现沉淀）：TRIAL 过期后 status 列仍为 TRIAL（无人自动翻转），**必须用墙钟判定**；`grantTrial` 重授后回到态 1（8f2d45a0 起重授同时重置 tier=BASIC）。

## 3. 设计令牌（锁定，与原型一致）

沿用 `docs/design-tokens.md` 全局令牌；本单新增语义色对：

| 令牌 | 值 | 用途 |
|---|---|---|
| `--health-ok` | `#4C9A5F`（=--success） | 健康徽标 |
| `--health-trial` | `#4A7F9D`（=--info） | 试点/待补缴徽标 |
| `--health-warn` | `#D28A2D`（=--warning） | 临期 14/7 |
| `--health-danger` | `#C2564B`（=--danger） | 临期 3/到期降档 |
| `--banner-info-soft` | `#E2EDF4` | info 横幅底 |
| `--banner-warn-soft` | `#F7EDDD` | warn 横幅底 |
| `--banner-danger-soft` | `#F7E5E2` | danger 横幅底 |

## 4. API 契约

### 4.1 租户端：扩展 `GET /subscription`（不新增端点）

响应新增 `health` 聚合块（commerce 域 `SubscriptionQueryService` 计算，判定器与 NIX-323/325 共享）：

```jsonc
"health": {
  "healthStatus": "trial|renewal_failed|cancelled|expired|expiring_soon|healthy",
  "level": 14,                    // 仅 expiring_soon：14/7/3
  "trialActive": true,            // 墙钟判定
  "effectiveTier": "PREMIUM",
  "daysToExpiry": 340,            // ACTIVE 锚 expiresAt；TRIAL 锚 trialEndsAt
  "degraded": false,              // 到期降档生效中（basic 回落）
  "exportWindow": {               // 仅 expired：NIX-325
    "terminatedAt": "...", "windowEndsAt": "...", "daysLeft": 20,
    "latestJob": { "jobId": 3, "status": "COMPLETED", "downloadedAt": null }  // 可空
  }
}
```

### 4.2 管理端：新增 `GET /admin/subscription-overview`（独立端点，不动 /admin/tenants 契约）

platform_admin 专用。分页 + `?health=`（trial|renewal_failed|expired|expiring_soon|healthy|all，默认 all）+ `?keyword=`。**排序**：expiring_soon 按剩余天数升序；**同日到期分组**（平台统一截止日批量到期场景）组内按租户名排序，行内显示 `sameDayGroup: true`。行字段：tenantId/name、tier/healthStatus/pill 级别、到期时间、daysToExpiry、exportWindow 摘要。

### 4.3 管理端不新增写操作；导出任务详情复用 `/admin/data-export-jobs`（NIX-325 已交付）。

## 5. 组件视觉规格

**租户端横幅**（四型，语义色对见 §3）：圆角 12、内边距 12、左侧 8px 状态圆点、标题 13/700、正文 12/1.55、CTA 主按钮（--primary 底白字）+可选 ghost 按钮；出现位置=订阅页顶部（首页横幅 Phase 2 评估，本单只做订阅页，避免首页信息噪音——⚠ 若用户要首页横幅为必做请指出）。

**订阅状态卡**：行式 k/v 列表，13px，分隔虚线 --border；徽标 pill 11/700 圆角 999。

**导出权卡**：虚线 --info 边框、标题含 ⬇ 图标、进度条 6px（--info-soft 底 / --info 填充，宽度=剩余天数比例）、CTA「发起全量导出」。

**管理端表格**：四色 pill（--health-*）、顶部筛选 chips（active 态 --primary 底白字）、行 hover --primary-soft、图例页脚；同日到期行加分组分隔。

**Flutter 组件落位**：横幅=订阅页新增 `SubscriptionHealthBanner`；状态卡扩展既有订阅页；导出权卡=`ExportEntitlementCard`；i18n 中英 ARB 同步（key 前缀 `subscriptionHealth.`）。

## 6. 验收标准

1. 判定矩阵 #1–#6 逐态实测（改库造态）：双端展示与矩阵一致；TRIAL 过期未翻转**不显示**"试点中"（裸 status 回归项）。
2. grantTrial 重授后横幅回到试点态（8f2d45a0 链路回归）。
3. 导出权卡倒计时与 NIX-325 job 状态联动（请求→COMPLETED→已下载状态变化可见）。
4. RENEWAL_FAILED 补缴→ACTIVE 后横幅消失（0237fc9a 链路回归）。
5. 管理端筛选/排序/同日分组正确；与 subscriptions 表逐条对账抽查。
6. `flutter analyze` 零告警；gen-l10n 无缺失 key；中英文案双语齐。
7. 新 UI 可达性倒查：owner 从「订阅管理」1 次点击到达；platform_admin 从管理后台租户菜单到达。

## 7. 开放问题（⚠ 待裁决，不阻塞 spec 批准）

- ⚠ 首页是否也要横幅（本 spec 默认仅订阅页）？
- ⚠ 临期分级阈值 14/7/3 是否需要可配置（当前硬编码常量）？
- ⚠ 管理端"发送续费提醒"按钮：Phase 1 置灰占位（外呼非目标），还是先做站内信？默认置灰。
