# Phase C PoC：hkt-blade-device 对接验证

方案 B（Feign + url 直连），不引入 Nacos / Spring Cloud Alibaba，用 Feign `url` 模式消费 blade
已有的 `/feign/v1/*` 端点。blade 不可改代码，本工程只作为消费方。

**已通过真实 blade平台 test 环境（172.22.4.17）和dev 环境（172.21.2.41）全链路验证（单元测试 18/18 + 真实联通性 13/13 全绿）。**

## Nacos 注册中心：

172.22.3.16:8848，namespace `c47123d9-9d2b-4fdf-a61a-8d5daa9c89ac

## blade平台 dev环境

| 服务             | 地址             | 用途                              |
| ---------------- | ---------------- | --------------------------------- |
| hkt-blade-auth   | 172.21.2.41:8108 | OAuth2 换票 `/oauth2/token`       |
| hkt-blade-device | 172.21.2.41:8100 | 设备 + 遥测 `/feign/v1/device/*`  |
| hkt-blade-system | 172.21.2.41:8106 | 用户管理 `/feign/v1/system/sdk/*` |

## blade平台 test环境

| 服务 | 地址 | 用途 |
|------|------|------|
| hkt-blade-auth | 172.22.4.17:8108 | OAuth2 换票 `/oauth2/token` |
| hkt-blade-device | 172.22.4.17:8100 | 设备 + 遥测 `/feign/v1/device/*` |
| hkt-blade-system | 172.22.4.17:8106 | 用户管理 `/feign/v1/system/sdk/*` |

## 换票记录

|本项目| blade 平台|service-user-id|换票|
|------|------|------|------|
| dev（19080）|dev 172.21.2.41|207938296942293811| ✅ | 
| test（18080） |test 172.22.4.17|2074385063398711296 | ✅ |        

## 单元测试（16/16 全绿）

### 对接测试（MockWebServer，6/6）

| # | 用例 | 覆盖点 |
|---|------|--------|
| 1 | `oauthTokenExchangeWorks` | `/oauth2/token` + `grant_type=openapi` + Basic Auth + `Tenant-Id` |
| 2 | `tokenHeaderInjected` | `token` 头 + `Tenant-Id` 头注入（blade 约定，无 Bearer） |
| 3 | `envelopeParsing` | `InternalResponse` 包络 + `DevicePageResp` 解析 |
| 4 | `deviceDetailWithTelemetry` | 设备详情 + 遥测属性 |
| 5 | `telemetryLatestQuery` | 遥测最新值（`deviceIds` 数组 + `deviceTypeCode`） |
| 6 | `errorDecoderOn500` | blade HTTP 500 → `BladeServiceException` |

### 加速度计换算测试（AccelerometerConverterTest，12/12）

| # | 用例 | 覆盖点 |
|---|------|--------|
| 7 | `positiveValue` | 正值 uint16 → g（+0.612g） |
| 8 | `negativeValue` | 负值补码 uint16 → g（-0.612g） |
| 9 | `zeroValue` | 零值 = 0g |
| 10 | `maxPositive` | 量程边界（512 → +2.048g） |
| 11 | `maxNegative` | 负边界（65485 → -0.204g） |
| 12 | `magnitudeStationary` | 静止合矢量 ≈ 1g |
| 13 | `magnitudeFlatHorizontal` | 水平放置 Z=1g |
| 14 | `motionIntensityZero` | 纯重力时运动强度 = 0 |
| 15 | `activityClassification` | rest/light/active/intense 阈值 |
| 16 | `realBladeComparison` | 真实 blade 样本：活动 > 静止 |
| 17 | `toMs2Conversion` | g → m/s²（1g = 9.80665） |
| 18 | `firmwareThreshold` | 固件动作阈值 512 raw ≈ 32mg |

## 真实联通性验证脚本（13 项检查）

```bash
cd business-platform/hkt-blade-device-docking
./scripts/verify-blade-docking.sh
```

检查链路：服务健康 → OAuth2 换票 → 设备详情（运维数据） → 设备+遥测快照 → 最新遥测 →
上行历史摘要（g 值 + 活动分类） → GPS+步数+加速度全量历史表（g 值 + roll/pitch 倾角 + 活动分类 + 静止/活动统计） → 物模型定义。

## 运行

```bash
# 单元测试（不依赖真实 blade）
cd business-platform/hkt-blade-device-docking
smart-livestock-server/gradlew test

# 真实联通性验证
./scripts/verify-blade-docking.sh
```

## OAuth2 换票流程

1. blade auth `POST /oauth2/token`，Basic Auth = `hkt_openapi:secret`
2. form params: `grant_type=openapi&userId={serviceUserId}`
3. header: `Tenant-Id: 000000`
4. 返回 `{"code":200,"data":{"accessToken":"...","expiresIn":43200}}`

**serviceUserId 获取方式**（blade 无现成 API 用户时的自建流程）：
```
# 1. 获取 RSA 公钥
curl http://172.22.4.17:8108/code/public-key

# 2. RSA 加密密码（PKCS1Padding）

# 3. 创建用户（feign 端点不需要 token）
curl -X POST http://172.22.4.17:8106/feign/v1/system/sdk/user/create \
  -H "Tenant-Id: 000000" -H "Content-Type: application/json" \
  -d '{"account":"sl_service","password":"{RSA-encrypted}","name":"SL Service"}'

# 4. 启用用户
curl -X PUT http://172.22.4.17:8106/feign/v1/system/sdk/user/{userId}/enable \
  -H "Tenant-Id: 000000"

# 5. 用 userId 换票（grant_type=openapi）
```

## 已验证的真实 API 端点

| 端点 | 方法 | 用途 | 状态 |
|------|------|------|------|
| `/oauth2/token` | POST | OAuth2 换票 | ✅ 12h token |
| `/feign/v1/system/sdk/user/create` | POST | 创建用户（无需 token） | ✅ |
| `/feign/v1/system/sdk/user/{id}/enable` | PUT | 启用用户（无需 token） | ✅ |
| `/feign/v1/device/lifecycle/pageDevices` | POST | 设备列表（120 台） | ✅ |
| `/feign/v1/device/lifecycle/getDeviceDetail` | POST | 设备详情 | ✅ |
| `/feign/v1/device/lifecycle/getDeviceDetailWithTelemetry` | GET | **设备+遥测快照** | ✅ |
| `/feign/v1/device/lifecycle/registerDevice` | POST | 设备注册 | ✅ |
| `/feign/v1/device/lifecycle/batchRegisterDevices` | POST | 批量注册 | ✅ |
| `/feign/v1/device/lifecycle/removeDevice` | POST | 删除（软删除） | ✅ |
| `/feign/v1/device/lifecycle/updateDeviceInfo` | POST | 更新设备 | ✅ |
| `/feign/v1/device/telemetry/history/latest` | POST | **最新遥测** | ✅ |
| `/device/report-record/page` | GET | **上行历史（推荐时序数据源，含 decodeData）** | ✅ 324+ 条 |
| `/feign/v1/device/type/findById` | GET | 设备物模型（19 属性） | ✅ |
| `/feign/v1/device-license/control/by-sn` | GET | License 查询 | 服务未注册 |

## CATTLE_TRACKER 物模型（19 属性）

| 属性 | 类型 | 说明 |
|------|------|------|
| `latitude` | float | GPS 纬度 |
| `longitude` | float | GPS 经度 |
| `stepNumber` | int | 步数（活动量） |
| `battery` | int | 电量 (%) |
| `antiDisassemblyStatus` | int | 防拆卸状态 |
| `workMode` | select | 工作模式（固定/分段周期） |
| `xAxisDirectionAccelerationValue` | int | **X 轴加速度（LIS3DH，需换算）** |
| `yAxisDirectionAccelerationValue` | int | **Y 轴加速度** |
| `zAxisDirectionAccelerationValue` | int | **Z 轴加速度** |
| 其余 10 个 | - | 分段周期配置、软硬件版本、上报间隔 |

## 加速度计换算（LIS3DH，固件源码 + 规格书 + 实测三方确认）

**传感器**: ST LIS3DH 三轴 MEMS 加速度计

**固件配置**（源码分析确认）:

| 配置项 | 值 |
|--------|-----|
| 量程 | ±2g |
| 分辨率模式 | Low Power（8-bit，~16mg 分辨率） |
| 数据上报 | 原始整数（`lis3dh_get_raw_data`） |
| 动作阈值 | 512 raw ≈ 32mg（小于此值当噪声忽略） |
| 高通滤波 | 未启用（数据含重力，静止合矢量 ≈ 1g） |

**换算公式**:
```python
def blade_accel_to_g(raw: int) -> float:
    signed = raw - 65536 if raw > 32767 else raw
    return signed * 0.004  # ~3.57mg/digit (实测), 4mg/digit (规格书)
```

**倾角计算**（数据含重力，可直接算姿态）:
```python
import math
roll  = math.degrees(math.atan2(ay, az))
pitch = math.degrees(math.atan2(-ax, math.sqrt(ay**2 + az**2)))
```

**活动分类**:

| 合矢量 | 分类 | 业务含义 |
|--------|------|---------|
| < 1.15g | rest | 静止/休息 |
| 1.15-1.5g | light | 轻微活动（吃草） |
| 1.5-2.5g | active | 活跃行走 |
| > 2.5g | intense | 剧烈运动/冲击 |


**精度限制**: LP 8-bit 模式最小可分辨 ~16mg。反刍咀嚼等细微动作可能检测不到。固件有 `lis3dh_high_res`（~1mg）备选，建议长期切换以支持健康监测。

**代码**: `AccelerometerConverter.java`（`toG` / `toMs2` / `magnitudeG` / `motionIntensity` / `rollDegrees` / `pitchDegrees` / `classifyActivity` / `isAboveFirmwareThreshold`）

## 技术栈

- Spring Boot 3.3.0 + Spring Cloud 2023.0.4 + OpenFeign（无 Nacos）
- Cloud 2023.0.x 匹配 Boot 3.2/3.3（Cloud 2024.0.x 需要 Boot 3.4.x）
- 加速度计换算工具类 + 10 个单元测试

## 与 smart-livestock-server 主项目的关系

本工程是独立 PoC。验证通过后，同一套 Feign Client / OAuth2 / DTO / 加速度计换算直接迁移到
`smart-livestock-server/.../iot/infrastructure/client/feign/`。
