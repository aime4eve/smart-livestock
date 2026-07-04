# Phase C：Feign + url 模式接入 hkt-blade-device（方案 B）

**Date**: 2026-07-04
**Status**: 草案（对比方案）
**对照方案**: `2026-07-03-phase-c-blade-device-integration-design.md` — 方案 A（纯 HttpClient）

---

## 1. 思路来源

open-platform-dev（Open API Service）通过 Spring Cloud OpenFeign 对接 hkt-blade-device，接口声明简洁，DTO 定义完整。smart-livestock-server 可以采用类似模式——但**不引入 Nacos 微服务全套体系**，仅引入 OpenFeign 以 `url` 模式直连 blade。

**核心变化**：Feign 不走 `name = "hkt-blade-device"`（Nacos 服务发现），而走 `url = "${blade.device.base-url}"`（配置直连）。

---

## 2. 方案对比

| 维度 | 方案 A：纯 java.net.http.HttpClient | 方案 B：Feign + url 模式 ✅ | 方案 C：Feign + Nacos（照搬 open-platform-dev） |
|------|------|------|------|
| **新增依赖数量** | 0 | 1（spring-cloud-starter-openfeign） | 4+（Cloud + Alibaba + Nacos） |
| **服务发现** | 手动配置 IP:Port | 手动配置 URL | Nacos 自动 |
| **负载均衡** | 无 | 无（blade 前置 Nginx/VIP 即可） | ✅ 内置 |
| **熔断降级** | 手写 try-catch | ✅ Feign FallbackFactory | ✅ Fallback + Sentinel |
| **接口定义风格** | 手动拼接 URL + JSON | **声明式接口**（与 open-platform-dev 完全一致） | 声明式接口 |
| **接口/DTO 复用** | 不可复用 | **15 个文件可直接参考/复制** | 可直接复用 |
| **启动依赖** | 零外部依赖 | 零外部依赖 | **依赖 Nacos 集群** |
| **运维复杂度** | 最低 | 低 | 高 |
| **架构侵入** | 无 | 极小（一个库） | 大（变成微服务节点） |
| **未来迁移到 Nacos** | 需重写 | **删 url 属性即可** | 已是 |

---

## 3. 技术实现

### 3.1 build.gradle 变更

```groovy
// 新增 BOM
dependencyManagement {
    imports {
        mavenBom "org.springframework.cloud:spring-cloud-dependencies:2024.0.0"
    }
}

dependencies {
    // 新增：仅 1 个
    implementation 'org.springframework.cloud:spring-cloud-starter-openfeign'

    // 原有依赖不变
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    // ...
}
```

**版本说明**：smart-livestock-server 是 Spring Boot 3.3.0，对应 Spring Cloud 2024.0.x。open-platform-dev 是 Boot 3.5.3 + Cloud 2025.0.0，版本不兼容，但 Feign 接口签名和 DTO 与版本无关，直接复制即可。

### 3.2 启动类

```java
@SpringBootApplication
@EnableFeignClients(basePackages = "com.smartlivestock.iot.infrastructure.client.feign")
public class SmartLivestockApplication {
    public static void main(String[] args) {
        SpringApplication.run(SmartLivestockApplication.class, args);
    }
}
```

### 3.3 Feign Client 定义（参考 open-platform-dev，加 url 属性）

```java
// iot/infrastructure/client/feign/BladeLicenseClient.java
@FeignClient(
    name = "blade-license",
    url = "${blade.device.base-url}",
    configuration = BladeFeignConfig.class,
    fallbackFactory = BladeLicenseFallback.class
)
public interface BladeLicenseClient {

    @GetMapping("/feign/v1/device-license/control/by-sn")
    InternalResponse<LicenseStatusResp> getLicenseStatusBySn(
        @RequestParam("deviceSn") String deviceSn);
}
```

