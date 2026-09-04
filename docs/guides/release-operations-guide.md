# 智慧畜牧市场测试版 运行维护指南（release）

> **读者**: 运维工程师 / 售后技术支持。覆盖日常巡检、日志排查、备份恢复、授权续期、版本升级与证书更换。
> **配套文档**: 安装部署（`release-install-guide.md`）、FAQ（`docs/marketing/technical-support-guide.md`，本指南不重复其内容，侧重运维操作）、故障方法论（`docs/reference/lessons-learned.md`）。
> 所有命令默认在**目标机**的 `release/` 目录执行（与 `docker-compose.release.yml`、`.env.release` 同级）。为省略书写，先定义：

```bash
cd /opt/smart-livestock-market-beta-<version>/release   # 按实际安装路径调整
alias dcr='docker compose --env-file .env.release -f docker-compose.release.yml'
```

---

## 1. 日常巡检

### 1.1 一键健康报告（九项）

```bash
./scripts/check-release-health.sh
```

覆盖：`/health`=200、9 服务 running+healthy、postgres/redis/rocketmq 可达、最新 Flyway 迁移成功、内部服务无宿主端口、TLS 证书剩余 > 30 天、datagen/simulator 双开关 false。退出码 0 = 全绿。

**建议频率**：

| 巡检项 | 频率 | 方式 |
|--------|------|------|
| check-release-health.sh | 每天 1 次（业务低峰，如 08:00），可 cron | `crontab -e`：`0 8 * * * cd /opt/.../release && ./scripts/check-release-health.sh >> /var/log/sl-health.log 2>&1` |
| `/health` 外部监控 | 持续（1 分钟粒度） | 监控系统拨测 `https://<主机>/health`（nginx 反代到 app），非 200 告警 |
| 备份 | 每天 1 次 + 每次变更前 | 见 §3，异地留存 |
| TLS 证书 | 由 health 第 8 项覆盖（< 30 天 FAIL） | 每周人工复核一次续期窗口 |
| 授权到期 | ONPREM 环境每月（临近到期加密到每周） | 见 §4.2 |

### 1.2 快速人工巡检

```bash
dcr ps                       # 9 个服务 Up (healthy)
curl -ks -o /dev/null -w '%{http_code}\n' https://localhost/health    # 200
df -h /opt                   # 磁盘余量（镜像+备份增长）
docker system df             # docker 空间占用
```

---

## 2. 日志与排查索引

### 2.1 各服务日志

```bash
dcr logs --tail 200 app          # 后端（业务、授权校验、ingestion）
dcr logs --tail 200 nginx        # 接入层（TLS、反代、瓦片代理）
dcr logs --tail 200 postgres     # 数据库
dcr logs --tail 200 redis
dcr logs --tail 200 rocketmq-namesrv
dcr logs --tail 200 rocketmq-broker
dcr logs --tail 200 ai-platform  # AI 行为分析（失败静默降级，不阻断主链路）
dcr logs --tail 200 tileserver   # 离线地图瓦片
dcr logs --tail 200 tile-worker  # 瓦片渲染 worker
dcr logs -f app                  # 跟踪滚动
```

常看的关键字（app 日志）：`Deployment license validation`（授权周期校验）、`License suspended/expired for tenant`（保护/降级动作）、`ApiException`（业务错误码）。

### 2.2 四层定位法（先定层，再查症状）

按 `docs/reference/lessons-learned.md` 的方法论，从外到内逐层排除，**只修定位到的那一层**：

| 层 | 典型症状 | 自查手段 |
|----|---------|---------|
| 1 环境层 | 工具崩、`._*` 文件污染、磁盘满 | `find . -name '._*' \| head`、`df -h` |
| 2 部署层 | 代码里有功能但前端没有、入口缺失 | `dcr ps` 容器是否旧实例；容器内 `main.dart.js` 与包内是否一致（nginx 镜像未重建类问题，lessons #6/#7） |
| 3 数据层 | 接口返回空、字段溢出、迁移失败 | Flyway：`dcr exec postgres psql -U postgres -d smart_livestock -c "select installed_rank,version,success from flyway_schema_history order by installed_rank desc limit 5"`（checksum mismatch 见 lessons #12） |
| 4 代码层 | 编译错、明确逻辑 bug | 最后才动；升级研发处理 |

### 2.3 遥测 / GPS / 告警常见症状速查

