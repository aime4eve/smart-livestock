# 饮水检测：无真牛条件下的继续工作方案（W1-W4）

日期：2026-10-08 ｜ 状态：**待用户批准**（硬性规则：批准前不动代码）｜ 前置：NIX-256 已结项（PR #129/#131），L2-real/L3 挂起中（无真实牛只数据）

## 0. 边界与总原则

**没有真牛时能推进的**：真实**设备**链路验证（不需要牛，需要胶囊+水浴）、演示数据补全（对销售）、真数据就绪的自动关卡、L3 物料筹备。
**明确不做的**：继续用仿真数据调参/改判据——L1（Aubé，F=0.928）与 L2-pre（仿真，F=0.908）已双达标，再调就是对着自家模拟器过拟合；对外准确率口径维持"试点验证方案"（AGENTS 红线）。

## 0.5 现状盘点：已实现什么、验证覆盖到哪一段

### 功能完成度（全部已在 dev 上线，2026-10-06 用户集成测试通过）

| 模块 | 状态 | 证据 |
|---|---|---|
| 检测内核（FallST 斜率 ∧ μ−kσ+1.0°C 深度 + 35–43°C 门卫 + 15min 滚动合并 + 发热排除） | ✅ | L1 Aubé 科研数据标定 **F=0.928@5-min**（生产口径）；滚动锚定修复后 6-min 0.9201，门禁 ≥0.90 不变 |
| 端到端批量回放 | ✅ | L2-pre 30 天×10 牛仿真回放 **F=0.908**，平台与离线内核对齐（0.9078）；FN 全分解无不明项 |
| 夜批调度 + admin 批量回算 | ✅ | dev 全群回算 1.45s/0 失败；夜批 03:40 每日自动 |
| 标记闭环（确认/驳回/补录/候选转正 + 跨重算保留） | ✅ | 演练 2,098 次打标 0 失败；标签跨重算逐数一致 |
| 三层汇总 + Premium 同类对比 + 48h 图（谷点+发热阴影） | ✅ | 集成测试通过；阴影区随 NIX-259 上线，dev 已有真实发热窗渲染 |
| 标签导出 + `--labels` 调参建议 | ✅ | 2,101 标签采信门槛通过；ε 护栏后建议=维持现产参数 |
| 交付与部署 | ✅ | PR #129/#130/#131 → master；dev 饮水+疫病双功能在线；两轮交付评审遗留清零 |

### 但"已验证"只覆盖了链路的后半段

L1 的输入是**论文 CSV 文件**（直接喂算法），L2-pre 的输入是**直接写数据库**（绕过设备与接入）——也就是说，从"胶囊传感器"到"平台 temperature_logs"的前半段物理链路，**从未有任何一条真实数据走过**。同时演示环境存在第二个空档：datagen 只生成平滑温度基线，饮水卡恒显 0 次。

