# 市场测试版部署实战指南（86 / 223 双机复盘）

> **定位**：本文是 2026-09 在 172.17.10.86（HOSTED 托管）与 172.17.10.223（ONPREM 离线独立部署）两台验证机上**实际走过全流程**的部署手册与踩坑复盘，与通用单机安装指南 `release-install-guide.md`（安装器视角）互补：安装指南回答"每一步是什么"，本文回答"实战顺序、真实耗时、哪些坑必须先知道"。
> 关联：实施计划看板 `docs/superpowers/plans/2026-09-03-nix-184-market-beta-release-readiness-plan.md`、lessons #20–#22（`docs/reference/lessons-learned.md`）、运维手册 `release-operations-guide.md`。

---

## 0. 环境与角色

| 项 | 172.17.10.86 | 172.17.10.223 |
|----|--------------|----------------|
| 定位 | HOSTED 托管验证机（我方运营，可演示） | ONPREM 离线独立部署验证机（模拟客户机房） |
| 网络 | 安装时可联网（apt/docker hub 可达） | **离线机**：download.docker.com 被 TLS/SNI 阻断，一切依赖随包携带 |
| 系统 | Ubuntu，12C/15G/117G | RHEL 系，同规格（安装器资源下限：8C/16G/100G，验证机用 `MIN_MEM_GB/MIN_DISK_GB` 覆盖） |
| Docker | 在线 apt 安装 | **离线 dpkg**：从 86 的 apt 缓存拷 deb 离线安装 |
| 访问 | `ssh hkt@172.17.10.86` | `ssh hkt@172.17.10.223` |

> dev 构建机 = `agentic@172.22.1.123`，源码目录 `~/smart-livestock-server`（deploy.sh rsync 同步），包输出 `~/release-pkg/`。

---

## 1. 构建发布包（dev 服务器）

```bash
# 前提：源码已 rsync 到 dev 服务器且与目标提交一致（跑一次 deploy.sh dev/test 即完成同步）
ssh agentic@172.22.1.123
cd ~/smart-livestock-server
nohup bash scripts/build-release-package.sh --skip-web --out ~/release-pkg \
  > ~/release-pkg/build-<版本>.log 2>&1 &
```

- **版本号 = `build.number` 文件值**（gradle 构建会自动 +1，连打两包版本不同是正常的）。产物：`~/release-pkg/smart-livestock-market-beta-<版本>.tar.gz`（约 1.6–1.7G）。
- `--skip-web` 复用服务器 `frontend/`（deploy.sh 刚同步过的就是新前端）；改了 Flutter 代码才需要去掉它重新构建 web。
- **包内 RELEASE_VERSION 必须与目标机 `.env.release` 的 `RELEASE_VERSION` 一致**，安装器硬校验。升级到新包版本时记得改 env（见 §4）。
- 构建完成后在构建机先过一遍 verify（GNU awk 环境）：

```bash
cd ~/release-pkg && mkdir -p v && tar xzf smart-livestock-market-beta-<版本>.tar.gz -C v \
  && cd v && bash release/scripts/verify-release-bundle.sh . && cd .. && rm -rf v
```

> ⚠️ 历史教训 #22：verify 脚本曾因 awk 区间表达式在目标机 mawk 上假失败——**558 起已修复**；更早的包（≤557）在 Ubuntu 目标机上 verify 不可信。

---

## 2. 传输（两跳：dev → Mac → 目标机）

dev 服务器到两台验证机无免密 SSH，以 Mac 为中转：

```bash
# Mac 上（每跳约 2.5 分钟 / 1.7G；Mac 磁盘紧张时逐台传、用完即删）
scp agentic@172.22.1.123:~/release-pkg/smart-livestock-market-beta-<版本>.tar.gz /tmp/
scp /tmp/smart-livestock-market-beta-<版本>.tar.gz hkt@172.17.10.86:~/
# 223 同理；传完删 Mac 中转
```

经验：一次一台，装完一台再传下一台，避免 Mac 磁盘同时躺两个包。

---

## 3. 全新安装（首次，223 离线案例）

1. **Docker 先行**（仅全新机需要）：86 在线 apt 安装；223 离线场景从 86 的 apt 缓存拷 deb 后 `dpkg -i`（download.docker.com 被阻断）。目标：Docker ≥ 29 + Compose v2 插件。
2. 解包并校验：

```bash
cd ~ && tar xzf smart-livestock-market-beta-<版本>.tar.gz
cd smart-livestock-market-beta-<版本>
bash release/scripts/verify-release-bundle.sh .   # 必须 13/13
```

