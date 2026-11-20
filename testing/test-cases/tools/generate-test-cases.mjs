#!/usr/bin/env node
// Generate documented test-case specs from server & mobile test suites.
import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';

const ROOT = process.cwd();
const OUT = path.join(ROOT, 'testing/test-cases');

function loadReqRegistry() {
  const dir = path.join(ROOT, 'docs/requirements');
  const reg = [];
  for (const f of fs.readdirSync(dir)) {
    if (!f.endsWith('.md')) continue;
    const text = fs.readFileSync(path.join(dir, f), 'utf8');
    for (const m of text.matchAll(/^\| (REQ-[A-Z]+-\d+) \| ([^|]+) \|/gm)) {
      reg.push({ id: m[1], title: m[2].trim(), module: f });
    }
  }
  return reg;
}

const REQ_KEYWORDS = [
  [/fence|envelope|track_draft|track2|track4|track_to_envelope|breach|buffer/i, ['REQ-RCH-003','REQ-RCH-004','REQ-RCH-005']],
  [/alert|workbench|alarm/i, ['REQ-RCH-006','REQ-RCH-007']],
  [/gps|trajectory|track_line|quality/i, ['REQ-IOT-005','REQ-IOT-006']],
  [/telemetry|ingestion|dedup|rumen|temperature/i, ['REQ-IOT-001','REQ-IOT-002','REQ-HLT-001','REQ-HLT-002']],
  [/estrus/i, ['REQ-HLT-006']],
  [/calving/i, ['REQ-HLT-004']],
  [/drinking/i, ['REQ-HLT-007']],
  [/fever|health|episode|epidemic|baseline|physiology/i, ['REQ-HLT-003','REQ-HLT-005']],
  [/subscription|quota|feature_gate|tier|entitlement|plan/i, ['REQ-CMC-001','REQ-CMC-002']],
  [/license|onprem|pilot/i, ['REQ-CMC-008']],
  [/contract|revenue/i, ['REQ-CMC-004','REQ-CMC-005']],
  [/auth|jwt|login|password|apikey|api_key|token|session/i, ['REQ-IDT-002']],
  [/farm|tenant|context|switcher|acting_as|scope/i, ['REQ-IDT-001','REQ-IDT-003']],
  [/role|permission|guard|security/i, ['REQ-IDT-004']],
  [/signal|sse|stream|outbox|push/i, ['REQ-PLT-001','REQ-PLT-002','REQ-PLT-005']],
  [/tile|map|coord|ranch|overview|livestock/i, ['REQ-RCH-001','REQ-RCH-002']],
  [/device|installation|gateway|thingsboard|tb_|provisioning/i, ['REQ-IOT-003','REQ-IOT-004']],
  [/partition|migration/i, ['REQ-NFR-001','REQ-NFR-002']],
];
function mapReq(filePath, testCaseName) {
  const hay = filePath + ' ' + (testCaseName || '');
  const ids = new Set();
  for (const [re, ids2] of REQ_KEYWORDS) {
    if (re.test(hay)) ids2.forEach(i => ids.add(i));
  }
  return [...ids].slice(0, 4);
}