| 症状 | 先查 | 对应经验 |
|------|------|---------|
| 设备遥测不上报 | 设备在线状态 → rocketmq namesrv/broker 健康 → app 日志 ingestion 错误 | FAQ §3.8 |
| GPS 轨迹查询为空（库里有数据） | ① 牲畜 active installation 是否存在 → ② 查询时间格式是否 URL 编码正确 | lessons #14，FAQ §3.9 |
| 离线地图不显示 | `curl -ks https://localhost/tiles/` 是否 404 透传（前端据此降级）→ tileserver 健康 → tile-worker 是否产瓦片 | FAQ §3.10 |
| 告警未触发 | 遥测是否入库（`temperature_logs`/`activity_logs`）→ 规则配置 → app 日志规则引擎 | — |
| 接口返回空列表但无报错 | 数据层 glob/挂载路径、JPQL 参数名与保留字 | lessons #3/#8 |
| 数据量不收敛/重复膨胀 | 时间解析是否 fallback `now()` 导致 cursor 失效；多来源是否带 `source` 字段 | lessons #10/#11 |
| 数值字段 INSERT 失败 `numeric field overflow` | 列 precision/scale（差值列至少 DECIMAL(10,2)） | lessons #13 |
| 第三方时间数据显示异常 | 第三方时间字段按原始数值用、不做时区换算 | lessons #17 |

> 授权类症状（导入失败、PENDING_ACTIVATION 阻断、SUSPENDED、指纹不匹配）见 §4；客户端 FAQ 见 `docs/marketing/technical-support-guide.md` §3。

### 2.4 瓦片服务：worker 密钥与首次建图

**worker 密钥必须等于种子值。** tile-worker 用 `SMART_LIVESTOCK_TILE_WORKER_KEY` 调 app `/api/v1`，服务端只认迁移 V36 预置的「瓦片下载 Worker」Key（`sl_live_tile_worker_a1b2c3d4e5f6g7h8i9j0k1l2`，scopes=`*`）。若此处填了随机值，症状是：app 日志每 `POLL_INTERVAL`（默认 60s）一条 `ApiKeyAuthFilter: API Key authentication failed`，worker 永远拉不到任务。`.env.release.example` 已直接带种子值；随机自填会静默失配。

轮换步骤（生产建议做，beta 可沿用种子值）：

```bash
NEW_KEY="sk_live_$(openssl rand -hex 32)"
docker exec -i $(docker ps --format '{{.Names}}' | grep postgres) psql -U postgres -d smart_livestock \
  -c "UPDATE api_keys SET key_hash = encode(sha256(convert_to('$NEW_KEY','UTF8')),'hex') WHERE key_name='瓦片下载 Worker';"
# 再把 .env.release 的 SMART_LIVESTOCK_TILE_WORKER_KEY 改为 $NEW_KEY，然后：
docker compose --env-file .env.release -f docker-compose.release.yml up -d tile-worker
```

**首次建图（全新安装瓦片集为空属预期）。** 新装机器 `/tiles/*` 全部 404、前端地图灰底降级，不是故障——tileserver 数据卷里还没有任何区域。建图链路：b2b_admin / platform_admin 在地图页圈选区域（或 `POST /admin/tiles/tasks`）→ tile-worker 轮询渲染 mbtiles → tileserver 出图。验证：`curl -ks https://localhost/tiles/<区域名>/<z>/<x>/<y>.png` 返回图片即通。

---

## 3. 备份与恢复

### 3.1 备份（backup-release.sh）

```bash
./scripts/backup-release.sh
# 自定义目标：BACKUP_ROOT=/mnt/nas/sl-backup ./scripts/backup-release.sh
```

产出 `backups/release-<时间戳>/`（目录权限自动 `go-rwx`，因含 DB 口令与 TLS 私钥）：

| 内容 | 路径 | 说明 |
|------|------|------|
| PostgreSQL 逻辑备份 | `db/smart_livestock.sql` | `pg_dump`，**恢复的唯一数据源** |
| 瓦片数据卷 | `volumes/tileserver-data.tar.gz` | 只读挂载 + tar |
| AI 模型卷 | `volumes/behavior-models.tar.gz` | 同上 |
| 环境配置 | `config/.env.release` | 含密钥，注意保管 |
| TLS 证书 | `config/certs/` | 缺失时跳过并 WARN |
| 完整性清单 | `SHA256SUMS` | 恢复前强校验 |

