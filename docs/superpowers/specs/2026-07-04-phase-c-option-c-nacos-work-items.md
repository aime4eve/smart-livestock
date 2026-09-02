# Phase C 方案 C：Feign + Nacos 微服务模式工作任务清单

**Date**: 2026-07-04
**Status**: 草案
**对照**: `2026-07-04-phase-c-feign-url-approach.md` — 方案 B（Feign + url），`2026-07-03-phase-c-blade-device-integration-design.md` — 方案 A（纯 HttpClient）

---

## 0. 方案 C 的核心变化

smart-livestock-server 从独立 Spring Boot 应用 → Spring Cloud 微服务节点：

```
改造前：                          改造后：
┌─────────────────────┐         ┌─────────────────────────┐
│ smart-livestock     │         │ smart-livestock          │
│ Boot 3.3 独立应用    │   →     │ Boot 3.3 + Cloud 2024   │
│ 无 Nacos/Feign      │         │ Nacos Discovery + Config │
│ 直连 DB/Redis/RMQ   │         │ Feign 服务发现调 blade    │
│ Docker Compose 启   │         │ 需 Nacos 集群连通         │
└─────────────────────┘         └─────────────────────────┘
```

---

## 1. 基础设施与依赖（smart-livestock 团队）

### 1.1 Gradle 依赖体系改造

| # | 任务 | 详细内容 | 风险 |
|---|------|----------|------|
| 1.1.1 | 引入 Spring Cloud BOM | `spring-cloud-dependencies:2024.0.x`（匹配 Boot 3.3.x） | 版本不匹配会导致编译失败 |
| 1.1.2 | 引入 Spring Cloud Alibaba BOM | `spring-cloud-alibaba-dependencies:2023.0.1.x`（匹配 Cloud 2024.0.x） | Alibaba 版本滞后 Cloud 一个世代 |
| 1.1.3 | 添加 Nacos Discovery | `spring-cloud-starter-alibaba-nacos-discovery` | — |
| 1.1.4 | 添加 Nacos Config | `spring-cloud-starter-alibaba-nacos-config` | — |
| 1.1.5 | 添加 OpenFeign | `spring-cloud-starter-openfeign` | — |
| 1.1.6 | 添加 LoadBalancer | `spring-cloud-starter-loadbalancer`（Feign 传递依赖，显式声明） | — |
| 1.1.7 | 依赖冲突解决 | 检查与现有 `spring-boot-starter-data-redis`、`rocketmq-spring-boot-starter` 的兼容性 | RocketMQ starter 可能与 Cloud 有传递依赖冲突 |

**关键决策**：smart-livestock-server 当前是 Spring Boot 3.3.0，对应的 Spring Cloud 版本是 **2024.0.x**（不是 open-platform-dev 的 2025.0.0，那个需要 Boot 3.5.x）。这意味着：
- 不能直接从 open-platform-dev 复制 pom.xml
- 如果 blade 要求 Cloud 版本对齐，可能需要升级 Boot → 3.5.x（额外风险）

### 1.2 启动类改造

| # | 任务 | 详细内容 |
|---|------|----------|
| 1.2.1 | 添加 `@EnableFeignClients` | 指定 Feign 接口扫描包路径 |
| 1.2.2 | 添加 `@EnableDiscoveryClient` | 启用 Nacos 服务注册（可选，新版 Spring Cloud 自动配置） |

### 1.3 bootstrap.yml 创建

smart-livestock-server 当前**没有 bootstrap.yml**（只有 `application.yml` + `application-test.yml`）。Spring Cloud 需要 bootstrap.yml 在 application.yml **之前**加载，用于连接 Nacos。

```yaml
# 新文件：src/main/resources/bootstrap.yml
spring:
  application:
    name: smart-livestock-server
  cloud:
    nacos:
      discovery:
        server-addr: ${NACOS_SERVER_ADDR:172.22.3.16:8848}
        namespace: ${NACOS_NAMESPACE:}         # 需要 blade 团队提供
        group: DEFAULT_GROUP
        username: ${NACOS_USERNAME:nacos}
        password: ${NACOS_PASSWORD:}
      config:
        server-addr: ${NACOS_SERVER_ADDR:172.22.3.16:8848}
        namespace: ${NACOS_NAMESPACE:}
        group: DEFAULT_GROUP
        username: ${NACOS_USERNAME:nacos}
        password: ${NACOS_PASSWORD:}
        file-extension: yml
```