```java
// iot/infrastructure/client/feign/BladeDeviceServiceClient.java
@FeignClient(
    name = "blade-device-lifecycle",
    url = "${blade.device.base-url}",
    configuration = BladeFeignConfig.class,
    fallbackFactory = BladeDeviceServiceFallback.class
)
public interface BladeDeviceServiceClient {

    @PostMapping("/feign/v1/device/lifecycle/registerDevice")
    InternalResponse<DeviceRegistrationResp> registerDevice(
        @RequestBody DeviceRegistrationReq request);

    @PostMapping("/feign/v1/device/lifecycle/pageDevices")
    InternalResponse<DevicePageResp> pageDevices(@RequestBody DevicePageReq request);

    @PostMapping("/feign/v1/device/lifecycle/getDeviceDetail")
    InternalResponse<DeviceDetailResp> getDeviceDetail(@RequestBody DeviceDetailReq request);

    @GetMapping("/feign/v1/device/lifecycle/getDeviceDetailWithTelemetry")
    InternalResponse<DeviceTelemetryResp> getDeviceDetailWithTelemetry(
        @RequestParam("deviceId") String deviceId);

    @PostMapping("/feign/v1/device/lifecycle/updateDeviceInfo")
    InternalResponse<Boolean> updateDeviceInfo(@RequestBody DeviceUpdateReq request);

    @PostMapping("/feign/v1/device/lifecycle/removeDevice")
    InternalResponse<Boolean> removeDevice(@RequestBody DeviceRemoveReq request);
}
```

```java
// iot/infrastructure/client/feign/BladeHistoryDataClient.java
@FeignClient(
    name = "blade-device-history",
    url = "${blade.device.base-url}",
    configuration = BladeFeignConfig.class,
    fallbackFactory = BladeHistoryDataFallback.class
)
public interface BladeHistoryDataClient {

    @PostMapping("/feign/v1/device/history/data/query-list-page/{deviceId}")
    InternalResponse<DeviceHistoryDataPageResp> queryHistoryDataPage(
        @PathVariable("deviceId") String deviceId,
        @RequestBody DeviceHistoryDataPageReq request);

    @PostMapping("/feign/v1/device/history/data/query-sub-device-list-page/{subDeviceId}")
    InternalResponse<DeviceHistoryDataPageResp> querySubDeviceHistoryDataPage(
        @PathVariable("subDeviceId") String subDeviceId,
        @RequestBody DeviceHistoryDataPageReq request);
}
```

### 3.4 Feign 配置：Token 拦截器

```java
// iot/infrastructure/client/feign/BladeFeignConfig.java
public class BladeFeignConfig {

    @Bean
    public RequestInterceptor bladeAuthInterceptor(BladeTokenProvider tokenProvider) {
        return template -> template.header("token", tokenProvider.getToken());
    }

    @Bean
    Logger.Level feignLoggerLevel() {
        return Logger.Level.BASIC;  // 或 FULL 调试用
    }
}
```

### 3.5 BladeTokenProvider（简化版 — 无 internalUserId）

open-platform-dev 的 `InternalTokenProvider` 需要从 `RequestContext` 获取 `internalUserId`（每个外部 App 绑定不同内部用户）。smart-livestock-server 是**系统对系统**调用，用固定的 service account：

```java
// iot/infrastructure/client/feign/BladeTokenProvider.java
@Component
public class BladeTokenProvider {

    private final OpenApiGatewayTokenService gatewayTokenService;

    @Value("${blade.oauth2.service-user-id:smart-livestock-server}")
    private String serviceUserId;

    public BladeTokenProvider(OpenApiGatewayTokenService gatewayTokenService) {
        this.gatewayTokenService = gatewayTokenService;
    }

    public String getToken() {
        if (gatewayTokenService.isReady()) {
            return gatewayTokenService.getAccessToken(serviceUserId);
        }
        throw new IllegalStateException("blade OAuth2 未就绪: "
            + gatewayTokenService.describeWhyNotReady());
    }
}
```

`OpenApiGatewayTokenService` 直接从 open-platform-dev **完整复制**（改 package），它用 `RestTemplate` + Basic Auth → OAuth2 token endpoint → 缓存 access_token。

### 3.6 Fallback 工厂

```java
// iot/infrastructure/client/feign/fallback/BladeLicenseFallback.java
@Component
public class BladeLicenseFallback implements FallbackFactory<BladeLicenseClient> {
    @Override
    public BladeLicenseClient create(Throwable cause) {
        log.warn("[PhaseC] BladeLicenseClient 调用失败，触发降级: {}", cause.getMessage());
        return deviceSn -> {
            throw new BladeServiceException("License 服务不可用", cause);
        };
    }
}
```

其他 Fallback 同理。降级策略：查询类返回空数据，注册类抛业务异常。

### 3.7 配置项

