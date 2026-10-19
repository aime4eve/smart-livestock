# 租户开通操作指南(HOSTED 云端)

> 版本:v3.1(2026-10-19):首例南非租户(全程 UI 开通)实测修订——**密码策略对齐 8 位四类字符**、**建牧场必须落 OWNER 绑定**(`POST /api/v1/admin/farms` 代建不绑主,须由 B2B 管理员 UI 建场选主或 `PUT /api/v1/farms/{id}/owner` 补绑)、新增建号即验密与 §7 故障速查、海外客户登录区号提示;强制改密锁页面刷新后不再丢失(2026-10-19 修复并部署 dev/test)。
> 版本:v3.0(2026-10-14):全球登录标识(账号/手机号/邮箱)、租户/牧场时区、试点授权当地日期换算、全程 UI 操作路径;修正角色示例错误(FARM_ADMIN 从来不是有效枚举)
> 适用:为 HOSTED 云端客户开通独立租户。首例:肯尼亚客户;第二例:南非客户(2026-10-19)。
> 前置事实源:`docs/reference/deployment.md`(环境/凭据)、`docs/deployment/release-install-guide.md`(授权模式)。

---

## 1. 背景与原则

- 系统为 HOSTED 单实例共享库多租户架构:业务表按 `tenant_id` 行级隔离,租户之间数据互不可见;开通新租户**不需要任何架构改造或发版**。
- **开通全程可走管理端 UI**(租户管理→新建租户→详情页建用户/授予试点);本章 curl 为等价 API 路径,便于脚本化与排障。
- **设备采集与租户解耦(用户裁决 2026-10-12,已实现)**:设备 EUI 全球唯一(全局唯一索引),数据采集按 EUI 通过 TB/blade 通道进行、与平台租户无关;租户与设备 1:1 映射。
- **免费试点统一截止日(用户裁决 2026-10-12,已实现)**:所有免费试点/自助试用统一到期于 `smartlivestock.trial.ends-at`(默认 `2027-09-30T21:00:00Z` = 2027-10-01 00:00 肯尼亚 EAT);按租户另定截止日时传**当地日期**,服务端按该租户时区自动换算。
- **时区三级链(用户裁决 2026-10-12,已实现)**:牧场时区 → 租户时区 → 平台默认(`SMARTLIVESTOCK_DEFAULT_TIMEZONE`,未配置时客户端偏移兜底)。时间显示、按日统计、试点日期换算、Blade X-TimeZone 均走此链。**给海外客户开租户,建租户时选时区(如 Nairobi UTC+3)是关键一步。**
- **登录标识(2026-10-14 已实现)**:用户账号 / 手机号(E.164,即 WhatsApp 号)/ 邮箱,任一 + 密码;三项至少配置一项,各自全局唯一。用户名仅为显示昵称可重复。
- 开通模式为**平台管理员代建**(无自助注册端点),与销售口径"厂商小批量开通试用"一致。

## 2. 环境前提

| 项 | 要求 | 现状核对 |
|---|---|---|
| 授权模式 | `license.mode=HOSTED` | dev/test 默认 HOSTED(application.yml) |
| 试点授权开关 | `smartlivestock.pilot-license.enabled=true` | 默认开启 |
| 统一试点截止日 | `smartlivestock.trial.ends-at`(env `SMARTLIVESTOCK_TRIAL_ENDS_AT`) | 默认 `2027-09-30T21:00:00Z`;推广期结束后运维调整或清空(清空回退 365d/14d 滚动模式) |
| 平台默认时区(可选) | `smartlivestock.timezone.default`(env `SMARTLIVESTOCK_DEFAULT_TIMEZONE`) | 默认未配置(客户端偏移兜底);多租户运营建议配置 |
| 目标实例 | 对外服务须公网可达 | test:`livestock.hkttech.cn`;⚠️ 86 为内网验证机,对客户开放前须确认公网实例 |
| 操作账号 | 平台管理员(PLATFORM_ADMIN) | 凭据见 `docs/reference/deployment.md`,本文用 `$TOKEN` 占位 |

## 3. 开通前信息收集清单

向客户/销售收集(缺项再补可后置,不阻塞建租户):