**全链路验证覆盖地图**（红=盲区，黄=空档，绿=已验证；W1-W4 各补一个洞）：

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 940 470" style="max-width:940px;width:100%;background:#fff" font-family="PingFang SC,Microsoft YaHei,sans-serif">
  <defs>
    <marker id="cmArrow" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L7,3 L0,6 Z" fill="#617061"/></marker>
  </defs>
  <text x="20" y="24" font-size="14" font-weight="700" fill="#374151">饮水检测全链路验证覆盖地图（2026-10-08）</text>
  <!-- W1 bracket -->
  <rect x="24" y="44" width="366" height="88" rx="10" fill="none" stroke="#C0392B" stroke-width="1.6" stroke-dasharray="7 5"/>
  <text x="36" y="62" font-size="11" font-weight="700" fill="#C0392B">W1 台架预验：把红段变绿（真胶囊+水浴 5 幕）</text>
  <!-- Row 1: real chain -->
  <g font-size="11" font-weight="700" text-anchor="middle">
    <rect x="34"  y="76" width="104" height="46" rx="7" fill="#FDECEC" stroke="#C0392B"/><text x="86"  y="97" fill="#96281B">胶囊传感器</text><text x="86"  y="112" font-size="8.5" font-weight="400" fill="#96281B">5-min 上报?</text>
    <rect x="156" y="76" width="104" height="46" rx="7" fill="#FDECEC" stroke="#C0392B"/><text x="208" y="97" fill="#96281B">LoRa 网关</text><text x="208" y="112" font-size="8.5" font-weight="400" fill="#96281B">转发形态?</text>
    <rect x="278" y="76" width="104" height="46" rx="7" fill="#FDECEC" stroke="#C0392B"/><text x="330" y="97" fill="#96281B">ThingsBoard</text><text x="330" y="112" font-size="8.5" font-weight="400" fill="#96281B">遥测落地?</text>
    <rect x="400" y="76" width="104" height="46" rx="7" fill="#FFF7E6" stroke="#D4A017"/><text x="452" y="97" fill="#8A6D0B">平台接入</text><text x="452" y="112" font-size="8.5" font-weight="400" fill="#8A6D0B">TB轮询·存量有</text>
    <rect x="522" y="76" width="104" height="46" rx="7" fill="#EAF3EC" stroke="#5B8C5A"/><text x="574" y="97" fill="#2F5233">检测内核/夜批</text><text x="574" y="112" font-size="8.5" font-weight="400" fill="#2F5233">L1+L2 双达标</text>
    <rect x="644" y="76" width="104" height="46" rx="7" fill="#EAF3EC" stroke="#5B8C5A"/><text x="696" y="97" fill="#2F5233">汇总/UI/48h图</text><text x="696" y="112" font-size="8.5" font-weight="400" fill="#2F5233">集成测试 ✓</text>
    <rect x="766" y="76" width="104" height="46" rx="7" fill="#EAF3EC" stroke="#5B8C5A"/><text x="818" y="97" fill="#2F5233">标记闭环</text><text x="818" y="112" font-size="8.5" font-weight="400" fill="#2F5233">演练 2098 次 ✓</text>
    <rect x="888" y="76" width="44" height="46" rx="7" fill="#EAF3EC" stroke="#5B8C5A"/><text x="910" y="94" font-size="9" fill="#2F5233">调参</text><text x="910" y="106" font-size="9" fill="#2F5233">闭环</text>
  </g>
  <g stroke="#617061" stroke-width="1.6">
    <line x1="138" y1="99" x2="154" y2="99" marker-end="url(#cmArrow)"/>
    <line x1="260" y1="99" x2="276" y2="99" marker-end="url(#cmArrow)"/>
    <line x1="382" y1="99" x2="398" y2="99" marker-end="url(#cmArrow)"/>
    <line x1="504" y1="99" x2="520" y2="99" marker-end="url(#cmArrow)"/>
    <line x1="626" y1="99" x2="642" y2="99" marker-end="url(#cmArrow)"/>
    <line x1="748" y1="99" x2="764" y2="99" marker-end="url(#cmArrow)"/>
    <line x1="870" y1="99" x2="886" y2="99" marker-end="url(#cmArrow)"/>
  </g>
  <text x="200" y="148" font-size="9.5" fill="#96281B">从未有真实数据走过（L1=论文文件喂算法，L2-pre=直接写库）</text>
  <!-- Row 2: demo lane -->
  <text x="20" y="196" font-size="12" font-weight="700" fill="#8A6D0B">演示链路</text>
  <rect x="34" y="208" width="170" height="46" rx="7" fill="#F8F6F0" stroke="#617061"/>
  <text x="119" y="228" font-size="11" font-weight="700" fill="#374151" text-anchor="middle">datagen 仿真温度</text>
  <text x="119" y="243" font-size="8.5" fill="#6B7280" text-anchor="middle">平滑基线 · 无饮水谷</text>
  <line x1="204" y1="231" x2="248" y2="231" stroke="#617061" stroke-width="1.6" marker-end="url(#cmArrow)"/>
  <rect x="252" y="208" width="190" height="46" rx="7" fill="#FFF7E6" stroke="#D4A017"/>
  <text x="347" y="228" font-size="11" font-weight="700" fill="#8A6D0B" text-anchor="middle">dev/test 演示环境</text>
  <text x="347" y="243" font-size="8.5" fill="#8A6D0B" text-anchor="middle">饮水卡恒显 0 次 → 客户以为没做</text>
  <path d="M470 231 L560 231" stroke="#D4A017" stroke-width="1.8" stroke-dasharray="6 4" marker-end="url(#cmArrow)"/>
  <text x="480" y="222" font-size="10.5" font-weight="700" fill="#D4A017">W2 植入标定形态谷</text>
  <text x="480" y="246" font-size="8.5" fill="#8A6D0B">演示当天活起来 + 发热/候选全链可演</text>
  <!-- Row 3: future lane -->
  <text x="20" y="296" font-size="12" font-weight="700" fill="#6B7280">未来事件（等待条件）</text>
  <g font-size="10.5" text-anchor="middle" font-weight="700">
    <rect x="34" y="308" width="150" height="46" rx="7" fill="none" stroke="#9AA5A0" stroke-dasharray="5 4"/><text x="109" y="328" fill="#4B5563">真胶囊接入牧场</text><text x="109" y="343" font-size="8.5" font-weight="400" fill="#6B7280">条件：试点/客户牛只</text>
    <rect x="228" y="308" width="170" height="46" rx="7" fill="none" stroke="#9AA5A0" stroke-dasharray="5 4"/><text x="313" y="328" fill="#4B5563">真实源累计 ≥30 天</text><text x="313" y="343" font-size="8.5" font-weight="400" fill="#6B7280">L2-real 触发条件</text>
    <rect x="442" y="308" width="170" height="46" rx="7" fill="none" stroke="#9AA5A0" stroke-dasharray="5 4"/><text x="527" y="328" fill="#4B5563">L2-real 真数据回放</text><text x="527" y="343" font-size="8.5" font-weight="400" fill="#6B7280">机制零改动，换数据即跑</text>
    <rect x="656" y="308" width="180" height="46" rx="7" fill="none" stroke="#9AA5A0" stroke-dasharray="5 4"/><text x="746" y="328" fill="#4B5563">L3 金标准试点验收</text><text x="746" y="343" font-size="8.5" font-weight="400" fill="#6B7280">水表+摄像头 96h×2</text>
  </g>
  <g stroke="#9AA5A0" stroke-width="1.5">
    <line x1="184" y1="331" x2="224" y2="331" marker-end="url(#cmArrow)"/>
    <line x1="398" y1="331" x2="438" y2="331" marker-end="url(#cmArrow)"/>
    <line x1="612" y1="331" x2="652" y2="331" marker-end="url(#cmArrow)"/>
  </g>
  <text x="238" y="376" font-size="10.5" font-weight="700" fill="#2C6486">W3 就绪面板：30 天到了系统自动举牌（不再靠任何人记得去查）</text>
  <line x1="313" y1="358" x2="313" y2="364" stroke="#2C6486" stroke-width="1.4" marker-end="url(#cmArrow)"/>
  <text x="676" y="376" font-size="10.5" font-weight="700" fill="#5B8C5A">W4 无牛先行：水表/标注/牧场物料现在备齐，有牛当天开跑</text>
  <line x1="746" y1="358" x2="746" y2="364" stroke="#5B8C5A" stroke-width="1.4" marker-end="url(#cmArrow)"/>
  <!-- Legend -->
  <g font-size="9.5">
    <rect x="34" y="416" width="18" height="12" fill="#FDECEC" stroke="#C0392B"/><text x="58" y="426" fill="#374151">盲区（无真数据走过）</text>
    <rect x="200" y="416" width="18" height="12" fill="#FFF7E6" stroke="#D4A017"/><text x="224" y="426" fill="#374151">空档（有链路无内容/未联动实测）</text>
    <rect x="420" y="416" width="18" height="12" fill="#EAF3EC" stroke="#5B8C5A"/><text x="444" y="426" fill="#374151">已验证（L1/L2-pre/dev 三级证据）</text>
    <rect x="660" y="416" width="18" height="12" fill="none" stroke="#9AA5A0" stroke-dasharray="4 3"/><text x="684" y="426" fill="#374151">未来事件（等条件）</text>
  </g>
  <text x="34" y="452" font-size="9" fill="#9AA5A0">一句话：后半段（绿）已三级证据收口；W1 补红段、W2 补演示黄段、W3 看住未来 30 天、W4 备好终点验收——四条流各补一个洞，互不依赖。</text>
