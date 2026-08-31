# 项目级 TB 设备接入对账与一站式开通设计（NIX-180）

> Date: 2026-08-29  
> Status: 已实现并部署 dev/test；project 89 核心验收通过，等待用户集成测试
> Issue: NIX-180（Parent: NIX-142）  
> Plan: `docs/superpowers/plans/2026-08-29-tb-device-autoconfig-plan.md`  
> Prototype: `docs/marketing/2026-08-29-tb-device-autoconfig-wizard.html`

## 1. 背景

NIX-179 已打通 TB REST 采集与 project 89 的 TB Gateway 路由，但设备接入仍有五段手工事实核对：NS 清单、TB device/profile/deviceId、本地 device、`tb_device_bindings`、active installation。缺任何一段都会表现为“NS 有数据但系统采集不到”。

Project 89 的项目名称包含“60台”，但 NS 清单 API 当时返回 30 台。对账事实源必须使用 NS `project/list` 对应项目的设备清单 API，而不是项目名称、口头数量或本地存量。

## 2. 目标

1. 输入 NS project id，输出 NS / TB / smart-livestock 三方差集报告。
2. TB 匹配使用原样、大写、小写三变体精确匹配；多个不同 TB deviceId 命中时阻断导入。
3. 校验 TB Device Profile，输出 profile 名称、TB deviceId、本地 device id、最近 TB telemetry 时间、绑定状态和 active installation 状态。
4. dry-run 只读；wet-run 在提交时重新校验并幂等创建本地 device 与 `RESOLVED` TB binding，写入 audit log。
5. 提供单设备一站式开通 API/App 向导：预检、确认、可选安装到牲畜、立即触发一次 TB 拉取。
6. 更新项目级接入操作说明，并保留 NS / TB Gateway / blade 的责任边界。

## 3. 非目标

- 不读取或修改 TB Gateway `OC` shared attribute / project mapping。
- 不自动创建 TB 设备，不修改 NS 设备、密钥、LoRaWAN App、项目归属或网关。
- 不从 EUI 推导 livestock；未显式选择牲畜时只开通采集，不承诺围栏与健康计算。
- 不引入 NS MQTT 作为应用采集通道，不用 datagen 冒充真实接入验收。

## 4. 架构

### 4.1 NS 清单

新增 `NsProperties` / `NsClient`：

- Base URL 默认 `http://172.17.201.15`，API prefix `/backend/api/`。
- `POST /login/` 获取 `token`，后续请求头 `x-token`。
- `GET /lora_wan/device/list/?org={orgId}&project={projectId}&page={page}&limit={limit}` 分页拉取。
- 响应只接受 `code=0`；`count` 是分页终止条件，`data` 中设备统一解析 `dev_eui` / `devEui`。
- 凭据来自 `SMARTLIVESTOCK_NS_USERNAME` / `SMARTLIVESTOCK_NS_PASSWORD`，不落库、不入 Git。

### 4.2 TB 对账

扩展 `TbClient`：

- `findDevices(eui)` 返回三变体精确命中的设备摘要，而不是只返回一个 id。
- `fetchDeviceProfiles()` 分页建立 profileId → profileName 映射。
- `fetchLatestTelemetryTs(tbDeviceId)` 用 `orderBy=DESC&limit=1` 查询最近 `result/dataHex` 时间。

Profile 白名单：

| TB profile | 本地类型 |
|---|---|
| `瘤胃胶囊-OC-配置-v2` | `CAPSULE` |
| `牛羊追踪器-OC-配置-v2` | `TRACKER` |

未知 profile 只报告 `PROFILE_MISMATCH`，不得导入。

### 4.3 对账与导入

`TbDeviceProvisioningService.reconcile(projectId, tenantId)`：

1. 分页拉取 NS project 清单并按规范化小写 EUI 去重。
2. 对每个 EUI 调用 TB 三变体精确匹配、profile 校验和最近 telemetry 查询。
3. 拉取本地 tenant devices，按小写 EUI 关联 `tb_device_bindings` 与 active installation。
4. 每台设备输出 `NS_MISSING / TB_MISSING / TB_AMBIGUOUS / PROFILE_MISMATCH / LOCAL_MISSING / BINDING_MISSING / NO_RECENT_TELEMETRY / NO_ACTIVE_INSTALLATION / RECONCILED` 差集代码。
5. 报告包含 `nsCount`、`tbUniqueCount`、`localCount`、`resolvedBindingCount`、`activeInstallationCount` 与事实源说明。