- [ ] 租户名称（建议含客户标识，如 `Kenya-<公司/项目>`）
- [ ] 联系人与联系电话
- [ ] **客户所在时区**(建租户必选;如肯尼亚=Africa/Nairobi)
- [ ] 租户管理员**登录标识**:用户账号 / 手机号(国际格式,即 WhatsApp 号)/ 邮箱,**至少一项**(按客户习惯,海外用户常只给邮箱或 WhatsApp 号)
- [ ] 管理员姓名与显示用户名(可选)
- [ ] 首批设备 EUI 清单(16 位 hex)
- 试点截止日默认统一为平台配置值(2027-10-01 00:00 肯尼亚时间);客户单独约定截止日的,记当地日期即可(如 2027-10-01),**无需人工换算 UTC**。

## 4. 开通步骤(UI 路径 + 等价 curl)

以下 `$BASE` 为 API 基址(dev:`http://172.22.1.123:19080`;test:`https://livestock.hkttech.cn`)。
**UI 路径**:登录平台管理员 → 运营管理 → 租户管理,以下每步括注对应界面入口。

### S1. 平台管理员登录

(UI:登录页输入框支持手机号/邮箱/用户账号任一)

```bash
curl -sk -X POST "$BASE/api/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"identifier":"<账号/手机号/邮箱>","password":"<密码>"}'
# 取 data.accessToken → $TOKEN
```

### S2. 创建租户(选时区!)

(UI:租户管理→「新建租户」,表单含"所在时区"下拉)

```bash
curl -sk -X POST "$BASE/api/v1/admin/tenants" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"<租户名称>","contactName":"<联系人>","contactPhone":"<电话>","timezone":"Africa/Nairobi"}'
# 记录 data.id → $TENANT_ID;返回 utcOffsetMinutes=180 即时区生效
```

- timezone 为 IANA 名,非法值 400;留空=继承平台默认。后续可在租户详情页修改。

### S3. 创建租户管理员用户(登录标识至少一项)

(UI:租户详情→「新增用户」:账号/手机号/邮箱/用户名四字段,前端已做"至少一项"校验)

```bash
curl -sk -X POST "$BASE/api/v1/admin/users" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"<姓名>","account":"demo.admin","email":"admin@customer.example","role":"B2B_ADMIN","tenantId":"'"$TENANT_ID"'","password":"<初始密码>"}'
```

- **登录标识三选一以上**:`account`(3-32 位,字母开头)/`phone`(E.164,如 +254712345678)/`email`;`username` 为显示昵称(可重复,选填)。全空返回 400"至少填写一项"。
- **角色枚举**:`PLATFORM_ADMIN / B2B_ADMIN / OWNER / WORKER / API_CONSUMER`——租户侧管理员用 `B2B_ADMIN`(牧场主用户由客户自建时用 OWNER)。⚠️ 历史版本示例中的 `FARM_ADMIN` 从来不是有效值。
- 重复标识分别报"该用户账号/邮箱/手机号已被使用"。
- **密码规则(2026-10-15 起):≥8 位,且须同时包含大写字母、小写字母、数字和特殊符号**;弱密码 400"新密码至少 8 位,且须同时包含大写字母、小写字母、数字和特殊符号"。
- ⚠️ **UI 建号两个实操坑(2026-10-19 南非租户实测)**:①创建失败时对话框**立即关闭、全部字段需重填**,且密码框无确认框——**先在别处拟好合规初始密码再粘贴提交,争取一次成功**;②建完**立即用下方 curl 验密**,确认密码与记录一致(当日曾因弱密码被拒→重填后口径漂移,客户登录 401)。
- **首登强制改密(NIX-191,预期行为)**:新建账号 `must_change_password=true`,首次登录停在"设置新密码"页;改密前除 `/me`、`/me/password` 外全部接口 403 `PASSWORD_CHANGE_REQUIRED`。交付时把初始密码与"首登需改密"一并告知客户。

```bash
# 建号后立即验密(不要在管理员浏览器里用客户账号登 UI,见 §8):
curl -sk -X POST "$BASE/api/v1/auth/login" -H 'Content-Type: application/json' \
  -d '{"identifier":"<客户标识>","password":"<刚设的初始密码>"}'
# 200 且 data.user.mustChangePassword=true ⇒ 标识与密码均正确,可交付
# 401 ⇒ 密码与建号时不一致 → 管理员重置密码(§8),重置后须再次验密
```

### S4. 授予云端试点授权

