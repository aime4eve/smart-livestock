# 健康整合最终形态实施计划（NIX-246）

> Spec：`docs/superpowers/specs/2026-09-23-health-integration-final-spec.md`（**v1.2**，F1-F21 + 裁决 23/24 方案 D）
> 原型（视觉蓝本）：`docs/prototypes/health-scenario-alert-integration-prototype.html`（屏 1/1b = 方案 D 晨报看板，2026-09-24 重绘）
> 纪律：实现与原型不一致时，先改原型+清单再确认（R-G5）；每阶段部署 dev + 浏览器走查后才进下一阶段。

## Phase 0 · 基线与分支

- [x] 工单 NIX-246 立项（2026-09-23；原自称 NIX-245 的编号已被定价工单占用，spec/评审/plan 三份已同步改号）；分支 `nix/246-health-integration`
- [ ] **前置一（F2/P0）**：NIX-243（PR #110）合入并验证 AI 评分产出——未就绪则 Phase 2/3/4 的 AI 元素按空态交付
- [x] **前置二（F9/F20）**：原型补第七屏（S5 排行页=屏 6）与 S1 展开态画面（屏 1b）——2026-09-23 已补，用户确认通过；**2026-09-24 屏 1/1b 按方案 D 重绘（裁决 23），用户确认通过**
- [ ] 全量测试基线记录（19 个既有失败清单）

## Phase 1 · 后端数据层（无 UI 变化，可独立验证）

- [ ] 病程聚合端点 `GET /farms/{farmId}/health/episodes`（**发热/消化/发情三页共用**；含活跃单/AI 档位/未读/hasActiveHealthAlert）
- [ ] 疫病专用端点 `GET /farms/{farmId}/health/epidemic/summary`（异常率/阈值/安全状态/密接计数；farm 级，不共用 episodes）
- [ ] `/health/overview` sceneSummary 增 activeAlertCount、AI 卡 aiAlertCount（与 summary 同源，按 origin 过滤）
- [ ] **origin 枚举列**（RULE/AI）：Flyway 迁移 + 历史回填（source='RULE'→RULE、健康类其余非空→AI、fence 'DATAGEN'→RULE）+ GROUP_HEALTH/筛选切换 + 单测（F21；与 NIX-243 source 修复合并对齐）
- [ ] **dismiss 权限扩展**：`AlertController` dismiss 端点 @PreAuthorize 从 OWNER/B2B_ADMIN 扩展到 WORKER + 单测（裁决 14/F1，操作行后端前置）
- [ ] **详情页 health 区块聚合端点**：fever/digestive/estrus detail DTO 合并为单端点（F18 定案合并，减请求数）+ 单测
- [ ] **开单去重**：createAlert 内 (livestock, type, ACTIVE) 查重，规则+AI 统一 + 单测（F5）
- [ ] 疫情开单路径（7 天窗口 >10% 开单、<5% 解决、farmId+EPIDEMIC+ACTIVE 去重；接 farm 级重载）+ 单测
- [ ] 自愈任务 `HealthAlertReconcileScheduler`（每小时：快照已恢复但 ACTIVE 健康单未关 → 调 RanchCommandPort.resolveAlert；疫情单走率回落分支；多实例并发防护）+ 单测（F4）
- [ ] 健康率口径修复（**定位明确**：getOverview/getStats 两处套用 activeLivestockIds 过滤 + 共享"观察态算健康"枚举函数）（F3）
- [ ] AI 档位 band/finding 字段（后端出，前端不再自行算；0.3 阈值常量；词表以 abrupt_change/circadian_disruption/multivariate 为键）（F12）
- [ ] 围栏聚合后端实现（summary 扩展或新端点；旧四列表+三 detail 端点保留一期）（F16）
- [ ] 编译 + 目标测试（失败集合不扩大）+ 部署 dev + curl 冒烟（episodes/epidemic summary/overview/疫情规则）

## Phase 2 · 牧场页概览（S1，方案 D 晨报看板）

> 2026-09-24 裁决 23：概览布局按方案 D 重做（A+C 整合）。此前迭代（dash 四卡/状态行告警行，commit 9f6754d2 及更早）为中间产物，最终形态以本节为准；后端数据层（场景 activeAlertCount、AI 卡、episodes、红点、重定向）沿用不返工。

