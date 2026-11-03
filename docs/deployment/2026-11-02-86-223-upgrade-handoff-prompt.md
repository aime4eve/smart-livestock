# 86/223 发布升级续跑提示词（交接用）

> **状态更新（2026-11-03 09:15，终态）**：**86 与 223 均已完成 840 升级，全链收口**。86：health 26/26、登录 200、md5 一致（回滚点 669 保留）。223（2026-11-03 设备修复后执行）：health 26/26、`deployment-info` ONPREM/VALID、登录 200、md5 一致、livestock 60 行数据存续（回滚点 669 保留）。本文保留作为下次升级流程参考。

> 用途：将本提示词投喂给任意智能体/会话，即可在上下文全无的情况下继续完成智慧畜牧项目 86（HOSTED）/ 223（ONPREM）两台验证机的发布升级（当前卡在网络层，研发侧工作已全部就绪）。

## 一、任务背景

- 项目：智慧畜牧（BoviScout），仓库本地路径 `/Volumes/DEV/00-products-dev/01-solutions/02-smart-livestock`，master 分支，最新提交 `67ed98e2`（已推 origin，Flutter CI 绿）。
- 目标：把 master 最新版本发布到 4 环境全量部署链的剩余两台：172.17.10.86（HOSTED，当前运行 669）与 172.17.10.223（ONPREM）。dev（19080）与 test（18080）已在本轮部署完成。
- 操作手册：`docs/deployment/release-deployment-playbook.md` §2（两跳传输）与 §4（升级流程）；经验判据见 `docs/reference/lessons-learned.md` #23。

## 二、当前发布包状态（研发侧已就绪）

- **发布包：`smart-livestock-market-beta-840.tar.gz`**（1.6G，版本以打包日志 `[OK] version: 840` 为准），位于：
  - Mac：`/tmp/smart-livestock-market-beta-840.tar.gz`
  - 123 构建机：`agentic@172.22.1.123:~/release-pkg/smart-livestock-market-beta-840.tar.gz`
  - 前端基线 md5（生效判据）：`b0bda30c43e7e26b7e449a5b785f163f`（`main.dart.js`）
- 构建机 verify **13/13 PASS**。
- **839 包已作废**：因 123 构建机源码树漂移（deploy.sh rsync 不带 `--delete`，git 已删除的陈旧类 `LoggingSignalOutboxEventPublisher.java` 残留并打进 jar），839 在 86 上启动失败（`SignalOutboxDispatcher` 注入到 2 个 `SignalOutboxEventPublisher` 候选 bean）。已对 123 做全量 `--delete` rsync 对齐本地源码后重打包为 840，编译零错误。**任何环境不得再安装 839**。

## 三、两台目标机现状

### 172.17.10.86（HOSTED，ssh hkt@172.17.10.86，免 sudo，hkt 在 docker 组）
- 旧 669 栈已 `docker compose --env-file .env.release -f docker-compose.release.yml down`（数据卷 pgdata/tileserver-data/behavior-models 全保留，回滚点完整）。
- Docker 旧镜像已 `prune -a`（回收 21G，磁盘现约 40G 可用；安装时用 `MIN_MEM_GB=15 MIN_DISK_GB=35` 覆盖预检）。
- `~/smart-livestock-market-beta-839.tar.gz` 与 `~/smart-livestock-market-beta-839/` 目录存在：内含**已继承好的 `release/.env.release`（RELEASE_VERSION=839）与 `release/secrets/certs/`**（继承自 669），839 的安装半途而废（app 起不来，postgres/redis 等容器可能残留，project 名 `smart-livestock-release`）。

### 172.17.10.223（ONPREM，ssh hkt@172.17.10.223）
- 本轮未动。旧版本目录以目标机实际为准（此前为 669 或更早，登录后 `ls -d ~/smart-livestock-market-beta-*` 确认）。
- 升级后必验：`GET /api/v1/deployment-info` 仍 `VALID`（ONPREM 授权调度器从 raw license 重推导）、登录可用、业务数据量对得上。

## 四、当前卡点（环境层，非研发层）

