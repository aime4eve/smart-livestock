# Lessons Learned / 踩坑经验沉淀

> 本文件记录开发与运维过程中遇到的真实问题、根因、解决步骤和可复用的判据,供后续 Agent 与人类成员参考。
> 新增条目请按"现象 → 误判 → 根因 → 解决 → 判据"五段式书写,并标注日期。

---

## 1. flutter gen-l10n 崩溃:并非 engine.stamp 权限,而是 AppleDouble 文件污染

- **日期**:2026-06-18
- **现象**:`flutter gen-l10n` 直接抛 `PathAccessException: .../.dart-tool/dart-flutter-telemetry-session.json (Operation not permitted)`,关闭 analytics 后变成 `FileSystemException: Failed to decode data using encoding 'utf-8', path = '.../lib/l10n/._app_en.arb'`。
- **误判**:最初以为是沙箱 Flutter 因 `engine.stamp` 权限崩溃,曾"手动同步 gen 文件作为过渡"——治标不治本,gen 文件与 arb 随时会再次不同步。
- **根因**:`lib/l10n/` 目录里混入了 macOS AppleDouble 文件 `._app_en.arb`、`._app_zh.arb`(以及 `gen/._app_localizations*.dart`)。gen-l10n 用 glob `app_*.arb` 匹配时会把这些二进制 resource-fork 文件也读进来,UTF-8 解码必然失败。telemetry 报错只是沙箱无法写 `~/.dart-tool` 的次生现象,真正阻断生成的是 AppleDouble 文件。
- **解决**:
  1. 删除 `lib/l10n/._app_*.arb` 与 `lib/l10n/gen/._app_localizations*.dart`。
  2. 沙箱内 Flutter 写不了 `~/.dart-tool`,用 `HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter gen-l10n` 绕过 telemetry 写入即可正常生成。
  3. 本机正常环境(无沙箱)直接 `flutter gen-l10n`。
- **验证**:`app_en.arb` 与 `app_zh.arb` key 数对齐(均 958);`flutter analyze --no-pub` 0 error,无 undefined getter。
- **判据(下次复现即套用)**:
  - 看到 `Failed to decode data using encoding 'utf-8'` 且 path 含 `._` 前缀 → 先删 `._*` 文件,不要怀疑 Flutter 工具本身。
  - 看到任何工具在 `/Volumes/DEV`(外置卷)上 UTF-8 解码失败 → 第一反应查 `._*` AppleDouble 污染。
  - 沙箱内 Flutter 报 `~/.dart-tool` 权限错 → 用 `HOME=/private/tmp` + `FLUTTER_SUPPRESS_ANALYTICS=true` 两个环境变量绕过,不要改 Flutter 安装本身。

---

## 2. 全仓库 AppleDouble(`._*`)污染:git pack 索引损坏 + 工具连环崩溃

- **日期**:2026-06-18
- **现象**:`git log` 大量报 `error: non-monotonic index .git/objects/pack/._pack-*.idx`;`docs/` 下出现 `._system-architecture.md`、`._tileserver-gl-implementation-overview.md`;`lib/l10n/` 出现 `._*.arb`(见第 1 条)。即整个仓库(含 `.git`)都被 macOS AppleDouble 文件污染。
- **根因**:某个同步流程在 macOS 外置卷 `/Volumes/DEV` 上用了 AppleDouble-unsafe 的方式拷贝/解压——可能 rsync 未带 Apple 相关参数、或 zip/tar 解压带出了 `._*`,或通过非 HFS+/APFS 中转(FAT/exFAT/网络卷)触发 macOS 生成 resource fork 伴随文件。
- **影响面**:不仅让 `flutter gen-l10n` 崩溃,还会让 `git` 操作报错、让任何按 glob 读取目录的工具(读取 `*.md`、`*.arb`、`*.dart` 等)读到二进制垃圾文件。
- **解决(未执行,按 AGENTS.md §3 不擅自清理 .git 与既有文件,待用户决策)**:
  - 清理:`find . -name '._*' -not -path './.git/*' -delete`(工作树)
  - 修 git:`find .git -name '._*' -delete`,然后 `git gc` 重建索引。
  - 根治同步链路:rsync 加 `--no-appledouble`(macOS 原生 rsync)或换不带 resource fork 的传输;解压用 `ditto -x --norsrc` 或确认源端无 `._*`;避免经 FAT/exFAT/网络卷中转。
- **判据**:
  - 任何"UTF-8 解码失败 / non-monotonic index / 工具读到不该读的文件"在 `/Volumes/DEV` 上出现 → 先 `find . -name '._*' | head` 扫一遍,十有八九是 AppleDouble 污染。

---

## 3. Tile `/admin/tiles/status` 返回空:确认是部署侧而非代码侧

- **日期**:2026-06-18
- **现象**:`curl http://172.22.1.123:18080/api/v1/admin/tiles/status` 返回空列表,此前怀疑"路径错位"。
- **代码侧结论(已核验,无需改)**:`TileController.java` 中 `TILES_DIR="/data"`,`getTileStatus()` 列 `/data` 下 `*.mbtiles`;`docker-compose.yml` 中 app 与 tileserver 都挂载 `tileserver-data:/data`(app 为 `:ro`)。代码路径与卷挂载一致,**路径错位问题在代码层面不存在**。
- **真正可能原因(部署/数据侧)**:
  1. `tileserver-data` 数据卷里根本没有 `.mbtiles` 文件(卷为空,或 mbtiles 放在了别的路径)。
  2. 旧版本镜像/旧 JAR 仍在运行(未真正重新部署)。
  3. 卷名拼错或挂载到了容器内其它路径。
