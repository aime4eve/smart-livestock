# 产品介绍截图拍摄清单（2026-11-05 · test 环境 172.22.1.123:18080）

- 账号：owner 13800138000（Demo 租户 1 · HKT Main Ranch / Pampas Steppe）；管理端 13800000000
- 会话方式：API 登录后 localStorage 注入（flutter.* 双重 JSON 编码），非人工造态——
  数据为 test 库既有演示数据（Demo Ranch 种子 + DATAGEN 长期仿真 + 疫病演练种子），未写库、无需恢复
- 规格统一：1440×900 视口 @2x（2880×1800），locale zh-CN，Chrome（Playwright executable_path）
- 图注口径：界面版本 = test 当前部署（v0.6.1-b805+），全部演示数据

| 文件 | 页面/路由 | 账号 | 画面要点 |
|---|---|---|---|
| fig-3-1-map.png | /ranch 牧场概览（首屏） | owner | 高德底图+围栏2多边形+牲畜标记+Hero（92% 健康率/13 头/100% 在线）+需要处理三类+告警 8 角标 |
| fig-3-2-twin.png | /twin/epidemic 疫病防控 | owner | 疑似源头 ST-21（演练种子）+四级处置队列+处置/记录/链路 tab+应急报告入口 |
| fig-3-3-fever.png | /twin/fever/1 体温详情 | owner | 当前 38.3℃/基线 38.5/状态正常+72h 体温曲线+发热持续时长分析 |
| fig-3-4-alerts.png | /alerts 告警中心 | owner | 严重/警告/信息/已消解四分桶+告警列表（围栏/健康/设备） |
| fig-3-5-ai.png | /twin/fever/1 体温详情（滚动） | owner | AI 异常检测卡（指数 0.5%/样本 48/health_l1）+异常指数趋势+阈值线（规则+AI 双轨） |
| fig-3-6-admin.png | /ops/admin 平台后台 | platform_admin | 左侧导航+租户列表（荣丰合作社/Demo Ranch） |
| fig-7-2-download.png | /login 登录页（登出态） | — | BoviScout v0.6.1 登录卡+底部三下载渠道（App/APK/IPA） |

## 与原方案差异（两处，已在 NIX-374 评论区同步）
1. 图 3-2 原「数智孪生首页」：NIX-245 后孪生总览已并入牧场页（/twin 301 → /ranch），且 Demo 群体当前无发热个体（发热列表为空态）→ 改拍疫病防控场景页（健康场景代表，图注相应调整）
2. 图 3-5 AI 双轨：由独立页面改为体温详情页滚动区（AI 异常卡挂载在个体健康详情页，livestock_detail_sheet / fever_detail_page）

## 验收后修正（2026-11-05 二轮）

1. **fig-3-3-fever.png**：裁切至 2880×1050（保留三统计卡+72h 曲线主体）。原因：柱状图 y 轴 21h/20h 刻度重叠为产品 UI 图表缺陷（visual-judge 抓到），对外文档取景规避；缺陷已记 NIX-374 待另立修复工单
2. **fig-3-6-admin.png**：重拍为 platform_admin 租户列表后做像素级脱敏——「南非-市场」租户联系人显示真实人名（用户本人），已用卡片底色覆盖人名置空（联系人字段可为空，观感自然），保留「联系人：」前缀
3. **特别事项待裁决**：fig-3-1 地图右上角有「高德」底图角标（演示牧场在中国境内自动选高德图源）。对外文档嵌入是否需替换图源（OSM）或加图注声明，由用户裁决

## 新制示意图（第二批 2026-11-06，P1×5 + P2×1，visual-judge 全过）

| 文件 | 对应章节 | 内容 |
|---|---|---|
| fig-1-1-landscape.png | §1.4 | 产品形态总览：可穿戴感知 → 平台 → 两种交付三段式 |
| fig-2-1-roles.png | §2.1 | 五类角色 × 三个操作端 |
| fig-4-1-telemetry.png | §4.3 | 设备接入链路（五节点链 + 三旁路源 + 分析出口） |
| fig-4-2-deployment.png | §4.4 | HOSTED / ONPREM 两栏对比 |
| fig-6-1-plans.png | §6.1 | 四档套餐分层（产犊预警按红线标「推进中」；不含具体价格） |
| fig-alert-overview.png | 附录 A | 告警类型速览（14 类四组着色） |

## 素材缺口

- **fig-5-1 硬件全家福**：98-hkt-iot 仓（其他传感器线）与本仓均无畜牧硬件（胶囊/追踪器/耳标）实物照片或渲染图 → 需用户提供产品图（营销素材/ODM 渲染图），收到后按型号+认证状态核验入册
- **P2 数据上报节奏图**：裁定不做——上报频率信息已由 fig-5-2（佩戴示意图）与 fig-4-1（链路图箭头标注）覆盖，重复表述

## fig-5-1 补录（2026-11-06）

- 图源：hktlora.com 官网三个产品页主图（用户裁决来源）——瘤胃胶囊 `product/lorawan-rumen-bio-capsules`（bolus-main3.jpg）、GPS 追踪器 `product/lorawan-gps-cattle-tracker`（tracker-800x800.jpg）、智能耳标 `product/lorawan-ear-tag`（eartag-2.jpg，实拍佩戴场景）
- 原图存 `src/`（3 张）；组合图 fig-5-1-family.png（三卡横排+型号+来源注）
- 文档 §5.1 嵌入，20 页版；§5.2 因表格跨页断裂改为新页起（pageBreakBefore）
- 图序修正：第七章图 7-3→7-2（第七章仅两图）