3. **填写 `release/.env.release`**（从 `.env.release.example` 拷贝）。必填项与校验规则见安装指南 §env 表；三条实战要点：
   - `SMART_LIVESTOCK_TILE_WORKER_KEY` **保持种子值** `sl_live_tile_worker_a1b2c3d4e5f6g7h8i9j0k1l2`（V36 预置 Key 的 rawKey；随机自填 = worker 永久 401，瓦片永不渲染，症状是 app 日志每 POLL_INTERVAL 一条 401）。生产轮换步骤见运维指南 §2.4。
   - `SMARTLIVESTOCK_LICENSE_MODE`：86=HOSTED、223=ONPREM；`DATAGEN_ENABLED`/`TELEMETRY_SIMULATOR_ENABLED` 必须 false（compose 层还有双保险）。
   - `POSTGRES_PASSWORD`/`JWT_SECRET` 用 `openssl rand -base64 48` 现场随机，绝不复用。
4. **TLS 证书**放 `release/secrets/certs/{fullchain.pem,privkey.pem}`（自签或本地 CA 方案见 §6）。
5. 安装（验证机规格不足时带覆盖参数）：

```bash
cd release && sudo env MIN_MEM_GB=15 MIN_DISK_GB=75 bash scripts/install-release.sh
# 结束判据：/health 200 + "Install complete"
sudo bash scripts/check-release-health.sh          # 目标 26/26
```

> ONPREM 授权首启即 PENDING_ACTIVATION：业务 API 全阻断是**设计行为**，按 `license-issuer` 签发 `.sllicense` → `GET /admin/deployment-license/enrollment` 取安装 ID/指纹 → `POST /admin/deployment-license` 导入 → VALID（全流程见安装指南与签发手册）。

---

## 4. 升级 / 重装（已有一套在跑的机器）

本轮（556 → 558）验证过的顺序，**数据卷全程保留**：

```bash
# 1) 新包解包到新目录（不要覆盖旧目录，回滚保险）
cd ~ && tar xzf smart-livestock-market-beta-<新版本>.tar.gz

# 2) 继承旧机状态：env（含 worker key 等已轮换值）与证书
cp  ~/smart-livestock-market-beta-<旧版本>/release/.env.release \
    ~/smart-livestock-market-beta-<新版本>/release/.env.release
sed -i "s/^RELEASE_VERSION=<旧>/<新>/" ~/smart-livestock-market-beta-<新版本>/release/.env.release
mkdir -p ~/smart-livestock-market-beta-<新版本>/release/secrets/certs
cp ~/smart-livestock-market-beta-<旧版本>/release/secrets/certs/* \
   ~/smart-livestock-market-beta-<新版本>/release/secrets/certs/

# 3) 包校验（13/13，注意 §1 的 mawk 教训——旧包在 Ubuntu 上会假 FAIL）
cd ~/smart-livestock-market-beta-<新版本> && bash release/scripts/verify-release-bundle.sh .

# 4) 停旧栈（端口 80/443 释放；命名数据卷 pgdata/tileserver-data/behavior-models 不受影响）
cd ~/smart-livestock-market-beta-<旧版本>/release
sudo docker compose --env-file .env.release -f docker-compose.release.yml down

# 5) 新目录安装（覆盖参数按机器实际；health 通过即成功）
cd ~/smart-livestock-market-beta-<新版本>/release
sudo env MIN_MEM_GB=15 MIN_DISK_GB=75 bash scripts/install-release.sh
sudo bash scripts/check-release-health.sh
```

**重装后必验的数据存续项**：登录可用、（ONPREM）`GET /api/v1/deployment-info` 仍 `VALID`（调度器从 raw license 重推导）、业务数据量对得上、（HOSTED）试点授权仍在。

**回滚**：旧版本目录原样保留（env/certs 都在里面），`down` 新栈 → 旧目录重新 `up -d` 即回滚——前提是 Flyway 没有引入新迁移；新迁移已应用时回滚需按运维指南走 DB 恢复。

---

## 5. 交付加固清单（交给客户 / 对外演示前逐项打勾）