</svg>

---

## W1 硬件台架预验（真实胶囊端到端链路，不需要牛）

**要回答的问题**：一条真实数据走完"胶囊 → 网关 → ThingsBoard → 平台 → 检测"全链时，形态是否满足检测器假设？这是 L1（论文文件）与 L2-pre（直接灌库）都没验过的盲区。

### 装置

| 物料 | 规格 | 说明 |
|---|---|---|
| 真胶囊 ×1 | 上次接入过 TB 的同款 | 需激活方式/供电 |
| 恒温加热磁力搅拌器 ×1（或水浴杯×2：45°C+25°C） | 控温 ±0.5°C、20-45°C | 实验室常见，约 ¥800-2000 |
| 参考温度计 ×1 | K 型热电偶/水银 ±0.1°C | 台架真值基准 |
| 采集侧 | 沿用上次真胶囊遥测接入的 TB 实例与网关 | **开放项 A**：具体实例/注册流程从运维记录核对 |

**台架设备部署示意**（示意非等比例；实线=数据流，虚线=人工操作）：

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 860 400" style="max-width:860px;width:100%;background:#fff" font-family="PingFang SC,Microsoft YaHei,sans-serif">
  <text x="20" y="26" font-size="14" font-weight="700" fill="#374151">W1 台架设备部署与数据链路</text>
  <!-- 槽A -->
  <rect x="30" y="60" width="210" height="96" rx="8" fill="#F8F6F0" stroke="#617061"/>
  <text x="44" y="82" font-size="12" font-weight="700" fill="#374151">恒温槽 A · 38.9°C ±0.5</text>
  <text x="44" y="98" font-size="10" fill="#6B7280">加热磁力搅拌器</text>
  <ellipse cx="100" cy="126" rx="30" ry="13" fill="#DCE8D5" stroke="#5B8C5A"/>
  <text x="88" y="130" font-size="9" fill="#2F5233">瘤胃胶囊</text>
  <line x1="185" y1="72" x2="185" y2="146" stroke="#D97B29" stroke-width="3"/>
  <circle cx="185" cy="76" r="4" fill="#D97B29"/>
  <text x="193" y="92" font-size="9" fill="#D97B29">参考温度计</text>
  <text x="193" y="104" font-size="9" fill="#D97B29">±0.1°C（真值）</text>
  <!-- 槽B -->
  <rect x="30" y="200" width="210" height="66" rx="8" fill="#EFF6FB" stroke="#2C6486"/>
  <text x="44" y="224" font-size="12" font-weight="700" fill="#2C6486">冷水槽 B · 25°C</text>
  <text x="44" y="240" font-size="10" fill="#6B7280">S2 谷 / S3 浅谷时换槽或注冷水</text>
  <!-- 换槽操作 -->
  <path d="M135 156 L135 196" stroke="#9AA5A0" stroke-width="2" stroke-dasharray="5 4" marker-end="url(#arrGray)"/>
  <text x="143" y="182" font-size="9" fill="#6B7280">按脚本换槽</text>
  <!-- 胶囊→网关 -->
  <defs>
    <marker id="arrGray" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L7,3 L0,6 Z" fill="#9AA5A0"/></marker>
    <marker id="arrBlue" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L7,3 L0,6 Z" fill="#2C6486"/></marker>
    <marker id="arrDark" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L7,3 L0,6 Z" fill="#374151"/></marker>
  </defs>
  <path d="M240 110 L322 110" stroke="#2C6486" stroke-width="2" marker-end="url(#arrBlue)"/>
  <text x="248" y="100" font-size="9" fill="#2C6486">LoRa 433/470MHz</text>
  <!-- 网关 -->
  <rect x="326" y="86" width="140" height="48" rx="8" fill="#fff" stroke="#617061"/>
  <text x="344" y="108" font-size="12" font-weight="700" fill="#374151">LoRa 网关</text>
  <text x="344" y="124" font-size="9" fill="#6B7280">既有设备</text>
  <!-- 网关→TB -->
  <path d="M466 110 L538 110" stroke="#2C6486" stroke-width="2" marker-end="url(#arrBlue)"/>
  <text x="470" y="100" font-size="9" fill="#2C6486">4G / 以太网</text>
  <!-- TB -->
  <rect x="542" y="86" width="140" height="48" rx="8" fill="#fff" stroke="#617061"/>
  <text x="560" y="108" font-size="12" font-weight="700" fill="#374151">ThingsBoard</text>
  <text x="560" y="124" font-size="9" fill="#6B7280">遥测接入（开放项A）</text>
  <!-- TB→平台 -->
  <path d="M612 134 L612 176" stroke="#2C6486" stroke-width="2" marker-end="url(#arrBlue)"/>
  <text x="620" y="160" font-size="9" fill="#2C6486">TB 轮询拉取</text>
  <!-- 平台 -->
  <rect x="542" y="180" width="220" height="64" rx="8" fill="#F8F6F0" stroke="#617061"/>
  <text x="560" y="204" font-size="12" font-weight="700" fill="#374151">智慧畜牧平台</text>
  <text x="560" y="220" font-size="10" fill="#6B7280">temperature_logs · source=THINGSBOARD</text>
  <text x="560" y="234" font-size="10" fill="#6B7280">（真实源 → 计入 W3 就绪面板）</text>
  <!-- 平台→检测 -->
  <path d="M612 244 L612 286" stroke="#374151" stroke-width="2" marker-end="url(#arrDark)"/>
  <!-- 检测 -->
  <rect x="542" y="290" width="220" height="60" rx="8" fill="#fff" stroke="#D97B29"/>
  <text x="560" y="312" font-size="12" font-weight="700" fill="#D97B29">检测内核 / 夜批 / admin 回算</text>
  <text x="560" y="328" font-size="10" fill="#6B7280">S2 谷检出 F≥0.90（对脚本真值）</text>
  <!-- 真值记录 -->
  <path d="M240 220 L322 220" stroke="#D97B29" stroke-width="2" stroke-dasharray="5 4" marker-end="url(#arrGray)"/>
  <rect x="326" y="196" width="140" height="48" rx="8" fill="#fff" stroke="#D97B29"/>
  <text x="344" y="218" font-size="11" font-weight="700" fill="#D97B29">温控真值 CSV</text>
  <text x="344" y="233" font-size="9" fill="#6B7280">评审基准（时间×温度）</text>
  <path d="M466 220 L538 220" stroke="#D97B29" stroke-width="2" stroke-dasharray="5 4" marker-end="url(#arrGray)"/>
  <text x="470" y="212" font-size="9" fill="#D97B29">对照评分</text>
  <text x="30" y="386" font-size="9" fill="#9AA5A0">虚线=人工/离线对照 · 实线=自动数据流 · 示意非等比例</text>