### 1.4 Nacos 配置迁移

| # | 任务 | 详细内容 |
|---|------|----------|
| 1.4.1 | 分析现有配置 | 哪些放 Nacos（动态配置），哪些留 application.yml（静态配置） |
| 1.4.2 | blade 相关配配置放 Nacos | `blade.oauth2.*`、`blade.device.base-url`（可在 Nacos 动态刷新） |
| 1.4.3 | 数据库/Redis/RocketMQ 保留本地 | 基础连接信息不适合放远程配置中心（启动依赖） |
| 1.4.4 | 创建 Nacos 配置文件 | `smart-livestock-server.yml` → Nacos 控制台上传 |
| 1.4.5 | 添加 `@RefreshScope` | 需要动态刷新的 Bean 上加注解 |
| 1.4.6 | 配置 `spring.config.import` | `optional:nacos:smart-livestock-server.yml?group=DEFAULT_GROUP&refreshEnabled=true` |

---

## 2. Feign 客户端开发（smart-livestock 团队）

方案 C 的 Feign 客户端使用 **服务发现模式**（`name` 而非 `url`）：

```java
// 方案 C：服务发现
@FeignClient(
    name = "hkt-blade-device",              // Nacos 服务名
    configuration = BladeFeignConfig.class,
    fallbackFactory = BladeDeviceServiceFallback.class
)

// 对比方案 B：url 直连
@FeignClient(
    name = "blade-device-lifecycle",
    url = "${blade.device.base-url}",        // 硬编码 URL
    configuration = BladeFeignConfig.class,
    fallbackFactory = BladeDeviceServiceFallback.class
)
```

### 2.1 Feign 接口定义

| # | 任务 | 文件 | 来源 |
|---|------|------|------|
| 2.1.1 | BladeLicenseClient | `GET /feign/v1/device-license/control/by-sn` | 复制 open-platform-dev |
| 2.1.2 | BladeDeviceServiceClient | 7 个端点（注册/分页/详情/遥测/更新/删除） | 复制 open-platform-dev `DeviceServiceClient` |
| 2.1.3 | BladeHistoryDataClient | 2 个端点（父设备/子设备历史分页） | 复制 open-platform-dev `DeviceHistoryDataClient` |

### 2.2 Feign 配置

| # | 任务 | 文件 | 说明 |
|---|------|------|------|
| 2.2.1 | BladeFeignConfig | 配置 Logger.Level + Token 拦截器 | 新增 |
| 2.2.2 | BladeTokenProvider | 用固定 service account 换票 | 新增（简化版 InternalTokenProvider） |
| 2.2.3 | OpenApiGatewayTokenService | OAuth2 换票 + 缓存 | **完整复制** open-platform-dev |
| 2.2.4 | OpenApiOAuth2Properties | OAuth2 配置属性 | **完整复制** open-platform-dev |
| 2.2.5 | OpenApiOAuth2RestConfig | RestTemplate Bean | **完整复制** open-platform-dev |

### 2.3 DTO（从 open-platform-dev 复制）

| # | 文件 | 说明 |
|---|------|------|
| 2.3.1 | `InternalResponse.java` | 通用响应包络 |
| 2.3.2 | `LicenseStatusResp.java` | License 响应 |
| 2.3.3 | `DeviceRegistrationReq.java` + `DeviceRegistrationResp.java` | 注册 |
| 2.3.4 | `DeviceDetailReq.java` + `DeviceDetailResp.java` | 设备详情 |
| 2.3.5 | `DeviceTelemetryResp.java` | 遥测（含内嵌 DTO `TelemetryPropertyDto`、`SubDeviceTelemetryResp`） |
| 2.3.6 | `DevicePageReq.java` + `DevicePageResp.java` | 分页查询 |
| 2.3.7 | `DeviceUpdateReq.java` + `DeviceRemoveReq.java` | 更新/删除 |
| 2.3.8 | `DeviceHistoryDataPageReq.java` + `DeviceHistoryDataPageResp.java` | 历史数据 |
| 2.3.9 | `LoginUser.java` | blade 内部用户对象 |

