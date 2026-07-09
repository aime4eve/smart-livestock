# 解决方案说明书 HTML — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个单文件 HTML 解决方案说明书，8 区块叙事长卷，面向混合受众（业务+技术），沿用 Flutter AppColors 视觉风格。

**Architecture:** 单文件 HTML（内联 CSS + JS），零外部依赖。CSS Variables 管理颜色/间距/字体，CSS Grid + Flexbox 布局，IntersectionObserver 驱动滚动动画。3 档响应式（桌面>1024 / 平板 768-1024 / 手机<768）。

**Tech Stack:** HTML5 + CSS3 (Variables/Grid/Flexbox) + 原生 JS (IntersectionObserver) + Google Fonts (NotoSansSC)

## Global Constraints

- 输出文件：`docs/marketing/solution-brochure.html`，单文件，浏览器直接打开
- 颜色 token 必须与 `Mobile/mobile_app/lib/core/theme/app_colors.dart` 一致
- 定价用人民币 ¥，取自 PRD v2.3 中文市场定价
- 竞品数据取自 PRD v2.3 Section 1.5
- 技术数字取自 CLAUDE.md（51 Controller、187 API、39 表、502 Java 文件）
- Hero 数字：4～6 年续航 / 72h 提前预警 / 5–10km 覆盖 / 14 天免费试用
- 字体：NotoSansSC（Google Fonts CDN）+ system-ui fallback
- 响应式断点：>1024px（桌面）/ 768-1024px（平板）/ <768px（手机）
- 技术架构区块默认折叠，点击展开

---

### Task 1: HTML 骨架 + CSS 基础体系

**Files:**
- Create: `docs/marketing/solution-brochure.html`

**Interfaces:**
- Produces: CSS 变量体系（颜色/间距/字体/响应式断点）、HTML 文档结构（`<head>` + 空的 `<body>` section 占位）、基础 reset 样式

- [ ] **Step 1: 创建目录并写入 HTML 骨架**

```bash
mkdir -p docs/marketing
```

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="SmartLivestock 智慧畜牧解决方案 — IoT + AI 数智孪生，数据驱动的精准养殖">
  <title>SmartLivestock 智慧畜牧解决方案</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;500;700;900&display=swap" rel="stylesheet">
  <style>
    /* === CSS Reset & Base === */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; }
    body {
      font-family: 'Noto Sans SC', system-ui, -apple-system, sans-serif;
      color: var(--color-text-primary);
      background: var(--color-surface);
      line-height: 1.8;
      -webkit-font-smoothing: antialiased;
    }

    /* === Design Tokens === */
    :root {
      /* Colors — aligned with app_colors.dart */
      --color-primary:       #2F6B3B;
      --color-primary-dark:  #244F2D;
      --color-primary-soft:  #E3F0E4;
      --color-accent:        #8BA95A;
      --color-surface:       #F8F6F0;
      --color-white:         #FFFFFF;
      --color-text-primary:  #263126;
      --color-text-secondary:#617061;
      --color-success:       #4C9A5F;
      --color-warning:       #D28A2D;
      --color-danger:        #C2564B;
      --color-info:          #4A7F9D;
      --color-border:        #D7D2C6;

      /* Spacing */
      --space-xs:   0.25rem;
      --space-sm:   0.5rem;
      --space-md:   1rem;
      --space-lg:   1.5rem;
      --space-xl:   2rem;
      --space-xxl:  3rem;
      --space-section: 5rem;

      /* Layout */
      --max-width: 1200px;
      --border-radius: 12px;

      /* Shadows */
      --shadow-sm: 0 1px 3px rgba(0,0,0,0.08);
      --shadow-md: 0 4px 12px rgba(0,0,0,0.10);
      --shadow-lg: 0 8px 24px rgba(0,0,0,0.12);
    }

    /* === Utility Classes === */
    .container { max-width: var(--max-width); margin: 0 auto; padding: 0 var(--space-lg); }
    .section { padding: var(--space-section) 0; }
    .section-title {
      font-size: 2rem; font-weight: 700; text-align: center;
      color: var(--color-text-primary); margin-bottom: var(--space-sm);
    }
    .section-subtitle {
      font-size: 1.1rem; text-align: center;
      color: var(--color-text-secondary); margin-bottom: var(--space-xxl);
      max-width: 600px; margin-left: auto; margin-right: auto;
    }
    .btn {
      display: inline-block; padding: 0.75rem 2rem; border-radius: 8px;
      font-size: 1rem; font-weight: 600; text-decoration: none;
      cursor: pointer; transition: all 0.2s ease; border: none;
    }
    .btn-primary { background: var(--color-primary); color: var(--color-white); }
    .btn-primary:hover { background: var(--color-primary-dark); transform: translateY(-2px); }
    .btn-outline { background: transparent; color: var(--color-white); border: 2px solid var(--color-white); }
    .btn-outline:hover { background: var(--color-white); color: var(--color-primary); }

    /* === Responsive === */
    @media (max-width: 1024px) {
      :root { --space-section: 4rem; }
      .section-title { font-size: 1.75rem; }
    }
    @media (max-width: 768px) {
      :root { --space-section: 3rem; }
      .section-title { font-size: 1.5rem; }
      .section-subtitle { font-size: 1rem; }
    }
  </style>
</head>
<body>

  <!-- SECTION: hero -->
  <!-- /SECTION: hero -->

  <!-- SECTION: pain-points -->
  <!-- /SECTION: pain-points -->

  <!-- SECTION: solution-overview -->
  <!-- /SECTION: solution-overview -->

  <!-- SECTION: capabilities -->
  <!-- /SECTION: capabilities -->

  <!-- SECTION: architecture -->
  <!-- /SECTION: architecture -->

  <!-- SECTION: advantages -->
  <!-- /SECTION: advantages -->

  <!-- SECTION: pricing -->
  <!-- /SECTION: pricing -->

  <!-- SECTION: cta -->
  <!-- /SECTION: cta -->

  <footer>
    <!-- placeholder -->
  </footer>

  <script>
    // Animations will be added later
  </script>