</svg>

### 温控场景脚本（5 幕）

| 幕 | 内容 | 验什么 |
|---|---|---|
| S1 稳态 | 38.9°C 恒温 12h | 采样粒度实测（假设 ≥5-min）、日点数 ≥24、时钟漂移 |
| S2 饮水谷 ×N | 程序化冷水注入/换槽：深 2.8-4.0°C、降 10-25min、指数回升；每日 6-8 谷，48h×2 轮 | 回放检出 F≥0.90（对脚本真值） |
| S3 边界谷 ×6 | 深 0.4-0.6°C 浅谷 | 进 ALGORITHM_CANDIDATE 待核实队列 |
| S4 发热段 | 39.8-40.5°C 维持 8h + 回落 | TB 告警触发 → 排除窗 → 0 检出 + 48h 图阴影渲染 |
| S5 断连 | 断电 2h | 缺口不产生幻影事件（MAX_ADJACENT_GAP 行为） |

**五幕温控场景时间轴**（纵轴温度 25-41°C，横轴约 120h，示意非等比例）：

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 380" style="max-width:900px;width:100%;background:#fff" font-family="PingFang SC,Microsoft YaHei,sans-serif">
  <text x="20" y="26" font-size="14" font-weight="700" fill="#374151">W1 五幕温控脚本（温度-时间示意）</text>
  <!-- 阶段底色带 x: S1 60-170, S2 170-470, S3 470-580, S4 580-730, S5 730-830 -->
  <rect x="60"  y="50" width="110" height="280" fill="#F8F6F0"/>
  <rect x="170" y="50" width="300" height="280" fill="#EFF6FB"/>
  <rect x="470" y="50" width="110" height="280" fill="#F8F6F0"/>
  <rect x="580" y="50" width="150" height="280" fill="#FBF1E7"/>
  <rect x="730" y="50" width="100" height="280" fill="#F3F4F6"/>
  <!-- 阶段标签 -->
  <text x="66"  y="68" font-size="11" font-weight="700" fill="#374151">S1 稳态 12h</text>
  <text x="176" y="68" font-size="11" font-weight="700" fill="#2C6486">S2 饮水谷×6-8/日 · 48h×2 轮</text>
  <text x="476" y="68" font-size="11" font-weight="700" fill="#374151">S3 浅谷×6</text>
  <text x="586" y="68" font-size="11" font-weight="700" fill="#D97B29">S4 发热 8h</text>
  <text x="736" y="68" font-size="11" font-weight="700" fill="#6B7280">S5 断电 2h</text>
  <!-- y(T)=330-(T-25)*15.6 → 38.9→113, 40.2→93, 38.4→121, 35→181, 25→330 -->
  <!-- 网格线 -->
  <line x1="60" y1="113" x2="830" y2="113" stroke="#E5E7EB" stroke-dasharray="3 4"/>
  <text x="836" y="117" font-size="9" fill="#9AA5A0">38.9</text>
  <line x1="60" y1="181" x2="830" y2="181" stroke="#E5E7EB" stroke-dasharray="3 4"/>
  <text x="836" y="185" font-size="9" fill="#9AA5A0">35.0</text>
  <line x1="60" y1="93"  x2="830" y2="93"  stroke="#E5E7EB" stroke-dasharray="3 4"/>
  <text x="836" y="97" font-size="9" fill="#9AA5A0">40.2</text>
  <!-- S1 平线 -->
  <polyline points="60,113 170,113" fill="none" stroke="#5B8C5A" stroke-width="2.5"/>
  <text x="70" y="132" font-size="9" fill="#5B8C5A">实测采样粒度 ≤5min？</text>
  <text x="70" y="144" font-size="9" fill="#5B8C5A">12h 点数 ≥144</text>
  <!-- S2 六谷锯齿（两轮缩影） -->
  <polyline points="170,113 185,113 200,181 215,150 232,113 247,113 262,181 277,150 294,113 309,113 324,181 339,150 356,113 371,113 386,181 401,150 418,113 433,113 448,181 463,150 470,121" fill="none" stroke="#2C6486" stroke-width="2.5"/>
  <text x="196" y="205" font-size="9" fill="#2C6486">谷深 2.8-4.0°C · 降 10-25min · 回升 60-120min</text>
  <text x="196" y="218" font-size="9" fill="#2C6486">回放验收：F≥0.90（对脚本真值）</text>
  <!-- S3 浅谷 -->
  <polyline points="470,121 485,121 495,128 505,121 520,121 530,128 540,121 555,121 565,128 580,113" fill="none" stroke="#5B8C5A" stroke-width="2.5"/>
  <text x="474" y="145" font-size="9" fill="#5B8C5A">深 0.4-0.6°C</text>
  <text x="474" y="157" font-size="9" fill="#5B8C5A">→ 待核实候选队列</text>
  <!-- S4 发热段 -->
  <polyline points="580,113 600,93 700,93 720,113 730,113" fill="none" stroke="#D97B29" stroke-width="2.5"/>
  <text x="590" y="86" font-size="9" fill="#D97B29">39.8-40.5°C 维持</text>
  <text x="590" y="130" font-size="9" fill="#D97B29">预期：TB 告警触发 → 窗内 0 检出</text>
  <text x="590" y="143" font-size="9" fill="#D97B29">→ 48h 图阴影渲染</text>
  <!-- S5 断连 -->
  <polyline points="730,113 742,113" fill="none" stroke="#6B7280" stroke-width="2.5"/>
  <line x1="742" y1="113" x2="818" y2="113" stroke="#6B7280" stroke-width="1.5" stroke-dasharray="2 6"/>
  <polyline points="818,113 830,113" fill="none" stroke="#6B7280" stroke-width="2.5"/>
  <text x="736" y="136" font-size="9" fill="#6B7280">数据缺口</text>
  <text x="736" y="148" font-size="9" fill="#6B7280">→ 0 幻影事件</text>
  <!-- x 轴 -->
  <line x1="60" y1="330" x2="830" y2="330" stroke="#9AA5A0" stroke-width="1"/>
  <text x="445" y="352" font-size="10" fill="#6B7280">时间（全程约 120h，其中 S2 轮次 96h 机时）</text>
  <text x="60" y="370" font-size="9" fill="#9AA5A0">示意非等比例 · 纵轴 25-41°C · 基线 38.9°C 对应健康瘤胃温度</text>