- **验证步骤(部署后执行)**:
  ```bash
  # 部署(用户执行)
  cd smart-livestock-server && ./gradlew bootJar -x test
  rsync -avz --exclude='.git' --exclude='.gradle' --exclude='node_modules' \
        --exclude='build/tmp' --exclude='build/classes' \
        . agentic@172.22.1.123:~/smart-livestock-server/
  ssh agentic@172.22.1.123 "cd ~/smart-livestock-server/build/libs && ls -t smart-livestock-server-*.jar | tail -n +2 | xargs rm -f"
  ssh agentic@172.22.1.123 "cd ~/smart-livestock-server && docker compose build app && docker compose up -d app"

  # 部署完成后验证
  curl -s http://172.22.1.123:18080/api/v1/admin/tiles/status | python3 -m json.tool
  # 若仍为 []:进容器看卷内容
  ssh agentic@172.22.1.123 "docker compose exec app ls -la /data"
  ssh agentic@172.22.1.123 "docker volume inspect smart-livestock-server_tileserver-data"
  ```
- **判据**:
  - "接口返回空"先分清是代码逻辑空还是数据空:核验代码 glob 与挂载路径一致后,直接进容器 `ls /data` 确认数据卷内容,不要在代码里继续改路径。

---

## 4. 沙箱环境下的 Flutter 工具通用绕过

- **日期**:2026-06-18
- **现象**:沙箱内 Flutter 几乎任何命令都因写不了 `~/.dart-tool`(遥测/缓存)而崩。
- **解决**:统一加两个环境变量再跑 Flutter 命令:
  ```bash
  HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter <cmd>
  ```
- **注意**:`flutter pub get` 仍需联网(沙箱默认禁网),依赖解析类操作要 `--offline` 或在非沙箱环境跑;`flutter analyze` 加 `--no-pub` 跳过 pub 检查。
- **判据**:沙箱内 Flutter 一律先套这两个环境变量,再判断是不是真问题。

---

## 5. 评审路由/分档/状态机逻辑时从 design 原文时态主语倒推，勿从阈值数字联想

- **日期**:2026-06-22
- **现象**:评审 ai-platform `route_by_neff` 迟滞实现时,我在 review H2 写"N_eff 在 160–200 之间抖动也会导致 algo 在 mahalanobis/rules 间反复切换"。被作者指出张冠李戴:160–200 是 iforest 迟滞带(上阈 200/下阈 160),纯阈值分支下该范围恒为 mahalanobis 不抖动;真正会抖的是 29/30 边界(rules↔mahalanobis)。我把 iforest 迟滞带 `[160,200)` 的效果错安到了 mahalanobis/rules 切换上,design 的两个迟滞带(`[24,30)` maha 档、`[160,200)` iforest 档)混了。
- **误判**:推理链断在两处——(1) 看到 router.py 顶部的 `hi_iforest=200`/`lo_iforest=160` 显眼数字,直接联想到"抖动",再顺手安到"最先想到的切换"(rules↔mahalanobis)上,**跳过了"纯阈值分支在 N_eff=180 时实际返回什么"这一步代入计算**(若算了会得 `180<200→mahalanobis`,例子立刻自相矛盾);(2) 把"迟滞带的阈值数字"当成"纯阈值下发生切换的边界",但纯阈值分支只读 `hi_maha=30`/`hi_iforest=200`,`lo_maha=24`/`lo_iforest=160` 仅迟滞分支用,纯阈值语境下 160 这个数根本不出现。
- **根因(更深一层)**:用了**联想式推理**(数字→抖动→最近的切换)而非**代入式推理**(拿调用方实际参数逐步求值)。而且分析停在 router.py 内部,没往下追一层到"router 返回值在 health_l1 怎么被消费"——`health_l1.py:42` 把 iforest 强降为 mahalanobis,200 边界实际零效果。只读被调函数、不读调用方对返回值的处理,是这类错误的标准形态。
- **解决(正确的锚点)**:评审路由/分档/状态机类代码,先锁定 design 原文的**时态与主语**——
  - "持续"(`N_eff 持续 ≥200`) → 跨次状态,单次调用无法表达,要求状态存储;
  - "同一头牛"(`同一头牛在临界值来回切换`) → per-key 状态,状态键是 `livestock_id`;
  - "来回切换" → 时间维度抖动,要求升/降档不对称的迟滞带。
  再对照代码是否提供了这些前提(状态存储?键?生命周期?)。本次 design §4.3 第 112 行三个前提(跨次/per-individual/状态化)一条都不满足——`health_l1.py:38` `router_state={}` 局部变量每次新建,迟滞分支端到端永不执行,design 要求零落实。这才是 H2 的准确定性(原写的"迟滞失效"是程度问题,准确说法是"设计要求的整个状态化机制未实现")。
- **判据(下次评审路由/分档/状态机即套用)**:
  - design 原文出现"持续""连续""同一 X""来回""反复"等时态/重复词 → 该要求是**跨次/状态化**的,单次调用的无状态函数不可能满足,必查代码是否有状态存储 + 分键;
  - 评审分档切换时,**代入调用方实际传入的参数逐步求值**每个 N_eff 区间的返回值,不要从阈值数字(`160/200`)联想行为——阈值是状态机的参数,不是状态机本身;纯阈值分支与迟滞分支读的阈值集合不同(`lo_*` 仅迟滞分支用);
  - 分析被调函数(router)后,**必须再追一层**看调用方(health_l1)如何消费返回值——返回值可能被改写(如 `if algo=="iforest": algo="mahalanobis"`),使某条档位整条失效;
  - 测试绿 ≠ 设计落实:单元测试若只覆盖"显式喂 state 时函数行为",而生产路径从不喂该 state,会产生"已测试的 bug"假象。状态化要求必须有**跨次/端到端**测试(同一 key 连续输入,断言输出不抖动)。

---

## 6. mine 页面入口"缺失":非代码问题,是 nginx 镜像未重建

