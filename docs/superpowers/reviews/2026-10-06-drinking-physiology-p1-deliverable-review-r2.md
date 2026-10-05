# NIX-256 产出物评审报告 R2（修复核验 + T6 交付物）

> 评审日期：2026-10-06
> 分支：`nix/256-drinking-physiology-p1`（评审基线 `992c756a`）
> 范围：上一轮评审（基线 `64b5d402`，报告 `2026-10-05-drinking-physiology-p1-deliverable-review.md`）之后的 5 个提交：
> `f02722f9`（评审修复 batch 1+2）、`8bbecab5`（CSV 导出端点）、`2be76996`（离线工具）、`af2c6f5a`（rolling merge anchor 修复）、`992c756a`（L2-pre 回放报告）
> 方法：4 个评审域并行（后端修复销号 / 标定口径+滚动锚定 / Flutter 修复 / T6 交付物+证据链），对照上一轮评审报告逐项销号 + 新发现问题；纯静态 + git 命令 + 产物交叉核对 + 截图目检。

## 总体判断

**修复方向与质量总体优秀**：B1 按推荐路径收口（生产口径重标定，F=0.928/0.9209 过门禁，spec §14.1 转正，三处数字一致）；M1/M2/M5/M6/M7 修复正确且有实质测试；滚动锚定修复正确（Java/Python 同构），且它本身是 T6 回放捕获的真 bug——回放环节价值得到证明。T6 交付物核心扎实：回放报告数字全部交叉核对通过、CSV 导出契约合规、backfill 生成器质量高、L2-real 顺延显式记录。

**但有三类问题挡在 T7 之前**：
1. **journey 集成测试从未真正跑绿**（B2/M8/m-e 同根），且 CI 结构性排除集成测试，测试类自述 "executed in CI/dev" 失实；
2. **证据链自伤**：af2c6f5a 覆盖了 L1 正典产物目录、"byte-identical/逐数一致"声明不实（6-min 0.9209→0.9201）、截图证据与报告结论不符、label_drill.py 复现不出报告声称的手工补录；
3. **保真豁免仍在自裁**：昨日 7 项 FAIL 至今无正式豁免记录，新补的 2 份 PASS 报告违反 spec"无 worst-region FAIL"口径。

---

## 一、上一轮发现销号总表