### 2.4 Fallback 工厂

| # | 文件 | 说明 |
|---|------|------|
| 2.4.1 | `BladeLicenseFallback.java` | License 查询失败 → 抛业务异常 |
| 2.4.2 | `BladeDeviceServiceFallback.java` | 设备服务失败 → 注册类抛异常，查询类返回空 |
| 2.4.3 | `BladeHistoryDataFallback.java` | 历史数据失败 → 返回空分页 |

---

## 3. Nacos 服务注册（smart-livestock 团队 + blade 团队配合）

### 3.1 smart-livestock 侧

| # | 任务 | 详细内容 |
|---|------|----------|
| 3.1.1 | 服务名确定 | `spring.application.name: smart-livestock-server` |
| 3.1.2 | 健康检查 | 确保 `/actuator/health` 返回正确状态（可能需要添加 actuator 依赖） |
| 3.1.3 | 服务实例元数据 | version、region 等（可选） |
| 3.1.4 | 分组策略 | 是否与 blade 在同一 Nacos group（`DEFAULT_GROUP`） |

### 3.2 blade 团队配合

| # | 任务 | 说明 |
|---|------|------|
| 3.2.1 | 提供 Nacos 连接信息 | server-addr、namespace、认证凭据 |
| 3.2.2 | 确认服务命名规范 | smart-livestock 的服务名是否与现有规范一致 |
| 3.2.3 | 开放网络 | smart-livestock-server → Nacos 的网络访问 |

---

## 4. OAuth2 服务账号（blade 团队 + smart-livestock 团队）

### 4.1 blade 团队

| # | 任务 | 说明 |
|---|------|------|
| 4.1.1 | 创建 service account | 为 smart-livestock-server 注册 OAuth2 客户端 |
| 4.1.2 | 分配权限 | 授权调用 License 查询、设备注册、历史数据等 Feign 端点 |
| 4.1.3 | 交付凭据 | `client_id` + `client_secret` + `token-uri` |
| 4.1.4 | 确认认证规范 | token header 名（`token` vs `Authorization: Bearer`） |

### 4.2 smart-livestock 团队

| # | 任务 | 说明 |
|---|------|------|
| 4.2.1 | 配置 OAuth2 | `blade.oauth2.client-id/client-secret/token-uri`（建议放 Nacos） |
| 4.2.2 | 验证换票 | 启动后调用 `BladeTokenProvider.getToken()` 确认可获取 token |

---

## 5. 业务逻辑改造（smart-livestock 团队）

与方案 A/B 相同：

| # | 任务 | 说明 |
|---|------|------|
| 5.1 | Device 模型新增字段 | `bladeDeviceId`、`rssi`、`snr`、`sf`、`lastGateway` |
| 5.2 | DeviceJpaEntity 新增字段映射 | 同上 |
| 5.3 | SpringDataDeviceRepository 新增查询 | `findByBladeDeviceId()` |
| 5.4 | DeviceApplicationService 注册流程改造 | 查 License → blade 注册 → 本地同步 |
| 5.5 | TelemetryWebhookController（新增） | blade webhook 推送接收端点 |
| 5.6 | DeviceDto + DeviceMapper 更新 | 新字段透出 |
| 5.7 | Flyway 迁移 | devices 表加字段 + 索引 |
| 5.8 | ErrorCode + i18n | blade 相关错误消息 |

---

## 6. 部署基础设施变更（smart-livestock 团队）

### 6.1 Docker Compose 变更

| # | 任务 | 详细内容 |
|---|------|----------|
| 6.1.1 | docker-compose.dev.yml 新增 Nacos 容器 | 本地开发需要 Nacos 独立部署或连接测试环境 Nacos |
| 6.1.2 | app 容器环境变量 | 新增 `NACOS_SERVER_ADDR`、`NACOS_NAMESPACE`、`NACOS_USERNAME`、`NACOS_PASSWORD` |
| 6.1.3 | app 容器依赖 | 新增强依赖：Nacos 必须先启动（或 `depends_on` 条件为 `service_healthy`） |
| 6.1.4 | docker-compose.test.yml 同步 | 测试环境同样需要 Nacos 连接 |
| 6.1.5 | .env.dev 变量 | 新增 Nacos 相关环境变量 |

