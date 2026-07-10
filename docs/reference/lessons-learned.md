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

## 9. TIMESTAMP WITHOUT TIME ZONE + JPA Instant = 8 小时时区偏移

- **日期**:2026-07-10
- **现象**:GPS 轨迹 API 按时间范围查询（24h）返回 0 条，但不带时间范围的查询返回 14 条。数据库中数据时间为 `2026-07-10 20:09:13`（北京时间），UTC 当前时间 `12:14Z`，24h 前 `7/9 12:14Z`——数据被当成 UTC `20:09Z`（未来时间），不在查询窗口内。
- **误判**:先怀疑是 (0,0) 过滤逻辑误杀了数据、再怀疑是 JPQL 参数名问题（确实也是问题之一），最后才发现是时区偏移。
- **根因**:`gps_logs.recorded_at` 列定义为 `TIMESTAMP WITHOUT TIME ZONE`。数据写入链路：
  1. `parseReportTime()` 用 `ZoneId.systemDefault()`（服务器 UTC+8）把平台时间 `07/03 13:14:34` 转为 `Instant`（UTC `05:14:34Z`）
  2. JPA `Instant` 写入 `TIMESTAMP WITHOUT TIME ZONE` 列时，截掉时区，存入 `05:14:34`（裸值）
  3. 实际平台返回的是本地时间，`parseReportTime` 用 `atZone(systemDefault).toInstant()` 已经把 `13:14:34` 转成了 `05:14:34Z`
  4. 但写入 TIMESTAMP 列时 Hibernate 又用 session timezone 重新转回本地时间 `13:14:34`（如果 JVM timezone 是 UTC+8）
  5. 读取时 Hibernate 再把 `13:14:34` 当 UTC，产生 8 小时偏移
  
  最终效果：数据被当成 UTC 存储，与前端传的 UTC 时间比较时偏了 8 小时。
- **解决**:`ALTER TABLE gps_logs ALTER COLUMN recorded_at TYPE TIMESTAMPTZ USING recorded_at AT TIME ZONE 'Asia/Shanghai'`，将裸时间戳按本地时区重新解释为带时区的时间戳。
- **判据**:
  - JPA `Instant` 映射到 PostgreSQL `TIMESTAMP WITHOUT TIME ZONE` → 一定会有时区偏移。一律用 `TIMESTAMPTZ`（`TIMESTAMP WITH TIME ZONE`）。
  - 时间范围查询返回 0 但数据确实存在 → 对比存储值与查询参数的时区解释是否一致。
  - 新建表的时间列一律 `TIMESTAMPTZ`，不用 `TIMESTAMP`。迁移时用 `AT TIME ZONE 'Asia/Shanghai'` 确保旧数据被正确重新解释。

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