| 发现 | 状态 | 证据摘要 |
|---|---|---|
| B1 深度判据 1.0°C 门槛 | ✅ 已修复（重标定转正路径） | `calibrate.py --depth-margin/--in-body-gate/--merge-gap`；生产口径 5/6-min F=0.928/0.9209 ≥0.90（10-min 0.8756 如实记录）；spec §14.1 + plan 附录 + results-production 三处一致。**附带证据链新问题 N1~N4** |
| B2 PhysiologyEventJourneyTest 必挂 | ⚠️ 静态修复成立，执行证据仍缺 | 改 JdbcTemplate 直插（UTC calendar 绑定、秒截断、GeneratedKeyHolder 回读，逻辑正确）；但 `build/test-results/` 无 journey 痕迹、CI 显式排除集成测试、提交说明自述 Docker 不可用 |
| M1 35–43°C 门卫 | ✅ 已修复 | 截断信号重标定，Se 89.0→86.6% 代价写入 spec §14.1；校准/内核门卫同构（含端点、均在日统计前过滤） |
| M2 同类均值含本牛 | ✅ 已修复（代码对齐 spec） | target `continue` 完全排除，全员 ≥5 天；测试反转后数学复核正确（390/60=6.50、peerCount=2）；spec §4 未动 |
| M3 gap=15 不可复现 | ⚠️ 部分修复 | `--merge-gap` 默认 15 ✓；但 `grid_results_gap15.csv` 仍是内联 schema 产不出；且 af2c6f5a 覆盖 L1 正典产物（N1） |
| M4 保真门禁自豁免 | ⚠️ 部分修复，豁免仍自裁 | 4 组缺失对照已补（no-data 89.6/skeleton 86.1/backfill NA/locked 两份）；**但** 2 份新 PASS 有 worst-region <85%（N7）、locked 两份 FAIL（79.9/77.6）只有作者自述 FRAMING.md、昨日 7 项 FAIL 仍无豁免记录 |
| M5 配置键缺失 | ✅ 已修复 | yml 两键 + `@Value` 一致；baselineMinDays 三层 summary 全下发（journey 断言=3）；lowConfidence 服务端派生、MANUAL 豁免正确；Flutter 镜像注释已修正 |
| M6 48h 谷点缺失 | ✅ 已修复 | `from: today−2d`；00:30/08:00/23:59 三点代入求值取数窗恒 ⊇ 绘图窗，闭环 |
| M7 生理编辑/删除 UI | ✅ 已修复（附 minor F2） | 行尾图标按钮；update/delete 接通死方法；三角色门控 + MANUAL 且 id≠null 行才可编辑（DISPOSITION 投影行天然排除）；删除二次确认；编辑 sheet 类型锁定/日期预填/500 字/防双击 |
| M8 发烧排除零端到端 | ⚠️ 测试已补且真实有效，执行证据同 B2 缺 | ACTIVE 开窗→全日零检出；AUTO_RESOLVED+6h→14:00 谷被吞、20:00 谷 containsExactly 存活（证明窗口有界）；断言非假绿但从未跑过 |
| m-a scanTo 硬编码 | ✅ | 改用 recalcOverlapHours，对称 |
| m-b 重算残日 μ/σ | ❌ 未修复 | 温度点下界仍 deleteFrom−DAY_PREFIX，无裁决记录 |
| m-c PATCH UNLABELED 超契约 | ❌ 未修复 | spec §15.2 未补、代码仍放行 |
| m-d POST /manual 幂等 | ✅ | 预查 + 竞态兜底重读；非事务化 save 论证正确；单测+journey 双钉 |
| m-e journey 从未真跑 | ❌ 未修复且自述失实加重 | javadoc 仍称 "executed in CI/dev"，CI 实际 `-PexcludeIntegrationTests=true`（N5） |
| m-f sample-day ≥24 点回写 spec | ❌ 未修复 | spec §4 未动 |
| m-g 窗口含今天 | ❌ 未修复 | spec §4 未钉、代码未动 |
| m-h F6 ±1h 边界测试 | ❌ 未修复 | +45 行检测测试全是滚动锚定用例 |
| m-i peer 扇出 32N | ◐ 部分缓解 | M2 顺带省 target 一路；根本扇出仍在（昨日已定性技术债） |
| m-j null body NPE | ✅（昨日定级偏重属实） | 复核：request==null 时前两行先抛 400，原不可达 |
| m-k~m-p 生理 minor | ❌ 未修复（未裁决） | |
| m-q 发热阴影区 | ❌ 未修复/未裁决 | plan 未裁 |
| m-r backfill 第 5 态 | ✅ 显式记录 | 代码注释 + state-backfill.NA.md（理由成立）；**spec §3.3 五态表述未同步** |
| m-s 生理侧零测试 | ◐ 部分修复 | 新增 342 行断言实质；但六形态渲染/farm 切换重建/未来日期/500 字上限仍零断言 |
| m-t real_api 静默 SKIP | ❌ 未修复 | |
| m-u 30min 陈旧注释 | ◐ 部分修复 | `combined_detector.py:15` docstring 仍写 "(30 min, fixed by spec)" |
| n3 chain-merge"行为正确" | ✅ 结论被 T6 证据推翻并修复 | 回放暴露幻影切分（52/174 谷、PPV 0.795）；双侧滚动锚定同构，因果链在报告 §0/§1.2 记录清楚 |
| n4 门卫重复定义 | ❌ 未修复 | 35.0/43.0 仍两处硬编码 |
| n8 mini-bars 封顶 / n9 备注 200 vs 500 / n12 painter 两套 / n13 硬编码色 | ❌ 未修复 | |
| n10 死 ARB key | ✅ | healthDrinkingWeekBars 三处删除零残留 |
| 上轮评审报告入库 | ✅ 无篡改 | f02722f9 单提交 +215 行，无后续修改 |

---

## 二、本轮新发现

### 🔴 T7 前必须闭环

**N1 · journey 集成测试从未跑绿 + CI 结构性排除 + 自述失实**
- `DrinkingEventJourneyTest.java:56-58` javadoc 称 "executed in CI/dev"，但 `.github/workflows/backend-ci.yml` 跑的是 `./gradlew test -PexcludeIntegrationTests=true`（`build.gradle:115`）——"executed in CI"从无可能；本机 `build/test-results/` 仅 DetectionService 单测痕迹。
- 涉及：B2（生理 journey）、M8（发烧排除 journey）、m-d（manual 幂等 journey 断言）、M5（三层 baselineMinDays=3 journey 断言）——**这些关键语义全部只有静态保证**。
- 处置：在有 Docker 的环境显式跑通三个 journey 类并留证（dev 部署后冒烟可顺带完成）；修正测试类自述。

### 🟠 Major