(UI:租户详情→「授予试点授权」→ 日历选**当地日期**;留空=平台统一截止日)

```bash
# 方式一(推荐):当地日期,服务端按该租户时区自动换算当地 00:00
curl -sk -X POST "$BASE/api/v1/admin/tenants/$TENANT_ID/pilot-license" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"localDate":"2027-10-01"}'
# Nairobi 租户 → trialEndsAt=2027-09-30T21:00:00Z(当地零点),无需人工换算

# 方式二:不带参数=平台统一截止日(smartlivestock.trial.ends-at)
curl -sk -X POST "$BASE/api/v1/admin/tenants/$TENANT_ID/pilot-license" \
  -H "Authorization: Bearer $TOKEN"

# 方式三(兼容):直接传 UTC 时刻
# -d '{"trialEndsAt":"2027-09-30T21:00:00Z"}'
```

- 置为 `TRIAL`(有效档位=PREMIUM 全功能);审计 `PILOT_LICENSE_GRANT` 带 `deadlineSource`(REQUESTED_LOCAL_DATE / REQUESTED / CONFIGURED / ROLLING)。
- 截止日优先级:localDate > trialEndsAt > 平台默认 > 滚动 365d;已有更晚 TRIAL 重调即收敛;400 校验(格式错/过去时刻)。

### S5. 初始牧场(可选,带时区)——**必须落 OWNER 绑定!**

⚠️ **平台管理员代建端点 `POST /api/v1/admin/farms` 不绑定任何牧场主**(ownerId 硬编码为空)——用它建出来的牧场,OWNER 登录只会看到"暂无关联牧场"。两条正确路径二选一:

**路径 A(推荐,2026-10-19 南非租户实测,纯 UI)**:用 S3 建的 B2B_ADMIN 登录客户端 → 牧场管理 → 新建牧场(UI:客户管理员自建,建场表单含时区下拉),**表单里必须选择牧场主(OWNER)**;创建即写入 OWNER/ACTIVE 绑定。
等价 API(B2B_ADMIN token):`POST /api/v1/farms`,body 额外带 `"ownerId": <OWNER用户id>`。

**路径 B**:平台管理员已用 `/admin/farms` 代建(平台管理员 UI 建场同样不绑主)的,再补绑牧场主(B2B_ADMIN token,同租户校验;旧 OWNER 自动 DISABLED,新 OWNER 建/复活为 OWNER/ACTIVE):

```bash
curl -sk -X PUT "$BASE/api/v1/farms/$FARM_ID/owner" \
  -H "Authorization: Bearer $B2B_TOKEN" -H 'Content-Type: application/json' \
  -d '{"ownerId": 123}'
```

- 牧场时区是三级链最高优先级;不传则继承租户。地图图源随牧场时区自动切换(中国系→高德,其他→OSM)。
- **绑定核对(开通必查)**:

```sql
SELECT user_id, farm_id, role, status FROM user_farm_assignments
WHERE farm_id = $FARM_ID AND status = 'ACTIVE';  -- 必须有 OWNER 行
```

### S5b. 设备移交(EUI 已挂在其他租户时)

开通向导 Step1 Check Device 报"Device EUI xxx already belongs to another tenant"= 该 EUI 档案在别的租户(常见:早期测试挂在 Demo Ranch)。**2026-10-19 起系统提供平台管理员移交能力**(写审计),按优先级:

**方式一(推荐):管理端 UI** — 平台管理员登录 → 目标租户详情页(`/ops/admin/{tenantId}`)→「设备移交」卡片 → 输入 EUI → 查询设备(显示当前归属租户)→ 确认移交。后端强校验:活跃安装未拆除 → 409 拒绝(先解绑);已归属目标租户 → 409;审计事件 `DEVICE_TENANT_TRANSFERRED`。

**方式二(等价 API,便于脚本化)**:
```bash
# 查询当前归属
curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/api/v1/admin/devices/lookup?eui=<EUI>"
# 执行移交(PLATFORM_ADMIN token)
curl -sk -X POST "$BASE/api/v1/admin/devices/transfer" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"devEui":"<EUI>","targetTenantId":<目标租户id>}'
```

**方式三(兜底,仅旧版本环境)**:SQL 直改(无审计,用后建议补记):
```sql
UPDATE devices SET tenant_id = <目标租户id>, updated_at = now()
WHERE dev_eui IN ('<EUI...>') AND tenant_id = <原租户id> AND deleted_at IS NULL;
```

