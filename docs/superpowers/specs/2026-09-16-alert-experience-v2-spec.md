# 告警体验升级 V2 · 设计规格（spec）

> 状态：已确认（阶段 2，2026-09-16 用户批准）
> 原型：`docs/prototypes/livestock-alert-experience-v2-prototype.html`（2026-09-16 已确认）
> 实施计划：`docs/superpowers/plans/2026-09-16-alert-experience-v2-plan.md`
> 本 spec 批准后 token 与口径表锁定，实施阶段不再变更视觉与口径。

---

## 1. Design Tokens（零新增，全部复用现有）

| Token | 值 | Flutter 对应 |
|---|---|---|
| --primary | #2F6B3B | AppColors.primary |
| --primary-dark | #244F2D | AppColors.primaryDark |
| --primary-soft | #E3F0E4 | AppColors.primarySoft |
| --surface / --surface-alt | #F8F6F0 / #FFFFFF | AppColors.surface / surfaceAlt |
| --border | #D7D2C6 | AppColors.border |
| --text-primary / --text-secondary | #263126 / #617061 | AppColors.textPrimary / textSecondary |
| --danger / --warning / --info / --success | #C2564B / #D28A2D / #4A7F9D / #4C9A5F | AppColors.danger / warning / info / success |
| --xs..--xxl | 4/8/12/16/24/32 | AppSpacing.xs..xxl |
| --radius-sm/md/lg | 8/12/16 | BorderRadius 8/12/16 |

---

## 2. 口径定义表（锁定）

| 数字 | 计算口径 | 数据源 |
|---|---|---|
| 活跃（汇总大数） | status=ACTIVE 告警全量总数（不分已读未读） | `GET /alerts/summary` → `active.total` |
| 未读（汇总大数） | 活跃 且 当前用户无 alert_read_status 记录 | `active.unread` |
| 严重 / 警告 / 提示 | 活跃 且 severity=CRITICAL / WARNING / INFO；**三者加总 ≡ active.total** | `active.critical / warning / info` |
| 牧场卡片数字 | 类型组活跃数：fence=FENCE_BREACH+FENCE_APPROACH+ZONE_APPROACH；health=TEMPERATURE_ABNORMAL+DIGESTIVE_ABNORMAL+ESTRUS+EPIDEMIC+AI_ANOMALY；device=DEVICE_TAMPER+DEVICE_LOW_BATTERY | `active.byGroup.*` |
| 牧场角标 / 卡片红点 | 同类型组的**未读**活跃数；为 0 时红点隐藏 | `active.byGroupUnread.*` |
| 底部"告警"tab 角标 | 未读活跃总数 | `active.unread` |
| 围栏聚合卡「N 头在栏外」 | 活跃 FENCE_BREACH 按 (livestockId,fenceId) 去重；「接近」=活跃 FENCE_APPROACH 同法 | `GET /ranch-overview` alerts 客户端聚合 |
| 已处理 | status ∈ {DISMISSED, AUTO_RESOLVED} | `resolved`；列表 `?status=RESOLVED` |
| 列表 total | 满足当前过滤条件的真实总数（不再截断 200） | `/alerts` 真分页 count |

**废弃口径**：「待处理」（alertSummaryPending）全面退役，被「活跃」取代。

---

## 3. 端点契约

### 3.1 新增 `GET /api/v1/farms/{farmId}/alerts/summary`

```json
{
  "code": "OK", "message": "success", "requestId": "...",
  "data": {
    "active": {
      "total": 14, "unread": 3,
      "critical": 13, "warning": 1, "info": 0,
      "byGroup":       { "fence": 13, "health": 1, "device": 0 },
      "byGroupUnread": { "fence": 2,  "health": 1, "device": 0 }
    },
    "resolved": 123
  }
}
```

- 未读用跨实体 JPQL 子查询（`NOT IN (SELECT alert_id FROM alert_read_status WHERE user_id=:uid)`）；
- 缓存 key `alerts:summary:{farmId}:{userId}`，TTL 10s，复刻 ranch-overview get→try/catch→DB→set 模式；
- markRead/batchRead/dismiss/autoResolve 写路径顺带删除该 key。

### 3.2 `GET /alerts` 真分页（响应封套不变）

| 参数 | 规则 |
|---|---|
| page | ≥1，默认 1 |
| pageSize | 默认 20，前端用 50，上限 200 |
| status | `ACTIVE` / `RESOLVED`（=DISMISSED OR AUTO_RESOLVED）/ `DISMISSED` / `AUTO_RESOLVED` |
| severity | `CRITICAL` / `WARNING` / `INFO`（本版真正生效） |

- items 按 id 倒序；`total` = 同过滤真实 count；
- `OpenAlertController` 同步真分页（保持无 read 富化语义）；
- 集成测试 total 断言在真分页后仍成立；`size` 参数名继续被忽略（与现状一致）。

---

## 4. 组件视觉规格