| # | 项 | 动作 | 依据 |
|---|----|------|------|
| 1 | **管理员口令** | 默认种子 `platform_admin/13800000000` 是发布包公开信息，交付前必须用 `PUT /api/v1/me/password` 轮换；正式方案见管理员账号设计（docs/superpowers/specs/2026-09-05-admin-bootstrap-design.md） | 本指南 §7 |
| 2 | tile-worker key | beta 可沿用种子值；生产按运维指南 §2.4 轮换（生成新 key → 更新 DB hash → 改 env → 重建 worker） | lessons #21 |
| 3 | 演示数据 | 223 交付客户前清理种子演示租户/牲畜（SQL 或后台），避免"客户数据=演示数据" | — |
| 4 | 密钥随机化 | 确认 `POSTGRES_PASSWORD`/`JWT_SECRET` 非模板值（安装器已强校验，复查即可） | 安装指南 |
| 5 | 证书 | 公网/客户内网用正规 CA 证书；仅我方演示环境可用本地 CA（§6） | §6 |
| 6 | 备份 | 交付前跑一轮 `backup-release.sh` + 恢复演练（86 已闭环验证） | 运维指南 §3 |

---

## 6. HTTPS 证书：三种签发方式（脚本一键完成）

**560+ 包自带 `release/scripts/gen-tls-cert.sh`**，覆盖内部部署的全部场景（openssl 一条依赖）：

```bash
# 方式一：快速自签（SAN 自动带本机 IP + localhost）
# 浏览器会提示不受信任——仅适合临时起服
bash scripts/gen-tls-cert.sh --out secrets/certs

# 方式二：本地 CA 模式（推荐内部使用）——创建 CA 并签发
# 把生成的 secrets/certs/ca/ca.crt 装进运营人员浏览器一次，
# 之后该 CA 签的所有服务器证书都被信任
bash scripts/gen-tls-cert.sh --out secrets/certs --create-ca \
  --san IP:172.17.10.86 --san IP:172.17.10.223

# 方式三：已有 CA（公司 CA / 上节创建的本地 CA）直接签发
bash scripts/gen-tls-cert.sh --out secrets/certs \
  --ca-cert ca.crt --ca-key ca.key --san IP:172.17.10.223
```

- 不带 `--san` 时自动探测本机 IP；`--force` 覆盖已存在的证书。
- 签完 `docker compose restart nginx` 生效。
- 一次性手敲等价操作（脚本内部做的事）见下；装 CA 进浏览器信任链后提示即消失。

安装器自签证书一年且不进任何信任链——Chromium 内核浏览器（含 ZCode 内建浏览器、Chrome）直接 `ERR_CERT_AUTHORITY_INVALID` 且无跳过入口。**不要用"忽略证书校验"**（全局降级）。我方演示环境的做法：

```bash
# Mac 上（~/.ssl-private/nix184-ca/，私钥 600，绝不入仓库）
OSSL=/opt/homebrew/opt/openssl@3/bin/openssl
$OSSL req -x509 -newkey rsa:2048 -keyout ca.key -out ca.crt -days 3650 -nodes \
  -sha256 -subj "/CN=NIX184 Local Dev CA"
printf 'basicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\n\
extendedKeyUsage=serverAuth\nsubjectAltName=IP:172.17.10.86,IP:172.17.10.223\n' > san.ext
$OSSL req -newkey rsa:2048 -keyout server.key -out server.csr -nodes -sha256 -subj "/CN=livestock-beta"
$OSSL x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 825 -sha256 -extfile san.ext
cat server.crt ca.crt > fullchain.pem
# 信任进登录钥匙串（用户域，免 sudo；Chromium 立即生效）
security add-trusted-cert -r trustRoot -k ~/Library/Keychains/login.keychain-db ca.crt
# 两台机 secrets/certs/{fullchain.pem,privkey.pem} 替换后：
sudo docker compose --env-file .env.release -f docker-compose.release.yml restart nginx
```

注意：叶子证书 825 天到期需重签；目标机 IP 变更要改 SAN 重签；该信任仅限导入过 CA 的机器——**客户环境仍应走正规 CA**（安装指南的证书替换流程不变）。

---

## 7. 踩坑速查表（实战按序排列）