### 6.2 Dockerfile

Dockerfile **不需要变更**（不改变 JRE 或启动命令），但启动参数可能需要加 Nacos 连接超时等 JVM 参数。

### 6.3 生产部署

| # | 任务 | 说明 |
|---|------|------|
| 6.3.1 | 确保 Nacos 内网可达 | smart-livestock-server 的生产容器需要访问 Nacos 集群 |
| 6.3.2 | 网络策略 | 安全组 / 防火墙开放 smart-livestock-server → Nacos 的端口 |
| 6.3.3 | 启动顺序 | Nacos → DB/Redis/RMQ → smart-livestock-server |
| 6.3.4 | 健康检查 | Nacos 健康检查端点 + smart-livestock actuator health |

---

## 7. 测试适配（smart-livestock 团队）

### 7.1 单元测试

| # | 任务 | 说明 |
|---|------|------|
| 7.1.1 | Feign 接口 Mock | Feign 是接口，单元测试直接 Mock 即可，不需要 Nacos |
| 7.1.2 | BladeTokenProvider Mock | 测试时不调用真实 OAuth2 |

### 7.2 集成测试

| # | 任务 | 说明 |
|---|------|------|
| 7.2.1 | Nacos 依赖处理 | `@SpringBootTest` 默认会尝试连接 Nacos——需要一个 **test profile** 关闭 Nacos |
| 7.2.2 | application-test.yml 更新 | `spring.cloud.nacos.discovery.enabled: false` + `spring.cloud.nacos.config.enabled: false` |
| 7.2.3 | Testcontainers Nacos | 可选：用 `testcontainers` 启动 Nacos 容器做真实集成测试 |
| 7.2.4 | CI 环境 | CI 管道默认走 test profile，跳过 Nacos |

### 7.3 现有测试影响

| # | 任务 | 说明 |
|---|------|------|
| 7.3.1 | 53 个现有测试类回归 | 确保加 Spring Cloud 依赖后现有测试全部通过 |
| 7.3.2 | 启动时间增加 | Nacos 连接初始化会增加启动时间，需评估 CI 超时设置 |

---

## 8. 可观测性（可选，但推荐）

| # | 任务 | 说明 |
|---|------|------|
| 8.1 | Feign 调用日志 | 通过 `logging.level` 开启 Feign DEBUG 日志 |
| 8.2 | Nacos 健康指标 | 暴露 `/actuator/health` 中的 Nacos 组件状态 |
| 8.3 | Feign Metrics | `spring-cloud-starter-loadbalancer` 自带指标，接入 Micrometer |
| 8.4 | SkyWalking（如果 blade 在用） | 添加 SkyWalking agent，接入 blade 的链路追踪 |

---

## 9. 任务汇总与工时估算

### 9.1 按团队汇总

| 分类 | smart-livestock 团队 | blade 团队 |
|------|------|------|
| **基础设施** | Gradle 依赖 + bootstrap.yml + Nacos 配置（6 项） | 提供 Nacos 连接信息（3 项） |
| **Feign 开发** | 3 个 Feign 接口 + 配置 + DTO + Fallback（~18 个文件） | 已有 API（无需开发） |
| **服务注册** | 服务名 + 健康检查（3 项） | 确认命名 + 开放网络（3 项） |
| **OAuth2** | 配置 + 验证（2 项） | 创建 service account + 交付凭据（4 项） |
| **业务逻辑** | Device 模型 + 注册 + Webhook + Flyway + i18n（8 项） | Webhook 引擎开发（参考方案 A/B 文档） |
| **部署** | Docker Compose + .env + 生产配置（5 项） | — |
| **测试** | 单元 + 集成 + CI + 回归（5 项） | — |
| **可观测** | 日志 + 健康检查 + metrics（4 项可选） | — |

### 9.2 工时估算

