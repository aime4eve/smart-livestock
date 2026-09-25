# NIX-246 围栏页视觉重构 · 方案 D Spec（晨报台账 × 形状沙盘）

> 原型：`docs/prototypes/nix-246-fence-tab-redesign-prototype.html`（方案 D 两态 + A/B/C 对照；基线三张）
> 裁决：方案 D 确认（A 骨架 + B 暗色仪表盘 + C 畜群分布整合）；A 保留为兜底形态归档。
> 原则：信息架构与现版完全一致，纯视觉升级；所有数据源已验证存在，无后端改动。

## 1. 信息架构（不变）

列表态：总账三格瓷砖 → 围栏卡片列表 → 对账行。
选中态：详情卡（暗色仪表盘 + 2×2 元数据 + 三操作位）→ 其余卡片半透明。
权限：`canManage=false` 隐藏新建/编辑/删除，其余不变（继承现版）。

## 2. 设计令牌表（确认后锁定）

### 2.1 颜色

| Token | 值 | 用途 | Flutter 落点 |
|---|---|---|---|
| `tile.green.grad` | `#2F6B3B → #3E7F4C` | 总账「围栏」瓷砖 | 复用概览 `_heroGrad2/3` 常量 |
| `tile.red.grad` | `#B3453B → #C9664F` | 总账「告警」瓷砖 | 复用概览 `_tileRed1/2` 常量 |
| `sandbox.bg.grad` | `#EAF3E6 → #DCE8D5` | mini 沙盘地形底 | 新增 `FenceSandboxTokens` |
| `panel.dark.bg` | `#14251A` | 详情暗色仪表盘底 | 同上 |
| `panel.grid` | `rgba(143,214,148,0.06)` / 16px 网格 | 暗盘坐标网格 | CustomPaint 画线 |
| `panel.scan` | `rgba(143,214,148,0 → 0.65 → 0)` | 扫描线渐变 | 线性渐变条 |
| `dot.safe` | `#4C9A5F` | 畜群点 · 正常 | 同 `AppColors.success` |
| `dot.watch` | `#D28A2D` | 畜群点 · 留意 | 同 `AppColors.warning` |
| `dot.alert` | `#C2564B` | 畜群点 · 告警/临近边界 | 同 `AppColors.danger` |
| `vertex.dot` | `#8FD694` | 多边形顶点标记（仅详情盘） | 新增 |
| `polygon.fill` | 围栏本色 `@16%`（列表）/ `@30%`（详情） | 沙盘多边形填充 | `color.withValues(alpha:)` |
| `polygon.stroke` | 围栏本色 100% | 沙盘边界虚线 | 同上 |

### 2.2 尺寸 / 圆角 / 字号

| Token | 值 | 说明 |
|---|---|---|
| `spine.width` | 3px | 卡片左侧围栏本色色脊（继承 A） |
| `sandbox.size` | 92 × 56 | 列表 mini 沙盘画布（与原型一致，原型即真源） |
| `panel.dark.height` | 108 | 详情暗盘画布高（与原型一致） |
| `radius.card` | 12 | 卡片圆角（`AppRadius` 现值） |
| `shadow.card` | `0 1 3 rgba(38,49,38,.06) + 0 1 2 .04` | D 卡片专用（概览瓷砖沿用黑影） |
| `shadow.elev` | `0 4 16 rgba(38,49,38,.12)` | 详情卡 |
| `dash.list` | `[4,3]`，描边 1.5 | 列表多边形虚线 |
| `dash.detail` | `[6,4]`，描边 2 | 详情多边形虚线 |
| `dot.radius` | 2（列表）/ 2.2（详情），告警点 2.4（列表）/ 2.6（详情） | 畜群点半径 |
| 阴影继承说明 | 总账瓷砖沿用概览黑影；D 卡片阴影用 `rgba(38,49,38,.06/.04)` | tile vs card |
| 字号 | 沿用现版：行名 11/700、元信息 9、瓷砖 big 19/800、标签 8-9 | 不新增字号档 |

## 3. 组件规格

### 3.1 总账三格瓷砖（继承概览）

- 围栏：`green.grad`，big = `fences.length`，sub = `{active} 个启用`。
- 在养：白卡，big = `overallStats.totalLivestock`，sub = `noGps>0 ? "含 {n} 头无GPS" : "全部已定位"`。
- 告警：围栏活跃告警 >0 时 `red.grad` + 未读角标（`summary.byGroupUnread.fence`），sub = `{涉及围栏数} 个围栏涉及`；=0 白卡绿字「无告警」。无 GPS/越界不属于「告警」，由在养卡副标与对账行表达（T3 裁决，修正早期 OR 写法）。

