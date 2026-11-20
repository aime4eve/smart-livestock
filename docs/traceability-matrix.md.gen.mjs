// Traceability matrix generator: aggregates REQ (docs/requirements) x TC (testing/test-cases)
import { readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
const ROOT = process.cwd();
const reqFiles = readdirSync(join(ROOT, "docs/requirements")).filter(f => f.startsWith("srs-module-"));
const reqs = new Map();
for (const f of reqFiles) {
  const text = readFileSync(join(ROOT, "docs/requirements", f), "utf8");
  for (const line of text.split("\n")) {
    const m = line.match(/^\| (REQ-[A-Z]+-\d+) \| (.+?) \| (.+?) \| (P\d) \| (.+?) \| (.+?) \|$/);
    if (m) reqs.set(m[1], { id: m[1], title: m[2], source: m[3], pri: m[4], status: m[6], file: f });
  }
}
const tcFiles = readdirSync(join(ROOT, "docs/testing/test-cases")).filter(f => /^tc-(server|app)-.*\.md$/.test(f));
const tcs = [];
const tickRe = /(NIX-\d+|#\d+|!1[0-9][0-9])/g;
for (const f of tcFiles) {
  const text = readFileSync(join(ROOT, "docs/testing/test-cases", f), "utf8");
  for (const line of text.split("\n")) {
    const m = line.match(/^\| (TC-[A-Z]+-\d+) \| (.+?) \| (P\d) \| (.+?) \| \`(.*?)\` \|$/);
    if (m) tcs.push({ tc: m[1], name: m[2], pri: m[3], reqList: m[4].split("、").map(s => s.trim()).filter(s => /^REQ-/.test(s)), src: m[5], file: f });
  }
}
const byReq = new Map();
const unknownReq = new Map();
for (const t of tcs) {
  for (const r of t.reqList.length ? t.reqList : ["__UNMAPPED__"]) {
    if (!reqs.has(r)) { unknownReq.set(r, (unknownReq.get(r) || 0) + 1); }
    if (!byReq.has(r)) byReq.set(r, []);
    byReq.get(r).push(t);
  }
}
let out = [];
out.push("# 追溯矩阵（Traceability Matrix）");
out.push("");
out.push("> 唯一权威源：本文件由 docs/traceability-matrix.md.gen.mjs 生成（node docs/traceability-matrix.md.gen.mjs），基线 2026-11-21。");
out.push("> 需求编号体系：docs/requirements/srs-smart-livestock.md（REQ-<域>-NNN，80 条）+ srs-requirements-debt.md（REQ-DEBT-001~010）。");
out.push("> 用例编号体系：docs/testing/test-cases/（TC-<域>-NNN，2604 条 / 357 文件；域 RCH/IOT/HLT/IDT/CMC/PLT/JRY）。");
out.push("> 映射口径：TC→REQ 为 docs/testing/test-cases 分册的自动映射列（关键词映射，人工校对后升级为定稿口径）。");
out.push("");
out.push("## 一、覆盖统计");
out.push("");
const cov = [...reqs.keys()].map(r => (byReq.get(r) || []).length);
out.push("| 指标 | 值 |");
out.push("|---|---|");
out.push("| REQ 需求条目 | " + reqs.size + " |");
out.push("| 有 TC 覆盖的 REQ | " + cov.filter(n => n > 0).length + " |");
out.push("| 无 TC 覆盖的 REQ | " + cov.filter(n => n === 0).length + "（见 §四） |");
out.push("| TC 用例总数 | " + tcs.length + " |");
out.push("| 映射到 REQ 的 TC 引用 | " + tcs.reduce((a, t) => a + t.reqList.length, 0) + " |");
out.push("| 未映射到任何 REQ 的 TC 引用 | " + (unknownReq.get("__UNMAPPED__") || 0) + " |");
out.push("");
out.push("## 二、REQ ↔ TC 全量映射表");
out.push("");
out.push("TC 编号每 REQ 最多列 20 条，超出以「…共 N 条」汇总，全清单见对应分册。");
out.push("");
out.push("| REQ | 需求摘要 | PRD 章节 / 来源 | 优先级 | 实现状态 | 覆盖 TC 数 | TC 编号（≤20） | 代表测试代码路径 | 工单/PR |");
out.push("|---|---|---|---|---|---|---|---|---|");
for (const [id, r] of reqs) {
  const list = byReq.get(id) || [];
  const prd = [...new Set([...r.source.matchAll(/PRD §[^、|)]*/g)].map(m => m[0]))].join("、") || "—";
  const ticks = [...new Set([...(r.source + " " + r.status).matchAll(/NIX-\d+/g)].map(m => m[0]))].join("、") || "—";
  const tcsTxt = list.length === 0 ? "无" : list.slice(0, 20).map(t => t.tc).join("、") + (list.length > 20 ? " …共 " + list.length + " 条" : "");
  const rep = list.length ? "\`" + list[0].src.split("::")[0] + "\`" : "—";
  const title = r.title.length > 40 ? r.title.slice(0, 38) + "…" : r.title;
  out.push("| " + id + " | " + title + " | " + prd + " | " + r.pri + " | " + r.status + " | " + list.length + " | " + tcsTxt + " | " + rep + " | " + ticks + " |");
}
out.push("");
out.push("## 三、REQ-DEBT ↔ 评审债映射");
out.push("");
out.push("| 需求债 | 摘要 | 状态 |");
out.push("|---|---|---|");
out.push("| REQ-DEBT-001~010 | N_eff 分档阈值、冷启动兜底、I14 时间戳统一、I9 ArchUnit、I11 updated_at、I12 域测试、AlertReadStatusTest mock 债、I13 校验成文、I10 shared 边界（部分）、前端 P2 集合 | 8 未闭环 + 2 部分闭环，详见 [srs-requirements-debt.md](requirements/srs-requirements-debt.md) |");
out.push("");
out.push("## 四、覆盖缺口");
out.push("");
const noTc = [...reqs.values()].filter(r => (byReq.get(r.id) || []).length === 0);
out.push("无 TC 覆盖的 REQ（" + noTc.length + " 条）：");
for (const r of noTc) out.push("- " + r.id + " " + r.title + "（" + r.status + "）");
out.push("");
if (unknownReq.size) {
  out.push("TC 自动映射引用了不存在/未登记的 REQ 编号：");
  for (const [k, v] of unknownReq) out.push("- " + k + "（引用 " + v + " 次）");
  out.push("");
}
out.push("## 五、域级对照（REQ 域 ↔ TC 分册）");
out.push("");
const byFile = new Map();
for (const t of tcs) byFile.set(t.file, (byFile.get(t.file) || 0) + 1);
out.push("| TC 分册 | TC 域 | 用例数 |");
out.push("|---|---|---|");
for (const [f, n] of byFile) out.push("| [test-cases/" + f + "](testing/test-cases/" + f + ") | " + f.replace(/tc-(server|app)-/, "").replace(/\.md/, "") + " | " + n + " |");
out.push("");
out.push("## 六、维护规则");
out.push("");
out.push("1. 新需求合入：先在 docs/requirements/ 登记 REQ-<域>-NNN（四要素齐备），重跑生成脚本刷新本矩阵。");
out.push("2. 新用例合入：docs/testing/test-cases/ 分册登记 TC-<域>-NNN 并填 REQ 映射列；生成脚本重跑后矩阵同步。");
out.push("3. REQ 实现/废弃状态变化：改 SRS 模块文件状态列，不改本矩阵手工内容（本文件除本节外均为生成物）。");
out.push("4. TC→REQ 自动映射为初稿口径；人工校对后更新分册内映射列即可，本矩阵下次生成自动吸收。");
out.push("5. 工单关闭/PR 合并不单独改本矩阵；工单号在 SRS 来源列维护。");
out.push("");
writeFileSync(join(ROOT, "docs/traceability-matrix.md"), out.join("\n") + "\n");
console.log("REQs=" + reqs.size + " TCs=" + tcs.length + " noTc=" + noTc.length + " unknownReq=" + JSON.stringify([...unknownReq]));