**移交后验证**:目标租户账号 `GET /api/v1/farms/{farmId}/devices/tb/preflight?eui=<EUI>` → `status=READY_TO_INGEST`(TB 侧有候选);客户继续向导 Step2/3 完成 provision 即建立 TB 绑定,遥测流入新租户。历史遥测行仍留原租户,不迁移。

## 5. 设备接入(EUI 1:1 归属)

原则:**采集按设备 EUI、与平台租户无关;归属按设备档案 `tenant_id`;一台设备只挂一个租户。**

- TB 通道轮询全部 RESOLVED 绑定(不按平台租户过滤),blade 通道按设备逐台同步——TB/NS 侧账号保持单一共享租户,新客户无需在 TB 开租户。
- 全局唯一索引 `uq_devices_eui_global`;EUI 已归属其他租户时报"设备 EUI 已归属其他租户"(转移为人工操作)。
- 建档三路径:NS/TB 预置流程(推荐,真实追踪器)/ 开放 API `POST /api/v1/open/devices/register`(API-Key→租户)/ 牧场侧 `POST /api/v1/farms/{farmId}/devices`。

```sql
-- 接入后核对:每个 EUI 恰 1 行且租户正确
SELECT dev_eui, device_code, tenant_id, status FROM devices
WHERE dev_eui IN ('<EUI1>','<EUI2>');
```

## 6. 开通验证清单(全绿才算完成)

| # | 验证项 | 方法 | 预期 |
|---|---|---|---|
| 1 | 建号验密(S3 完成后**立即**) | curl 登录(见 S3) | 200 + `mustChangePassword=true`;401=密码不一致,走 §8 重置 |
| 2 | 时区生效 | 租户详情/`GET /admin/tenants/$TENANT_ID` | timezone 正确,utcOffsetMinutes 匹配 |
| 3 | 订阅状态 | `GET /api/v1/admin/subscriptions`(注意:该接口 tenantId 过滤暂不生效,按返回列表核对目标租户行) | `status=trial`,trial_ends_at=约定时刻,effectiveTier=PREMIUM |
| 4 | OWNER-牧场绑定(S5 后立即) | §5 绑定核对 SQL + OWNER 登录抽查 | ACTIVE OWNER 行;OWNER 登录可见牧场(不再"暂无关联牧场") |
| 5 | 首登强制改密走通 | 客户首登或抽查 | 改密页设置新密码后进入系统 |
| 6 | 数据隔离 | 租户管理员任一业务列表 | 仅见本租户数据 |
| 7 | 既有租户回归 | 任一既有账号登录抽查 | 不受影响 |
| 8 | 审计留痕 | audit_logs 按 tenant_id 查 | 有 PILOT_LICENSE_GRANT(deadlineSource 正确) |
| 9 | 设备归属(有设备时) | 第 5 节 SQL + TB 日志 `polling N bound device(s)` | EUI 唯一且租户正确,数据流入 |

辅助:管理端用户列表"最近登录"自 2026-10-19 起可用(`last_login_at` 修复落库),可核对客户是否真实登录过。

## 7. 故障速查(2026-10-19 增,来源:南非租户开通实录)

| 症状 | 原因 | 处置 |
|---|---|---|
| 登录 401「账号/手机号/邮箱或密码错误」 | 标识不存在或密码不符(文案刻意泛化防探号) | 核对标识格式(邮箱原样/手机号带区号/账号原样);仍失败→§8 重置密码 |
| 登录后全部功能 403「请先修改初始密码后再使用系统」 | `must_change_password` 未改(NIX-191 预期行为,非故障) | 在改密页设置新密码即解除 |
| OWNER 登录显示"暂无关联牧场" | 牧场未建,或建场时未绑 OWNER(代建端点不绑主) | §5 绑定核对;缺→`PUT /farms/{id}/owner` |
| 建用户 400「新密码至少 8 位…」 | 初始密码不符 2026-10-15 策略 | 换合规密码;UI 失败会关窗,注意重填全部字段 |
| 403「租户已禁用/已删除」 | 租户生命周期门禁 | 租户管理页核查租户状态 |
| 海外客户手机号登录失败 | 登录页区号按本机时区猜测,**无 UTC+2 条目,南非会默认 +254**(中国 +86) | 让客户**优先用邮箱**登录;用手机号须手动选对区号(本地格式自动去前导 0 拼区号) |