```yaml
# application.yml
blade:
  device:
    base-url: ${BLADE_DEVICE_URL:http://hkt-blade-device:8080}
  oauth2:
    enabled: ${BLADE_OAUTH2_ENABLED:false}
    token-uri: ${BLADE_OAUTH2_TOKEN_URL:}
    client-id: ${BLADE_OAUTH2_CLIENT_ID:}
    client-secret: ${BLADE_OAUTH2_CLIENT_SECRET:}
    expiry-skew-seconds: 120
    connect-timeout-ms: 5000
    read-timeout-ms: 15000
  telemetry:
    webhook-secret: ${BLADE_TELEMETRY_WEBHOOK_SECRET:}

# Feign 日志
logging:
  level:
    com.smartlivestock.iot.infrastructure.client.feign: DEBUG
```

---

## 4. 新增文件清单

```
iot/infrastructure/client/feign/
├── BladeLicenseClient.java              ← 参考 open-platform-dev DeviceLicenseClient
├── BladeDeviceServiceClient.java        ← 参考 open-platform-dev DeviceServiceClient
├── BladeHistoryDataClient.java          ← 参考 open-platform-dev DeviceHistoryDataClient
├── BladeFeignConfig.java                ← 新增（Token 拦截器）
├── BladeTokenProvider.java              ← 新增（简化版 InternalTokenProvider）
├── OpenApiGatewayTokenService.java      ← 从 open-platform-dev 复制
├── OpenApiOAuth2Properties.java         ← 从 open-platform-dev 复制
├── OpenApiOAuth2RestConfig.java         ← 从 open-platform-dev 复制
├── InternalResponse.java                ← 从 open-platform-dev 复制
├── fallback/
│   ├── BladeLicenseFallback.java
│   ├── BladeDeviceServiceFallback.java
│   └── BladeHistoryDataFallback.java
└── dto/
    ├── LicenseStatusResp.java
    ├── DeviceRegistrationReq.java
    ├── DeviceRegistrationResp.java
    ├── DeviceDetailReq.java
    ├── DeviceDetailResp.java
    ├── DeviceTelemetryResp.java
    ├── DevicePageReq.java
    ├── DevicePageResp.java
    ├── DeviceUpdateReq.java
    ├── DeviceRemoveReq.java
    ├── DeviceHistoryDataPageReq.java
    ├── DeviceHistoryDataPageResp.java
    └── LoginUser.java
```

**13 个文件从 open-platform-dev 复制**（改 package），**5 个文件新增**（FeignConfig、TokenProvider、3 个 Fallback）。总计约 18 个文件。

---

## 5. 与方案 A 的代码量对比

| | 方案 A：纯 HttpClient | 方案 B：Feign + url |
|------|------|------|
| Feign 接口（3 个） | — | 3 个接口 ~60 行 |
| DTO（11 个） | 相同（仍需定义） | 直接复制 ~200 行 |
| HTTP 调用样板代码 | 手动拼接 URL + Header + Body + 解析响应 ~150 行/客户端 | 0（Feign 自动） |
| Token 管理 | 手写 ~100 行 | 复制 open-platform-dev ~200 行 |
| Fallback | 手写 try-catch ~50 行/客户端 | 声明式 Fallback ~20 行/客户端 |
| **总代码量** | **~500 行** | **~480 行（但大量复制，手写少）** |

表面上看代码量相当，但方案 B 的**核心价值在于接口契约的精确对齐**——15 个文件从 open-platform-dev 直接复制，接口签名不会出错。

---

## 6. 未来迁移路径

```
Phase C 当前：Feign + url 模式
  url = "${blade.device.base-url}"
  ↓ 一步迁移
Phase 3 后续：Feign + Nacos 服务发现
  name = "hkt-blade-device"  （删掉 url 属性）
  + Nacos Discovery 依赖
  + bootstrap.yml
```

迁移时：
1. 加 Nacos 依赖 + 配置
2. Feign Client 注释掉 `url` 属性
3. 服务自动发现 blade，无需改任何业务代码

---

## 7. 与 open-platform-dev 的关系图

```
open-platform-dev（外部 BFF）              smart-livestock-server（业务系统）
         │                                           │
         │ Feign + Nacos                             │ Feign + url
         │ name="hkt-blade-device"                   │ url="${blade.device.base-url}"
         │ ↓                                         │ ↓
         └──────────┬─────────────────────────────────┘
                    │
                    ▼
            hkt-blade-device
           (设备管理平台)
```

两者调用同一套 blade Feign 端点，只是**服务发现方式不同**（Nacos vs 直连 URL）。