**N2 · af2c6f5a 覆盖 L1 正典产物目录，L1 报告引用全断链**
- `calibrate.py:505-506` `--out` 缺省 `results/`，重跑未带 `--out` → L1 原产物（0.94/TP650/FP3、gap=30 初版 375 行）被生产口径数字覆盖。
- L1 标定报告 `:5`/`:142`/`:174` 的引用全部指向已被覆盖的文件；报告从未同步修改。
- `results/` 与 `results-production/` 现在同为生产口径但 6-min 差 1 TP，无任何文档解释两目录并存关系。
- 处置：恢复 L1 正典产物（或改 L1 报告引用指向）+ 给 spec §14.1 复现命令补 `--out output/drinking-l1/results-production`。

**N3 · "byte-identical/逐数一致"验证声明不实**
- af2c6f5a 提交说明与 spec §14.1 勘误（spec:270）称"全网格重跑逐数一致"；实际 diff 两目录 grid CSV 有 **15 行差异全在 6-min**（rolling 锚定每行 TP−1：选定行 622/0.9201 vs 623/0.9209）。
- spec §14.1 正典表的 0.9209 是修复前 chain-first 代码的产物，**当前内核复跑得 0.9201**——正典数字与当前内核脱钩（门禁结论不受影响，0.9201≥0.90）。
- replay 报告 `:37` 引用的 "0.9006@6min" 也是修复前数字。
- 处置二选一：三处表述改为"5/10-min 逐数一致、6-min TP−1（F 0.9201，门禁不变）"（推荐，保留锚定敏感性的定量证据）；或用当前代码重跑覆盖 results-production/ 并同步 spec/plan 数字。

**N4 · label_drill.py 的 manual POST 必然 400，复现不出报告声称的 3 条补录**
- `output/drinking-l2/drill/label_drill.py:113-114` 发送 `t["start"] + ":00"`，truth.csv 的 bout_start 已含秒（`2026-09-05T07:25:00`），拼出 `"…07:25:00:00"`；后端严格按 `yyyy-MM-dd HH:mm` 解析必抛 400。
- 报告 §2 自述"带秒→400 VALIDATION_ERROR"恰好证明此路径不通，却又声称 "POST manual ×3 成功（id 7672–7674）"——提交版脚本复现不出（`:80` 声称可复现）。
- 修法：`t["start"][:16]` 一行；需作者说明当时实际执行路径。

**N5 · 英文边界样张证据与结论不符（截图重复且不含饮水分节）**
- `ui-en-detail-1.png` 与 `ui-en-detail-2.png` md5 完全相同（`2a052fbd…`），内容均为详情页**顶部**（无饮水分节）；`ui-en-home.png` 实为登录页。
- 报告 §4（`:69`）声称这两张截图证明"发热长注释英文完整呈现、无截断溢出 ✓"——证据不支撑结论。golden 测试（Ahem 方框字）只证几何证不了实字渲染。
- 修法：en-US locale 滚动至饮水分节重截图替换；或修订该行为"几何已由 golden 覆盖、实字渲染待补"。

**N6 · 两份新 PASS 保真报告违反 spec"无 worst-region FAIL"口径**
- `state-no-data.report.txt`：overall 89.6% PASS 但 content 区 **84.5%**；`state-skeleton.report.txt`：overall 86.1% 但 bottom_nav **69.0%**、summary_strip **84.5%**。
- spec §6 验收 1 原文"≥85%（**区域报告无 worst-region FAIL**）"——按字面两份都应 FAIL。实现方再次按 overall 口径自判 PASS（M4 延续）。
- 附带：报告生成器诊断自相矛盾（先列 `[!] below threshold` 又打印 "All regions meet threshold"），工具 verdict 逻辑未贯彻 worst-region 规则。

**N7 · labels-mode 建议逻辑无平局/噪声护栏，工具产物与报告结论互相矛盾**
- `calibrate.py:393-400` 按行序取首个 F 最大值；产物正式建议 `R_th=0.5/gap=10`，但 Top-10 显示 gap=10 与 15 的 F **完全相同**（0.8793 平局偏向行序），对现产档仅 +0.0003 F（=1 个 TP）。
- replay 报告 `:50` 自述"差 ≤0.04pp 属噪声，建议=维持现产参数"——人肉覆盖了工具输出。spec §15.4 定位是"运维据此改配置"，每次未来运行都会复发。
- 修法：best 选择加 epsilon（ΔF<0.5pp 不出变更建议）+ 平局优先现产参数点；重跑覆盖 labels_suggestion.txt。

