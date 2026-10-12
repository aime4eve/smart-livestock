# 租户开通操作指南(HOSTED 云端)

> 版本:v2.0(2026-10-12)
> 适用:为 HOSTED 云端客户开通独立租户。首个应用案例:肯尼亚客户。
> 前置事实源:`docs/reference/deployment.md`(环境/凭据)、`docs/deployment/release-install-guide.md`(授权模式)。

---

## 1. 背景与原则

- 系统为 HOSTED 单实例共享库多租户架构:业务表按 `tenant_id` 行级隔离,租户之间数据互不可见;开通新租户**不需要任何架构改造或发版**,全程走管理端 API。
- **设备采集与租户解耦(用户裁决 2026-10-12,已实现)**:设备 EUI 全球唯一(V20261012100000 全局唯一索引),数据采集按 EUI 通过 TB/blade 通道进行、与平台租户无关;租户与设备 1:1 映射,租户只能查看和使用与其关联设备的数据。
- **免费试点统一截止日(用户裁决 2026-10-12,已实现)**:所有免费试点/自助试用统一到期于配置项 `smartlivestock.trial.ends-at`(application.yml 默认 `2027-09-30T21:00:00Z` = 2027-10-01 00:00 肯尼亚 EAT)。到期由 `CommerceScheduler` 小时任务统一降级 FREE/BASIC,数据保留。
- 开通模式为**平台管理员代建**(无自助注册端点),与销售口径"厂商小批量开通试用"一致。

## 2. 环境前提

| 项 | 要求 | 现状核对 |
|---|---|---|
| 授权模式 | `license.mode=HOSTED`(该模式无主机绑定,试点授权为租户级 DB 记录) | test 环境默认即为 HOSTED(application.yml:186) |
| 试点授权开关 | `smartlivestock.pilot-license.enabled=true` | test 默认开启(application.yml:193) |
| 统一试点截止日 | `smartlivestock.trial.ends-at`(env `SMARTLIVESTOCK_TRIAL_ENDS_AT`) | 默认 `2027-09-30T21:00:00Z`;推广期结束后由运维统一调整或清空(清空回退 365d/14d 滚动模式) |
| 目标实例 | 对外服务须公网可达 | test:`livestock.hkttech.cn`(nginx→18080);⚠️ 86 HOSTED 为内网验证机(172.17.10.86),对客户开放前须确认公网可达实例 |
| 操作账号 | 平台管理员(PLATFORM_ADMIN 角色) | 凭据见 `docs/reference/deployment.md`,本文一律用 `$TOKEN` 占位 |

## 3. 开通前信息收集清单

向客户/销售收集,缺一项则暂停开通:

- [ ] 租户名称(建议含客户标识,如 `Kenya-Demo` / 客户公司名)
- [ ] 联系人与联系电话
- [ ] 租户管理员手机号(全局唯一,作为登录账号;密码规则 ≥10 位含字母数字)
- [ ] 首批设备 EUI 清单(16 位 hex,用于设备建档与 1:1 归属核对)
- 试点截止日不再按租户收集——所有租户统一为 `smartlivestock.trial.ends-at` 配置值(当前=2027-10-01 00:00 肯尼亚时间)。

## 4. 开通步骤

以下 `$BASE` 为 API 基址(test:`https://livestock.hkttech.cn` 或内网 `http://172.22.1.123:18080`)。

### S1. 平台管理员登录,取 token

```bash
curl -sk -X POST "$BASE/api/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"phone":"<平台管理员手机号>","password":"<密码>"}'
# 取 data.accessToken → $TOKEN;如返回 mustChangePassword=true,先 PUT /api/v1/me/password 改密后重登
```

### S2. 创建租户

```bash
curl -sk -X POST "$BASE/api/v1/admin/tenants" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"<租户名称>","contactName":"<联系人>","contactPhone":"<联系电话>"}'
# 记录返回的租户 id → $TENANT_ID
```

### S3. 创建租户管理员用户

```bash
curl -sk -X POST "$BASE/api/v1/admin/users" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"phone":"<管理员手机号>","name":"<姓名>","role":"FARM_ADMIN","tenantId":"'"$TENANT_ID"'","password":"<初始密码>"}'
```

- 手机号全局唯一,重复返回 `DUPLICATE_RESOURCE`。
- 角色取值见用户管理模块(牧场管理员用 `FARM_ADMIN`);不传 `password` 则为默认值,正式交付必须显式设置强密码。

### S4. 授予云端试点授权(统一截止日)

```bash
curl -sk -X POST "$BASE/api/v1/admin/tenants/$TENANT_ID/pilot-license" \
  -H "Authorization: Bearer $TOKEN"
# 返回 {"tenantId":..,"status":"TRIAL","trialEndsAt":"2027-09-30T21:00:00Z"}
```

- 该端点把订阅置为 `TRIAL`(有效能力档位 = PREMIUM 全功能,即"免费到统一截止日"),并写审计日志(`PILOT_LICENSE_GRANT`)。
- **到期时间 = `smartlivestock.trial.ends-at` 配置值,全平台统一**;若该租户已有更晚的 TRIAL,重调本端点会收敛回统一截止日。
- 不再需要任何 SQL 校准(v1.0 的 S5 步骤已随统一截止日实现废止)。
- 授权/拒绝均落 `audit_logs`,事后可追溯。
- 存量收敛:改造前按旧 365 天规则授予的 TRIAL 租户,重调一次本端点即对齐统一截止日。

### S5. 初始牧场(可选)

租户管理员登录 App 后可自建牧场;如需平台代建:

```bash
curl -sk -X POST "$BASE/api/v1/admin/farms" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"tenantId":"'"$TENANT_ID"'","name":"<牧场名>","latitude":..,"longitude":..,"areaHectares":..}'
```