- **日期**:2026-07-02
- **现象**:dev 环境(19080)owner 登录后,mine 页面看不到"畜牧管理"入口。后端 `/me` 接口正常返回,代码里 `mine_page.dart` 确实有入口逻辑(`Key('mine-livestock-mgmt')` → `AppRoute.livestockList.path`),i18n 文案 `livestockListTitle`="牲畜管理" 也齐全。
- **误判**:从代码层面逐项排查——`MineController` 调 `GET /me` 正常、`ApiClient` envelope 解包逻辑正确、路由 `livestockList` 存在、arb 文案有 key、git 历史确认入口在当前 HEAD。代码完全正确,问题不在代码层。差点在 ApiClient 和 controller 层继续深挖。
- **根因**:`nginx` 的 Dockerfile 用 `COPY frontend /usr/share/nginx/html` 把前端文件烤进镜像,而 `deploy.sh` 只执行 `docker compose build app`,从未 rebuild nginx。前端文件虽然 rsync 到了 host(`~/smart-livestock-server/frontend/main.dart.js` 是最新的),但容器一直用旧镜像里的旧前端。容器内 grep `mine-livestock-mgmt` 返回 0,host 上 grep 返回 1。
- **解决**:
  1. `deploy.sh` 第 47 行 `build app` → `build app nginx`,每次部署重建 nginx 镜像。
  2. `build_web.sh` 构建后自动把产物复制到 `smart-livestock-server/frontend/`(之前本地这份目录停留在 6 月 30 日旧版本,直接 deploy 会把 host 上的好文件反向覆盖)。
  3. 重新构建前端 → 部署 → 浏览器验证:登录 owner → `/mine` 页面 DOM 确认 `node_id=2` = "牲畜管理" → 点击跳转到 `/livestock` 牲畜列表页。
- **判据(下次复现即套用)**:
  - 前端入口/功能"缺失",先 grep **容器内**的 `main.dart.js` 是否包含对应 key,再 grep host 上的。两者不一致 → 是镜像未重建,不是代码问题。
  - Dockerfile 用 `COPY` 烤入文件的场景,改了源文件后必须 rebuild 对应镜像;`docker compose build` 时要带上该 service 名(这里是 nginx),不能只 build app。
  - 部署链路多步(构建→复制→rsync→docker build),每一环都要验证产物到了下一环节:`grep -c "key" smart-livestock-server/frontend/main.dart.js`(本地)→ `docker exec <nginx> grep -c "key" /usr/share/nginx/html/main.dart.js`(容器),不要假设中间步骤自动完成。
  - 一句话:**前端更新后,先确认容器内文件确实是最新的,再查代码。**

---

## 沉淀规则(给后续维护者)

1. 每解决一个非平凡问题,追加一条到本文件,按"现象 → 误判 → 根因 → 解决 → 判据"五段式。
2. 重点写"误判"——把曾经走过的弯路记下来,避免重复踩。
3. "判据"要写成可立即套用的 if-then 规则,便于下一个 Agent 快速定位。
4. 涉及部署/数据的验证,遵循 AGENTS.md §5:编译 Agent 可做,部署与集成测试由用户执行。

---

## 7. 前后端联合部署缺一不可：只部署后端不构建前端 = 看不到变化

- **日期**:2026-07-10
- **现象**:后端 API 改了返回结构（LivestockDto 新增 devices 字段、详情 API 填充设备列表），curl 验证 API 正常返回设备数据，但浏览器里前端始终看不到设备信息/轨迹。
- **误判**:连续修了三处后端 bug（JPQL 参数名 :from 冲突、GPS 时区偏移、reportTime 格式解析），每次只部署后端就告诉用户"刷新看看"，结果前端始终是旧 bundle。
- **根因**:nginx 的 Dockerfile 用 `COPY frontend /usr/share/nginx/html` 烤入前端文件。只跑 `deploy.sh dev` 不会重新构建 Flutter web bundle——`build_web.sh` 是独立的构建步骤，需要先执行再部署。后端变了但前端没重新编译，浏览器加载的还是旧版 `main.dart.js`。
- **解决**:
  1. 先 `cd Mobile/mobile_app && ./build_web.sh`（构建 Flutter web + 拷贝到 `smart-livestock-server/frontend/`）
  2. 再 `cd smart-livestock-server && ./scripts/deploy.sh dev`（rsync + docker compose build nginx）
  3. 两步缺一不可
- **判据**:
  - 后端 API curl 验证通过但前端看不到效果 → 99% 是前端没有重新构建部署，不要继续查后端。
  - 每次前端代码变更后，必须 `build_web.sh` + `deploy.sh` 两步都执行。
  - 部署后用 `docker exec <nginx> grep -c "newKey" /usr/share/nginx/html/main.dart.js` 确认容器内是最新前端。

---

## 8. JPQL 参数名 :from 与 JPQL 保留字 FROM 冲突

- **日期**:2026-07-10
- **现象**:GPS 时间范围查询 `findByDeviceIdAndRecordedAtBetween(deviceId, from, to)` 始终返回空列表，但无参数查询 `findByDeviceId(deviceId)` 正常返回数据。数据库直接 SQL 查询也返回正确结果。
- **误判**:最初以为是 (0,0) 过滤条件误删了数据、或 BETWEEN 语法写错，反复查数据是否存在。
- **根因**:`@Query` JPQL 中参数名 `:from` 与 JPQL 保留字 `FROM` 冲突。Hibernate 参数绑定在解析 `BETWEEN :from AND :to` 时，将 `:from` 误认为关键字 `FROM`，导致绑定失败，查询静默返回空结果（不报错）。
- **解决**:参数名从 `:from`/`:to` 改为 `:startTime`/`:endTime`，避免与 JPQL 保留字冲突。
- **判据**:
  - `@Query` 中的 `:paramName` 查询返回空但无报错 → 检查参数名是否与 JPQL/HQL 保留字冲突（FROM、SELECT、WHERE、JOIN、ORDER、GROUP 等）。
  - 命名参数一律用业务语义全称（`startTime`、`endTime`、`deviceId`），不用 SQL/JPQL 保留字的缩写或近义词。

---


## 10. 平台 reportTime 格式不匹配导致重复同步 + 数据膨胀