> 语义说明（脚本头注释）：`pg_dump` 为逻辑备份。要求崩溃一致快照时，先 `dcr stop app tile-worker` 再备份、完成后 `dcr start`；或接受无 WAL 的逻辑备份语义。`pgdata` 原始卷**不**归档（跨 postgres 版本恢复不支持，逻辑备份为准）。

### 3.2 恢复（restore-release.sh，破坏性操作）

```bash
./scripts/restore-release.sh backups/release-20260903-120000
# 无人值守（自动化场景）：./scripts/restore-release.sh <备份目录> --yes
```

脚本五步：① 校验备份 SHA256SUMS（失败拒恢复）→ ② **交互确认，需手动输入大写 `RESTORE`**（`--yes` 跳过）→ ③ 停 app / tile-worker / nginx（postgres 保持运行），DROP + 重建数据库并回放 dump → ④ 用 tar 覆盖恢复两个数据卷 → ⑤ `compose up -d` 并自动执行 `check-release-health.sh` 作为最终门禁。

### 3.3 恢复后验证

1. health check 九项全绿（脚本自动跑）。
2. 业务抽查：登录 → 租户/牧场列表 → 任一牲畜的最近遥测与告警记录，与备份前已知状态比对。
3. 若备份跨较长时间窗，核对授权状态：`GET /api/v1/admin/deployment-license/current` 确认 `runtimeStatus` 为恢复时点的状态（库内授权记录随备份整体回滚，属预期）。

---

## 4. 授权续期操作（ONPREM）

### 4.1 到期前续期流程（建议 30 天启动）

```text
到期前 30 天：巡检发现 expiresAt 临近（GET /current 或客户侧到期提醒页）
   ↓
客户提出续期申请 → 厂商人工完成合同/付款确认（线下流程，系统不代判）
   ↓
issuer 签发 ACTIVE 类型授权：绑定原 tenantId / installationId / fingerprintHash，
   tier 与有效期按合同，签发原因注明续期（issuer /issue/new → preview → confirm → 下载）
   ↓
客户侧导入（platform_admin）：
   curl -X POST ".../api/v1/admin/deployment-license?tenantId=<ID>" \
        -H "Authorization: Bearer $TOKEN" -F "file=@{licenseId}.sllicense" -F "confirm=true"
   ↓
GET /current 确认：runtimeStatus=VALID、licenseType=ACTIVE、subscriptionStatus=ACTIVE，
   旧授权记录自动标记 REPLACED
```

要点：

- 续期授权必须是 **ACTIVE 类型**。到期降级为 FREE 后，TRIAL 类型授权会被拒绝（409 `STATE_CONFLICT`，`license.import.trialDowngradeRejected`）——试用不可重来，只能付费续。
- 绑定三元组任一不符 → 403 `LICENSE_BINDING_MISMATCH`（客户换机/重装系统指纹会变，见 §4.4）。
- 导入被拒时订阅与运行态**不变**，可放心重试；每次拒绝都留审计事件。

### 4.2 到期降级行为（客户预期管理）

授权过期后由调度器（每 5 分钟，启动时也跑）自动处理：

- `runtimeStatus → EXPIRED`，订阅降级 **FREE/BASIC**（ACTIVE/TRIAL/RENEWAL_FAILED → FREE；FREE 幂等）。
- **业务 API 不阻断**、数据全部保留；超出 FREE 档的能力由 FeatureGate 关闭（前端表现为功能入口隐藏/升级提示）。
- 续期授权导入后立即恢复 ACTIVE/PREMIUM，无需重启。
- HOSTED 环境对应动作：重新对租户调试点授权（延长到 max(当前， now+365d)），或按合同走订阅开通。

### 4.3 时间回拨保护（SUSPENDED）的处理

系统时间回拨超过容差（`SMARTLIVESTOCK_LICENSE_TIME_TOLERANCE`，默认 PT2M）时，下个校验周期触发保护：

