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

## 沉淀规则(给后续维护者)

1. 每解决一个非平凡问题,追加一条到本文件,按"现象 → 误判 → 根因 → 解决 → 判据"五段式。
2. 重点写"误判"——把曾经走过的弯路记下来,避免重复踩。
3. "判据"要写成可立即套用的 if-then 规则,便于下一个 Agent 快速定位。
4. 涉及部署/数据的验证,遵循 AGENTS.md §5:编译 Agent 可做,部署与集成测试由用户执行。