- **日期**:2026-07-10
- **现象**:平台设备 DEV-GPS-001 的遥测日志从预期的 ~360 条膨胀到 79,277 条，且数据间隔为毫秒级（而非平台的 30 分钟级）。`last_telemetry_synced_at` 每次同步都在推进，但数据量持续增长。
- **误判**:先怀疑 datagen 未真正关闭（检查确认 `DATAGEN_ENABLED=false`），再怀疑是重复同步的 cursor 去重逻辑有 bug。
- **根因**:blade 平台返回的 `reportTime` 格式为 `MM/dd/yyyy HH:mm:ss`（如 `07/03/2026 13:14:34`），但 `parseReportTime()` 只支持 `yyyy-MM-dd HH:mm:ss`、`yyyy-MM-dd'T'HH:mm:ss` 和 ISO instant 三种格式。全部解析失败后 fallback 到 `Instant.now()`，导致：
  1. 每条记录的 `report_time` 被写成入库时间（毫秒级间隔）
  2. cursor 去重失效（所有 `Instant.now()` 都比上次的 cursor 新）
  3. 每次定时同步都重新摄入全部 360 条
- **解决**:`TIME_FORMATS` 数组新增 `DateTimeFormatter.ofPattern("MM/dd/yyyy HH:mm:ss")`。
- **判据**:
  - 日志中出现 `Could not parse reportTime` WARN → 立即检查平台实际返回的时间格式，补到 TIME_FORMATS。
  - 同步数据量持续增长且不收敛 → 检查 cursor 去重是否依赖时间解析（解析失败 → fallback 到 now → 去重失效 → 无限重播）。
  - 对接第三方平台时，先用 `curl`/日志确认所有时间字段的确切格式，再写解析器。不要假设格式。

---

## 11. datagen 与真实遥测共用同一张表无来源标记

- **日期**:2026-07-10
- **现象**:两台平台注册设备的遥测日志混入了大量 datagen 模拟数据（154,884 条），无法按字段区分哪些是平台真实遥测、哪些是 datagen 模拟。删除时只能靠时间窗口（平台同步前 vs 后）近似切割。
- **误判**:先按精确 (0,0) 删除脏 GPS（遗漏了近零坐标），再按时间窗口删除（datagen 和平台时间重叠期无法精确区分）。
- **根因**:`device_telemetry_logs` 表没有 `source` 字段记录数据来源。`TelemetryIngestionService.ingest()` 接收 `TelemetrySource` 参数但只用于控制 alert 检测和 cursor 推进，不写入日志表。datagen 和平台数据写入同一张表后完全混在一起。
- **解决（本次）**:靠时间窗口（平台首次同步时间 `2026-07-09 17:06:24` 作为分界线）删除平台设备上的旧数据，再重置 cursor 全量重新同步。
- **建议（根治）**:`device_telemetry_logs` 新增 `source VARCHAR(20)` 列，`logDeviceTelemetry()` 写入 `TelemetrySource` 枚举值。后续可按来源精确过滤/删除/统计。
- **判据**:
  - 多数据源写入同一张表 → 必须有来源标记字段（source/source_type），否则清理和排查只能靠时间近似。
  - 设计遥测采集架构时，`source` 字段与 `recorded_at` 同等重要——前者区分数据来源，后者区分时间顺序，缺一不可。

---

## 12. Flyway 迁移文件未提交 git 导致 checksum mismatch

- **日期**:2026-07-10
- **现象**:新增 Flyway 迁移后部署，应用启动报 `Migration checksum mismatch for migration version 20260709150000`，容器不断重启。
- **误判**:以为是迁移文件内容有语法错误。
- **根因**:迁移 `V20260709150000__phase3_add_runtime_status.sql` 在服务器上直接创建并执行了（通过之前的对话），但从未提交到 git。新增迁移 `V20260710140000` 后，rsync 把代码同步到服务器，但 `V20260709150000` 重建后的内容与服务器上已执行的原版不同（checksum 不匹配）。
- **解决**:
  1. 在 git 中重建该迁移文件（用 `IF NOT EXISTS` 保证幂等）
  2. 在数据库中 `UPDATE flyway_schema_history SET checksum = <new_checksum> WHERE version = '20260709150000'`
  3. 重启应用
- **判据**:
  - Flyway checksum mismatch → 先 `SELECT version, script, checksum FROM flyway_schema_history WHERE version = '<version>'` 看服务器记录，再对比 git 中的文件。
  - 任何在服务器上直接执行的迁移必须同步提交到 git，否则下次 rsync 部署必然 checksum 不匹配。
  - 迁移文件一律用 `IF NOT EXISTS` / `IF EXISTS` 保证幂等性，因为可能被执行多次（重建后）。

---

## 13. estrus_scores DECIMAL(5,2) 精度不足导致 INSERT 失败

- **日期**:2026-07-10
- **现象**:平台遥测数据同步后，`estrus_scores` 表 INSERT 报 `numeric field overflow: A field with precision 5, scale 2 must round to an absolute value less than 10^3`。
- **误判**:最初在 `device_telemetry_logs` 的 numeric 列中寻找溢出字段。
- **根因**:`distance_delta DECIMAL(5,2)` 最大值 999.99，而 `calculateDistanceDelta()` 计算近期与历史活动距离差值（单位：米），当活动量大时差值轻松超过 1000。
- **解决**:`distance_delta` → `DECIMAL(10,2)`，`temp_delta` → `DECIMAL(8,2)`，JPA `@Column(precision)` 同步更新。
- **判据**:
  - `numeric field overflow` → 根据错误信息的 `precision/scale` 值定位具体列（precision=5,scale=2 → DECIMAL(5,2)），再找哪张表有该定义。
 - 涉及差值/累加计算的数值列，按业务上界设精度：距离差（米）至少 DECIMAL(10,2)，温度差至少 DECIMAL(8,2)。
 - Flyway 迁移定义列精度时，考虑计算结果的最大值，不只是单条记录的值域。

---

## 14. GPS 轨迹查询返回空：先排除安装记录状态再查时间