## 5. 设备接入(EUI 1:1 归属)

原则:**采集按设备 EUI、与平台租户无关;归属按设备档案的 `tenant_id`;一台设备自始至终只挂一个租户。**(2026-10-12 已实现)

- **采集通道**:TB 通道轮询全部 RESOLVED 绑定(不再按平台租户过滤),blade 通道按设备逐台同步——两条通道均与租户无关,TB/NS 侧账号保持单一共享租户,无需为新客户在 TB 开租户。
- **唯一性保障**:库级全局唯一索引 `uq_devices_eui_global(dev_eui)`(含软删行);建档三入口(租户注册/开放 API/NS·TB·DeviceHub 预置)均有跨租户占用预检,EUI 已归属其他租户时报 `设备 EUI {0} 已归属其他租户`——跨租户转移是人工操作,不能靠重新注册完成。

设备建档到租户的三条路径(任选):

1. **NS/TB 预置流程(推荐,真实追踪器)**:治理/设备管理界面按 EUI 匹配 NS/TB 候选 → 建设备档案(归属=操作时选定租户)→ 建 `tb_device_bindings`。
2. **租户自助(开放 API)**:`POST /api/v1/open/devices/register`,凭租户绑定的 API-Key 鉴权(api_key→tenantId),设备进入该租户 INVENTORY。
3. **牧场侧端点**:`POST /api/v1/farms/{farmId}/devices`(farm-scoped,租户用户自建)。

接入后核对(防挂错租户):

```sql
SELECT dev_eui, device_code, tenant_id, status FROM devices
WHERE dev_eui IN ('<EUI1>','<EUI2>');
-- 每个 EUI 必须恰好 1 行(含软删),且 tenant_id 为目标租户
```

## 6. 开通验证清单(全绿才算完成)

| # | 验证项 | 方法 | 预期 |
|---|---|---|---|
| 1 | 租户管理员登录 | `POST /api/v1/auth/login`(管理员手机号) | 200 + accessToken |
| 2 | 订阅状态 | `GET /api/v1/admin/subscriptions?tenantId=$TENANT_ID` | `status=trial`,`trial_ends_at`=统一截止日(2027-09-30T21:00:00Z),`effectiveTier=PREMIUM` |
| 3 | 数据隔离 | 租户管理员调任一业务列表(如牧场/牲畜) | 仅见本租户数据;Demo Ranch 等既有租户数据不可见 |
| 4 | 既有租户回归 | 任一既有租户账号登录抽查 | 不受影响 |
| 5 | 审计留痕 | `SELECT * FROM audit_logs WHERE tenant_id=$TENANT_ID ORDER BY created_at DESC` | 有 `PILOT_LICENSE_GRANT` |
| 6 | 设备归属(有设备时) | 第 5 节核对 SQL + TB 轮询日志(`polling N bound device(s)`) | 每 EUI 恰 1 行、租户正确;新租户设备绑定后一个轮询周期内数据流入 |

## 7. 安全注意

- 平台管理员账号权限跨租户,操作后登出;对外交付前确认租户管理员**首次登录强制改密**已走完,禁用任何公开种子凭据(test 库存有公开种子账号,对外实例必须轮换,见 `docs/reference/deployment.md`)。
- 本文所有 `<占位符>` 凭据不得写入任何交付物/聊天记录;真实密码只在执行时使用。

## 附录 A:端点速查

| 端点 | 用途 | 权限 |
|---|---|---|
| `POST /api/v1/auth/login` | 登录 | 公开 |
| `GET/POST /api/v1/admin/tenants` | 租户列表/创建 | PLATFORM_ADMIN |
| `GET/PUT /api/v1/admin/tenants/{id}` | 租户详情/更新 | PLATFORM_ADMIN |
| `PUT /api/v1/admin/tenants/{id}/status` | 启用/停用(注:当前为接口占位,状态字段未落库) | PLATFORM_ADMIN |
| `PUT /api/v1/admin/tenants/{id}/phase` | sample↔batch 切换 | PLATFORM_ADMIN |
| `POST /api/v1/admin/tenants/{id}/pilot-license` | 授予/对齐统一截止日试点 | PLATFORM_ADMIN + HOSTED + 开关 |
| `POST /api/v1/admin/users` | 建用户(带 tenantId/role) | PLATFORM_ADMIN |
| `POST /api/v1/admin/farms` | 代建牧场 | PLATFORM_ADMIN |
| `POST /api/v1/open/devices/register` | 开放 API 设备建档(API-Key→租户) | 租户 API-Key |
| `POST /api/v1/farms/{farmId}/devices` | 牧场侧建设备 | 租户用户 |

## 附录 B:统一试点截止日速查

| 配置项 | 值 |
|---|---|
| `smartlivestock.trial.ends-at`(application.yml 默认 / env `SMARTLIVESTOCK_TRIAL_ENDS_AT`) | `2027-09-30T21:00:00Z` |
| 对客户表述(肯尼亚 EAT=UTC+3,无夏令时) | 2027-10-01 00:00:00 当地时间 |
| 推广期结束后 | 运维改 env 换新截止日,或置空回退滚动模式(pilot now+365d / 自助 now+14d) |

## 附录 C:本指南首例参数(肯尼亚客户,开通时填写)

```
租户名称:      ____________(建议 Kenya-<客户/项目标识>)
联系人/电话:    ____________
管理员手机号:   ____________
试点截止:      统一配置值 2027-10-01 00:00 肯尼亚时间(2027-09-30T21:00:00Z)
设备 EUI 清单:  ____________
开通执行人/日期: ____________ / ____________
```