const SERVER_VOLUMES = [
  { file: 'tc-server-ranch-alert.md', title: '后端·告警与信号流（ranch alert/signal）', domain: 'RCH', re: /ranch.*(alert|signal)/i },
  { file: 'tc-server-ranch-fence.md', title: '后端·电子围栏（ranch fence）', domain: 'RCH', re: /ranch.*fence/i },
  { file: 'tc-server-ranch-livestock-overview.md', title: '后端·牲畜档案与牧场总览', domain: 'RCH', re: /\/ranch\//i },
  { file: 'tc-server-gps-telemetry.md', title: '后端·GPS 与遥测采集', domain: 'IOT', re: /iot.*(gps|telemetry|trajectory|track)/i },
  { file: 'tc-server-iot-device.md', title: '后端·设备与安装', domain: 'IOT', re: /\/iot\//i },
  { file: 'tc-server-health.md', title: '后端·健康监测与 AI 分析（health）', domain: 'HLT', re: /\/health\//i },
  { file: 'tc-server-identity.md', title: '后端·身份认证与多租户', domain: 'IDT', re: /(\/identity\/|shared\/security|shared\/scope|PasswordPolicy|FarmIdPathParser)/i },
  { file: 'tc-server-commerce.md', title: '后端·订阅与商业（commerce）', domain: 'CMC', re: /\/commerce\//i },
  { file: 'tc-server-licensing.md', title: '后端·许可证（licensing）', domain: 'CMC', re: /licensing/i },
  { file: 'tc-server-datagen.md', title: '后端·数据仿真（datagen）', domain: 'PLT', re: /datagen/i },
  { file: 'tc-server-platform-shared.md', title: '后端·平台与共享设施', domain: 'PLT', re: /(\/platform\/|analytics|MessageResolver|QuotaInterceptor)/i },
  { file: 'tc-server-integration.md', title: '后端·端到端旅程集成测试', domain: 'JRY', re: /\/integration\//i },
];
const APP_VOLUMES = [
  { file: 'tc-app-alerts.md', title: 'App·告警工作台', domain: 'RCH', re: /features\/alerts/i },
  { file: 'tc-app-fence.md', title: 'App·围栏编辑与轨迹导入', domain: 'RCH', re: /(features\/fence|fence_dto|fence_sandbox|ranch_fence_tab)/i },
  { file: 'tc-app-gps-quality.md', title: 'App·GPS 质量治理', domain: 'IOT', re: /gps_quality/i },
  { file: 'tc-app-devices.md', title: 'App·设备管理', domain: 'IOT', re: /features\/devices/i },
  { file: 'tc-app-drinking.md', title: 'App·饮水监测', domain: 'HLT', re: /drinking/i },
  { file: 'tc-app-livestock-health.md', title: 'App·牲畜档案/牧场地图/健康页', domain: 'RCH', re: /(features\/livestock|features\/ranch|features\/pages|features\/physiology)/i },
  { file: 'tc-app-subscription-license.md', title: 'App·订阅门控与许可', domain: 'CMC', re: /(subscription|license)/i },
  { file: 'tc-app-admin-tools.md', title: 'App·管理员工具', domain: 'PLT', re: /features\/admin/i },
  { file: 'tc-app-auth-tenant.md', title: 'App·登录认证与租户切换', domain: 'IDT', re: /(features\/auth|features\/tenant|farm_switcher|\/app\/|route_guard|session_logout)/i },
  { file: 'tc-app-core-infra.md', title: 'App·基础设施与通用组件', domain: 'PLT', re: /.*/ },
];

function classify(rel) {
  let vol = SERVER_VOLUMES.find(v => v.re.test(rel));
  if (!vol) vol = APP_VOLUMES.find(v => v.re.test(rel));
  if (!vol) vol = { file: 'tc-unclassified.md', title: '未归类', domain: 'PLT' };
  let prio = 'P1';
  if (/(integration|Journey|SecurityTest|Interceptor|e2e)/.test(rel)) prio = 'P0';
  else if (/Controller|Guard/.test(rel)) prio = 'P0';
  else if (/(golden|visual|smoke|painter|_page_test|widget_test|snap|card|banner|section|empty|layout|marker|dashed)/i.test(rel)) prio = 'P2';
  else if (/(core\/|database|migration|contract|theme)/i.test(rel)) prio = 'P1';
  return { vol, prio };
}

function parseJava(abs, rel) {
  const src = fs.readFileSync(abs, 'utf8');
  const className = (src.match(/(?:class|record)\s+(\w+)/) || [])[1] || path.basename(rel, '.java');
  const tests = [];
  const lines = src.split('\n');
  for (let i = 0; i < lines.length; i++) {
    if (!/@Test\b/.test(lines[i])) continue;
    { const sm = lines[i].match(/@Test\s+(?:void|Future<[^>]*>)\s+(\w+)\s*\(/); if (sm) { tests.push({ name: sm[1], display: '' }); continue; } }
    let display = '';
    for (let j = i + 1; j < Math.min(i + 8, lines.length); j++) {
      const dm = lines[j].match(/@DisplayName\(\s*"([^"]*)"\s*\)/);
      if (dm) { display = dm[1]; continue; }
      if (/^\s*(@|\/\/|\/\*)/.test(lines[j])) continue;
      const mm = lines[j].match(/(?:void|Future<[^>]*>)\s+(\w+)\s*\(/);
      if (mm) { tests.push({ name: mm[1], display }); break; }
    }
  }
  return { className, tests };
}

function parseDart(abs, rel) {
  const src = fs.readFileSync(abs, 'utf8');
  const tests = [];
  const stack = [];
  const lines = src.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const gm = line.match(/^\s*group\(\s*'([^']*)'/);
    if (gm) { stack.push(gm[1]); continue; }
    if (/^\s*\}\)\s*;?\s*$/.test(line) && stack.length) stack.pop();
    const tm = line.match(/^\s*(?:test|testWidgets)\(\s*'([^']*)'/);
    if (tm) { tests.push({ name: tm[1], display: stack.join(' > ') }); continue; }
    if (/^\s*(?:test|testWidgets)\(\s*$/.test(line)) {
      for (let j = i + 1; j < Math.min(i + 4, lines.length); j++) {
        const nm = lines[j].match(/^\s*'([^']*)'/);
        if (nm) { tests.push({ name: nm[1], display: stack.join(' > ') }); break; }
        if (/\S/.test(lines[j]) && !/^\s*['"]/.test(lines[j])) break;
      }
    }
  }
  return { className: path.basename(rel, '_test.dart'), tests };
}

const serverFiles = execSync("find smart-livestock-server/src/test -name '*Test.java'", { encoding: 'utf8' }).trim().split('\n');
const appFiles = execSync("find Mobile/mobile_app/test -name '*_test.dart'", { encoding: 'utf8' }).trim().split('\n');

const volumes = new Map();
const counters = {};
function addCase(vol, tc) {
  if (!volumes.has(vol.file)) volumes.set(vol.file, { ...vol, cases: [] });
  volumes.get(vol.file).cases.push(tc);
}
function nextId(domain) {
  counters[domain] = (counters[domain] || 0) + 1;
  return 'TC-' + domain + '-' + String(counters[domain]).padStart(3, '0');
}
function javaPre(rel) {
  if (/integration|Journey/.test(rel)) return '部署完成后环境可用；种子数据已加载';
  if (/Controller|Security/.test(rel)) return '已认证测试用户与目标角色上下文';
  return '测试夹具按测试类 @BeforeEach 构造';
}
function dartPre(rel) {
  if (/e2e/.test(rel)) return '后端 dev 环境可用；种子账号可登录';
  if (/page_test|widget|visual|golden/.test(rel)) return '目标 Widget 可独立 pump；必要时包 ProviderScope';
  return '单元级，无需外部依赖（mock 由 setUp 注入）';
}

const all = [...serverFiles, ...appFiles].sort();
let totalCases = 0, totalFiles = 0;
const fileIndex = [];
const totalByPrio = { P0: 0, P1: 0, P2: 0 };
const skipped = [];
for (const rel of all) {
  const abs = path.join(ROOT, rel);
  const isJava = rel.endsWith('.java');
  let parsed;
  try { parsed = isJava ? parseJava(abs, rel) : parseDart(abs, rel); } catch (e) { skipped.push(rel + ': ' + e.message); continue; }
  if (parsed.tests.length === 0) { skipped.push(rel); continue; }
  const { vol, prio } = classify(rel);
  const reqs = mapReq(rel, parsed.className);
  for (const t of parsed.tests) {
    const id = nextId(vol.domain);
    const tReq = mapReq(rel, t.name + ' ' + (t.display || ''));
    addCase(vol, { id, prio, title: (isJava && t.display) ? t.display : t.name, group: isJava ? '' : t.display, source: rel + '::' + t.name, pre: isJava ? javaPre(rel) : dartPre(rel), reqs: (tReq.length ? tReq : reqs).join('、') });
    totalCases++;
  }
  fileIndex.push({ rel, className: parsed.className, count: parsed.tests.length, volume: vol.file, prio });
  totalFiles++;
}

fs.mkdirSync(OUT, { recursive: true });
fs.mkdirSync(path.join(OUT, 'tools'), { recursive: true });

const BT = '`';
for (const [key, v] of volumes) {
  v.cases.sort((a, b) => a.id.localeCompare(b.id));
  let md = '# 测试用例规格：' + v.title + '\n\n';
  md += '> 用例域：' + v.domain + ' ｜ 用例数：' + v.cases.length + '\n';
  md += '> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。\n';
  md += '> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。\n\n';
  md += '| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |\n|---|---|---|---|---|\n';
  for (const c of v.cases) {
    totalByPrio[c.prio]++;
    md += '| ' + c.id + ' | ' + c.title.replace(/\|/g, '/') + ' | ' + c.prio + ' | ' + (c.reqs || '—') + ' | ' + BT + c.source + BT + ' |\n';
  }
  md += '\n## 用例明细（初稿模板）\n\n';
  for (const c of v.cases) {
    md += '### ' + c.id + ' ' + c.title + '\n\n';
    md += '- 优先级：' + c.prio + '\n- 前置条件：' + c.pre + '\n';
    if (c.group) md += '- 所属分组：' + c.group + '\n';
    md += '- 步骤：运行来源测试 ' + BT + c.source + BT + '（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）\n';
    md += '- 预期结果：测试断言全部通过；失败即用例不通过\n';
    md += '- 对应 REQ：' + (c.reqs || '—（待人工映射）') + '\n\n';
  }
  fs.writeFileSync(path.join(OUT, key), md);
}

let readme = '# 测试用例规格（testing/test-cases）\n\n';
readme += '> 由 tools/generate-test-cases.mjs 从后端 ' + serverFiles.length + ' 个测试类与 Mobile ' + appFiles.length + ' 个测试文件批量解析生成初稿（2026-11-21 基线）。\n';
readme += '> 用例编号：TC-<域>-NNN，域对齐 SRS REQ 体系（RCH/IOT/HLT/IDT/CMC/PLT/JRY=旅程集成）。\n';
readme += '> 状态：脚本初稿——优先级为规则推断，REQ 为关键词自动映射，步骤为单测载体模板，均需人工校对。\n\n';
readme += '## 统计\n\n- 测试文件：' + totalFiles + '\n- 文档化用例：' + totalCases + '（P0 ' + totalByPrio.P0 + ' / P1 ' + totalByPrio.P1 + ' / P2 ' + totalByPrio.P2 + '）\n\n## 分册索引\n\n';
readme += '| 分册 | 域 | 用例数 |\n|---|---|---|\n';
for (const [key, v] of [...volumes.entries()].sort()) readme += '| [' + key + '](' + key + ') | ' + v.domain + ' | ' + v.cases.length + ' |\n';
if (skipped.length) readme += '\n## 未解析文件（' + skipped.length + '）\n\n' + skipped.map(s => '- ' + s).join('\n') + '\n';
fs.writeFileSync(path.join(OUT, 'README.md'), readme);

fs.writeFileSync(path.join(OUT, 'tools/test-file-index.json'), JSON.stringify({ generatedAt: '2026-11-21', totalFiles, totalCases, counters, files: fileIndex }, null, 2));
console.log('files=' + totalFiles + ' cases=' + totalCases, JSON.stringify(counters));
console.log('skipped:', skipped.length);