- **Mac 到 172.17.10.x 网段路由中断**（ssh 报 `No route to host`），今天该网段多次抖动（早间 206 宕机数小时后自愈；午间 86 短暂恢复后又断）。
- **86 服务器本身在线**：从 123（172.22.1.123）探测 86 的 22 端口可达。
- **123 → 86 无免密 SSH**（`Permission denied (publickey,password)`），无法从 123 代传；123 公钥在 `agentic@172.22.1.123:~/.ssh/id_ed25519.pub`。
- 223 与 206（DeviceHub）从 123 探测 22/9876 端口状态：223 DOWN、206 OK。

## 五、续跑步骤（86 → 223，一次一台，顺序不可颠倒）

### 86（前置二选一：Mac 路由恢复，或把 123 公钥加入 86 的 `~/.ssh/authorized_keys`）
1. 传包：Mac 路由恢复则 `scp /tmp/smart-livestock-market-beta-840.tar.gz hkt@172.17.10.86:~/`；否则在 86 可达 123 的前提下从 123 反向 `scp ~/release-pkg/smart-livestock-market-beta-840.tar.gz`（需先打通密钥）。
2. 清理 839 残留：`rm ~/smart-livestock-market-beta-839.tar.gz && rm -rf ~/smart-livestock-market-beta-839`（env/certs 先拷出）；解包 840：`cd ~ && tar xzf smart-livestock-market-beta-840.tar.gz`（新目录，不覆盖 669，留作回滚）。
3. 继承状态：从 839 目录（或 669 目录）拷 `release/.env.release`（`sed` RELEASE_VERSION→840）与 `release/secrets/certs/*`。
4. 校验：`cd ~/smart-livestock-market-beta-840 && bash release/scripts/verify-release-bundle.sh .` → **11/13 属预期**（2 条证书 FAIL=继承成功），判据看 `SHA256SUMS verifies` PASS。
5. 清残留栈：`cd ~/smart-livestock-market-beta-839/release 2>/dev/null && docker compose --env-file .env.release -f docker-compose.release.yml down`（839 半装容器）。
6. 安装：`cd ~/smart-livestock-market-beta-840/release && env MIN_MEM_GB=15 MIN_DISK_GB=35 bash scripts/install-release.sh`，结束判据 `/health 200 + "Install complete"`。
7. 验证：`sudo bash scripts/check-release-health.sh`（免 sudo 机器去掉 sudo）；owner 种子登录 `POST /api/v1/auth/login {"identifier":"13800138000","password":"123"}` 返回 200；容器内 `main.dart.js` md5 == `b0bda30c43e7e26b7e449a5b785f163f`；（HOSTED）试点授权仍在。

### 223（86 完成后再动）
- 同 §4 流程，旧版本号以目标机为准；env/certs 从其旧目录继承并 sed 版本号；ONPREM 额外验 `deployment-info VALID` 与数据存续。

## 六、红线与经验
- 版本号以打包日志 `[OK] version` 为准；不重装 839。
- 旧版本目录一律保留（回滚点：down 新栈 → 旧目录 `up -d`）。
- verify 11/13 = 证书继承成功的证明，不是失败。
- `check-release-health.sh` 历史 26 项为满；10/13 类"半通过"先对照 #23 判读再动手。
- 远程进程探活禁裸 `pgrep -f`（自匹配误报）。
- Flyway：840 无新增迁移（test 库已验证 schema 20261026100000 为最新基线），回滚无迁移障碍。

## 七、全部完成后的收尾
- 向用户汇报两台升级结果（版本、健康检查、登录冒烟、md5 判据）。
- 删除探测提醒（schedule `schedule-1c8f1913-fb3d-4cfa-9782-d19c2fdd2a39`，若仍存在）。
- 遗留工单备忘：`docs/superpowers/requirements/2026-10-31-subscription-health-threshold-configurable.md`（临期阈值可配置化，未获批编码）；`nix324-seed-state-smoke.sh` 的 `expiring_soon` 注释与 SQL 不一致（5 天到不了 3 天级）待修。