| 症状 / 场景 | 根因与正确姿势 | 出处 |
|-------------|----------------|------|
| 包 verify 在 Ubuntu 目标机报 `compose ports: found outside nginx -> []` | mawk 不支持 awk 区间 `{4,}`，**静默**匹配零行；558 起已修（显式枚举字符类）。更早的包该结果不可信 | lesson #22 |
| 热修文件后 verify 报 SHA256SUMS 失配 | 完整性校验在正确工作——**修复进 repo 重出包**，不要手改清单 | lesson #22 |
| 重装预检 FAIL：端口占用 / 证书缺失 / 内存磁盘不足 | 升级语境正常：先 down 旧栈；certs 从旧目录拷；`MIN_MEM_GB`/`MIN_DISK_GB` 覆盖 | 安装器 |
| 启用 TB 后日志里没有任何 `[TB]` 行 | **正常**：绑定表（`tb_device_bindings`）空时 `poll()` 直接 return，连 `[TB] polling` 都不打；TB 绑定走 NS 设备预置路径创建，blade 同步来的设备走 blade 遥测通道、不建 TB 绑定 | §9.4 |
| tile-worker 每 POLL_INTERVAL 一条 401、瓦片永不渲染 | worker key ≠ V36 种子值；env 保持种子值，生产按运维指南 §2.4 轮换 | lesson #21 |
| rsync 源码后 Flyway 报重复迁移版本 | AppleDouble（`._*`）文件被当迁移；rsync 带 `--delete --exclude='._*'` | lesson #20 |
| 改过的迁移在目标机 checksum mismatch | 逐版本修 `flyway_schema_history` checksum；且必须先过"全新库从零跑通" | lesson #20 |
| 服务器重跑 gradle 测试/构建行为异常 | 陈旧 `build/resources` 脏副本：先 `./gradlew clean` | lesson #20 |
| Mac 传包磁盘不够 / 误传旧包 | 两跳逐台、传完即删中转；文件名带版本号核对 | §2 |
| 223 装 Docker 失败（TLS/SNI 阻断） | 离线机定位：从 86 的 apt 缓存拷 deb 离线 dpkg 安装 | §0/§3 |
| RHEL 系 bash 没有 `/dev/tcp` | 健康探测用 `nc`/`curl`，不要用 bash 内建 TCP（check-release-health 已按此实现） | lessons #21 注 |
| 备份脚本在容器属主 root 文件上 chmod 失败 | 脚本已容忍（不中止）；备份目录权限自动收紧 | 运维指南 §3 |
| Chromium 打开自签 HTTPS 报 `-202` 无跳过 | §6 本地 CA 方案；禁止"忽略证书校验" | §6 |

---

## 8. 实测耗时参考（供排期）

| 步骤 | 耗时 |
|------|------|
| 构建发布包（--skip-web） | 8–10 分钟 |
| 单跳传输（1.7G） | ~2.5 分钟 |
| 解包 + verify | ~2 分钟 |
| 全新安装（含镜像 load + health 等待） | 4–6 分钟 |
| 升级重装（含 down 旧栈） | 5–8 分钟 |
| check-release-health | ~1 分钟 |

---

## 9. 采集对接（ThingsBoard / NS / blade）

> **环境归属**：86 = dev 环境载体、223 = test 环境载体——采集对接复用对应 dev/test 环境的凭据与端点。凭据事实源是 dev 构建机 `agentic@172.22.1.123` 的 `~/smart-livestock-server/.env.dev`（dev）与 `.env`（test）；**绝不写入发布包、仓库或文档**。2026-09-12 首次接入，操作与验证方法沉淀如下。

### 9.1 三条通道与端点

| 通道 | 作用 | dev（→86） | test（→223） |
|------|------|-----------|-------------|
| ThingsBoard（TB） | 瘤胃胶囊遥测直拉（轮询 5 分钟，回看 180 天） | `.env.dev` 的 `SMARTLIVESTOCK_TB_*` | `.env` 的 `SMARTLIVESTOCK_TB_*` |
| NS | 设备预置数据源（导入/绑定设备时经 `listDevices` 建档建 TB 绑定） | `SMARTLIVESTOCK_NS_*` | 同左 |
| blade 设备同步 | 设备台账同步 + 遥测通道（5 分钟增量） | blade dev `172.21.2.41:8100/8108`，服务账号 `2079382969422938112` | blade test `172.22.4.17:8100/8108`，服务账号 `2074385063398711296` |

TB / NS 的 BASE_URL 不需要配：application.yml 默认值即 `http://172.22.3.105` / `http://172.17.201.15`。

**网络可达性实测（2026-09-12）**：

| 目标 | 86（172.17.10.x） | 223（172.17.10.x） |
|------|------|------|
| TB `172.22.3.105:80` | ✅ | ✅ |
| NS `172.17.201.15:80` | ✅ | ✅ |
| blade dev `172.21.2.41:8100/8108` | ❌ 网络策略阻断，**待开通后按 §9.3 补配** | — |
| blade test `172.22.4.17:8100` | — | ✅ |

### 9.2 双机当前状态