- 现象：`runtimeStatus=SUSPENDED`，`lastErrorCode=LICENSE_TIME_ROLLBACK`，`protectionReason=PROTECTION_TIME_ROLLBACK`；业务 API 全部 403 `LICENSE_REQUIRED`，仅登录与授权管理可达（含 Open API）。
- 处理：**把系统时间校准回正确时间**（NTP 修复），不要手工改库里的 `maxObservedAt` 锚点；等下个周期（≤5 分钟）调度器重验自愈回 VALID 并重新映射订阅。
- 时钟长期错乱导致授权时间窗失效的极端场景：时间修复后若仍 EXPIRED，由 issuer 重新签发新 `expiresAt` 的授权导入（对 `2026-...` 型时间写死的旧授权无解，重签是唯一路径）。
- 数据库被手工篡改（改状态表）同样会在下个周期自愈并留事件——这也是"改库绕授权"不可行并被审计的原因。

### 4.4 换机 / 指纹变化

`/etc/machine-id` 变化（重装系统、迁移主机）→ 实时指纹与授权绑定不符 → 校验失败进入 `SUSPENDED`（`LICENSE_BINDING_MISMATCH`）。处理：issuer 按新指纹重新签发授权导入；原指纹授权作废（REPLACED）。**不支持**把宿主机 machine-id 改回旧值来"骗"授权——按合规流程重签。

---

## 5. 版本升级

前提：新版本发布包已按安装指南 §3 完成校验（SHA256SUMS + verify-release-bundle）。

```bash
# 0) 准备：新版包解包到独立目录（与旧版并存，保留回滚能力）
cd /opt && tar xzf smart-livestock-market-beta-<new-version>.tar.gz

# 1) 备份当前运行环境（必做，跨 Flyway 版本升级的回滚唯一手段）
cd /opt/smart-livestock-market-beta-<old-version>/release
./scripts/backup-release.sh

# 2) 在新版 release/ 复用现有配置与证书
cd /opt/smart-livestock-market-beta-<new-version>/release
cp /opt/smart-livestock-market-beta-<old-version>/release/.env.release .env.release
sed -i "s/^RELEASE_VERSION=.*/RELEASE_VERSION=<new-version>/" .env.release   # 对齐新包标签
mkdir -p secrets && cp -a /opt/smart-livestock-market-beta-<old-version>/release/secrets/certs secrets/

# 3) 安装（preflight → docker load 新镜像 → up -d 重建容器 → 等待 /health）
./scripts/install-release.sh
```

- **Flyway 自动迁移**：app 启动时自动执行未应用的迁移，无需手工步骤；health check 第 6 项会验证最新迁移成功。升级后首次启动较慢（迁移 + 缓存预热），`HEALTH_TIMEOUT_SECS=600` 保险。
- **升级后验证**：九项 health + 端到端冒烟（登录、遥测、告警、GPS、瓦片、Open API）+ `GET /current` 确认授权状态未变。
- **回滚预案**：
  1. 在新版目录 `dcr down`（保留卷）。
  2. 回到旧版 release/ 目录，恢复升级前的备份：`./scripts/restore-release.sh backups/release-<升级前时间戳> --yes`（脚本结尾自动跑 health check）。
  3. 旧版 `./scripts/install-release.sh` 重新拉起旧镜像栈。
  > **重要**：Flyway 迁移不自动回退。凡跨了 DB 迁移的升级，回滚**必须**先恢复数据库备份（§3.2），否则旧版代码对上新表结构可能异常。仅镜像小修（无迁移）时可直接切回旧包 `up -d`。

---

## 6. 证书更换

```bash
# 1) 放置新证书（覆盖旧文件；确认链完整、私钥与证书匹配）
openssl x509 -noout -modulus -in secrets/certs/fullchain.pem  | openssl md5   # 与下一行输出一致
openssl rsa  -noout -modulus -in secrets/certs/privkey.pem    | openssl md5
openssl x509 -enddate -noout -in secrets/certs/fullchain.pem                # 确认新到期日

# 2) 重启 nginx 加载（证书是 bind-mount，无需重建镜像/重启全栈）
dcr restart nginx

# 3) 验证
curl -sI https://<域名>/health | head -1                      # HTTP/2 200
echo | openssl s_client -connect <域名>:443 2>/dev/null | openssl x509 -noout -enddate
./scripts/check-release-health.sh                             # 第 8 项应显示新的剩余天数
```

> 建议在剩余有效期 < 30 天前完成更换（health check 第 8 项会提前 FAIL 提醒）；续期证书签发时确认 SAN 覆盖实际访问域名。ONPREM 客户环境由运维远程指导客户自行更换（边界见 technical-support-guide §5）。