</body>
</html>
```

- [ ] **Step 2: 浏览器打开验证骨架**

```bash
open docs/marketing/solution-brochure.html
```

Expected: 空白页面，标题「SmartLivestock 智慧畜牧解决方案」，背景 #F8F6F0，字体已加载。

- [ ] **Step 3: Commit**

```bash
git add docs/marketing/solution-brochure.html
git commit -m "feat: add solution brochure HTML skeleton and CSS foundation"
```

---

### Task 2: Hero 区块

**Files:**
- Modify: `docs/marketing/solution-brochure.html` — 替换 `<!-- SECTION: hero -->` 占位

**Interfaces:**
- Consumes: CSS 变量体系（Task 1）
- Produces: Hero section HTML + CSS

- [ ] **Step 1: 添加 Hero CSS（插入 `</style>` 前）**

```css
    /* === Hero === */
    .hero {
      background: linear-gradient(135deg, var(--color-primary-dark) 0%, var(--color-primary) 100%);
      color: var(--color-white); text-align: center;
      padding: 6rem var(--space-lg) 5rem;
    }
    .hero-title {
      font-size: 3rem; font-weight: 900; line-height: 1.3;
      margin-bottom: var(--space-md); animation: fadeInUp 0.8s ease;
    }
    .hero-subtitle {
      font-size: 1.25rem; opacity: 0.9; margin-bottom: var(--space-xxl);
      max-width: 640px; margin-left: auto; margin-right: auto;
      animation: fadeInUp 0.8s ease 0.15s both;
    }
    .hero-stats {
      display: grid; grid-template-columns: repeat(4, 1fr);
      gap: var(--space-lg); max-width: 900px;
      margin: 0 auto var(--space-xxl);
      animation: fadeInUp 0.8s ease 0.3s both;
    }
    .hero-stat {
      background: rgba(255,255,255,0.12); border-radius: var(--border-radius);
      padding: var(--space-lg) var(--space-md);
      backdrop-filter: blur(8px);
    }
    .hero-stat-number { font-size: 2rem; font-weight: 900; line-height: 1.2; }
    .hero-stat-label { font-size: 0.9rem; opacity: 0.85; margin-top: var(--space-xs); }
    .hero-cta {
      display: flex; gap: var(--space-md); justify-content: center;
      flex-wrap: wrap; animation: fadeInUp 0.8s ease 0.45s both;
    }
    @keyframes fadeInUp {
      from { opacity: 0; transform: translateY(24px); }
      to   { opacity: 1; transform: translateY(0); }
    }
    @media (max-width: 768px) {
      .hero-title { font-size: 2rem; }
      .hero-stats { grid-template-columns: repeat(2, 1fr); }
      .hero-stat-number { font-size: 1.5rem; }
    }
    @media (max-width: 480px) {
      .hero-title { font-size: 1.75rem; }
      .hero-stats { grid-template-columns: 1fr; }
    }
```

- [ ] **Step 2: 替换 Hero HTML 占位**

```html
  <!-- SECTION: hero -->
  <section class="hero">
    <h1 class="hero-title">智慧畜牧，数据驱动的精准养殖</h1>
    <p class="hero-subtitle">IoT 设备 + AI 数智孪生 + 云平台，从经验养殖迈向数据驱动的精准管理</p>
    <div class="hero-stats">
      <div class="hero-stat">
        <div class="hero-stat-number">4～6 年</div>
        <div class="hero-stat-label">设备续航，一次安装长期免维护</div>
      </div>
      <div class="hero-stat">
        <div class="hero-stat-number">72 小时</div>
        <div class="hero-stat-label">AI 提前预警，早于临床症状</div>
      </div>
      <div class="hero-stat">
        <div class="hero-stat-number">5–10 公里</div>
        <div class="hero-stat-label">LoRaWAN 覆盖半径，无需蜂窝基站</div>
      </div>
      <div class="hero-stat">
        <div class="hero-stat-number">14 天</div>
        <div class="hero-stat-label">全功能免费试用，零风险上手</div>
      </div>
    </div>
    <div class="hero-cta">
      <a href="#cta" class="btn btn-primary" style="background:var(--color-white);color:var(--color-primary);">预约演示</a>
      <a href="#pricing" class="btn btn-outline">免费试用</a>
    </div>
  </section>
  <!-- /SECTION: hero -->