## 8. 安全注意

- 平台管理员权限跨租户,操作后登出;确认客户**首登强制改密**已走完;对外实例必须轮换公开种子凭据(见 `docs/reference/deployment.md`)。
- `<占位符>` 凭据不得写入交付物/聊天记录。
- **验证客户账号密码一律用 curl**(200 + `mustChangePassword=true` 即正确),不要在管理员浏览器里用客户账号登录 UI——会停在改密页并残留客户会话。
- 客户自助修改登录标识走"我的→编辑资料"(改登录标识需验当前密码,留审计)。
- **管理员重置密码=找回通道**:`POST /api/v1/admin/users/{userId}/reset-password`,body `{"newPassword":"<合规新密码>"}`(同一密码策略)。**重置后 `must_change_password` 重新点亮**(NIX-191:重置=他人设的凭据),客户下一次登录仍会被要求设置自己的新密码——把这一点连同新密码一并告知。(验证码/邮件验证为后续外部服务依赖)

## 附录 A:端点速查

| 端点 | 用途 | 权限 |
|---|---|---|
| `POST /api/v1/auth/login` | 登录(identifier=账号/手机/邮箱) | 公开 |
| `GET/POST /api/v1/admin/tenants` | 租户列表/创建(含 timezone) | PLATFORM_ADMIN |
| `GET/PUT /api/v1/admin/tenants/{id}` | 详情/更新(可改 timezone) | PLATFORM_ADMIN |
| `POST /api/v1/admin/tenants/{id}/pilot-license` | 试点授权(localDate/trialEndsAt 可选) | PLATFORM_ADMIN + HOSTED + 开关 |
| `POST /api/v1/admin/users` | 建用户(account/phone/email/username) | PLATFORM_ADMIN |
| `POST /api/v1/admin/users/{userId}/reset-password` | 管理员重置密码(重置后重新要求首登改密) | PLATFORM_ADMIN |
| `GET /api/v1/admin/devices/lookup?eui=` | 查询 EUI 当前归属(移交前置) | PLATFORM_ADMIN |
| `POST /api/v1/admin/devices/transfer` | 设备移交目标租户(审计 DEVICE_TENANT_TRANSFERRED) | PLATFORM_ADMIN |
| `PUT /api/v1/me` | 本人编辑资料(登录标识变更需 currentPassword) | 登录用户 |
| `POST /api/v1/farms` | 建牧场(body 含 ownerId=选牧场主) | 租户用户(B2B_ADMIN/OWNER) |
| `PUT /api/v1/farms/{farmId}/owner` | 指定/变更牧场主(写 OWNER 绑定) | 租户用户(B2B_ADMIN) |
| `POST /api/v1/open/devices/register` | 开放 API 设备建档 | 租户 API-Key |
| `POST /api/v1/farms/{farmId}/devices` | 牧场侧建设备 | 租户用户 |

## 附录 B:关键配置速查

| 配置项 | 当前值 |
|---|---|
| `smartlivestock.trial.ends-at`(env `SMARTLIVESTOCK_TRIAL_ENDS_AT`) | `2027-09-30T21:00:00Z`(=2027-10-01 00:00 肯尼亚 EAT) |
| `smartlivestock.timezone.default`(env `SMARTLIVESTOCK_DEFAULT_TIMEZONE`) | 未配置(可选;配置后为三级链末端默认) |
| 推广期结束 | 改 env 换截止日/时区,或置空回退 |

## 附录 C:开通实例登记

```
租户名称:       ____________(建议 <国家/地区>-<客户/项目标识>)
联系人/电话:     ____________
客户时区:       ____________(建租户/牧场时选择;南非=Africa/Johannesburg)
管理员登录标识:  账号________ / 手机(WhatsApp)________ / 邮箱________(至少一项)
管理员姓名/用户名:__________ / __________(用户名选填)
试点截止:       默认统一值;单独约定则填当地日期 ______
设备 EUI 清单:   ____________
开通执行人/日期: ____________ / ____________
```

已开通实例:肯尼亚客户(2026-10,首例,产出本指南);南非客户「南非-市场」(2026-10-19,test,Africa/Johannesburg,首例全程 UI 开通,本版修订来源)。