| 机器 | 运行栈 | TB | NS | blade | 数据流 |
|------|--------|----|----|-------|--------|
| 86（HOSTED / dev 载体） | `~/smart-livestock-market-beta-560/release` | ✅ 登录 200 | ✅ | ⏳ 待网络开通 | 暂无（无绑定设备时 TB 静默待命） |
| 223（ONPREM / test 载体） | `~/smart-livestock-market-beta-562/release` | ✅ 登录 200 | ✅ | ✅ 同步中 | blade 首轮 2 设备 2073 条入库，此后 5 分钟增量 |

升级到新版本目录时，`.env.release` 随目录走（§4 步骤 2 会继承），采集配置跟着迁移，无需重配。

### 9.3 给发布机接采集的操作步骤

（1）凭据从 dev 构建机 **ssh 管道直传**目标机（不落中间明文、不进日志；Mac 上执行）：

```bash
# 86：TB+NS（dev 侧凭据）
ssh agentic@172.22.1.123 'grep -E "^SMARTLIVESTOCK_(TB|NS)_(USERNAME|PASSWORD)=" ~/smart-livestock-server/.env.dev; \
  echo SMARTLIVESTOCK_TB_ENABLED=true; echo SMARTLIVESTOCK_NS_ENABLED=true; \
  echo SMARTLIVESTOCK_TB_LOOKBACK_DAYS=180' \
| ssh hkt@172.17.10.86 'cat > ~/tb-ns-merge.env && chmod 600 ~/tb-ns-merge.env'

# 223：全套（test 侧凭据，含 AGENTIC_PLATFORM_*）
ssh agentic@172.22.1.123 'grep -E "^(AGENTIC_PLATFORM|SMARTLIVESTOCK_TB|SMARTLIVESTOCK_NS)" ~/smart-livestock-server/.env' \
| ssh hkt@172.17.10.223 'cat > ~/test-merge.env && chmod 600 ~/test-merge.env'
```

（2）目标机上备份 + awk 合并（先替换已有键、再**追加缺失键**——`AGENTIC_PLATFORM_SYNC_ENABLED` 等键不在 `.env.release.example` 预置列表里，漏追加会静默走默认 `false`）：

```bash
cd ~/smart-livestock-market-beta-<版本>/release
cp .env.release .env.release.bak-$(date +%Y%m%d)
awk -v mf="$HOME/<合并文件>" '
BEGIN { while ((getline line < mf) > 0) {
    if (line == "" || line !~ /=/) continue
    i=index(line,"="); k=substr(line,1,i-1); v=substr(line,i+1)
    if (!(k in kv)) order[++n]=k; kv[k]=v }
  close(mf) }
{ i=index($0,"=")
  if (i>1) { k=substr($0,1,i-1); if (k in kv) { seen[k]=1; print k"="kv[k]; next } }
  print }
END { for (j=1;j<=n;j++) if (!(order[j] in seen)) print order[j]"="kv[order[j]] }
' .env.release > .env.release.new && mv .env.release.new .env.release && rm -f "$HOME/<合并文件>"
```

回滚：`cp .env.release.bak-<日期> .env.release` 后重新 `up -d`。

（3）重启（只重建 app 容器，数据卷与授权状态不动）：

```bash
docker compose --env-file .env.release -f docker-compose.release.yml up -d
```

### 9.4 验证清单

| 项 | 方法 / 判据 |
|----|------------|
| TB 凭据 | `source` 进 `.env.release` 的 `SMARTLIVESTOCK_TB_*` 后 `curl -s -o /dev/null -w "%{http_code}" -X POST http://172.22.3.105/api/auth/login` → **200**；只看状态码，不要打印 token |
| blade 同步 | `docker compose logs app \| grep PlatformSync`：`[PlatformSync] device N ... synced M records (ingested=M)`；无行则查 `AGENTIC_PLATFORM_SYNC_ENABLED` 是否真进了容器 |
| 遥测入库 | psql：`select source, count(*) from device_telemetry_logs where created_at > now() - interval '2 hours' group by source`（blade 来源 = `AGENTIC_PLATFORM`） |
| TB 通道 | psql：`select binding_status, count(*) from tb_device_bindings group by binding_status`；**表空 = 静默待命，属正常**（见 §7 踩坑表） |
| 整机 | `bash scripts/check-release-health.sh` → 26/26 |

> 机制背景：发布 compose 的 app 服务用 `env_file: .env.release` 整体注入，`environment:` 段只钉内部路由——所以在 `.env.release` 加键即可达 Spring 配置；但反过来说，**没写的键不会出现在容器里**，会走 application.yml 默认值（如 `SYNC_ENABLED` 默认 false、`TB_BLADE_EXCLUSION` 默认 false）。
