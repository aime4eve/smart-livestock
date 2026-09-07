# 市场测试版发布检查清单（NIX-184）

> **用法**: 发布负责人逐项勾选；每个阶段全部通过才进入下一阶段。用例编号对应 `docs/testing/market-beta-test-cases.md`；操作步骤见 `release-install-guide.md` / `release-operations-guide.md`。
> 运行机器标注：【构建机】【issuer 机】【86=172.17.10.86 HOSTED 验证机】【223=172.17.10.223 ONPREM 离线验证机】。

---

## 1. 代码验收【构建机 / CI】

- [ ] 后端**目标测试 0 失败**：licensing 领域/应用/Controller 测试、issuer 回程向量（`IssuerRoundtripVectorTest`）、commerce 授权适配相关测试全绿
- [ ] 后端全量回归：失败集合**不扩大**（既有基线 19 个失败 = 14 Testcontainers Docker 环境 + 5 `AlertReadStatusTest` mock 债务，见测试用例文档 §8）
- [ ] `./gradlew bootJar -x test` 构建成功
- [ ] Flutter：`flutter analyze` 无告警（CI 同口径）
- [ ] Flutter：既有测试全绿 + NIX-184 新增用例全绿（TC-F-01 ~ TC-F-08）
- [ ] Flutter：`flutter build web`（或 `build_web.sh`）产出完整 web bundle
- [ ] i18n：`flutter gen-l10n` 无缺失 key，zh/en arb key 集合一致；后端 `messages_zh/en.properties` 双语对齐（含 `license.*` 新 key）
- [ ] issuer【issuer 机】：`.venv/bin/pytest -q` 全绿（TC-I-01 ~ TC-I-07）

## 2. 包验收【构建机】

- [ ] `scripts/build-release-package.sh --version <v>` 成功（或 `--skip-web` 复用已验证 web 产物）
- [ ] 解包后 `./release/scripts/verify-release-bundle.sh <包目录>` **13 项全 PASS**（TC-P-02）
- [ ] `sha256sum -c SHA256SUMS` 全部 OK
- [ ] 六脚本 `bash -n` 语法通过（TC-P-03：install-release / check-release-health / backup-release / restore-release / verify-release-bundle；构建侧 build-release-package）
- [ ] 包结构完整（TC-P-04）：`images.tar.gz` + `release/{docker-compose.release.yml, .env.release.example, RELEASE_VERSION, scripts/, docs/, infrastructure/nginx/nginx.release.conf}`
- [ ] `docker compose -f docker-compose.release.yml config` 通过（TC-P-01，需临时 env）

## 3. 环境验收（双机实测，引用测试用例 §6）

### 3.1 172.17.10.86 — HOSTED 托管验证机

- [ ] TC-H-01 安装：install-release.sh 通过（preflight、镜像加载、/health 200）
- [ ] TC-H-02 端口暴露：仅 nginx 80/443 可达，DB/Redis/RocketMQ/tileserver 无外部端口
- [ ] TC-H-03 HTTPS：证书有效、HTTP 301 跳 HTTPS、TLS1.2/1.3
- [ ] TC-H-04 试点授权：platform_admin 开通 365 天试点 → TRIAL/effectiveTier=PREMIUM，延长生效
- [ ] TC-H-05 check-release-health 九项全 PASS（含 Flyway 最新、datagen 关闭）
- [ ] TC-H-06 备份恢复：backup → restore（确认词 RESTORE）→ /health 200、数据在

### 3.2 172.17.10.223 — ONPREM 离线验证机

- [ ] TC-O-01 离线安装：断网/最小依赖下 images.tar.gz 导入 → install-release.sh 通过
- [ ] TC-O-02 PENDING_ACTIVATION：未导入授权时业务 API 全部 403 `LICENSE_REQUIRED`，登录/登记信息可达
- [ ] TC-O-03 登记与签发：GET enrollment 取 installationId/fingerprint → issuer 按此签发 .sllicense
- [ ] TC-O-04 授权导入：上传（file+confirm）→ VALID/TRIAL，effectiveTier=PREMIUM，业务 API 恢复
- [ ] TC-O-05 绑定拒绝：复制授权到另机 / 改 payload / 指纹不匹配 / 租户不匹配 → 全部拒绝
- [ ] TC-O-06 时间回拨：回拨系统时间 → SUSPENDED 保护；恢复时间 + 导入有效授权可解除
- [ ] TC-O-07 到期降级：expiresAt 过后自动降 FREE/BASIC，数据保留，能力受 FeatureGate 限制
- [ ] TC-O-08 续费恢复：导入 ACTIVE 续费授权 → ACTIVE/PREMIUM，旧授权 REPLACED
- [ ] TC-O-09 数据库篡改校正：手工改状态表 → 调度器（≤5 分钟）恢复真实状态并留事件
- [ ] TC-O-10 断网独立运行：全程无外网依赖（镜像、公钥内置、授权离线）
- [ ] 端到端冒烟（TC-E-01 ~ TC-E-07）：业务链路 + 遥测→告警 + GPS + AI 降级 + 瓦片 + Open API + datagen/simulator 无数据

## 4. 安全验收

- [ ] 发布包内**无** license-issuer 目录/文件（verify-release-bundle 第 6 项）
- [ ] 发布包内**无**任何私钥材料（`BEGIN ... PRIVATE KEY` 扫描，第 7 项）与 `*.pem` 文件（第 8 项）
- [ ] 发布包内**无** `*.sllicense` 授权文件（第 9 项）
- [ ] `DATAGEN_ENABLED` / `TELEMETRY_SIMULATOR_ENABLED`：compose 硬编码 false（第 10/11 项）且 `.env.release.example` 模板值为 false
- [ ] 数据服务（postgres/redis/rocketmq×2/ai-platform/tileserver/app/tile-worker）无宿主机端口映射（health 第 7 项）
- [ ] issuer【issuer 机】：私钥目录 0700 / 密钥文件 0600（`KEYS_STRICT_PERMISSIONS=1`），服务仅内网可达（127.0.0.1 或内网反代），签发/下载审计可查
- [ ] `.env.release` 权限 600；备份目录 `go-rwx`；客户交付物不含任何厂商密钥/凭据
- [ ] 公钥注册表 `license-public-keys.json` 内无测试 keyId（`sl-license-test` 仅存在于 src/test）

## 5. 文档验收（六件套齐备）

- [ ] `docs/api-contracts/admin-api.md` §14「部署授权与试点授权」5 端点契约完整
- [ ] `docs/api-contracts/changelog.md` 2026-09-03 条目已追加
- [ ] `docs/guides/release-install-guide.md`（本清单与运维指南随包发布：包内 `release/docs/` 三份齐）
- [ ] `docs/guides/release-operations-guide.md`
- [ ] `docs/guides/release-checklist.md`（本文件）
- [ ] `docs/marketing/technical-support-guide.md`（售后 FAQ 与 ONPREM 支持边界为最新版）

## 6. 发布后

- [ ] 生产/交付环境 `https://<主机>/health` 返回 200
- [ ] `check-release-health.sh` 九项全 PASS 并留存输出
- [ ] 执行**首次备份**一次并异地留存（`backup-release.sh`）
- [ ] 监控接入：`/health` 拨测 + health 巡检 cron（运维指南 §1）
- [ ] ONPREM 交付件登记：客户名称、installationId、授权 licenseId/expiresAt、合同号入台账（issuer 记录 + 工单系统）
- [ ] 到期提醒机制建立：授权 expiresAt 前 30/15/7 天提醒（运维指南 §4）