- [ ] **Hero 晨报卡**：深绿渐变（#1C3F25→#2F6B3B→#3E7F4C）+ 日期/牧场名 + 按健康率生成标题（≥95%「牧场一切平稳」/「N 只需要关注」，裁决 24）+ 副标（X/Y 只健康 · N 个围栏需要巡查，围栏去重数）+ 健康率环形进度（#8FD694，Flutter 用 SizedBox+CustomPainter 或.percent_indicator 类组件 1:1）+ 两枚 chip（头在养/设备在线）
- [ ] **一行三色告警瓷砖**：红（围栏，渐变底白字+未读白底角标）/ 橙（健康）/ 白（设备，0 时灰数字+绿"正常"，>0 升橙底）；小节标题"需要处理 · 共 N 起"；点击 → 告警中心对应分类
- [ ] **2×2 场景卡**：场景主题色图标底 + 名称 + 状态胶囊（平稳绿/N 只异常橙/含严重红）+ 人话副标（发热拆发烧/低热/持续超时；平稳固定语）；点击 → /health/{scene}
- [ ] **AI 摘要卡**：🤖 + 标题 + "谁最需要关注 ›"（→ S5）+ 摘要句 + 档位胶囊（NIX-243 未就绪走空态）
- [ ] **对账提示**：仅场景异常数 ≠ 活跃单数时渲染琥珀条（牛级折叠口径，F5；替换现常驻绿条）
- [ ] 面板展开态与收起态同构（**五格统计取消**，数字并入 Hero/瓷砖小标题；旧 stat5 实现如有残留一并移除）
- [ ] 地图标记：有活跃健康单加红点（数据源 episodes/summary hasActiveHealthAlert）
- [ ] /twin 9 条路由重定向（映射表 spec §2.1）+ 建场向导落点改 /ranch + 孪生页删除
- [ ] 底部导航未读红点（badge 新增，数据源 summary）（F19）
- [ ] ARB 双语新增（Hero 标题两态/副标模板/瓷砖文案/场景副标模板/对账不一致文案）+ gen-l10n 零缺失
- [ ] FarmScoped 规则核查（新 controller 全部继承基类）
- [ ] build_web + deploy dev + 浏览器走查（视觉对照原型屏 1/1b 1:1 + 对账数字与告警中心一致 + Hero 标题两态切换验证）

## Phase 3 · 管理台 + 详情页融合（S2/S3a/S3b）