### 🟡 Minor

- **N8** · spec §14.1 复现命令缺 `--out`，照做会再踩 N2（`spec:267`）。
- **N9** · `grid_results_gap15.csv` 仍不可复现（内联 schema），M3 只收了一半。
- **N10** · selection.json 口径元数据回归：生成器不写 `in_body_gate/depth_margin/merge_gap/anchor` 标识，两份 selection.json 同 schema 不同数字均无法自描述口径。
- **N11** · 标定报告未随口径收口更新：`:116` 仍称 gap15 文件为"终版"、`:174` 文件清单与现状矛盾。
- **N12** · "bit for bit parity" 措辞过头（`calibrate.py:240`）：ddof 0 vs 1、斜率取段内最大速率（差异③）、trough `<` vs `<=` 三处未折算未声明；方向均保守，门禁结论不变。
- **N13** · labels 模式空正样本边界崩溃：`valid` 为空时 `best=None`，`:424-427` 无条件引用 → TypeError。
- **N14** · backfill README 缺"清理并恢复"章节（AGENTS.md §2 硬性规则：明确时间窗 ✓ + MANUAL_IMPORT + 结束后清理恢复快照）；README 导入段提示可灌 dev/test 容器，缺清理指引是真实缺口。source=DATAGEN 有用户裁决依据可议。
- **N15** · labels-mode 输入 CSV 未归档：`labels_suggestion.txt:3` 指向 `/tmp/labels-export-2.csv`，仓库产物无法重算 labels_grid。
- **N16** · 报告 §3 MANUAL "0.15–0.60°C 浅谷"与 vspot-20.csv 不符（实际 −0.15/−0.07/−0.20，负值=无可见谷）；结论方向不受影响，"0.60"无出处。
- **N17** · m-m 随 M7 显性化：编辑 sheet 清空备注 → repository 不发送空串 → 后端保留旧值 → 用户可见的静默失败（`physiology_api_repository.dart:53`）。T7 验收用户极可能试"清空备注"，建议二选一收口。
- **N18** · 谷点过滤下界与 minX 不咬合的边缘（`drinking_detail_section.dart:498` vs `:516`）：48h 窗起点温度缺口时谷点 x<minX 被 clip；建议下界取 `max(windowStart, minX)`。

### ⚪ Nit

- n-a · `DrinkingLabelExportService.java:42-43` javadoc 误引 "spec §15.4 example"（spec 无此示例）。
- n-b · 报告 "平台≡离线" 过强（F 0.9084 vs 0.9078，写"对齐"才准确）。
- n-c · recalc 响应 devices:12 vs 回填 10 台，多 2 台未解释（疑本地种子胶囊）。
- n-d · `ui-en-home.png` 实为登录页，命名误导。
- n-e · `label_drill.py:11` usage 声明第三参数，代码不读。
- n-f · CSV 导出 note 列无 Excel 公式注入防护（admin 专用，风险低）。
- n-g · 导出端点无 HTTP 层 journey（服务层 4 单测 + curl 实测 200/350,803B 兜底）。
- n-h · 编辑非发病记录时底部恒显"发病无需填写结束日期"提示（语境不符）。
- n-i · 新测试用 `find.text('编辑生理记录')` 等中文文案查找，违反 Mobile/AGENTS.md "按 Key 查找 widget"约定。
- n-j · `calibrate.py:70-71` 注释 "MANUAL = missed-event (FN)" 与实现（匹配时计 TP）张力，注释应改写。

---

## 三、已核对无问题清单（要点）

**滚动锚定修复（af2c6f5a）**
- Java `lastMemberStart` 与 Python 逐行同构；0/10/20/30min 四谷代入：旧语义幻影切 2 事件、新语义正确并 1 事件 ✓；15.0 整边界双侧同为不并 ✓；两单测钉定；链式胶合（0/14/28 全并）是测试钉定的有意语义 ✓
- **这是 T6 回放捕获的真 bug**（幻影切分 52/174 谷、PPV 0.795），异常样本回灌 T3 的因果链在报告 §0/§1.2 记录清楚——plan T6 验证要求 ✓

**生产口径标定收口（B1/M1）**
- spec §14.1 表 ↔ results-production/selection.json ↔ plan 附录三处逐值一致 ✓；门禁 5/6-min 过、10-min 0.8756 如实记录 ✓；维持 R_th=0.7 的"防御性中心档"决策链完整 ✓
- 门卫双侧同构（含端点、先过滤再算日 μ/σ）✓；谷深参数勘误（2.8–4.0）有独立复核批准记录 + `--depth-min/max` 可复现原区间 ✓