</svg>

### 实施步骤

1. 开放项 A 核对（TB 实例/设备注册）＋装置搭建（0.5d）；
2. S1-S5 脚本化执行（机械换水可人工按表操作，温度曲线以参考温度计记录为准）（0.5d 编排 + 96h 机时）；
3. 平台侧：接入完成待 96h；经 `POST /admin/drinking-recalculate` 全窗回算；对照脚本真值评分（复用 T6 评分脚本）（1d）；
4. 报告落 `docs/research/`：逐幕验收结果 + 原始数据导出 + 温控真值曲线 vs 上报曲线对照（0.5d）。

### 验收标准（逐项）

1. S1：实测采样间隔 ≤5min 占比 ≥95%，12h 点数 ≥144；
2. S2：检出 Se/PPV/F 对脚本真值 F≥0.90；
3. S3：≥5/6 浅谷进候选队列；
4. S4：告警触发、窗内 0 事件、48h 阴影可见；
5. S5：缺口段 0 幻影事件；
6. 报告归档，数据导出（source=THINGSBOARD，天然真实源）。

### 风险与对策

- 胶囊实际上报粒度 >5min（如 10-min）→ **台架的核心价值正在于此**：直接得出"固件采样率需调整"的硬结论，进固件需求单；
- 水浴降温速率 ≠ 牛瘤胃降温速率 → 报告如实记录形态差异，检出判定以脚本真值为准（形态学参数已知敏感轴：深度/回升比，见 spec §14）。

**工作量：约 3 人日 + 96h 机时。** 需要你提供：胶囊及激活方式、TB 接入信息（开放项 A）、搅拌器或采购预算。

---

## W2 演示谷补全（datagen 植入饮水形态，销售演示用）

**要回答的问题**：客户打开 dev/test 演示环境时，饮水卡有活数据可看（当前 datagen 温度是平滑基线，饮水卡恒空——"0 次"会被当成功能没做）。