- [ ] 管理台通用行组件（**三页共用**：异常行/已恢复组（resolvedAt 派生）/折叠正常/对账条/未读点/"只看未读"按钮）
- [ ] **管理台新路由**：/health/fever、/health/digestive、/health/estrus、/health/epidemic 四条（spec §2/§2.1；旧 /twin/{scene} 重定向已在 Phase 2 铺垫）
- [ ] 发热管理台（含"只看未读"）→ 消化 → 发情（配种语气，对账条"发情活动 N 只 · 高分 M 只"，高分阈值与健康率口径共用常量，F13）→ 疫病（专用 summary + 规则卡 + 密接空态）
- [ ] 牲畜详情页重构：健康区双态（常态三格卡 / 病程态多卡按 severity→场景序，F6）；病程卡（四格值/趋势图发烧段标红/AI 观察三格（NIX-243 未就绪走空态文案）+一句话/时间线/**操作行：处理=dismiss（Phase 1 已扩展 WORKER 权限）、忽略=markRead**、定位、轨迹）（F1/P0）
- [ ] 深链锚点 `?section=health`（ensureVisible + 30s 刷新竞态处理，spec §5.12）
- [ ] 内容迁移清单逐项验收：体温曲线、胃蠕动曲线、发情曲线（Premium+）、发烧时长图（Standard+）、消化热力图（Standard+）、结论/建议文案、AI 卡（技术字段移出 UI 改"AI 观察三格"，F10/裁决 20）、AI 曲线、30s 自动刷新、门控矩阵（含密接 Premium+ 随迁）
- [ ] 三张场景详情页 + 密接整页退役 + 深链重定向（spec §2.1 映射表）
- [ ] 详情级五 Controller 迁移 FarmScopedAsyncNotifier（F17）
- [ ] i18n 还债：孪生迁移内容入 arb；assessRiskLevel 改枚举 + 前端比较改枚举（F15）
- [ ] 用药记录按钮不实现（已裁决移除）
- [ ] 测试（管理台/详情页既有测试迁移）+ 部署 dev + 浏览器走查全区块

## Phase 4 · 告警中心改版（S4）+ AI 排行（S5）

- [ ] 三级别统计 cells + 对账行移除（据实形态，F14）；两行三标签页（围栏放牧/动物健康/设备健康，数字+未读角标）
- [ ] 告警列表日期分组头（原型补录，F14）
- [ ] 健康条目改通知行（点击 → /livestock/{id}?section=health）；围栏/设备保持现有弹层
- [ ] 围栏牛×围栏聚合卡（默认聚合、点开明细、类型 chip 筛选保留；消费 Phase 1 后端聚合）
- [ ] AI 排行页"谁最需要关注"（档位降序；数据源 = episodes 聚合不限 scene 按 band→score 排序取 topN，不另建端点；**前置二原型补齐后实施**；NIX-243 未就绪走空态）
- [ ] summary 端点消费方核对（tab 数字/牧场卡/导航红点不变）
- [ ] 部署 dev + 浏览器走查（三屏数字一致 + 全跳转路径）

## Phase 5 · 文案人话化 + 收口

- [ ] 全量术语替换（评分/样本/模型名/仿真→演示数据，**管理员控制台与 admin 网关脚注豁免**）+ ARB 双语 + gen-l10n 零缺失 + flutter analyze
- [ ] 删除死代码（旧页面/旧组件/未用 provider）
- [ ] 文档：project-overview/deployment/user-journey 更新；知识库同步
- [ ] 全量测试对照基线；PR（等用户 dev 验收后合并，test 部署等通知）

## 风险与回滚

- 每阶段独立 PR 内分 commit，可按 Phase 回退；数据层向后兼容（新端点/新字段，旧 UI 不破坏）
- 告警中心统计块移除影响 V2 的对账行语义 → 数字家搬到牧场概览（已在 spec 记录）
- 详情页重构为最大风险点（功能与数据零删除验收清单兜底，裁决 20）
- NIX-243 合并时序风险：origin 列与 source 修复需合并窗口内对齐（F21 注意项）

## 附：评审发现 → plan 任务追溯（F1-F21 全覆盖对照）

| 发现 | 落点 |
|---|---|
| F1 处理=dismiss | P1 dismiss 权限扩展 WORKER；P3 操作行（处理=dismiss/忽略=markRead） |
| F2 NIX-243 前置 | P0 前置一；P2/P3/P4 AI 元素空态 |
| F3 健康率定位 | P1 健康率口径修复（getOverview/getStats+共享函数） |
| F4 自愈任务更正 | P1 HealthAlertReconcileScheduler（resolveAlert） |
| F5 去重+对账 | P1 createAlert 去重；P2 对账行牛级折叠 |
| F6 详情页双态 | P3 健康区双态+多卡排序 |
| F7 疫情独立 | P1 疫情专用 summary 端点+farm 级开单 |
| F8 密接空态 | P3 疫病密接空态文案（采集另立工单） |
| F9 S5 无蓝本 | P0 前置二（原型补第七屏）；P4 S5 任务 |
| F10 门控+零删除 | P3 门控矩阵含密接 Premium+ 随迁、AI 技术字段移出 UI |
| F11 路由补全 | P2 重定向映射表；P3 管理台新路由 /health/{scene} |
| F12 band 后端 | P1 band/finding 后端字段+0.3 常量 |
| F13 发情口径 | P3 发情对账条（高分阈值共用常量） |
| F14 告警中心现状+补录 | P4 三级别 cells+对账行移除、日期分组头；P3 只看未读按钮 |
| F15 i18n 还债 | P3 迁移内容入 arb+assessRiskLevel 枚举化 |
| F16 围栏聚合 | P1 后端聚合+旧端点保留一期；P4 聚合卡消费 |
| F17 红点/锚点/FarmScoped | P2 地图红点；P3 锚点+竞态、五 Controller 迁基类 |
| F18 合并端点定案 | P1 详情页 health 区块聚合端点 |
| F19 导航红点 | P2 底部导航 badge |
| F20 展开态原型 | P0 前置二；P2 展开态与收起态同构（方案 D，五格统计取消，裁决 23） |
| F21 字段/枚举/origin | P1 origin 枚举列+回填、AUTO_RESOLVED 措辞；P1/P3 字段用 createdAt 语义；P5 管理员控制台豁免 |