### 3.2 围栏卡片（D 列表态）

横向结构：`spine(3) → terrain(92×56) → info`。

**mini 沙盘绘制规则（`FenceSandboxPainter`，CustomPaint）：**
1. 取 `fence.points`（≥3 个点才绘制），在画布内归一化到包围盒，四周留 12% margin，保持纵横比。
2. 多边形：fill = 本色 16%，stroke = 本色 1.5 虚线 `[4,3]`。
3. 畜群点阵：`livestockMarkers` 经 `fencePolygonContainsLatLng` 过滤出栏内个体，经同一归一化映射落点。点色 = `fenceStatusMap[livestockId]`：`SAFE→safe`、`APPROACH→watch`、`BREACH→alert`。告警/留意点带脉冲动画（共享 AnimationController 以 22.8s 公倍周期循环：watch 12 圈 / alert 19 圈整数相位，keyframe 对齐原型 opacity 1→0.30→1）。
4. `points<3`：只画地形底 + 居中浅灰轮廓占位，不画点阵。
5. 沙盘为相对形状渲染（归一化坐标），**不做 GCJ/WGS 转换**——归一化消除了坐标系差异，形状与地图视觉一致。

**info 列**：row1 = 名称（11/700，ellipsis）+ 类型标签 + 停用标签；row2 = `{livestockCount} 头 · {area} 公顷` + 告警胶囊（>0 红 `⚠ {n} 起告警` / =0 绿 `✓ 正常`）。
停用围栏：整卡 60% 透明度（与原型一致，不做额外去饱和）。透明度组合规则（T3 裁决）：选中态优先——`isDimmed` 时统一 0.5，否则停用卡 0.6。

### 3.3 选中详情卡（暗色仪表盘）

纵向结构：`dark(108) → light(元数据 + 操作)`，整卡 `shadow.elev`。

**dark 画布**：
- 同一归一化放大绘制：fill 30%，stroke 2 虚线 `[6,4]`，顶点 `vertex.dot` r2.2。
- 畜群点阵同 3.2 规则（r2.2，告警 2.6）。
- 扫描线：2px 高横条，`panel.scan` 渐变，top = phase×height，3.8s/圈（22.8s 主循环内整数 6 圈，无缝循环）。
- 左下角坐标读数 = 围栏包围盒中心（`format: 112.938°E 28.229°N`，纯数字无 i18n）。
- 右上角徽章：`{activeAlerts} 起告警` +（`approachCount>0` 时）`· {n} 头临近边界`。

**light 区**（继承 A 现版）：detail-head（色点 + 名称 + 类型标签）、2×2 元数据（面积/类型/在养/活跃告警，告警红字）、三操作位（编辑边界 info / 围栏告警 soft / 删除 danger icon）。

### 3.4 对账行（继承）

`noGps + outside > 0` 时显示琥珀胶囊，复用现版文案 `ranchFenceLocationGap`。

## 4. 交互细则

| 动作 | 行为 | 现状 |
|---|---|---|
| 点卡片 | `onFenceSelected(fence.id)`，地图聚焦（现有逻辑） | 复用 |
| 再点选中卡 | 取消选中 | 复用 |
| 编辑边界 | 现有 `_openFullEditor` 流程 | 复用 |
| 删除 | 现有确认弹窗 + 刷新 | 复用 |
| 新建 | 现有 fenceForm 路由 | 复用 |
| 牧场切换 | RanchFenceTab 由 RanchPage 重建，沙盘随之刷新 | 复用 |

## 5. 数据与状态映射

| UI 元素 | 数据源 | 空态/兜底 |
|---|---|---|
| 瓷砖围栏数/启用数 | `fences.length` / `active` 计数 | 0 时瓷砖白卡化 |
| 瓷砖在养 | `overview.overallStats.totalLivestock`（**需新增传参**） | — |
| 瓷砖告警数 | `alerts` 按 fence 类型 + ACTIVE 过滤计数 | 0 → 白卡「无告警」 |
| 瓷砖未读角标 | `alertSummary.byGroupUnread.fence`（**需新增传参**） | 0 不显示 |
| 多边形 | `fence.points`（≥3） | 灰色占位轮廓 |
| 畜群点阵 | `livestockMarkers` + `fencePolygonContainsLatLng` + `fenceStatusMap` | 无点位只画形状 |
| 点色 | `fenceStatusMap`（RanchPage 已构建，**需新增传参**） | 缺省 `SAFE` |
| 告警胶囊/详情徽章 | `alerts.fenceId==fence.id && ACTIVE` 计数 | 0 → 绿「正常」 |
| 临近边界数 | `fenceStatusMap` 中该栏 `APPROACH` 计数 | 0 不拼接 |

