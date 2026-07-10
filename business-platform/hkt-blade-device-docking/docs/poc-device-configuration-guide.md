# PoC 设备配置指南

本指南说明如何向 PoC 验证流程中添加新设备。整个过程只改一个文件，只填一个字段，不碰代码。

## 快速添加设备（10 秒）

编辑 [scripts/devices.conf](../scripts/devices.conf)，在末尾加一行：

```
00956906000285d8
```

只需要填设备的 EUI 编码，这是你手里有的唯一信息。备注可选，空格分隔：

```
00956906000285d8 新注册的追踪器
```

然后重新运行验证脚本。脚本会自动通过 blade API 把 EUI 解析成 deviceId，新设备出现在所有检查步骤中。

## 文件格式

devices.conf 每行一个设备，`|` 分隔 EUI 和备注：

```
0095690600028ea6 | CATTLE_TRACKER active, 388 records
0095690600028600 | CATTLE_TRACKER active, 370 records
00956906000285d8 | CATTLE_TRACKER registered, no data yet
```

| 列 | 字段 | 必填 | 说明 |
|---|------|------|------|
| 1 | EUI | 是 | 设备标识符（blade 上 deviceName / deviceIdentifier） |
| 2 | 备注 | 否 | 自由描述，纯人类可读，不影响逻辑 |

以 `#` 开头的行是注释，空行会被忽略。不需要手动查 deviceId，脚本运行时自动解析。

## deviceId 自动解析流程

脚本在拿到 OAuth token 后、开始设备检查前，会插入一个解析步骤（Step 1.5）：

```
对于 devices.conf 中的每个 EUI：
  调用 POST /feign/v1/device/lifecycle/pageDevices {"keyword":"EUI","size":1}
  从返回结果提取 deviceId
```

解析失败的设备会在输出里标 `[FAIL]`，后续步骤自动跳过。

## 设备状态与验证结果判定

| 场景 | 判定 | 说明 |
|------|------|------|
| 有上报数据（total > 0，telemetry 非空） | **PASS** | 正常验证通过 |
| 设备已注册但无数据（code:200，total:0） | **WARN** | 不算失败，提示"设备尚未上报" |
| API 返回错误（code != 200） | **FAIL** | 真正的故障，需要排查 |
| EUI 在 blade 上查不到 | **FAIL** | 设备未注册到 blade |

新注册的设备加入 devices.conf 后不会拉低验证通过率，只会在输出里标记 WARN。

## 验证脚本支持的检查

devices.conf 中的每个设备会自动走以下步骤：

1. **deviceId 解析** — EUI 到数字 ID 的自动查询
2. **设备详情** — onlineStatus / RSSI / SNR / lastActiveTime
3. **设备+遥测快照** — battery / GPS / 步数 / 三轴加速度（含 g 值换算和活动分类）
4. **最新遥测** — 所有设备的 batch 查询
5. **上行历史** — report-record 分页，含 decodeData 解析
6. **全量历史表** — 时间排序的 GPS+步数+加速度完整表
7. **物模型** — 设备类型定义（用第一个有效设备的 typeId 查询）

## 环境变量覆盖

验证脚本所有连接参数都支持环境变量覆盖，不改文件：

```bash
# 连其他 blade 环境
DEVICE_HOST=192.168.1.100 DEVICE_PORT=8100 \
AUTH_HOST=192.168.1.100 AUTH_PORT=8108 \
./scripts/verify-blade-docking.sh

# 换 OAuth 凭据
CLIENT_ID=my_client CLIENT_SECRET=my_secret \
SERVICE_USER_ID=123456 \
./scripts/verify-blade-docking.sh

# 用自定义设备清单
DEVICES_FILE=/path/to/my-devices.conf \
./scripts/verify-blade-docking.sh
```

## 当前设备清单

| EUI | 状态 |
|-----|------|
| 0095690600028ea6 | 在线，388 条记录 |
| 0095690600028600 | 在线，370 条记录 |
| 00956906000285d8 | 已注册，暂无数据 |

完整清单维护在 [scripts/devices.conf](../scripts/devices.conf)，以此文件为准。
