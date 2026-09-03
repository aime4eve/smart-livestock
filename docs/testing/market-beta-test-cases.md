# NIX-184 市场测试版测试用例

> 关联：实现设计 `docs/superpowers/specs/2026-08-31-market-beta-release-readiness-implementation-design.md`（§15 测试设计）、实施计划 `docs/superpowers/plans/2026-09-03-nix-184-market-beta-release-readiness-plan.md`。
> 环境：本地（单测/构建）、dev（172.22.1.123）、部署验证机 **172.17.10.86（HOSTED）/ 172.17.10.223（ONPREM 离线）**。
> 通过标准：单测类用例对应自动化测试全绿；部署类用例在目标机人工/脚本执行并留验证记录。

## 1. 后端单元测试（licensing）

| ID | 用例 | 步骤要点 | 预期 |
|---|---|---|---|
| TC-B-01 | canonical JSON 排序与时间 | 多层级 payload 序列化 | 按键名字典序递归排序、compact 分隔、UTC `yyyy-MM-dd'T'HH:mm:ss'Z'`、整数无小数点 |
| TC-B-02 | Ed25519 签名验签 | 有效私钥签名 → 验签 | 验签通过；改任一 byte 失败 |
| TC-B-03 | 非法 envelope 拒绝 | 缺 format/keyId/payload/signature 字段 | 拒绝，LICENSE_INVALID |
| TC-B-04 | keyId 不支持 | envelope.keyId 不在公钥注册表 | 拒绝，LICENSE_INVALID |
| TC-B-05 | payloadSha256 不匹配 | 篡改 payload 后原 hash | 拒绝，LICENSE_INVALID |
| TC-B-06 | 绑定不匹配 | 依次改 tenantId / installationId / fingerprintHash | 三者均拒绝，LICENSE_BINDING_MISMATCH |
| TC-B-07 | 过期授权降级 | expiresAt < now 跑校验 | 状态 EXPIRED，订阅映射 FREE/BASIC，数据保留 |
| TC-B-08 | 续费授权激活 | EXPIRED/TRIAL/FREE 后导入 ACTIVE 授权 | ACTIVE / license.tier，旧 license 标记 REPLACED |
| TC-B-09 | 授权配额优先 | ONPREM 下 license 配额与 FeatureGate 并存 | license 配额优先生效；无该 key 回退 FeatureGate；HOSTED 行为不变 |
| TC-B-10 | 时间回拨保护 | max_observed_at 后系统时间回拨 | SUSPENDED / LICENSE_TIME_ROLLBACK，业务 API 被阻断 |
| TC-B-11 | 改库自愈 | 手工改 deployment_license_states 后跑 scheduler | 恢复真实状态，事件留痕 |
| TC-B-12 | 365 天试点创建 | 无订阅租户调 pilot-license | 创建 TRIAL/BASIC，trialEndsAt=now+365d，effectiveTier=PREMIUM |
| TC-B-13 | 365 天试点延长 | 未过期 TRIAL 再调 | 延长到 max(current, now+365d)，不缩短 |
| TC-B-14 | 非法订阅状态拒绝 | ACTIVE/FREE/SUSPENDED/CANCELLED/EXPIRED/RENEWAL_FAILED 状态调 pilot-license | STATE_CONFLICT 拒绝，审计留痕 |
| TC-B-15 | 降级后不可重回试用 | EXPIRED 降级 FREE 后导入 TRIAL 类型授权 | 拒绝（须 ACTIVE 续费授权） |
| TC-B-16 | 导入用量预检 | 牲畜/围栏/牧工/设备任一超 license 配额 | 导入失败，LICENSE_QUOTA_EXCEEDED，不进入降级/激活 |

## 2. Controller / API 测试