`import(projectId, requestedItems, operator)`：

1. 重新拉取 NS/TB 当前状态，不信任 dry-run 快照。
2. 只导入 `NS_PRESENT + TB_UNIQUE + PROFILE_VALID` 的设备。
3. 本地 EUI 已存在则复用；缺失时创建 ACTIVE device，默认编号 `TB-{projectId}-{eui}`。
4. binding 按 `(device_id, provider)` 与 `(provider, external_device_id)` 幂等处理；外部身份冲突时整项失败，不覆盖。
5. 每台设备写入 `TB_DEVICE_IMPORTED` audit log，包含 project id、EUI、TB deviceId/profile、本地 device id、导入结果、操作者和时间。

### 4.4 单设备向导

后端提供：

- `GET /api/v1/farms/{farmId}/devices/tb/preflight?eui=...`
- `POST /api/v1/farms/{farmId}/devices/tb/provision`

预检状态：

`PENDING_NS → PENDING_TB_DEVICE → PENDING_TELEMETRY → READY_TO_INGEST → PENDING_INSTALLATION → ACTIVE`

Project route 状态不自动判定；当 TB 设备存在但无 telemetry 时输出 `PENDING_TELEMETRY` 与人工检查提示，避免读取或猜测 TB Gateway shared attribute。

开通请求必须包含 EUI，可选 `deviceCode` 与 `livestockId`。服务端仍以当前 TB 校验结果推断设备类型并重新校验请求类型；`livestockId` 缺省时开通到 `PENDING_INSTALLATION`，存在时创建 active installation。事务提交后对新建/复用 binding 立即触发一次 TB 拉取。

### 4.5 App 向导

现有“注册设备”表单升级为三步向导：

1. 输入 EUI 并预检。
2. 确认 TB deviceId、profile、设备类型和设备编号；用户可重新预检。
3. 选择牲畜或选择“暂不安装”，提交开通并展示分层结果。

控制器使用 farm-scoped API，必须继承 `FarmScopedAsyncNotifier` 并在 `build()` 调用 `watchActiveFarmId()`。所有文案进入中英 ARB。

## 5. 安全与幂等

1. dry-run 不调用任何写 repository，不写 audit log。
2. wet-run 提交时重新校验 NS/TB，防止旧 dry-run 快照导入已失效设备。
3. EUI 入库前统一小写并要求 16 位 hex。
4. TB 大小写同名不同 deviceId 判定 `TB_AMBIGUOUS`，只输出候选，不导入。
5. 本地 EUI 复用 active device；软删除记录不自动复活，报告 `LOCAL_SOFT_DELETED`。
6. TB deviceId 已绑定其他本地 device 时判定身份冲突，整项失败。
7. 无 livestockId 只提示围栏/健康不生效，不自动猜测安装关系。
8. 导入和单设备开通都不修改 TB Gateway project mapping。

## 6. 验收标准

- [ ] project 89 只读对账返回 30 台 NS 设备及三方差集；项目名称数量差异在报告说明中可见。
- [ ] 大小写同名不同 TB 设备被阻断，候选 deviceId 完整输出。
- [ ] dry-run 无 device/binding/audit 写入；wet-run 重复执行不新增重复 device/binding。
- [ ] 导入结果能追溯 project id、EUI、TB deviceId/profile、本地 device id、操作者和时间。
- [ ] 单设备向导无 telemetry、TB 设备缺失、profile 不匹配、本地已存在、未安装时输出对应状态。
- [ ] EUI 规范化、大小写歧义、profile 校验、dry-run/wet-run、幂等导入、NS 分页解析、TB profile/telemetry 查询均有单测。
- [ ] 后端 `compileJava compileTestJava` 和目标测试通过；Flutter `gen-l10n analyze` 与 release web build 通过。
- [ ] README 更新项目级对账/导入操作说明。
- [ ] dev 部署后用真实 project 89 完成 dry-run、少量 wet-run、绑定追溯和首次 TB 拉取验证；test 部署等待用户通知。

## 7. 关键提醒

NS 在线、TB 有设备、本地有 binding 都不是业务闭环证据。验收必须按层输出：NS 清单、TB telemetry、本地 DTL、active installation、health/fence 消费条件。特别是无 active installation 时温度和胃动力会跳过，这不是 TB 通道故障。