### W2a 实时谷植入（SynthesisService，1d）

- 挂载点：`generateCapsuleBaseline` 的 7 点/tick 生成（`SynthesisState` 已有状态机）；
- 每牛日饮水计划：Poisson(7) 截断 [4,11] 谷/日（对齐 Cardot 7.3±2.8 量级），06:00-21:00 分布；
- 谷形态=标定正典：深度 log-uniform[2.8,4.0]°C、下降 10-25min 线性、指数回升（0.7×D 于 60-120min 内恢复）、噪声 σ0.06；
- 10% 边界谷（0.35-0.55°C）→ 候选"待核实"队列可演示；
- 开关：`DatagenFarmRules` 增 `drinkingValleys` 布尔（demo 规则默认开、可按牧场关）——沿用 datagen 控制台规则面，不需要新配置体系。

### W2b 发热演示段（0.5d，可选）

- 复用既有 `demoHealthEvent` 机制：每牧场每周 1 次 8h +1.2°C 发热段 → 触发 TEMPERATURE_ABNORMAL → 周柱橙染 + 48h 阴影 + "发热期·已排除"标注全链活演示。

### W2c 即装即得回填（0.5d）

- `backfill_sim.py` 增 `--emit-datagen`：输出 temperature_logs 列序、source=DATAGEN、按目标牧场胶囊绑定选牛；
- README 附 test/dev 一键 `\copy` 与**清理条款**（AGENTS §2：明确时间窗 + 结束后清理恢复快照）；
- 效果：全新演示环境当天即有 30 天历史 → 基线/同类对比立即可示（否则要自然养数据 30 天）。

### 验收标准

1. dev/test 部署后 24h：夜批产出 DATAGEN 事件，饮水卡日柱 4-11 次/日非空；
2. 候选队列可见且可转正/驳回（打标闭环演示路径完整）；
3. W2b：发热日柱橙染 + 48h 阴影渲染 + 卡内发热提示文案；
4. W2c：全新库回填后 summary 三层（日/周/30 日基线）即刻有值；
5. 红线自检：事件 source=DATAGEN 全程透传；导出/标签工具对这些行行为正常。

**工作量：2 人日。** 部署 dev 需你按惯例放行（test 同）。

---

## W3 真实数据就绪面板（把"等 30 天"变成系统自动举牌）

**要回答的问题**：真胶囊哪天接入、哪天攒够 30 天可做 L2-real——不需要任何人记得去查。

### 设计

- **real-source 集**：`health.drinking.real-sources`（默认 `THINGSBOARD,AGENTIC_PLATFORM`；`UNKNOWN` 为历史遗留真实数据是否计入——**开放项 B**，默认不计，运维可加）；
- **指标（每设备）**：近 90 天"真实源牛日"数（当日该设备真实源点 ≥24）｜当前连续天数｜状态机 `未接入 → 采集中 → 已就绪`｜`readyAt` 预估（连续采集则=首见日+29 天）；
- **端点**：`GET /api/v1/admin/drinking/real-data-readiness`（PLATFORM_ADMIN/B2B_ADMIN）→ 每设备行 + 牧场汇总；
- **实现注记**：90 天全设备聚合在分区表上按日聚合（`date_trunc('day')` + source 过滤）；量级先实测（万级设备内毫秒级），超量级再加日批缓存表——P1 不预优化；
- **展示**：P1=端点+JSON（curl 即用）；P1.5=若已有平台管理 UI 则挂一行汇总（实施时核实，无则止步端点）；就绪提醒=响应 `ready:true` 标记，运维脚本可订阅（不新建通知渠道）。

### 验收标准

1. 本地栈造 THINGSBOARD 源 32 天点（隔日断一天）→ realDays=31、status=ready、readyAt=首见+30；
2. 同设备 DATAGEN 点不计入；
3. UNKNOWN 按 config 开关两态行为正确；
4. 无设备环境返回空列表不报错。

**工作量：1-1.5 人日。**

---

## W4 L3 无牛筹备（物料与文档，花钱项你拍板）