| ID | 用例 | 预期 |
|---|---|---|
| TC-C-01 | 非 platform_admin 访问四个授权端点 | 403 AUTH_FORBIDDEN |
| TC-C-02 | HOSTED 模式调地端 API（enrollment/upload/current） | 拒绝（AUTH_FORBIDDEN） |
| TC-C-03 | ONPREM 模式调试点 API | AUTH_FORBIDDEN |
| TC-C-04 | ONPREM 自助订阅结账/升级/取消 | 全部拒绝 |
| TC-C-05 | GET enrollment | 返回 tenantId/installationId/fingerprintHash/publicKeyId/supportedPublicKeyIds/generatedAt；重复调用 installationId 稳定 |
| TC-C-06 | multipart 上传成功 | 有效 .sllicense + confirm=true 导入成功，状态即时生效 |
| TC-C-07 | multipart 上传失败 | 篡改/错租户/缺 confirm 各场景拒绝并返回对应错误码 |
| TC-C-08 | GET current | 返回授权、订阅映射、最近校验结果、max_observed_at、保护原因 |
| TC-C-09 | GET mode | 返回 HOSTED/ONPREM 与 pilotLicenseEnabled，与配置一致 |
| TC-C-10 | enforcement 放行清单 | /health、login/refresh、deployment-license/**、admin/tenants/** 始终可达 |
| TC-C-11 | PENDING_ACTIVATION 阻断 | 牧场/牲畜/设备/遥测/健康/Open API 业务 API 全部 LICENSE_REQUIRED |
| TC-C-12 | SUSPENDED 仅授权管理 | 仅登录与授权管理可达，业务 API 返回 LICENSE_REQUIRED |

## 3. license-issuer 测试（pytest）

| ID | 用例 | 预期 |
|---|---|---|
| TC-I-01 | 登录失败 | 错误密码拒绝并审计 |
| TC-I-02 | CSRF 缺失拒绝 | 无 token 的 POST 被拒 |
| TC-I-03 | 私钥缺失 fail fast | 启动/签发时报错退出，不出部分文件 |
| TC-I-04 | canonical 向量一致 | Python 与 Java（license-issuer/test-vectors/）产出字节一致 |
| TC-I-05 | 签发文件可被 Java 验签 | 下载的 .sllicense 通过 Ed25519LicenseVerifier |
| TC-I-06 | 篡改 payload 后 Java 拒绝 | LICENSE_INVALID |
| TC-I-07 | 签发/下载均有审计 | SQLite 审计记录含操作人、licenseId、payloadSha256、时间 |

## 4. Flutter 测试

| ID | 用例 | 预期 |
|---|---|---|
| TC-F-01 | 授权页角色可见性 | platform_admin 可见入口；其他角色不可见且直达被 redirect |
| TC-F-02 | 登记信息渲染 | installationId/fingerprintHash/publicKeyId 正确显示，可复制 |
| TC-F-03 | 文件上传 | 选择 .sllicense 后调用正确 API（multipart + confirm） |
| TC-F-04 | 状态卡片渲染 | VALID/PENDING_ACTIVATION/EXPIRED/SUSPENDED 四种状态样式与文案正确 |
| TC-F-05 | 试点授权按钮 | HOSTED 模式显示；点击调用 pilot-license API；冲突错误文案展示 |
| TC-F-06 | alerts route 无 dead code | `flutter analyze` 无 dead_code / unused_local_variable 警告 |
| TC-F-07 | 中英文 key 完整 | zh/en arb key 集合一致，gen-l10n 无缺失 |
| TC-F-08 | 续费引导文案 | EXPIRED/SUSPENDED 状态展示续费引导 |

## 5. 发布包验证（本机）

| ID | 用例 | 预期 |
|---|---|---|
| TC-P-01 | compose config | `docker compose -f docker-compose.release.yml config` 通过 |
| TC-P-02 | verify-release-bundle | SHA256 正确；无 license-issuer；无私钥/BEGIN PRIVATE KEY/*.pem 私钥/*.sllicense；DATAGEN_ENABLED=false；TELEMETRY_SIMULATOR_ENABLED=false；数据服务无 host 端口映射 |
| TC-P-03 | 脚本语法 | 六脚本 bash -n 通过 |
| TC-P-04 | 包结构 | images.tar.gz + release/{compose,env,scripts,docs} + SHA256SUMS 齐全 |

## 6. 部署验证矩阵（双机实测）

### 6.1 172.17.10.86 — HOSTED 托管验证机

| ID | 用例 | 预期 |
|---|---|---|
| TC-H-01 | 安装 | install-release.sh 通过（Docker/资源/端口/证书校验、镜像加载、/health 200） |
| TC-H-02 | 端口暴露 | 仅 nginx 80/443 可达；DB/Redis/RocketMQ/tileserver 无外部端口 |
| TC-H-03 | HTTPS | 证书有效、HTTP 跳转 HTTPS、TLS1.2/1.3 |
| TC-H-04 | 试点授权 | platform_admin 开通 365 天试点 → 订阅 TRIAL/BASIC effectiveTier=PREMIUM；延长生效 |
| TC-H-05 | check-release-health | 全项通过（含 Flyway 最新、datagen 关闭） |
| TC-H-06 | 备份恢复 | backup-release.sh → restore-release.sh → /health 200、数据在 |

### 6.2 172.17.10.223 — ONPREM 离线独立部署验证机

| ID | 用例 | 预期 |
|---|---|---|
| TC-O-01 | 离线安装 | 断网/最小依赖下 images.tar.gz 导入 → install-release.sh 通过 |
| TC-O-02 | PENDING_ACTIVATION | 未导入授权时业务 API 全部阻断，可登录/看租户/看登记信息 |
| TC-O-03 | 登记与签发 | GET enrollment 取 installationId/fingerprint → issuer 按此签发 .sllicense |
| TC-O-04 | 授权导入 | 上传后 VALID/TRIAL，effectiveTier=PREMIUM，业务 API 恢复 |
| TC-O-05 | 绑定拒绝 | 复制授权到另机 / 改 payload / 指纹不匹配 / 租户不匹配 → 全部拒绝 |
| TC-O-06 | 时间回拨 | 回拨系统时间 → SUSPENDED 保护模式；恢复时间+导入有效授权可解除 |
| TC-O-07 | 到期降级 | expiresAt 过后自动降级 FREE/BASIC，数据保留，能力受 FeatureGate 限制 |
| TC-O-08 | 续费恢复 | 导入 ACTIVE 续费授权 → ACTIVE/PREMIUM，旧授权 REPLACED |
| TC-O-09 | 数据库篡改校正 | 手工改状态表 → scheduler 5 分钟内恢复真实状态 |
| TC-O-10 | 断网独立运行 | 全程无外网依赖（镜像、公钥内置、授权离线） |

## 7. 端到端业务链路（冒烟，dev + 双机）

| ID | 用例 | 预期 |
|---|---|---|
| TC-E-01 | 牧场/牲畜/围栏/设备增删改查 | 全链路正常（配额内） |
| TC-E-02 | 遥测上报 → 告警 | 遥测入库、规则告警触发、App 可见 |
| TC-E-03 | GPS 轨迹 | 上报→入库→轨迹查询正常 |
| TC-E-04 | 健康评分（AI 试点） | AI 失败时静默降级，不影响遥测与规则告警主链路 |
| TC-E-05 | 离线地图 | /tiles/ 正常出图 |
| TC-E-06 | Open API | API Key 鉴权、限流、租户隔离行为与发布前一致 |
| TC-E-07 | datagen/simulator 关闭 | release 环境无仿真数据写入 |

## 8. 回归基线

- 后端全量测试既有 19 个失败（14 Testcontainers Docker 环境 + 5 AlertReadStatusTest mock 债务）；本次判断回归以**目标测试全绿 + 失败集合不扩大**为准。
- Flutter：`flutter analyze`（CI 同口径）+ 既有测试全绿 + 新增用例全绿。