### 4.1 AlertSummaryHeader（替代 AlertSummaryStrip）
- hero 区：两格各 flex1，padding `10,12,8`，格间 1px border 竖分隔；数字 24px w700（活跃=primary、未读=danger），label 9px textSecondary；未读=0 时整格透明度 0.55；
- 三格行：padding `0,12,7`，gap 5；每格高 ~26px 圆角 6 背景 surface，内容 6px 圆点 + 数字 11px w700（danger/warning/info）+ 标签 9px textSecondary；选中态 border primary + 背景 primarySoft；INFO 常显；
- 对账行：8px textSecondary 居中 `{critical} + {warning} + {info} ＝ {total} 活跃 ✓`。

### 4.2 RefreshHint
- 高 ~20px，背景 surface 下边框 border；8px textSecondary 居中 + 10px 旋转圈（success 色 top arc）；文案两态：`每 30 秒自动更新 · 刚刚已刷新` / `已暂停（操作中）`。

### 4.3 FenceStatusCard（牧场告警 tab 顶部）
- 容器 margin `8,12,4`，圆角 12，边框 rgba(194,86,75,.25)，背景 surface-alt，shadow-card；
- 头部：30×30 图标位（danger 10% 底）+ 标题 11px w700 + 副行 9px（数字分别 danger/warning 加粗）+ chev；
- 明细行：8px 状态点（越界=danger、接近=warning）+ 编号 10px w600（宽 64）+ 围栏·状态 9px + 时间 8px + chev；
- 底部行动行：primarySoft 背景，9px w600 primaryDark `查看全部 {count} 条围栏告警 →`；
- 无活跃围栏告警时整卡隐藏；默认展开，可收起（不持久化）。

### 4.4 UnreadBadge
- 最小 15×15 胶囊圆角 8，danger 底白字 8px w700，padding `0,4`；≤0 隐藏；dash 卡右上 `6,6`。

### 4.5 LoadMoreFooter
- 按钮 10px w600 primary 字、primarySoft 底、圆角 8、padding `7,18`；加载中 12px 圈；无更多隐藏；
- meta 8px textSecondary `已显示 {shown} / {total} 条（活跃 {active} · 已处理 {resolved}）`。

### 4.6 空状态
- 64px 圆形 primarySoft ✅ + 标题 13px w700 `没有活跃告警` + 描述 10px 两行 + 按钮 `查看 {resolved} 条已处理记录`；RefreshHint 保留。

---

## 5. 页面与数据流

### 5.1 告警中心 alerts_page
- 默认 `_activeTab = active`；tab→status：活跃=ACTIVE、已处理=RESOLVED、全部=缺省；
- pageSize=50 上拉加载；筛选变化重置第 1 页；
- 汇总区数字独立于列表过滤（只来自 summary 端点）；
- `AutoRefreshListener(30s)` 包 body：非批量且无弹层时 `alertsController.silentRefresh()`（新方法，不置 AsyncLoading、保滚动）+ summary 静默刷；
- 全部已读：本地置活跃 items read=true + summary 静默刷新（未读归零）。

### 5.2 牧场页 ranch_page
- 新 `alertSummaryControllerProvider`（FarmScopedAsyncNotifier，watchActiveFarmId）；ranch 30s Timer 追加静默刷；
- 底部告警 tab 角标 = `active.unread`；三卡数字 = byGroup；红点 = byGroupUnread；
- 告警 tab = FenceStatusCard + 现有活跃事件简表；事件行点击 → 告警中心带 category 预筛选。

### 5.3 l10n 新增 key（zh 模板 + en 同步）
`alertSumActive` / `alertSumUnread` / `alertSumInfo` / `alertSumReconcile(a,b,c,total)` / `alertRefreshHint` / `alertRefreshPaused` / `alertRefreshedJustNow` / `alertLoadMore` / `alertShownOf(shown,total,active,resolved)` / `alertFenceStatusTitle` / `alertFenceAggSub(out,near)` / `alertFenceViewAll(count)` / `alertFenceStateOut` / `alertFenceStateNear` / `alertEmptyCta(count)`；
弃用 `alertSummaryPending`（保留 key 定义，移除代码引用）。

### 5.4 数据模型
新 `RanchAlertSummary`（lib/features/alerts/domain/），fromJson 容错（`?? 0`）；告警中心与牧场页共用同一 provider。

---

## 6. 交互规则（锁定）
1. 三格=级别筛选开关；「活跃」大数点击=清筛选回第 1 页；
2. 30s 刷新：后台暂停、回前台立刷、批量/弹层暂停、保滚动位置；
3. 聚合卡默认展开；「查看全部」带 category=fence；
4. 分页每页 50；筛选变化重置；
5. 全部已读后未读大数、红点、角标全归零。

## 7. 验收对照
严重+警告+提示=活跃=summary.total（含 INFO）；读一条未读三处同步 -1、全部已读全归零；DB>200 条时 total 真实；聚合卡数=overview 围栏告警去重数；30s 自动更新不打断滚动/批量；analyze 零新增、gen-l10n 零缺失、目标测试全绿、后端失败基线不扩大。