- **日期**:2026-07-10
- **现象**:前端 24h / 7d / 30d 轨迹全部返回空，但数据库 `gps_logs` 表有 64 万条数据，`recorded_at` 是 `TIMESTAMPTZ`，时间范围正确。
- **误判**:一开始怀疑又是时区偏移（第 9 条）或 JPQL 参数名冲突（第 8 条），反复查 `recorded_at` 列类型和参数绑定。
- **根因**:分两层：
  1. **业务层**：前端 `/livestock/{id}/gps-logs` 通过 livestockId → active installation → deviceId → gps_logs 链式查询。之前测试解绑功能时把 livestock 1/2 的安装记录解绑了，`getActiveInstallationByLivestock` 返回空，整个链路断掉返回空列表。
  2. **时间格式层**：即使有 active installation，前端 `DateTime.toUtc().toIso8601String()` 输出 `+00:00` 时区偏移（非 `Z` 后缀），URL 编码将 `+` 变成空格（`...637881 00:00`），后端 `Instant.parse()` 抛 `DateTimeParseException` → 500 INTERNAL_ERROR。
- **解决**:
  1. 恢复被误解绑的安装记录。
  2. 新增 `parseInstant()` 工具方法，解析前 `replace(" ", "+")` 还原 URL 编码。
- **判据**:
  - `gps_logs` 有数据但 API 返回空 → 先查 `SELECT * FROM installations WHERE livestock_id = ? AND removed_at IS NULL`，确认有 active installation；再查时间格式。
  - API 返回 500 + `DateTimeParseException` → 检查 query param 中的时间格式是否被 URL 编码破坏（`+00:00` → ` 00:00`）。
  - `Instant.parse()` 只接受 `Z` 后缀或完整 offset；前端用 `toIso8601String()` 输出的是 `+00:00` 格式，后端必须做兼容处理。
  - **不要因为"时间相关问题"就只查时间**——业务链路（installation 状态）可能同时断了，分层排查。

---

## 15. 设备解绑功能从前到后的三个连锁 bug

- **日期**:2026-07-10
- **现象**:点击设备"解绑"只弹出演示 SnackBar，没有真正调用后端。修复后又连续触发三个问题。
- **误判**:每个 bug 都在解决后才暴露下一个，没有一开始就做端到端验证。
- **根因**:三个独立 bug 叠加：
  1. **InstallationJpaEntity 缺 `@PreUpdate`**：mapper `toJpaEntity()` 创建新 JPA entity，`createdAt` 为 null，`merge` 后 UPDATE 写入 null，违反 NOT NULL 约束 → 500。
  2. **`_loadInstallations()` 未带分页参数**：后端默认 `pageSize=20`，45 条活跃安装只拿到前 20 条，第 21 条以后的设备前端误判为"未绑定"，安装时触发 409 `设备已安装`。
  3. **设备生命周期状态不感知**：设备状态机 `INVENTORY→ACTIVE→OFFLINE→DECOMMISSIONED`，只有 ACTIVE 可安装。前端缺少 `lifecycleStatus` 字段和激活入口，INVENTORY 设备直接安装触发 409 `DEVICE_NOT_ACTIVE`。
- **解决**:
  1. `InstallationJpaEntity` 加 `@PreUpdate` 回填 `createdAt`。
  2. `_loadInstallations()` 加 `pageSize=500`。
  3. `DeviceItem` 增加 `lifecycleStatus`，设备列表对非 ACTIVE 设备显示"激活"按钮。
- **判据**:
  - `merge` 后 UPDATE 写 audit 列（`created_at`）为 null → JPA entity 缺 `@PreUpdate` 保护审计字段。
  - 前端"已绑定"判断与后端数据不一致 → 检查前端是否漏了分页参数，只拿了部分数据。
  - `DEVICE_NOT_ACTIVE` 409 → 前端没感知设备生命周期状态，需要先激活再安装，参考 spec §4.3 状态机。
  - **修复一个功能后，必须端到端走完整链路**（安装→激活→解绑→刷新），不要只测一步就认为"修好了"。

---

## 16. farmGet 路径缺前导斜杠导致 404

- **日期**:2026-07-10
- **现象**:设备健康详情 `devices/3/health` 返回 404，实际请求 URL 拼成了 `/farms/1devices/3/health`（farmId 和 devices 之间缺斜杠）。
- **误判**:以为是后端路由未注册或设备不存在。
- **根因**:`ApiClient.farmGet(suffix)` 的实现是 `'/farms/$id$suffix'`——直接拼接。suffix 必须以 `/` 开头，否则 `$id + suffix` 之间没有分隔符。`farmGet('devices/3/health')` → `/farms/1devices/3/health`。
- **解决**:所有 `farmGet`/`farmPost`/`farmPut`/`farmDelete` 的 suffix 参数统一以 `/` 开头。
- **判据**:
  - `farmXxx` 调用返回 404 且 URL 中 farmId 和路径段粘连（`1devices` 而非 `1/devices`）→ suffix 缺前导 `/`。
  - 新增 `farmGet`/`farmPost` 调用时，suffix 一律以 `/` 开头。

---

## 17. 以 reportTime 原始数值为时间基准，不做时区换算