**L3 试点牧场设备部署示意**（侧视，示意非等比例；三路数据流=胶囊遥测 / 水表脉冲 / 视频标注）：

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 430" style="max-width:900px;width:100%;background:#fff" font-family="PingFang SC,Microsoft YaHei,sans-serif">
  <text x="20" y="26" font-size="14" font-weight="700" fill="#374151">L3 试点牧场设备部署（侧视示意）</text>
  <defs>
    <marker id="faBlue" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L7,3 L0,6 Z" fill="#2C6486"/></marker>
    <marker id="faGray" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L7,3 L0,6 Z" fill="#9AA5A0"/></marker>
    <marker id="faOrange" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L7,3 L0,6 Z" fill="#D97B29"/></marker>
    <marker id="faGreen" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L7,3 L0,6 Z" fill="#5B8C5A"/></marker>
  </defs>
  <!-- 地面 -->
  <line x1="30" y1="345" x2="870" y2="345" stroke="#9AA5A0" stroke-width="2"/>
  <text x="36" y="360" font-size="9" fill="#9AA5A0">牧场地面</text>
  <!-- 牛 ×2 -->
  <g>
    <ellipse cx="120" cy="300" rx="52" ry="30" fill="#F8F6F0" stroke="#617061"/>
    <rect x="86" y="322" width="8" height="23" fill="#617061"/><rect x="146" y="322" width="8" height="23" fill="#617061"/>
    <ellipse cx="176" cy="286" rx="16" ry="12" fill="#F8F6F0" stroke="#617061"/>
    <circle cx="138" cy="296" r="6" fill="#2C6486" stroke="#fff" stroke-width="1.5"/>
    <ellipse cx="255" cy="306" rx="46" ry="26" fill="#F8F6F0" stroke="#617061"/>
    <rect x="226" y="326" width="7" height="19" fill="#617061"/><rect x="278" y="326" width="7" height="19" fill="#617061"/>
    <circle cx="268" cy="303" r="5.5" fill="#2C6486" stroke="#fff" stroke-width="1.5"/>
    <text x="56" y="272" font-size="11" font-weight="700" fill="#374151">泌乳牛 ×8-12</text>
    <text x="56" y="287" font-size="9" fill="#2C6486">● 瘤胃胶囊 · 5-min 上报</text>
  </g>
  <!-- 饮水槽 -->
  <rect x="470" y="300" width="150" height="45" rx="6" fill="#EFF6FB" stroke="#2C6486"/>
  <rect x="476" y="312" width="138" height="26" rx="3" fill="#B9D4E6"/>
  <text x="492" y="292" font-size="11" font-weight="700" fill="#2C6486">饮水槽（≤2 处）</text>
  <!-- 进水管+水表 -->
  <line x1="380" y1="330" x2="470" y2="330" stroke="#2C6486" stroke-width="4"/>
  <circle cx="428" cy="330" r="14" fill="#fff" stroke="#2C6486" stroke-width="2"/>
  <text x="421" y="334" font-size="11" font-weight="700" fill="#2C6486">W</text>
  <text x="392" y="312" font-size="9" fill="#2C6486">DN15 脉冲水表（启动流量≤1.5L/min）</text>
  <!-- 采集器 -->
  <rect x="300" y="216" width="118" height="40" rx="6" fill="#fff" stroke="#2C6486"/>
  <text x="312" y="232" font-size="10" font-weight="700" fill="#2C6486">脉冲采集器</text>
  <text x="312" y="246" font-size="9" fill="#6B7280">树莓派记时间戳</text>
  <line x1="428" y1="316" x2="392" y2="256" stroke="#2C6486" stroke-width="1.8" marker-end="url(#faBlue)"/>
  <!-- 摄像头杆 -->
  <line x1="700" y1="345" x2="700" y2="120" stroke="#617061" stroke-width="4"/>
  <rect x="676" y="112" width="48" height="20" rx="4" fill="#374151"/>
  <text x="648" y="98" font-size="10" font-weight="700" fill="#374151">摄像头 ×2</text>
  <text x="648" y="127" font-size="8" fill="#6B7280">俯拍+侧拍</text>
  <path d="M676 122 L560 300" stroke="#9AA5A0" stroke-width="1" stroke-dasharray="4 4"/>
  <path d="M700 132 L610 300" stroke="#9AA5A0" stroke-width="1" stroke-dasharray="4 4"/>
  <!-- LoRa 网关杆 -->
  <line x1="800" y1="345" x2="800" y2="140" stroke="#617061" stroke-width="4"/>
  <line x1="800" y1="140" x2="800" y2="112" stroke="#2C6486" stroke-width="3"/>
  <circle cx="800" cy="110" r="4" fill="#2C6486"/>
  <text x="760" y="170" font-size="10" font-weight="700" fill="#2C6486">LoRa 网关</text>
  <!-- 胶囊→网关 无线弧 -->
  <path d="M150 282 Q480 60 792 128" fill="none" stroke="#2C6486" stroke-width="1.6" stroke-dasharray="6 4" marker-end="url(#faBlue)"/>
  <text x="440" y="88" font-size="9" fill="#2C6486">433/470 MHz</text>
  <!-- 云端区 -->
  <rect x="40" y="52" width="180" height="44" rx="8" fill="#F8F6F0" stroke="#617061"/>
  <text x="58" y="70" font-size="11" font-weight="700" fill="#374151">ThingsBoard → 平台</text>
  <text x="58" y="86" font-size="9" fill="#6B7280">temperature_logs（真实源）</text>
  <path d="M796 112 Q460 40 224 70" fill="none" stroke="#2C6486" stroke-width="1.8" marker-end="url(#faBlue)"/>
  <text x="380" y="42" font-size="9" fill="#2C6486">4G / 以太网</text>
  <!-- 视频链 -->
  <rect x="640" y="216" width="130" height="40" rx="6" fill="#fff" stroke="#374151"/>
  <text x="654" y="232" font-size="10" font-weight="700" fill="#374151">NVR / 存储</text>
  <text x="654" y="246" font-size="9" fill="#6B7280">96h×2 轮录像</text>
  <line x1="700" y1="134" x2="700" y2="212" stroke="#374151" stroke-width="1.8" marker-end="url(#faGray)"/>
  <rect x="640" y="286" width="150" height="44" rx="6" fill="#FBF1E7" stroke="#D97B29"/>
  <text x="654" y="304" font-size="10" font-weight="700" fill="#D97B29">人工标注 → truth.csv</text>
  <text x="654" y="318" font-size="9" fill="#6B7280">判定：嘴触水≥3s 计一次</text>
  <line x1="705" y1="258" x2="708" y2="282" stroke="#D97B29" stroke-width="1.8" marker-end="url(#faOrange)"/>
  <!-- 水表→对齐 -->
  <path d="M359 256 Q420 320 636 305" fill="none" stroke="#2C6486" stroke-width="1.6" stroke-dasharray="6 4" marker-end="url(#faBlue)"/>
  <text x="430" y="278" font-size="9" fill="#2C6486">脉冲时刻 CSV</text>
  <text x="438" y="266" font-size="9" fill="#D97B29">±2min 互认 → 复核队列</text>
  <!-- 检测对照 -->
  <rect x="40" y="150" width="180" height="44" rx="8" fill="#EFF6FB" stroke="#2C6486"/>
  <text x="56" y="168" font-size="10" font-weight="700" fill="#2C6486">平台检测结果</text>
  <text x="56" y="182" font-size="9" fill="#6B7280">事件/频次（被评对象）</text>
  <path d="M128 96 L128 146" stroke="#2C6486" stroke-width="1.8" marker-end="url(#faBlue)"/>
  <text x="30" y="410" font-size="9" fill="#9AA5A0">双通道金标准（水表+视频）· 96h×2 轮间隔≥7 天 · 预跑 48h 适应期 · 示意非等比例</text>