**后端修复**
- M2 修复后数学复核正确；javadoc 与 spec §4 四条件合取对齐 ✓
- M5 消费链完整（yml↔@Value↔三层下发↔MANUAL 豁免↔journey 断言）✓
- m-d 幂等与生理先例逐点同构 ✓；m-a 对称化正确 ✓
- B2 修复静态正确（UTC calendar/秒截断/GeneratedKeyHolder/DDL 列集）✓；M8 两用例代入求值成立 ✓

**Flutter 修复**
- M6 三点代入求值闭环 ✓；M7 权限门控/二次确认/类型锁定/防双击/异常文案全对 ✓
- farm-scoped 合规保持；kDrinkingLowConfidence 零残留；baselineMinDays 服务端下发三处挂载点消费 ✓
- 新测试实质非假绿（委托参数、invalidateSelf 计数、对话框双路径、阈值正反两向）✓
- golden 机制健全（Ahem 限制有声明、溢出独立失败、PNG 目检无 bug 快照）✓；ARB 中英对称增删、零硬编码回潮 ✓

**T6 交付物**
- CSV 导出：路径/权限/列集/BOM/CRLF/转义/时区/整分钟折叠全对；4 单测实质；farm_id 批量 join 无 N+1 ✓
- backfill_sim.py：无副作用、seed 固定可复现、胶囊绑定镜像 ACL、时区口径文档化自洽、发热告警行逐条件吻合排除窗口消费链 ✓；产物核验 86401/1985/207/14 等数字全对 ✓
- 回放报告数字交叉核验：1652+333=1985、FN 分解 14+200+78+41=333、F=0.9084、CONFIRMED 1994=1643+348+3、REJECTED 107=97+9+1、PATCH 2098、labels grid 625+表头、V 形 20 例组成与数值逐值相符、SVG 真实 20 格 ✓
- L2-real 顺延显式记录（触发条件二选一、仿真不混充生产红线）✓
- labels 极性映射符合 §15.3、≥100 采信门槛含 INSUFFICIENT 分支 ✓

---

## 四、待裁决 / 行动清单

**T7 阻塞项（必须闭环）**
1. 在有 Docker 的环境跑通三个 journey 测试类并留证（N1）；修正测试类"executed in CI"自述。
2. 证据链修复（N2/N3/N8/N9/N10/N11 同源一次提交）：恢复 L1 正典产物或改 L1 报告引用；"逐数一致"表述改为实际差异（6-min 0.9209→0.9201）或重跑覆盖；复现命令补 `--out`；selection.json 加口径元数据键；更新标定报告文件清单。
3. 修 `label_drill.py` manual 时间格式（一行）+ 说明当时实际执行路径（N4）。
4. 重截英文饮水分节截图替换重复的 detail-2（N5）。
5. labels 建议逻辑加 epsilon + 现产优先平局规则，重跑覆盖 suggestion（N7）。

**待用户裁决**
6. **保真豁免清单**（正式提请逐批裁决，写入 plan 附录）：昨日 7 项 FAIL（card-normal 73.8 / chart-overlay 84.6 / note-box 65.0 / form-empty 78.4 / form-sheet 56.4 / form-sheet-panel 73.8 / aligned 69.5）+ locked 两份（79.9/77.6）+ worst-region 不达标两份（no-data content 84.5 / skeleton bottom_nav 69.0）。
7. **未修复 minor 的处置**（m-b/m-c/m-f/m-g/m-h/m-k~m-p/m-q/m-t/n4/n8/n9/n12/n13）——上轮建议的 plan 附录"已批准偏离清单"仍未建立，本轮原样再撞；建议逐项转正或排期。
8. spec §3.3 五态表述与 m-r 豁免的口径缝归属（spec 本轮未同步）。
9. N17 备注清空语义：repository 发送空串 + 后端支持显式清空，或 sheet hint 注明"置空不清除"。

**教训（建议入 lessons-learned）**
- "双侧同构 ≠ 双侧正确"：昨日 n3 判 Java/Python 一致即正确，实际 Python 参照物带同一 bug；T6 回放是唯一捕获环节——L2-pre 回放不可替代。
- 验证声明必须可由当前代码复现："byte-identical/逐数一致"类断言在提交前用当前代码重跑一次再写（N3 是 M3 在"修复 M3 的提交"里复发）。
- 截图证据须与结论一一对应：重复截图（md5 相同）+ 截图内容不含结论对象，在验收时会被同样方法打回（经验 #25 的反面教材）。