- **日期**:2026-07-11
- **现象**:HKT-11-01 牲畜已绑定设备 00956906000285d8（dev_eui），数据库 gps_logs 有 252 条数据，后端 API 不带时间范围正常返回，但前端轨迹面板（24h/7d/30d）全部返回空。
- **误判**:第一反应是安装记录断裂（#14），排查后 installation 正常。然后怀疑是 ZoneId.systemDefault() 在 Docker（UTC）环境下导致时区偏移，把 systemDefault 改成硬编码 Asia/Shanghai。但这个方案的前提假设——"blade 返回的是北京时间"——只是推测，blade JSON 中 reportTime 没有任何时区标识（createTime/updateTime 均为 null），无法从数据本身确证时区。
- **根因**:反复出错的根源不是"猜错了时区"，而是**不该猜**。blade 平台 reportTime 字段格式为 MM/dd/yyyy HH:mm:ss，无时区标识。之前每次都试图确定"真实时区"然后做换算（atZone(systemDefault) → 改列类型 → atZone(Asia/Shanghai)），每次换环境就又偏了。正确做法：**直接用 reportTime 的原始时间数值，只做格式转换（MM/dd/yyyy → ISO），不做任何时区加减换算。** 后端 parseReportTime 用 ldt.toInstant(ZoneOffset.UTC)，前端查询也用本地时间数值（不做 toUtc()），全系统共享同一时间基准。
- **历史教训**:#9（已删除）把根因归到列类型（TIMESTAMP WITHOUT TIME ZONE），修复用 AT TIME ZONE 'Asia/Shanghai' 转换存量数据。列类型改 TIMESTAMPTZ 本身合理，但根因分析错误——真正的问题是 parseReportTime 里 ZoneId.systemDefault() 随部署环境（host UTC+8 → Docker UTC）变化导致行为不一致。#9 没有追到数据源头（parseReportTime），只改了下游（列类型 + 存量数据），所以问题反复出现。每次换部署环境，systemDefault 变了，偏移方向就变了，"修复"就失效。
- **解决**:
  1. 后端 AgenticPlatformReportData.parseReportTime()：ldt.toInstant(ZoneOffset.UTC)——格式转 ISO，数值不变，不依赖任何时区假设。
  2. 前端 trajectory_sheet.dart：去掉 toUtc()，用本地时间数值构造查询参数，与后端同一基准。
  3. 不需要数据迁移：当前 Docker（systemDefault=UTC）环境下存的数据已经是"原始数值当 UTC"，与 ZoneOffset.UTC 行为一致。
- **判据**:
  - 对接第三方平台的时间字段，如对方不带时区标识（无 Z/+08:00 后缀）→ **直接用原始数值不做换算**，只做格式转换。不要猜对方时区。
  - 后端解析无时区时间字符串一律 LocalDateTime.toInstant(ZoneOffset.UTC)，不用 ZoneId.systemDefault()、不硬编码来源时区。
  - 前端查询时间参数也不要做 toUtc() 转换，保持和后端存储同一基准。
 - 时间范围查询返回空但数据存在 → 先确认存储端和查询端是否在同一时间基准上（都做换算 vs 都不做换算），不要只改一端。

---

## 18. Excel 数值单元格读出 ".0" 后缀：Integer 解析静默失败、展示串带小数点

- **日期**:2026-07-29
- **现象**:NIX-79 遥测文件导入部署后集成验证：xlsx 的 RSSI 列（-99）入库后变成设备快照值（-89），与文件不符；帧计数器在预览中显示为 "119.0"。
- **误判**:第一反应是 readings 优先逻辑没生效（4.4 适配漏了 rssi 分支），查 logDeviceTelemetry 代码确认 readings-first 写法无误。然后怀疑 xlsx 里 RSSI 列是空字符串——用 Python 直接读文件确认值就是 -99。
- **根因**:blade 导出的 xlsx 中帧计数器/RSSI/SNR 是 **NUMERIC 单元格**（非文本）。POI 读出 double `-99.0`，经 `BigDecimal.toPlainString()` 得到字符串 `"-99.0"`；`Integer.parseInt("-99.0")` 抛 NumberFormatException，被"宽容解析返回 null"的逻辑吞掉 → readings 缺 rssi → 静默回退到设备快照值。单元测试全程用 STRING 单元格构造 xlsx，没覆盖到真实文件的 NUMERIC 形态。
- **历史教训**:与 #8（JPQL 返回空无报错）同类——**静默 fallback 让数据错误不可见**：解析失败返回 null 再兜底快照值，功能"看起来正常"，只有逐字段核对数据才能发现。宽容解析（garbage → null → 默认值）的代价是错误输入永远不报。
- **解决**:
  1. `TelemetryImportService.cellString` NUMERIC 分支：整数值按 Excel 显示语义渲染（`value == Math.floor(value)` → long 字符串，"119" 而非 "119.0"），一处修复同时解决解析失败与展示问题。
  2. 补回归测试：用 POI 构造 NUMERIC 单元格的 xlsx（double 119.0/-99.0/-9.0），断言 frameCounter="119" 且 rssi/snr 正确进 readings。
  3. dev 库中已导入的错误行按 source='MANUAL_IMPORT' 清理后重导（source 列（#11）第一次发挥排障价值）。
- **判据**:
  - 读 Excel 数值列做 Integer/Long 解析 → 先想单元格类型：NUMERIC 读出必带 ".0"，要么渲染时去尾，要么用 BigDecimal 解析再取整。
  - 涉及文件解析的功能，测试 fixtures 必须覆盖**真实文件里的单元格类型**（NUMERIC vs STRING），不能只用顺手的一种。
  - 宽容解析 + 兜底默认值 = 错误隐身衣；集成验证要逐字段比对源文件与入库值，不只看行数。


## 19. 被单测 mock 掉的数据库约束：startTrial 缺 billingCycle 在线上首跑才炸

- **日期**:2026-09-04
- **现象**:NIX-184 试点授权上线后人工验证：对新租户开通 365 天试点返回 INTERNAL_ERROR。日志 `null value in column "billing_cycle" of relation "subscriptions" violates not-null constraint`，抛点在 `CommerceLicenseAdapter.applyTrialLicense → Subscription.startTrial → save`。
- **误判**:三层防线全部漏过——① `CommerceLicenseAdapterTest` mock 了仓储 save，SQL 约束不在测试世界里；② `SubscriptionTest` 原有断言 `getBillingCycle()).isNull()` 把 bug 行为**固化成了预期**（对着实现写测试而非对着 schema 写）；③ 该链路没有任何 Testcontainers 集成测试。深层：本机 Docker 跑不了 Testcontainers（既有 14 失败），任务卡全部按"纯单测"设计，**环境限制悄悄降格了验收标准**；且部署后只做了 /health 存活检查，没对新写路径做业务冒烟——这条路径在所有环境都从未真实执行过，人工测试是它的第一次运行。
- **历史教训**:与 #15（修复后必须端到端走全链路）同源的新变体——**新功能上线也必须端到端走一遍**；"目标单测全绿"只是下限不是验收。测试断言必须从契约（schema/设计文档）推导，不能从当前实现反推，否则测试会变成 bug 的保护伞。
- **解决**:
  1. `Subscription.startTrial` 工厂默认 `billingCycle="monthly"`（列 NOT NULL，付费周期语义激活后才生效），删除断言 null 的过时用例并新增 monthly 断言（243c0505）。
  2. 补 `PilotLicenseJourneyTest`（Testcontainers 真库）：创建租户→授权→断言订阅行真实落库（billingCycle 非空）→再授权延长→ACTIVE 租户冲突拒绝。
  3. 部署验证升级为两段：存活检查（/health）+ **新增写端点业务冒烟**（真实调用成功与拒绝路径）。