| 阶段 | smart-livestock | blade | 说明 |
|------|------|------|------|
| 1. 基础设施 | 2-3 天 | 0.5 天 | Gradle + bootstrap + Nacos 配置迁移 |
| 2. Feign 开发 | 1-2 天 | 0 | 主要是复制 + 适配 |
| 3. Nacos 注册 | 0.5 天 | 0.5 天 | 联调注册、健康检查 |
| 4. OAuth2 对接 | 0.5 天 | 0.5 天 | 创建账号 + 配置验证 |
| 5. 业务逻辑 | 2-3 天 | 2-3 天 | Device 改造 + Webhook（与方案 A/B 相同） |
| 6. 部署适配 | 1 天 | 0 | Docker Compose + 生产变量 |
| 7. 测试适配 | 1-2 天 | 0 | CI profile + 回归 |
| 8. 联调 | 2-3 天 | 2-3 天 | 端到端联调 |
| **合计** | **10-15 天** | **6-8 天** | |

对比：
- **方案 A（纯 HttpClient）**：smart-livestock 6-8 天，blade 4-6 天
- **方案 B（Feign + url）**：smart-livestock 7-10 天，blade 4-6 天
- **方案 C（Feign + Nacos）**：smart-livestock 10-15 天，blade 6-8 天

### 9.3 方案 C 独有的额外工作（相对方案 B）

| 额外工作 | 工时 | 说明 |
|----------|------|------|
| Gradle 依赖体系改造 | 1 天 | 加 BOM + 5 个依赖 + 冲突解决 |
| bootstrap.yml 创建 | 0.5 天 | 新文件 + Nacos 配置 |
| Nacos 配置迁移决策 | 0.5 天 | 分析哪些配置放 Nacos |
| Nacos 服务注册 | 0.5 天 | 与 blade 联调 |
| Docker Compose 增加 Nacos | 0.5 天 | 开发/测试环境 |
| CI/测试适配 | 0.5-1 天 | test profile 跳过 Nacos |
| 生产部署网络配置 | 0.5 天 | 容器 → Nacos 连通 |
| blade 团队配合（Nacos 信息 + 账号） | 1 天 | |

---

## 10. 风险清单

| # | 风险 | 严重度 | 缓解措施 |
|---|------|--------|----------|
| 1 | Boot 3.3 + Cloud 2024.0 版本兼容性 | 高 | 提前验证 `gradle dependencies` 无冲突 |
| 2 | Nacos 客户端与 RocketMQ starter 冲突 | 中 | RocketMQ starter 可能带旧版 Alibaba 依赖 |
| 3 | 现有 53 个测试因 Spring Cloud 依赖失败 | 中 | 先跑全量测试，逐个修复 |
| 4 | 启动时间显著增加（Nacos 连接超时） | 中 | 配置 Nacos 连接超时 + 本地开发可关闭 |
| 5 | blade Nacos 集群不可用 → smart-livestock 起不来 | 高 | 配置 `spring.cloud.nacos.discovery.fail-fast: false` |
| 6 | 生产环境网络不通（容器 → Nacos） | 高 | 提前验证网络策略 |
| 7 | Nacos 版本不兼容 | 中 | 确认 blade 的 Nacos 版本，匹配客户端版本 |
| 8 | 未来需要与 blade 同步升级 Cloud/Alibaba 版本 | 低 | 长期维护成本 |

---

## 11. 与方案 B 的选择决策矩阵

| 决策因素 | 方案 B 更适合 | 方案 C 更适合 |
|----------|------|------|
| **smart-livestock 是否已有 Spring Cloud** | 当前没有 → 方案 B | — |
| **是否有专人维护 Nacos 连接** | 无 → 方案 B | 有 → 方案 C |
| **blade 是否需要负载均衡** | blade 有前置 Nginx → 方案 B | 多 blade 实例 → 方案 C |
| **是否需要 Nacos 动态配置刷新** | 不需要 → 方案 B | 需要（如热更新 blade 地址）→ 方案 C |
| **未来是否全面微服务化** | 无计划 → 方案 B | 有计划 → 方案 C（提前铺路） |
| **团队是否熟悉 Spring Cloud** | 不熟悉 → 方案 B | 熟悉 → 方案 C |
| **是否有可用 Nacos 集群** | 无 → 方案 B | 有 → 方案 C |