```

- [ ] **Step 3: 浏览器验证**

```bash
open docs/marketing/solution-brochure.html
```

Expected: 深绿渐变 Hero，标题居中，4 个统计数字横向排列，标题淡入上移动画。

- [ ] **Step 4: Commit**

```bash
git add docs/marketing/solution-brochure.html
git commit -m "feat: add hero section with stats and CTAs"
```

---

### Task 3: 痛点区块

**Files:**
- Modify: `docs/marketing/solution-brochure.html` — 替换 `<!-- SECTION: pain-points -->` 占位

- [ ] **Step 1: 添加痛点 CSS（追加到 `</style>` 前）**

```css
    /* === Pain Points === */
    .pain-points { background: var(--color-surface); }
    .pain-grid {
      display: grid; grid-template-columns: repeat(4, 1fr);
      gap: var(--space-lg); max-width: var(--max-width);
      margin: 0 auto; padding: 0 var(--space-lg);
    }
    .pain-card {
      background: var(--color-white); border-radius: var(--border-radius);
      padding: var(--space-xl); text-align: center;
      box-shadow: var(--shadow-sm); transition: transform 0.3s ease, box-shadow 0.3s ease;
    }
    .pain-card:hover { transform: translateY(-4px); box-shadow: var(--shadow-md); }
    .pain-icon {
      width: 56px; height: 56px; border-radius: 50%;
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto var(--space-md); font-size: 1.5rem;
    }
    .pain-icon-1 { background: #FDF2EE; color: var(--color-warning); }
    .pain-icon-2 { background: #FDECEC; color: var(--color-danger); }
    .pain-icon-3 { background: #ECF0FD; color: var(--color-info); }
    .pain-icon-4 { background: #FEF3E4; color: var(--color-warning); }
    .pain-card h3 { font-size: 1.1rem; margin-bottom: var(--space-sm); color: var(--color-text-primary); }
    .pain-card p { font-size: 0.95rem; color: var(--color-text-secondary); line-height: 1.7; }

    @media (max-width: 1024px) { .pain-grid { grid-template-columns: repeat(2, 1fr); } }
    @media (max-width: 640px)  { .pain-grid { grid-template-columns: 1fr; } }
```

- [ ] **Step 2: 替换痛点 HTML 占位**

```html
  <!-- SECTION: pain-points -->
  <section class="section pain-points">
    <h2 class="section-title">传统牧场面临的挑战</h2>
    <p class="section-subtitle">规模化养殖中，这些痛点每天都在消耗利润</p>
    <div class="pain-grid">
      <div class="pain-card">
        <div class="pain-icon pain-icon-1">&#9200;</div>
        <h3>人工巡栏效率低</h3>
        <p>500 头牧场每天巡栏超过 3 小时，人力成本居高不下，且难以做到 24 小时不间断监控。</p>
      </div>
      <div class="pain-card">
        <div class="pain-icon pain-icon-2">&#9764;</div>
        <h3>疾病发现不及时</h3>
        <p>依赖牧工经验判断，早期症状极易被忽视。往往发现时已错过最佳治疗窗口，损失惨重。</p>
      </div>
      <div class="pain-card">
        <div class="pain-icon pain-icon-3">&#128270;</div>
        <h3>牲畜走失盗窃</h3>
        <p>散养模式下牲畜位置不可见，发生走失或盗窃后追溯困难，每年造成可观经济损失。</p>
      </div>
      <div class="pain-card">
        <div class="pain-icon pain-icon-4">&#128246;</div>
        <h3>网络覆盖差</h3>
        <p>偏远牧场蜂窝信号不稳定，传统数字化工具频繁断连，实际使用体验大打折扣。</p>
      </div>
    </div>
  </section>
  <!-- /SECTION: pain-points -->
```

- [ ] **Step 3: 浏览器验证**

Expected: 4 列痛点卡片，米白背景，卡片 hover 上浮。

- [ ] **Step 4: Commit**

```bash
git add docs/marketing/solution-brochure.html
git commit -m "feat: add pain points section"
```

---

### Task 4: 方案全景 + 核心能力

**Files:**
- Modify: `docs/marketing/solution-brochure.html` — 替换 `<!-- SECTION: solution-overview -->` 和 `<!-- SECTION: capabilities -->` 占位

- [ ] **Step 1: 添加方案全景 CSS**

```css
    /* === Solution Overview === */
    .solution { background: var(--color-white); }
    .solution-flow {
      display: grid; grid-template-columns: repeat(3, 1fr);
      gap: var(--space-xl); max-width: var(--max-width);
      margin: 0 auto; padding: 0 var(--space-lg); position: relative;
    }
    .solution-step {
      text-align: center; padding: var(--space-xl);
      background: var(--color-surface); border-radius: var(--border-radius);
      position: relative;
    }
    .solution-step:not(:last-child)::after {
      content: '→'; position: absolute; right: -1.5rem; top: 50%;
      transform: translateY(-50%); font-size: 1.5rem;
      color: var(--color-accent); font-weight: 700;
    }
    .solution-step-icon {
      width: 64px; height: 64px; border-radius: 50%;
      background: var(--color-primary-soft); color: var(--color-primary);
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto var(--space-md); font-size: 1.75rem;
    }
    .solution-step h3 { font-size: 1.15rem; margin-bottom: var(--space-sm); color: var(--color-primary); }
    .solution-step ul { list-style: none; text-align: left; }
    .solution-step li { font-size: 0.95rem; color: var(--color-text-secondary); padding: 0.25rem 0; }
    .solution-step li::before { content: '✓ '; color: var(--color-success); font-weight: 700; }

    /* === Core Capabilities === */
    .capabilities { background: var(--color-primary-soft); }
    .cap-grid {
      display: grid; grid-template-columns: repeat(3, 1fr);
      gap: var(--space-lg); max-width: var(--max-width);
      margin: 0 auto; padding: 0 var(--space-lg);
    }
    .cap-card {
      background: var(--color-white); border-radius: var(--border-radius);
      padding: var(--space-xl); box-shadow: var(--shadow-sm);
      transition: transform 0.3s ease, box-shadow 0.3s ease;
      border-top: 4px solid var(--color-primary);
    }
    .cap-card:hover { transform: translateY(-6px); box-shadow: var(--shadow-lg); }
    .cap-card-icon { font-size: 2rem; margin-bottom: var(--space-md); }
    .cap-card h3 { font-size: 1.15rem; margin-bottom: var(--space-sm); color: var(--color-text-primary); }
    .cap-card p { font-size: 0.95rem; color: var(--color-text-secondary); line-height: 1.7; }

    @media (max-width: 1024px) {
      .solution-flow { grid-template-columns: 1fr; gap: var(--space-lg); }
      .solution-step:not(:last-child)::after {
        content: '↓'; right: 50%; top: auto; bottom: -2rem;
        transform: translateX(50%);
      }
      .cap-grid { grid-template-columns: repeat(2, 1fr); }
    }
    @media (max-width: 640px) {
      .cap-grid { grid-template-columns: 1fr; }
    }
```

- [ ] **Step 2: 替换方案全景 + 核心能力 HTML 占位**

```html
  <!-- SECTION: solution-overview -->
  <section class="section solution">
    <h2 class="section-title">SmartLivestock 三位一体解决方案</h2>
    <p class="section-subtitle">从感知到分析到管理，全链路闭环</p>
    <div class="solution-flow">
      <div class="solution-step">
        <div class="solution-step-icon">&#128225;</div>
        <h3>IoT 感知层</h3>
        <ul>
          <li>GPS 追踪器（项圈式）</li>
          <li>瘤胃胶囊（吞服式）</li>
          <li>智能耳标</li>
          <li>LoRaWAN 网关</li>
        </ul>
      </div>
      <div class="solution-step">
        <div class="solution-step-icon">&#129504;</div>
        <h3>AI 分析引擎</h3>
        <ul>
          <li>发热早期检测</li>
          <li>消化功能分析</li>
          <li>发情智能识别</li>
          <li>疫病趋势预警</li>
          <li>无监督异常检测</li>
        </ul>
      </div>
      <div class="solution-step">
        <div class="solution-step-icon">&#9729;</div>
        <h3>云平台管理</h3>
        <ul>
          <li>多租户 SaaS 架构</li>
          <li>实时地图监控</li>
          <li>告警即时推送</li>
          <li>数据分析报表</li>
        </ul>
      </div>
    </div>
  </section>
  <!-- /SECTION: solution-overview -->

  <!-- SECTION: capabilities -->
  <section class="section capabilities">
    <h2 class="section-title">六大核心能力</h2>
    <p class="section-subtitle">覆盖牲畜管理全场景，从定位到健康一站式解决</p>
    <div class="cap-grid">
      <div class="cap-card">
        <div class="cap-card-icon">&#128506;</div>
        <h3>实时定位追踪</h3>
        <p>GPS + LoRaWAN 双模定位，全球覆盖。支持历史轨迹回放与热力图分析，牲畜位置一目了然。</p>
      </div>
      <div class="cap-card">
        <div class="cap-card-icon">&#128737;</div>
        <h3>电子围栏告警</h3>
        <p>手绘多边形或模板快速创建虚拟围栏，越界实时推送告警。支持分时段策略与围栏区域细分管理。</p>
      </div>
      <div class="cap-card">
        <div class="cap-card-icon">&#10084;</div>
        <h3>AI 健康监测</h3>
        <p>发热、消化、发情、疫病四大分析引擎，覆盖牲畜全生命周期。瘤胃温度基线偏离 72h 趋势预警。</p>
      </div>
      <div class="cap-card">
        <div class="cap-card-icon">&#128202;</div>
        <h3>无监督异常检测</h3>
        <p>STL 节律剥离 + CUSUM 突变检测，体温、蠕动、活动三维联合分析。规则引擎与 AI 双轨并行，误报率大幅降低。</p>
      </div>
      <div class="cap-card">
        <div class="cap-card-icon">&#128295;</div>
        <h3>设备全生命周期管理</h3>
        <p>追踪器、瘤胃胶囊、耳标统一管理。电量、信号、在线状态实时监控，异常主动告警。支持批量入网与安装记录追溯。</p>
      </div>
      <div class="cap-card">
        <div class="cap-card-icon">&#128190;</div>
        <h3>离线全功能作业</h3>
        <p>无网络环境下完整运行：离线地图瓦片、离线围栏数据、离线牲畜缓存。网络恢复后自动同步，牧场深处也不中断。</p>
      </div>
    </div>
  </section>
  <!-- /SECTION: capabilities -->
```

- [ ] **Step 3: 浏览器验证**

Expected: 白色背景三列流程图（桌面端箭头连接）+ 浅绿背景 3x2 卡片网格，hover 上浮。

- [ ] **Step 4: Commit**

```bash
git add docs/marketing/solution-brochure.html
git commit -m "feat: add solution overview and core capabilities sections"
```

---

### Task 5: 技术架构区块

**Files:**
- Modify: `docs/marketing/solution-brochure.html` — 替换 `<!-- SECTION: architecture -->` 占位

- [ ] **Step 1: 添加架构 CSS**

```css
    /* === Architecture === */
    .architecture { background: var(--color-surface); }
    .arch-layout {
      display: grid; grid-template-columns: 1fr 320px;
      gap: var(--space-xxl); max-width: var(--max-width);
      margin: 0 auto; padding: 0 var(--space-lg); align-items: start;
    }
    .arch-diagram {
      background: var(--color-white); border-radius: var(--border-radius);
      padding: var(--space-xl); box-shadow: var(--shadow-sm);
    }
    .arch-diagram h3 { font-size: 1.15rem; color: var(--color-primary); margin-bottom: var(--space-lg); }
    .arch-contexts {
      display: grid; grid-template-columns: repeat(3, 1fr);
      gap: var(--space-sm); margin-bottom: var(--space-lg);
    }
    .arch-ctx {
      background: var(--color-primary-soft); border-radius: 8px;
      padding: var(--space-sm) var(--space-md); text-align: center;
      font-size: 0.85rem; font-weight: 600; color: var(--color-primary);
    }
    .arch-layers {
      display: flex; flex-direction: column; gap: var(--space-xs);
      font-size: 0.85rem; color: var(--color-text-secondary);
    }
    .arch-layers span { padding: var(--space-xs) var(--space-sm); background: #F0F4F8; border-radius: 4px; }
    .arch-stats {
      background: var(--color-white); border-radius: var(--border-radius);
      padding: var(--space-xl); box-shadow: var(--shadow-sm);
    }
    .arch-stats h3 { font-size: 1rem; color: var(--color-text-primary); margin-bottom: var(--space-md); }
    .arch-stat-item {
      display: flex; justify-content: space-between; align-items: baseline;
      padding: var(--space-sm) 0; border-bottom: 1px solid var(--color-border);
    }
    .arch-stat-item:last-child { border-bottom: none; }
    .arch-stat-value { font-size: 1.5rem; font-weight: 900; color: var(--color-primary); }
    .arch-stat-label { font-size: 0.9rem; color: var(--color-text-secondary); }
    .arch-tech-tags {
      margin-top: var(--space-xl); display: flex; flex-wrap: wrap; gap: var(--space-sm);
    }
    .arch-tag {
      background: var(--color-primary-soft); color: var(--color-primary);
      padding: 0.3rem 0.8rem; border-radius: 20px;
      font-size: 0.85rem; font-weight: 500;
    }
    .arch-expand {
      text-align: center; margin-top: var(--space-lg);
    }
    .arch-expand-btn {
      background: none; border: 1px solid var(--color-border); border-radius: 8px;
      padding: 0.6rem 1.5rem; font-size: 0.9rem; color: var(--color-text-secondary);
      cursor: pointer; font-family: inherit;
    }
    .arch-expand-btn:hover { border-color: var(--color-primary); color: var(--color-primary); }
    .arch-detail {
      display: none; margin-top: var(--space-lg);
      background: var(--color-white); border-radius: var(--border-radius);
      padding: var(--space-xl); box-shadow: var(--shadow-sm);
    }
    .arch-detail.open { display: block; }
    .arch-detail table { width: 100%; border-collapse: collapse; font-size: 0.9rem; }
    .arch-detail th, .arch-detail td {
      text-align: left; padding: var(--space-sm) var(--space-md);
      border-bottom: 1px solid var(--color-border);
    }
    .arch-detail th { color: var(--color-primary); font-weight: 600; }

    @media (max-width: 1024px) {
      .arch-layout { grid-template-columns: 1fr; }
      .arch-contexts { grid-template-columns: repeat(3, 1fr); }
    }
    @media (max-width: 640px) {
      .arch-contexts { grid-template-columns: repeat(2, 1fr); }
    }
```

- [ ] **Step 2: 替换架构 HTML 占位**

```html
  <!-- SECTION: architecture -->
  <section class="section architecture">
    <h2 class="section-title">技术架构一览</h2>
    <p class="section-subtitle">企业级技术底座，支撑规模化运营</p>
    <div class="arch-layout">
      <div class="arch-diagram">
        <h3>DDD 限界上下文（9 个）</h3>
        <div class="arch-contexts">
          <div class="arch-ctx">Identity<br>身份与租户</div>
          <div class="arch-ctx">Ranch<br>牧场与围栏</div>
          <div class="arch-ctx">IoT<br>设备与遥测</div>
          <div class="arch-ctx">Health<br>数智孪生健康</div>
          <div class="arch-ctx">Commerce<br>商业计费</div>
          <div class="arch-ctx">Analytics<br>统计与门户</div>
          <div class="arch-ctx">Datagen<br>数据合成</div>
          <div class="arch-ctx">Platform<br>调度台</div>
          <div class="arch-ctx">Shared<br>共享内核</div>
        </div>
        <h3 style="margin-top:var(--space-lg);margin-bottom:var(--space-sm);">洋葱架构分层</h3>
        <div class="arch-layers">
          <span>Interfaces — REST Controller / DTO / 组装器</span>
          <span>Application — 用例编排 / 事务边界 / Port 定义</span>
          <span>Domain — 领域模型 / 领域服务 / 仓储接口</span>
          <span>Infrastructure — JPA 持久化 / MQ 消费 / ACL 适配</span>
        </div>
        <div class="arch-tech-tags">
          <span class="arch-tag">Spring Boot 3.3</span>
          <span class="arch-tag">Java 17</span>
          <span class="arch-tag">PostgreSQL 16</span>
          <span class="arch-tag">Redis 7</span>
          <span class="arch-tag">RocketMQ 5.1</span>
          <span class="arch-tag">Flutter 3.x</span>
          <span class="arch-tag">Riverpod</span>
          <span class="arch-tag">Docker Compose</span>
          <span class="arch-tag">JWT 双 Token</span>
          <span class="arch-tag">AI Platform</span>
        </div>
      </div>
      <div class="arch-stats">
        <h3>关键数字</h3>
        <div class="arch-stat-item">
          <span class="arch-stat-label">REST Controller</span>
          <span class="arch-stat-value">51</span>
        </div>
        <div class="arch-stat-item">
          <span class="arch-stat-label">API 端点</span>
          <span class="arch-stat-value">187</span>
        </div>
        <div class="arch-stat-item">
          <span class="arch-stat-label">数据库表</span>
          <span class="arch-stat-value">39</span>
        </div>
        <div class="arch-stat-item">
          <span class="arch-stat-label">Java 文件</span>
          <span class="arch-stat-value">502</span>
        </div>
        <div class="arch-stat-item">
          <span class="arch-stat-label">测试类</span>
          <span class="arch-stat-value">53</span>
        </div>
        <div class="arch-stat-item">
          <span class="arch-stat-label">前端模块</span>
          <span class="arch-stat-value">30</span>
        </div>
        <div class="arch-stat-item">
          <span class="arch-stat-label">代码行数</span>
          <span class="arch-stat-value">~63K</span>
        </div>
      </div>
    </div>
    <div class="arch-expand" style="max-width:var(--max-width);margin:var(--space-lg) auto 0;padding:0 var(--space-lg);">
      <button class="arch-expand-btn" onclick="toggleArchDetail()">展开完整技术栈 ▼</button>
    </div>
    <div class="arch-detail" id="archDetail" style="max-width:var(--max-width);margin:var(--space-lg) auto 0;padding:0 var(--space-lg);">
      <div style="background:var(--color-white);border-radius:var(--border-radius);padding:var(--space-xl);box-shadow:var(--shadow-sm);">
        <table>
          <thead><tr><th>层次</th><th>技术</th><th>版本</th><th>说明</th></tr></thead>
          <tbody>
            <tr><td>后端框架</td><td>Spring Boot</td><td>3.3.x</td><td>Java 17，Gradle 构建</td></tr>
            <tr><td>持久层</td><td>Spring Data JPA + Hibernate</td><td>—</td><td>Flyway 管理 DDL</td></tr>
            <tr><td>数据库</td><td>PostgreSQL</td><td>16</td><td>时序数据按月 RANGE 分区</td></tr>
            <tr><td>缓存</td><td>Redis</td><td>7</td><td>会话 / 限流（Lua 滑动窗口）</td></tr>
            <tr><td>消息队列</td><td>RocketMQ</td><td>5.1</td><td>跨上下文事件总线</td></tr>
            <tr><td>认证</td><td>JJWT</td><td>0.12.5</td><td>Access 1h + Refresh 7d</td></tr>
            <tr><td>安全</td><td>Spring Security</td><td>—</td><td>RBAC + 多租户隔离</td></tr>
            <tr><td>前端框架</td><td>Flutter</td><td>3.x</td><td>iOS / Android / Web 三端</td></tr>
            <tr><td>状态管理</td><td>Riverpod</td><td>—</td><td>Compile-safe DI</td></tr>
            <tr><td>地图</td><td>flutter_map + tileserver-gl</td><td>—</td><td>逐瓦片智能路由 + MBTiles 离线</td></tr>
            <tr><td>AI 平台</td><td>Python + FastAPI + scikit-learn</td><td>—</td><td>STL + CUSUM + iForest</td></tr>
            <tr><td>部署</td><td>Docker Compose</td><td>—</td><td>dev / test 双环境隔离</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>
  <!-- /SECTION: architecture -->
```

- [ ] **Step 3: 添加 JS toggle 函数（插入 `<script>` 标签内）**

```javascript
    function toggleArchDetail() {
      const detail = document.getElementById('archDetail');
      const btn = document.querySelector('.arch-expand-btn');
      detail.classList.toggle('open');
      btn.textContent = detail.classList.contains('open') ? '收起技术栈 ▲' : '展开完整技术栈 ▼';
    }
```

- [ ] **Step 4: 浏览器验证**

Expected: 左侧 9 上下文网格 + 4 层架构 + 技术标签，右侧数字面板。点击「展开」显示完整技术栈表格。

- [ ] **Step 5: Commit**

```bash
git add docs/marketing/solution-brochure.html
git commit -m "feat: add architecture section with expandable tech stack"
```

---

### Task 6: 竞品优势对比表

**Files:**
- Modify: `docs/marketing/solution-brochure.html` — 替换 `<!-- SECTION: advantages -->` 占位

- [ ] **Step 1: 添加优势 CSS**

```css
    /* === Advantages === */
    .advantages { background: var(--color-white); }
    .adv-table-wrapper {
      max-width: var(--max-width); margin: 0 auto; padding: 0 var(--space-lg);
      overflow-x: auto;
    }
    .adv-table { width: 100%; border-collapse: collapse; font-size: 0.95rem; }
    .adv-table th, .adv-table td {
      padding: var(--space-md); text-align: center; border-bottom: 1px solid var(--color-border);
    }
    .adv-table thead th {
      background: var(--color-surface); font-weight: 700; color: var(--color-text-primary);
      position: sticky; top: 0;
    }
    .adv-table thead th:first-child { text-align: left; border-radius: var(--border-radius) 0 0 0; }
    .adv-table thead th:last-child { border-radius: 0 var(--border-radius) 0 0; }
    .adv-table tbody td:first-child { text-align: left; font-weight: 600; color: var(--color-text-primary); }
    .adv-col-ours { background: var(--color-primary-soft); }
    .adv-col-ours td { color: var(--color-primary); font-weight: 600; }
    .adv-check { color: var(--color-success); font-weight: 700; }
    .adv-cross { color: #ccc; }
    .adv-partial { color: var(--color-warning); }
    .adv-note { font-size: 0.85rem; color: var(--color-text-secondary); margin-top: var(--space-md); text-align: center; }
```

- [ ] **Step 2: 替换优势 HTML 占位**

```html
  <!-- SECTION: advantages -->
  <section class="section advantages">
    <h2 class="section-title">为什么选择 SmartLivestock</h2>
    <p class="section-subtitle">与国际主流竞品全面对比，核心维度均具差异化优势</p>
    <div class="adv-table-wrapper">
      <table class="adv-table">
        <thead>
          <tr>
            <th>功能维度</th>
            <th>Halter</th>
            <th>Vence</th>
            <th>Nofence</th>
            <th>Digitanimal</th>
            <th class="adv-col-ours">SmartLivestock</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>GPS 定位</td>
            <td class="adv-check">✓</td>
            <td class="adv-check">✓</td>
            <td class="adv-check">✓</td>
            <td class="adv-check">✓</td>
            <td class="adv-col-ours adv-check">✓</td>
          </tr>
          <tr>
            <td>虚拟围栏</td>
            <td class="adv-check">✓</td>
            <td class="adv-check">✓</td>
            <td class="adv-check">✓</td>
            <td class="adv-partial">△</td>
            <td class="adv-col-ours adv-check">✓ 核心</td>
          </tr>
          <tr>
            <td>电池寿命</td>
            <td>6 个月</td>
            <td>1 年</td>
            <td>6 个月</td>
            <td>2–3 年</td>
            <td class="adv-col-ours"><strong>4～6 年</strong></td>
          </tr>
          <tr>
            <td>通信方式</td>
            <td>蜂窝</td>
            <td>蜂窝</td>
            <td>4G/LTE</td>
            <td>LoRaWAN</td>
            <td class="adv-col-ours"><strong>LoRaWAN</strong></td>
          </tr>
          <tr>
            <td>强制月费</td>
            <td class="adv-check">✓</td>
            <td class="adv-check">✓</td>
            <td class="adv-check">✓</td>
            <td class="adv-cross">✗</td>
            <td class="adv-col-ours"><strong>可选订阅</strong></td>
          </tr>
          <tr>
            <td>健康监测</td>
            <td class="adv-check">✓</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-check">✓</td>
            <td class="adv-col-ours adv-check"><strong>瘤胃胶囊</strong></td>
          </tr>
          <tr>
            <td>AI 异常检测</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-col-ours"><strong>无监督 + 三维联合</strong></td>
          </tr>
          <tr>
            <td>数智孪生</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-col-ours"><strong>4 大场景</strong></td>
          </tr>
          <tr>
            <td>设备防盗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-col-ours"><strong>蓝牙关联告警</strong></td>
          </tr>
          <tr>
            <td>离线作业</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-cross">✗</td>
            <td class="adv-col-ours"><strong>无网络全功能</strong></td>
          </tr>
        </tbody>
      </table>
    </div>
    <p class="adv-note">数据来源：各品牌公开产品文档及独立评测，截止 2026 年 7 月</p>
  </section>
  <!-- /SECTION: advantages -->
```

- [ ] **Step 3: 浏览器验证**

Expected: 6 列对比表，SmartLivestock 列绿色高亮，横向可滚动（移动端）。

- [ ] **Step 4: Commit**

```bash
git add docs/marketing/solution-brochure.html
git commit -m "feat: add competitive advantages comparison table"
```

---

### Task 7: 定价 + CTA + Footer

**Files:**
- Modify: `docs/marketing/solution-brochure.html` — 替换 `<!-- SECTION: pricing -->` 和 `<!-- SECTION: cta -->` 占位，替换 `<footer>` 占位

- [ ] **Step 1: 添加定价/CTA/Footer CSS**

```css
    /* === Pricing === */
    .pricing { background: var(--color-primary-soft); }
    .pricing-grid {
      display: grid; grid-template-columns: repeat(4, 1fr);
      gap: var(--space-lg); max-width: var(--max-width);
      margin: 0 auto var(--space-xl); padding: 0 var(--space-lg);
      align-items: start;
    }
    .pricing-card {
      background: var(--color-white); border-radius: var(--border-radius);
      padding: var(--space-xl); text-align: center;
      box-shadow: var(--shadow-sm); transition: transform 0.3s ease, box-shadow 0.3s ease;
      border: 2px solid transparent; position: relative;
    }
    .pricing-card:hover { transform: translateY(-6px); box-shadow: var(--shadow-lg); }
    .pricing-card.featured {
      border-color: var(--color-primary); transform: translateY(-8px);
      box-shadow: var(--shadow-lg);
    }
    .pricing-card.featured:hover { transform: translateY(-12px); }
    .pricing-badge {
      position: absolute; top: -14px; left: 50%; transform: translateX(-50%);
      background: var(--color-primary); color: var(--color-white);
      padding: 0.25rem 1rem; border-radius: 20px;
      font-size: 0.85rem; font-weight: 700;
    }
    .pricing-name { font-size: 1.15rem; font-weight: 700; color: var(--color-text-primary); margin-bottom: var(--space-sm); }
    .pricing-price { font-size: 2.5rem; font-weight: 900; color: var(--color-primary); margin-bottom: var(--space-xs); }
    .pricing-price small { font-size: 1rem; font-weight: 400; }
    .pricing-heads { font-size: 0.9rem; color: var(--color-text-secondary); margin-bottom: var(--space-lg); }
    .pricing-features { list-style: none; text-align: left; margin-bottom: var(--space-lg); }
    .pricing-features li { padding: 0.4rem 0; font-size: 0.9rem; color: var(--color-text-secondary); border-bottom: 1px solid #f0f0f0; }
    .pricing-features li::before { content: '✓ '; color: var(--color-success); font-weight: 700; }
    .pricing-features li.disabled { color: #ccc; }
    .pricing-features li.disabled::before { content: '— '; color: #ccc; }
    .pricing-card .btn { width: 100%; }
    .pricing-trial {
      text-align: center; font-size: 1rem; color: var(--color-text-primary);
      max-width: var(--max-width); margin: 0 auto; padding: 0 var(--space-lg);
    }
    .pricing-trial strong { color: var(--color-primary); }

    /* === CTA === */
    .cta-section {
      background: linear-gradient(135deg, var(--color-primary-dark) 0%, var(--color-primary) 100%);
      color: var(--color-white); text-align: center; padding: 5rem var(--space-lg);
    }
    .cta-title { font-size: 2rem; font-weight: 700; margin-bottom: var(--space-md); }
    .cta-subtitle { font-size: 1.1rem; opacity: 0.9; margin-bottom: var(--space-xl); }
    .cta-buttons { display: flex; gap: var(--space-md); justify-content: center; flex-wrap: wrap; }
    .btn-cta-primary {
      background: var(--color-white); color: var(--color-primary);
      padding: 0.85rem 2.5rem; border-radius: 8px;
      font-size: 1.05rem; font-weight: 700; text-decoration: none;
      transition: transform 0.2s ease;
    }
    .btn-cta-primary:hover { transform: translateY(-2px); }
    .btn-cta-secondary {
      background: transparent; color: var(--color-white);
      padding: 0.85rem 2.5rem; border-radius: 8px;
      font-size: 1.05rem; font-weight: 600; text-decoration: none;
      border: 2px solid rgba(255,255,255,0.5);
      transition: all 0.2s ease;
    }
    .btn-cta-secondary:hover { border-color: var(--color-white); background: rgba(255,255,255,0.1); }

    /* === Footer === */
    .site-footer {
      background: var(--color-primary-dark); color: rgba(255,255,255,0.7);
      text-align: center; padding: var(--space-xl); font-size: 0.85rem;
    }

    @media (max-width: 1024px) {
      .pricing-grid { grid-template-columns: repeat(2, 1fr); }
    }
    @media (max-width: 640px) {
      .pricing-grid { grid-template-columns: 1fr; }
      .pricing-card.featured { transform: none; }
      .cta-title { font-size: 1.5rem; }
    }
```

- [ ] **Step 2: 替换定价/CTA/Footer HTML 占位**

```html
  <!-- SECTION: pricing -->
  <section class="section pricing" id="pricing">
    <h2 class="section-title">灵活的订阅方案</h2>
    <p class="section-subtitle">从免费版起步，按需升级，无隐性费用</p>
    <div class="pricing-grid">
      <div class="pricing-card">
        <div class="pricing-name">BASIC</div>
        <div class="pricing-price">¥0<small>/月</small></div>
        <div class="pricing-heads">含 50 头牲畜</div>
        <ul class="pricing-features">
          <li>GPS 实时定位</li>
          <li>电子围栏 ≤3 个</li>
          <li>基础设备管理</li>
          <li>7 天数据保留</li>
          <li class="disabled">健康评分</li>
          <li class="disabled">发情检测</li>
          <li class="disabled">AI 异常检测</li>
          <li class="disabled">API 访问</li>
        </ul>
        <a href="#cta" class="btn" style="background:var(--color-surface);color:var(--color-text-primary);">免费开始</a>
      </div>
      <div class="pricing-card">
        <div class="pricing-name">STANDARD</div>
        <div class="pricing-price">¥299<small>/月</small></div>
        <div class="pricing-heads">含 200 头牲畜</div>
        <ul class="pricing-features">
          <li>GPS 实时定位</li>
          <li>电子围栏 ≤5 个</li>
          <li>历史轨迹回放</li>
          <li>体温监测</li>
          <li>30 天数据保留</li>
          <li>8h 工单响应</li>
          <li class="disabled">AI 异常检测</li>
          <li class="disabled">API 访问</li>
        </ul>
        <a href="#cta" class="btn btn-primary">选择标准版</a>
      </div>
      <div class="pricing-card featured">
        <span class="pricing-badge">推荐</span>
        <div class="pricing-name">PREMIUM</div>
        <div class="pricing-price">¥699<small>/月</small></div>
        <div class="pricing-heads">含 1,000 头牲畜</div>
        <ul class="pricing-features">
          <li>STANDARD 全部功能</li>
          <li>电子围栏 ≤10 个</li>
          <li>发情检测 + 繁殖管理</li>
          <li>疫病预警 + 消化分析</li>
          <li>AI 无监督异常检测</li>
          <li>90 天数据保留</li>
          <li>4h 工单响应</li>
          <li>API 访问</li>
        </ul>
        <a href="#cta" class="btn btn-primary">选择专业版</a>
      </div>
      <div class="pricing-card">
        <div class="pricing-name">ENTERPRISE</div>
        <div class="pricing-price" style="font-size:1.75rem;">定制</div>
        <div class="pricing-heads">不限牲畜数</div>
        <ul class="pricing-features">
          <li>PREMIUM 全部功能</li>
          <li>集团多牧场联动</li>
          <li>私有化部署选项</li>
          <li>定制功能开发</li>
          <li>3 年数据保留</li>
          <li>专属客户经理</li>
          <li>7×24 电话支持</li>
          <li>SLA 99.99%</li>
        </ul>
        <a href="#cta" class="btn" style="background:var(--color-surface);color:var(--color-text-primary);">联系销售</a>
      </div>
    </div>
    <div class="pricing-trial">
      新用户注册即享 <strong>14 天 PREMIUM 全功能免费试用</strong>，到期后自动降为免费版，数据保留，随时升级
    </div>
  </section>
  <!-- /SECTION: pricing -->

  <!-- SECTION: cta -->
  <section class="cta-section" id="cta">
    <h2 class="cta-title">开启智慧养殖之旅</h2>
    <p class="cta-subtitle">14 天全功能免费试用，亲眼见证数据驱动的改变</p>
    <div class="cta-buttons">
      <a href="#" class="btn-cta-primary">预约演示</a>
      <a href="#" class="btn-cta-secondary">免费试用</a>
      <a href="#" class="btn-cta-secondary">联系销售</a>
    </div>
  </section>
  <!-- /SECTION: cta -->
```

- [ ] **Step 3: 替换 Footer 占位**

```html
  <footer class="site-footer">
    © 2026 SmartLivestock. 智慧畜牧，数据驱动的精准养殖。
  </footer>
```

- [ ] **Step 4: 浏览器验证**

Expected: 4 列套餐卡片，PREMIUM 列抬高加绿色边框 + "推荐"标签。CTA 深绿背景三按钮。Footer 深色底。

- [ ] **Step 5: Commit**

```bash
git add docs/marketing/solution-brochure.html
git commit -m "feat: add pricing, CTA, and footer sections"
```

---

### Task 8: 滚动动画 + 响应式打磨

**Files:**
- Modify: `docs/marketing/solution-brochure.html` — JS 区域加入 IntersectionObserver，CSS 加入动画类

- [ ] **Step 1: 添加滚动渐现 CSS**

```css
    /* === Scroll Reveal === */
    .reveal { opacity: 0; transform: translateY(30px); transition: opacity 0.6s ease, transform 0.6s ease; }
    .reveal.visible { opacity: 1; transform: translateY(0); }
    .reveal-delay-1 { transition-delay: 0.1s; }
    .reveal-delay-2 { transition-delay: 0.2s; }
    .reveal-delay-3 { transition-delay: 0.3s; }
```

- [ ] **Step 2: 替换 `<script>` 标签内容（保留 toggleArchDetail 函数）**

```javascript
    function toggleArchDetail() {
      const detail = document.getElementById('archDetail');
      const btn = document.querySelector('.arch-expand-btn');
      detail.classList.toggle('open');
      btn.textContent = detail.classList.contains('open') ? '收起技术栈 ▲' : '展开完整技术栈 ▼';
    }

    // Scroll reveal animation
    const observerOptions = { threshold: 0.15, rootMargin: '0px 0px -50px 0px' };
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
        }
      });
    }, observerOptions);

    document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
```

- [ ] **Step 3: 给需要动画的元素加上 `.reveal` 类**

需要修改的元素（逐个 Edit）：

- 痛点卡片：每个 `.pain-card` 加上 `class="pain-card reveal"`
- 方案步骤：每个 `.solution-step` 加上 `class="solution-step reveal"`
- 能力卡片：每个 `.cap-card` 加上 `class="cap-card reveal"` 和递增 `reveal-delay-1/2/3`
- 架构区块：`.arch-layout` 中的两个子元素分别加 `reveal`
- 对比表：`.adv-table-wrapper` 加 `class="adv-table-wrapper reveal"`
- 定价卡片：每个 `.pricing-card` 加 `reveal` + 递增 delay

- [ ] **Step 4: 响应式细调**

在 CSS 中加入平滑过渡和移动端细节调整：

```css
    /* === Smooth section transitions === */
    section { transition: padding 0.3s ease; }

    /* === Mobile nav tweaks === */
    @media (max-width: 480px) {
      .hero { padding: 4rem var(--space-md) 3rem; }
      .hero-cta { flex-direction: column; align-items: center; }
      .hero-cta .btn { width: 100%; max-width: 280px; text-align: center; }
      .cta-buttons { flex-direction: column; align-items: center; }
      .cta-buttons a { width: 100%; max-width: 280px; text-align: center; }
      .section { padding: var(--space-section) 0; }
    }
```

- [ ] **Step 5: 浏览器验证**

```bash
open docs/marketing/solution-brochure.html
```

Expected: 滚动时卡片渐现。移动端（Chrome DevTools 手机模式）：单列布局，CTA 按钮全宽。

- [ ] **Step 6: Commit**

```bash
git add docs/marketing/solution-brochure.html
git commit -m "feat: add scroll reveal animations and responsive polish"
```

---

### Task 9: 最终 QA 与内容校验

**Files:**
- No file changes expected — 验证通过则完成

- [ ] **Step 1: 内容准确性核对**

逐项核对：
- [ ] Hero 数字与规格一致：4～6 年 / 72h / 5–10km / 14 天
- [ ] 竞品对比表数据与 PRD v2.3 Section 1.5 一致
- [ ] 定价与中文市场数据一致（¥299/¥699）
- [ ] 技术数字与 CLAUDE.md 一致（51/187/39/502/53/30/63K）
- [ ] 9 个限界上下文名称正确
- [ ] 颜色 token 与 app_colors.dart 一致

- [ ] **Step 2: 多分辨率验证**

```bash
open docs/marketing/solution-brochure.html
```

在 Chrome DevTools 中验证：
- [ ] 桌面 1440px：全部多列布局正常，动画流畅
- [ ] 平板 768px：2 列布局，表格可横向滚动
- [ ] 手机 375px：单列堆叠，按钮全宽，文字不溢出

- [ ] **Step 3: 功能验证**

- [ ] 点击「展开完整技术栈」→ 表格出现，按钮文字切换
- [ ] 滚动页面 → 各区块卡片渐现动画生效
- [ ] 点击 Hero/定价 CTA 按钮 → 锚点跳转到对应区块
- [ ] 套餐卡片 hover → 上浮 + 阴影加深

- [ ] **Step 4: 最终 Commit**

```bash
git add docs/marketing/solution-brochure.html
git commit -m "feat: final QA - solution brochure complete"
```