- **判据**:
  - 单测 mock 掉仓储的写路径 → 数据库约束/触发器/迁移语义全部脱测，**新增 INSERT/UPDATE 路径必须至少一条真库集成测试**。
  - 写领域单测时先看表约束：NOT NULL/唯一键/生成列都是领域工厂必须满足的契约。
  - 测试断言与实现"意外一致"地断言了可疑行为（如 isNull）→ 停下来查 schema 与设计，不要顺手固化。
  - 本机跑不了的测试层（Testcontainers/Docker）≠ 可以不写；要显式安排在有 Docker 的环境执行（如 dev 服务器 `./gradlew test`），否则验收门槛被环境静默掏空。


## 20. 全新库迁移链三连断：只有存量环境验证过的迁移，对"第一次"没有免疫力

- **日期**:2026-09-04
- **现象**:NIX-184 补 `PilotLicenseJourneyTest`（Testcontainers 全新库）后在 dev 服务器首跑，Spring 启动连续倒在三个不同位置：① `V20260822100000__partition_ops_hardening.sql` 报 "cannot insert a non-DEFAULT value into column delta"；② `behavior_datasets.definition_digest` / `behavior_feature_contracts.schema_hash` 等列 Hibernate validate 报 "found bpchar, expecting varchar(64)"；③ 修 ① 时 `attgenerated='0'` 条件写错（应为空字节 `''`）报 syntax error at ")"。
- **误判**:①初期怀疑迁移与版本顺序相关，实际是分区搬移函数 `INSERT ... SELECT *` 回插时撞上 `temperature_logs.delta`（V20 `GENERATED ALWAYS` 生成列）——存量库迁移执行时默认分区恰好无行所以从未触发，全新库有种子数据必炸；②CHAR(64) 哈希列在存量库上恰好已是 varchar（或建库历史不同），validate 从未在全新库跑过。
- **根因**:迁移链只在"存量库增量执行"语境下验证过，**全新库路径（Testcontainers 每次都走）从未被真实执行**——与 #19 同源：写路径/初始化路径没有第一次。目录列类型细节（`pg_attribute.attgenerated` 正常值是空字节 `''` 不是 '0'）只能靠真实执行暴露。
- **历史教训**:与 #12（checksum mismatch）配套的另一半——改历史迁移必须同步修 checksum（CRC32 逐行不回加换行、低 32 位有符号，先用未改动文件对拍验证算法）；而**允许自己改历史迁移的前提是接受全新库也会重跑它**，这正是暴露 ①② 的机会而非代价。
- **解决**:
  1. 分区搬移回插改为显式列清单（`pg_attribute` 过滤 `attgenerated=''`），生成列由 DB 重算（V20260822100000）。
  2. 三文件 5 处 `CHAR(64)` → `VARCHAR(64)`（V20260822100000 未涉、V20260823100000 ×2、V20260903120000 ×3——后者是 NIX-184 自己引入的，设计文档写法照抄也会踩）。
  3. dev/test 库 `flyway_schema_history` 逐版本修 checksum，重新部署 dev 使 jar 内嵌迁移与 DB 一致。
  4. `PilotLicenseJourneyTest` + 既有 Auth/CommerceJourneyTest 在 dev 服务器全新库全绿——Testcontainers 家族复活。
- **判据**:
  - 新增/修改迁移后，验证标准不是"dev 库重启正常"，而是"**全新库能从零跑通**"（本地 Testcontainers 或 dev 服务器 `./gradlew clean test --tests *JourneyTest`）。
  - 表里存在 `GENERATED ALWAYS`/identity 列 → 一切行复制/搬移逻辑禁止 `SELECT *`，必须显式列清单排除生成列。
  - 哈希/指纹列用 `CHAR(n)` 而 JPA 实体是 `@Column(length=n)` 的 String → validate 必挂；项目约定统一 `VARCHAR(n)`。
  - 迁移里查 PG 目录（pg_attribute 等）先查文档确认取值域（attgenerated: ''/'s'/'v'），不要凭感觉写 '0'。
  - dev 服务器跑真库测试三件套：rsync `--delete --exclude='._*'`（防 AppleDouble 假迁移）→ `./gradlew clean`（防陈旧 build/resources 脏副本）→ 改过的迁移同步修 checksum。

---

## 21. 集成测试一轮抓四缺陷：契约示例、配置模板与实现语义的三方脱节