**接口改动（唯一）**：`RanchFenceTab` 构造参数新增 `totalLivestock`、`fenceUnread`、`fenceStatusMap`、`livestockMarkers` 四个入参，由 `RanchPage` 传入（数据均为现成计算结果，仅透传；`livestockMarkers` 为沙盘点阵过滤所需，T3 实现时补充）。不新增任何 Provider/请求。

## 6. 可实现性推敲结论

1. **点在多边形内**：`fence_polygon_contains.dart` 已存在且已被 ranch_page / fence_page 使用，纯函数可单测。✅
2. **点色状态**：`fenceStatusMap`（SAFE/APPROACH/BREACH）RanchPage 已计算，透传即可。✅
3. **形状归一化绘制**：相对坐标渲染，无坐标转换、无瓦片依赖；CustomPaint 无资源开销。✅
4. **动画预算**：Tab State 持单个 `AnimationController`（repeat，22.8s = scan/watch/alert 周期公倍数，整数相位防 wrap 跳变），列表脉冲与详情扫描线共用 progress，无每卡 ticker。✅
5. **性能量级**：围栏 ≤ 20、栏内点 ≤ 数百，painter 每帧 <1ms 量级；列表不可见时 sheet tab 切走即不 paint。✅
6. **风险点**：`points` 极扁（面积≈0）时归一化会拉伸——绘制时对长宽比 clamp（短边补足 20% 占比，无倍数上限）。语义为**可见性优先于形状保真**的退化兜底；若产品要求强形状保真，应改占位提示而非拉伸（V1 不做）。

## 7. i18n 新增键（中英同步）

| Key | zh | en |
|---|---|---|
| `fenceTileActiveSub` | `{n} 个启用` | `{n} active` |
| `fenceTileLivestockSubGps` | `含 {n} 头无GPS` | `{n} without GPS` |
| `fenceTileLivestockSubOk` | `全部已定位` | `All located` |
| `fenceTileAlertSub` | `{n} 个围栏涉及` | `{n} fences involved` |
| `fenceTileAlertClear` | `无告警` | `No alerts` |
| `fenceListHint` | `点击展开仪表盘` | `Tap for dashboard` |
| `fenceNearBoundary` | `{n} 头临近边界` | `{n} near boundary` |
| `fenceTileLivestock` | `在养` | `Livestock` |
| `fenceStatusSummary` | `{fences} 个围栏 · {livestock} 头在养` | `{fences} fences · {livestock} livestock` |
| `fenceTypeUnknown` | `未知类型` | `Unknown` |

（后三键为 T3 实现期发现的缺失键；对账行、元数据标签、按钮、停用标签、告警徽章文案 `{count} 条告警` 复用现有键 `alertFenceStatusTitle`/`alertFenceAlertCount` 等。）

## 8. 验收标准

1. 原型保真：三格瓷砖渐变色值、卡片行布局（3/92/56）、沙盘点色与脉冲、暗盘扫描线，与原型逐项对齐（`prototype-to-flutter-fidelity` 截图对比）。
2. `flutter analyze` 0 issue；`gen-l10n` 无缺失；新键中英同步。
3. 浏览器走查：选中联动地图聚焦、再点收起、编辑/删除/新增全链路不变、牧工视角无管理按钮。
4. 边界：无 points 围栏占位态、无点位沙盘、停用围栏 opacity .6、0 告警白卡。
5. 部署 dev 后 `main.dart.js` 哈希一致 + 种子账号登录 200 + 围栏页走查截图。

## 9. 待拍板（默认值已选，可否决）

1. **坐标读数**：详情暗盘左下角显示围栏中心坐标。默认保留（B 的仪器感来源之一）；若嫌信息噪音可去掉，无 l10n 成本差异。
2. **列表脉冲动画**：默认启用（共享单个 controller，开销可忽略）；若要极致省电可降级为静态点。
