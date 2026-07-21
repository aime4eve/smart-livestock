# blade 平台环境映射设计（本项目 dev/test ↔ blade dev/test）

日期：2026-07-21
状态：已实施完成（dev ↔ blade dev、test ↔ blade test 换票均已打通）

## 背景与目标

blade 平台（第三方物联网平台，提供设备遥测采集与指令下发）自身有 dev / test 两套环境。本项目（smart-livestock-server）也有 dev / test 两套 docker-compose stack（见 `2026-07-01-dev-test-env-isolation-design.md`）。

**目标**：让两套环境一一对应——

| 本项目 stack | nginx 入口 | 对接 blade 环境 | blade 地址 |
|---|---|---|---|
| dev（`sl-dev`） | 19080 | blade dev | 172.21.2.41 |
| test（`smart-livestock-server`） | 18080 | blade test | 172.22.4.17 |

## 现状问题

- `application.yml`、`docker-compose.dev.yml`、`docker-compose.test.yml` 中 `agentic-platform.*` 的默认值**全部指向 blade test（172.22.4.17）**，dev stack 实际连的也是 blade test。
- 远程服务器上手动维护的 `.env`（test）/ `.env.dev`（dev）中未显式配置 blade 相关变量。

## blade 环境信息

Nacos 注册中心：172.22.3.16:8848，namespace `c47123d9-9d2b-4fdf-a61a-8d5daa9c89ac`。
本项目是 blade 的外部调用方，Feign 走 URL 直连模式，**不注册到 Nacos**，该信息仅作记录。

| 服务 | blade dev | blade test | 用途 |
|---|---|---|---|
| hkt-blade-auth | 172.21.2.41:8108 | 172.22.4.17:8108 | OAuth2 换票 `/oauth2/token` |
| hkt-blade-device | 172.21.2.41:8100 | 172.22.4.17:8100 | 设备 + 遥测 `/feign/v1/device/*` |
| hkt-blade-system | 172.21.2.41:8106 | 172.22.4.17:8106 | 用户管理 `/feign/v1/system/sdk/*` |

说明：

- 本项目代码只调用 blade-device（设备/遥测）与 blade-auth（换票）；**blade-system 不被代码调用**，仅在开通服务账号（`service-user-id`）时手工使用，不配入应用。
- license base-url 与 device base-url 相同（同一网关 8100）。

## 设计

### 配置分层原则

环境差异落在两处：

1. **git 内的默认值**：compose 文件的 `${VAR:-default}` 默认值按各自环境写死，保证"拿到代码直接 compose up 即连对应 blade 环境"。
2. **远程手动维护的 env 文件**（`.env` / `.env.dev`，rsync 排除、不进 git）：存放环境特定值与密钥（OAuth2 client-secret 等），优先级高于 compose 默认值。

### 变更点

#### 1. `docker-compose.dev.yml`（app 服务 environment）

```yaml
AGENTIC_PLATFORM_DEVICE_BASE_URL: ${AGENTIC_PLATFORM_DEVICE_BASE_URL:-http://172.21.2.41:8100}
AGENTIC_PLATFORM_LICENSE_BASE_URL: ${AGENTIC_PLATFORM_LICENSE_BASE_URL:-http://172.21.2.41:8100}
AGENTIC_PLATFORM_OAUTH2_TOKEN_URI: ${AGENTIC_PLATFORM_OAUTH2_TOKEN_URI:-http://172.21.2.41:8108/oauth2/token}
```

#### 2. `docker-compose.test.yml`（app 服务 environment）

保持 172.22.4.17 地址不变，补齐此前缺失的 token-uri 行：

```yaml
AGENTIC_PLATFORM_OAUTH2_TOKEN_URI: ${AGENTIC_PLATFORM_OAUTH2_TOKEN_URI:-http://172.22.4.17:8108/oauth2/token}
```

#### 3. `application.yml`

默认值保持不变（指向 blade test），本地开发 `AGENTIC_PLATFORM_OAUTH2_ENABLED` 默认 false，不连真实 blade，无需改动。

#### 4. `.env.example` / `.env.dev.example`

各自补充 blade 配置段（含环境地址对应关系注释），作为远程 env 文件的维护模板。

#### 5. 远程服务器 env 文件（172.22.1.123，手动维护）

- dev（`~/smart-livestock-server/.env.dev`）：blade 地址改为 172.21.2.41（8100 / 8108）。
- test（`~/smart-livestock-server/.env`）：确认 blade 地址为 172.22.4.17，缺失则补齐。

### 不变更项

- 不引入 Nacos 客户端 / 服务发现。
- 不新增 hkt-blade-system 的配置项（代码不调用）。
- Java 代码零改动，纯配置变更。

## 开放问题（已解决，2026-07-21）

- **blade dev / test 是两套完全独立的平台，账号体系不通用**。实测：现有凭据打 blade dev 换票返回 `30010901 用户名或密码错误`，打 blade test 成功。
- **根因**：OAuth2 client（`hkt_openapi` + secret）两平台相同，但服务账号 `service-user-id` 是各平台库内的用户，test 的 `2074385063398711296` 在 dev 不存在。
- **解决**：按 `business-platform/hkt-blade-device-docking/README.md` 记载的自助流程，在 blade dev 上创建了服务账号：
  1. `GET http://172.21.2.41:8108/code/public-key` 取 RSA 公钥
  2. RSA（PKCS1Padding）加密密码
  3. `POST http://172.21.2.41:8106/feign/v1/system/sdk/user/create` 创建用户（account=`sl_service`）
  4. `PUT .../user/{userId}/enable` 启用
  5. 换票验证通过

### 各环境服务账号（维护在远程 env 文件，不进 git）

| 环境 | blade 平台 | service-user-id | 说明 |
|---|---|---|---|
| dev | 172.21.2.41 | `2079382969422938112` | 2026-07-21 新建（sl_service） |
| test | 172.22.4.17 | `2074385063398711296` | 既有账号（SmartLivestock Service） |

client-id / client-secret / tenant-id（`hkt_openapi` / `000000`）两平台相同。

## 验证结果（2026-07-21）

1. ✅ YAML 语法校验通过；compose 默认值渲染正确（dev→172.21.2.41，test→172.22.4.17）。
2. ✅ `./scripts/deploy.sh dev` 部署成功，`sl-dev-app-1` 容器内 `AGENTIC_PLATFORM_*` 指向 172.21.2.41，日志 `agentic-platform.oauth2 ready`，同步调度器正常派发任务。
3. ✅ blade dev 端到端：`/oauth2/token` 换票成功（12h token），带 token 调 `/feign/v1/device/lifecycle/pageDevices` 返回 44 台设备。
4. ✅ test stack 的远程 `.env` 补齐 blade test 配置并启用 OAuth2/同步，应用重启后 `oauth2 ready`（token-uri=172.22.4.17:8108），换票 curl 验证通过。