- **日期**: 2026-09-04
- **现象**: NIX-184 集成测试（API 级按契约文档打 86/223/dev）一轮发现 4 个单测全绿的真实缺陷：① 按契约示例传 `"breed":"西门塔尔牛"` / `"gender":"female"` 建牲畜 → 500（撞 `chk_livestock_breed` / `chk_livestock_gender`，服务层零校验）；② `POST /admin/api-keys` 按契约传 `scopes` 创建成功，但实现根本不读该字段 → 建出的 key 调任何 Open API 都 403；③ 门户建 key 返回体里没有 rawKey——ACL 适配器建完按 id 回查实体，把唯一一次的密钥明文丢了；④ 安装指南让操作员随机生成 `SMART_LIVESTOCK_TILE_WORKER_KEY`，但 DB 只认 V36 种子固定 rawKey → 两台验证机 tile-worker 每 60s 一条 401，瓦片永不渲染。
- **误判**: ①一开始以为是 NIX-184 新代码引入；实际是 7 月品种规范迁移只改了库和 Flutter（App 发规范码），契约文档示例从未跟进。②③ 是上线以来就存在的功能缺失，只是没人用管理端/门户真实建过 key 走完 Open API。
- **根因**: **文档示例、配置模板、实现语义三个"非代码层"没有随代码演进的同步机制**——迁移改了取值域、契约写了实现没有的字段、模板要求与种子矛盾，全都不会让任何测试变红，只有拿文档当输入去打真实环境才炸。与 #15（端到端走完整链路）同源：mock/单测验证"代码彼此一致"，集成测试验证"文档与代码一致"。
- **解决**: ① `LivestockAttributes` 服务层规范化（中文别名→规范码、大小写宽容、未知值 400 带可选清单）+ 契约示例全部改规范码；② 管理端接受并校验 scopes（`ScopeInterceptor.KNOWN_SCOPES` 单一事实源）+ 门户级限流默认对齐；③ 端口方法直返服务层 Map（含 rawKey），创建响应一次性返回；④ env 模板直接带种子值 + 安装指南钉死 + 运维指南补轮换 SQL 与首次建图章节（两台验证机运维侧已即时修复验证）。
- **判据**:
  - 迁移收紧取值域（CHECK/枚举/规范化）时，同一次提交必须同步：API 契约示例、Flutter 提交值、服务层校验——三处缺一就是"按文档调用 500"。
  - 创建类响应若含一次性机密（rawKey/密码/token），禁止"建完回查实体"的映射路径——回查永远拿不到明文；契约字段要在实现里逐字段核对（本次 `apiKey` vs `rawKey` 笔误即漏网）。
  - 配置模板里与 DB 种子耦合的键，模板必须带种子值本身（或安装脚本同步写库），"让用户随机生成"与"库里只有固定 hash"不能同时成立；症状特征：**周期性 401（等于 POLL_INTERVAL）= 某个轮询组件密钥失配**。
  - 集成测试输入必须来自契约文档而非自己发明的 payload——用自己"正确的"值测，等于替文档掩盖了漂移。

---

## 22. verify 脚本的 awk 区间表达式在 mawk 上静默失配：目标机 awk 方言是发布包的现实环境

- **日期**: 2026-09-05
- **现象**: 558 发布包在 86（Ubuntu）上机校验，`verify-release-bundle.sh` 报 `compose ports: found outside nginx -> []`——列表为空却判 FAIL；同一包同一文件在 dev 服务器（GNU awk）上是全过的。
- **误判**: 先怀疑包损坏或 compose 变更，实际 SHA256 全对；是脚本第 142 行 awk 正则 `[[:space:]]{4,}` 用了 POSIX 区间表达式，**mawk 1.3.4（Ubuntu 默认 awk）不实现区间**，静默匹配零行 → nginx 自己的 ports: 都探不到 → 空列表走 FAIL 分支。
- **根因**: 脚本头部宣称 "Runs on: Any machine"，但开发与自测只发生在 GNU awk 机器上——**验证工具本身没有在它声称要跑的方言环境里验证过**（与 #20"全新库没有第一次"同构：目标机 awk 没有第一次）。
- **解决**: 区间展开为四个显式 `[[:space:]]` 类 + `+`（f812e02e）；557 包作废重出 558；双机重装后 13/13 全过。
- **判据**:
  - 随发布包下机的校验/运维脚本，禁用 awk 正则区间 `{n,m}`（mawk 不支持且**静默失配**，不报错最危险）；显式枚举字符类最稳。
  - "校验工具在构建机上是绿的" ≠ "在目标机是绿的"——发布验收必须包含**在目标机原样跑一遍 verify**，并把它当真实测试而不是仪式。
  - 热修补过包内文件后，SHA256SUMS 必然失配——这是完整性校验在正确工作；正确出路是修复进 repo 重出包，而不是手改清单。
  - 复装/升级语境的 install 预检失败（端口占用/证书缺失/资源阈值）不是包的问题：先 down 旧栈、拷贝 secrets/certs、用 `MIN_MEM_GB/MIN_DISK_GB` 覆盖参数（install 脚本自带）。

---

## 关键词索引（遇症状按关键词快速定位）

| 编号 | 关键词 |
|------|--------|
| #1 | utf-8, decode, `._`, gen-l10n, arb, apple-double |
 | #2 | non-monotonic index, git, `._`, pack-idx, `/Volumes/DEV` |
 | #3 | 空列表, tile, status, 数据卷, glob, 挂载路径 |
 | #4 | sandbox, flutter, dart-tool, telemetry, HOME, analytics |
 | #5 | 路由, 状态机, 迟滞, hysteresis, neff, 阈值, 评审 |
 | #6 | 入口缺失, nginx, 镜像, main.dart.js, docker compose build |
 | #7 | 前端无变化, build_web.sh, deploy.sh, 缺一不可 |
 | #8 | jpql, @Query, from, 保留字, reserved-word, 返回空 |
 | #10 | reportTime, 数据膨胀, cursor, now(), 不收敛 |
 | #11 | datagen, source 字段, 多数据源, 共表 |
 | #12 | flyway, checksum, 迁移未提交, schema_history |
 | #13 | numeric overflow, decimal, precision, scale |
 | #14 | gps 空轨迹, installation, url-encode, 时间格式 |
 | #15 | 解绑, 连锁 bug, 端到端, install→active→unbind |
 | #16 | farmGet, 404, suffix, 前导斜杠, 路径粘连 |
 | #17 | reportTime, 时区, timezone, toInstant, UTC, 不换算 |
 | #18 | excel, xlsx, poi, numeric-cell, ".0", 静默回退, Integer.parseInt |
 | #19 | billing-cycle, not-null, start-trial, mock, 集成测试, journey, testcontainers, 生成列, generated-column, 冒烟 |
 | #20 | fresh-database, 全新库, generated-column, 生成列, bpchar, char, varchar, partition, attgenerated, checksum, journey |
 | #21 | 契约漂移, breed, gender, check-constraint, scopes, raw-key, api-key, tile-worker, 401, 轮询, 文档示例, 集成测试 |
 | #22 | mawk, awk, interval, {4,}, 区间表达式, verify-release-bundle, sha256sums, 热修, 重装, 预检, ubuntu |