</svg>

### W4a 水表选型清单（0.5d 出采购单）

| 候选 | 型类 | 单价区间 | 优劣 |
|---|---|---|---|
| ① | DN15 霍尔涡轮脉冲传感器（NPN 脉冲） | ¥30-120 | 便宜、脉冲密；需自配计数采集器（树莓派/PLC 记脉冲时间戳）、IP65 需防水壳 |
| ② | 工业脉冲远传水表 DN15-25（机械表+脉冲模块） | ¥150-400 | 耐用、量程稳；启动流量偏高（慢饮可能漏计） |
| ③ | LoRa/NB-IoT 远传水表 | ¥300-600 | 免采集器；依赖网关/运营商 |

**推荐 ②×2 主用 + ①×2 备用，预算 ≤¥1500**。选型硬指标：牛饮水峰值流速 2-20L/min 在量程内、**启动流量 ≤1.5L/min**（慢饮也计到）、IP67、脉冲当量书面确认（每升 N 脉冲，写进标注协议换算）。

### W4b 标注套件（1d）

- CSV 模板（truth.csv 同构：`bout_start/bout_end/duration/drink_count/annotator/confidence/video_file/clock_offset`）；
- 标注指南：VLC 逐帧快捷键流程；判定规则（嘴触水 ≥3s 计一次饮水；间隔 <60s 并段）；与水表脉冲时刻对齐口径（±2min 内互认，超差进复核队列）；
- 双人 10% 交叉质检 + 一致率门槛（≥90%）；培训样例视频脚本（5 个典型段）；
- 产出物：`docs/research/` 标注包（模板+指南+质检单）。

### W4c 牧场人选标准 + 合作一页纸（0.5d）

- 筛选条件：泌乳牛 ≥12 头可分群｜饮水点 ≤2 处可装水表/摄像头｜有电有网或可布 4G｜车程 ≤3h｜愿签数据协议；
- 一页纸（给牧场主）：装什么、装多久、对牧场的回报（免费获得 96h 饮水监测报告 + 后续优惠）。

**工作量：2 人日（不含采购到货周期）。**

---

## 5. 排期、依赖与排序逻辑

```
W2 演示谷 (2d)   ──┐
W1 台架   (3d+96h机时) ├── 四线并行，互不依赖
W3 就绪面板 (1.5d) ├── 
W4 L3筹备 (2d)    ──┘（W4a 采购周期长，批准即下单）
```

### 为什么建议 W2 → W1 → W3 → W4

排序原则只有三条，对着 §0.5 覆盖地图看就直白：

1. **外部依赖最少的先做**——W2 是纯软件、零外部依赖（datagen 在我们手里），批准即可开工；W1 价值最高但要等你提供胶囊、激活方式、TB 接入信息（开放项 A），且 96h 是无人值守机时——所以 W2 先动工，W1 的物料核对并行去要，人到机开。
2. **销售回报最先落袋**——W2 完成当周，dev/test 演示环境的饮水卡就"活"了（当前恒 0 次是销售现场的真实痛点）；W1/W3 的收益是技术性与流程性的，兑现晚于 W2。
3. **长周期采购立即启动、编码排后**——W4a 水表下单后要吃物流周期，批准当天就该下单（不等编码排到它）；W4b/c 文档没有前置依赖，放最后收尾。

W3 排在 W1 后的原因：它很小（1.5 天），且语义上"接住 W1 的成果"——台架通关证明链路可行后，将来真设备接入，30 天门槛由 W3 自动盯，不需要人记着。

**一句话：四条流不是并列待办清单，而是覆盖地图上四个洞各补一刀——红段（W1）、演示黄段（W2）、未来 30 天盯梢（W3）、终点验收物料（W4）。** 全部批准时按上述顺序串行推进；只批准部分时按已批的任意顺序做（互不依赖）。

## 6. 工单拆分建议（批准后立单）

- W1 → NIX-26x「饮水检测硬件台架预验」（含开放项 A 核对）；
- W2 → NIX-26x「datagen 饮水谷演示植入」；
- W3 → NIX-26x「真实数据就绪面板」；
- W4 → 并入 L3 试点立项单（与 2026-10-06 L3 方案合并为一张 Epic）。

## 7. 需要你提供的

1. **W1**：胶囊 1 颗及激活方式；上次真胶囊接入的 TB 环境（开放项 A）；搅拌器实物或采购预算；
2. **W2**：dev/test 部署放行（按惯例 dev 我可自行，test 等通知）；
3. **W4a**：采购预算确认（≤¥1500）；
4. **开放项 B**：历史 UNKNOWN 数据是否计入"真实源"（默认不计）。
