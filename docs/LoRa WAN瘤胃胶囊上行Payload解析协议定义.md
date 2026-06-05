# LoRaWAN 上传数据 Payload 协议定义说明

## 1. 文档目的

本文档用于说明 `LoRaWAN_Smart_Rumen_Bolus` 项目中的设备上行 `payload` 协议定义，便于平台侧、解码侧和联调人员统一理解字段含义、字节顺序和换算规则。

## 2. 结论摘要

- 当前固件默认启用的是“在那协议”上传格式。
- 当前编译配置中 `ZN_COM_ENABLE = 1`，因此设备正常上报时发送的是固定 14 字节载荷。
- 当前默认 `FPort = 10`。
- 仓库中的 `Compents/Decode/cattle_sheep_track.js` 解析的是另一套旧版标准协议，不适用于当前默认编译配置下的瘤胃胶囊固件。

## 3. 协议依据

本说明依据以下代码整理：

- `USER/config.h`
- `USER/Drive/communicate.c`
- `USER/Drive/include/communicate.h`
- `USER/Drive/include/control_center.h`
- `Compents/Sensirion/SHT40X.c`
- `USER/Drive/adc.c`
- `USER/Drive/accelerometer.c`
- `Compents/LoRa/LoRaWAN_APPLY.c`
- `Compents/Decode/cattle_sheep_track.js`

## 4. 当前生效协议

### 4.1 生效条件

当前固件配置：

- `ZN_COM_ENABLE = 1`
- `LoRaWAN_DEFAULT_PORT = 10`

因此当前设备默认采用“在那协议”格式上传。

### 4.2 载荷总览

上行 `payload` 总长度固定为 `14` 字节：

| 字节序号 | 长度 | 字段名 | 说明 |
| --- | --- | --- | --- |
| Byte0 | 1 | FrameHead | 固定为 `0xC1` |
| Byte1 | 1 | SensorStatus | 传感器状态，首次上报为 `0x80`，后续为 `0x00` |
| Byte2-3 | 2 | BaseTemp12 | 基准温度，12 位有符号编码，按大端发送 |
| Byte4 | 1 | DeltaTemp1 | 第 2 个温度点与前一个温度点的差值 |
| Byte5 | 1 | DeltaTemp2 | 第 3 个温度点与前一个温度点的差值 |
| Byte6 | 1 | DeltaTemp3 | 第 4 个温度点与前一个温度点的差值 |
| Byte7 | 1 | DeltaTemp4 | 第 5 个温度点与前一个温度点的差值 |
| Byte8 | 1 | DeltaTemp5 | 第 6 个温度点与前一个温度点的差值 |
| Byte9 | 1 | DeltaTemp6 | 第 7 个温度点与前一个温度点的差值 |
| Byte10-13 | 4 | GastricMotility | 胃动量，32 位无符号整数，大端发送 |

### 4.3 示例报文

首次上报示例：

```text
C1 80 0D 46 FF FE FF FE FE FE 00 21 AB 9F
```

非首次上报示例：

```text
C1 00 0D 4F FE FD FF FE FF FE 00 21 AB 9F
```

以上示例来自 `communicate.c` 中的注释样例。

### 4.4 字段定义

#### 4.4.1 FrameHead

- 固定值：`0xC1`
- 用于标识当前“在那协议”报文。

#### 4.4.2 SensorStatus

- `0x80`：首次上报
- `0x00`：非首次上报

该值由静态计数器控制，仅第一次上报设置为 `0x80`。

#### 4.4.3 BaseTemp12

该字段表示第 1 个温度点，为 12 位有符号编码值，放在 2 字节中按大端发送。

编码公式如下：

```text
raw_temp = ((temperature + 0.4) * 100 - 4000) * 2048 / 3100
```

其中：

- `temperature` 单位为摄氏度
- 编码时使用四舍五入
- 若结果为负数，则加上 `0x1000`，以 12 位有符号形式发送

平台解码建议按以下步骤处理：

```text
raw16 = (Byte2 << 8) | Byte3
raw12 = raw16 & 0x0FFF
if raw12 >= 0x0800:
    raw12 = raw12 - 0x1000
temperature = ((raw12 * 3100.0 / 2048.0) + 4000.0) / 100.0 - 0.4
```

说明：

- `raw12` 的有效位只有低 12 位
- 解码结果单位为摄氏度

#### 4.4.4 DeltaTemp1 ~ DeltaTemp6

这 6 个字节分别表示后续 6 个温度点相对前一个温度点的差值。

编码公式如下：

```text
delta_byte = (current_temperature - previous_temperature) * 127
```

字段特性：

- 类型：`int8`
- 单位：摄氏度差值
- 解码公式：`delta_temperature = signed_byte / 127.0`

温度序列恢复方式：

```text
T0 = BaseTemp12 解码后的温度
T1 = T0 + DeltaTemp1 / 127.0
T2 = T1 + DeltaTemp2 / 127.0
T3 = T2 + DeltaTemp3 / 127.0
T4 = T3 + DeltaTemp4 / 127.0
T5 = T4 + DeltaTemp5 / 127.0
T6 = T5 + DeltaTemp6 / 127.0
```

因此当前协议一次报文可恢复出 7 个温度点。

#### 4.4.5 GastricMotility

- 长度：4 字节
- 类型：`uint32`
- 字节序：大端

编码方式：

```text
value = (Byte10 << 24) | (Byte11 << 16) | (Byte12 << 8) | Byte13
```

说明：

- 该值直接来自 `device_t.sensor_t.gastricMotility`
- 代码中注释名为“胃动量”
- 其业务单位和医学意义在当前仓库中未见进一步定义，平台侧建议先按原始无符号整数入库

### 4.5 数据来源说明

#### 4.5.1 温度来源

- 温度采样来自 `SHT40X`
- 原始温度在设备中按“放大 1000 倍”保存
- 写入 `device_t.temperature[]` 时转换为近似 `0.01` 摄氏度单位
- 当前协议默认使用 7 个温度点进行压缩上传

#### 4.5.2 电池电压来源

虽然当前“在那协议”默认上报中未直接包含电池电压字段，但设备内部电压值已采集：

- `device_t.sensor_t.vol`：单位 `mV`
- 电量百分比 `batteryLevel` 的计算规则如下：
  - `batteryVoltage >= 3100` 时记为 `100`
  - `2500 < batteryVoltage < 3100` 时按线性规则计算
  - 其他情况记为 `0`

#### 4.5.3 胃动量来源

- `device_t.sensor_t.gastricMotility` 来自加速度算法累计值
- 当前上传时直接发送当前累计值，不做额外缩放

## 5. 历史标准协议

### 5.1 适用说明

当 `ZN_COM_ENABLE = 0` 时，设备走项目内的标准 TLV 协议，上行载荷不是固定长度，而是由同步头和多个数据项拼接而成。

该协议的帧头与当前“在那协议”不同。

### 5.2 帧格式

标准协议的上行帧结构如下：

| 字节序号 | 长度 | 字段名 | 说明 |
| --- | --- | --- | --- |
| Byte0-2 | 3 | SyncHead | 固定为 `68 6B 74` |
| Byte3 | 1 | SpecialType | 特殊标识字节 |
| Byte4 | 1 | PackSeq | 包序号 |
| Byte5... | N | TLV Data | 若干数据项，顺序拼接 |

说明：

- `SyncHead = 0x68 0x6B 0x74`
- `PackSeq` 为设备本地包序号，自增
- `SpecialType` 当前上行构包中默认写 `0x00`

### 5.3 当前周期上报包含的数据项顺序

标准模式下，周期上报默认按如下顺序拼接：

| 顺序 | 数据类型 | Type 值 | 说明 |
| --- | --- | --- | --- |
| 1 | 软硬件版本 | `0x01` | 硬件版本 + 软件版本 |
| 2 | 温度组数据 | `0x4D` | 多组温度数据 |
| 3 | 电池电压 | `0x8B` | 单位 mV |
| 4 | 胃动量 | `0x49` | 4 字节 |
| 5 | X 轴加速度 | `0x4A` | 1 字节 |
| 6 | Y 轴加速度 | `0x4B` | 1 字节 |
| 7 | Z 轴加速度 | `0x4C` | 1 字节 |
| 8 | 上报周期 | `0x86` | 单位分钟 |

### 5.4 TLV 数据项定义

#### 5.4.1 `0x01` 软硬件版本

格式：

```text
[01][HardwareVer][SoftwareVer]
```

当前配置：

- `HARDWARE_VER = 0x10`
- `SOFTWARE_VER = 0x05`

#### 5.4.2 `0x09` 温度数据

格式：

```text
[09][TempH][TempM][TempL]
```

说明：

- 长度 3 字节
- 来自 `device_t.sensor_t.temperature`
- 温度值按“放大 1000 倍”保存
- 负温以最高位标识，当前项目中使用 `0x800000` 作为负号位

解码建议：

```text
raw = (TempH << 16) | (TempM << 8) | TempL
if raw & 0x800000:
    temperature = -(raw & 0x7FFFFF) / 1000.0
else:
    temperature = raw / 1000.0
```

#### 5.4.3 `0x4D` 温度组数据

格式：

```text
[4D][Count][T0H][T0L][T1H][T1L]...[TnH][TnL]
```

说明：

- `Count` 为温度组个数
- 每个温度点 2 字节，大端
- 值来自 `device_t.temperature[]`
- 单位为摄氏度，缩放后建议按 `value / 100.0` 还原
- 若最高位为 `1`，表示负温

解码建议：

```text
raw = (Hi << 8) | Lo
if raw & 0x8000:
    temperature = -(raw & 0x7FFF) / 100.0
else:
    temperature = raw / 100.0
```

#### 5.4.4 `0x03` 电量百分比

格式：

```text
[03][BatteryLevel]
```

说明：

- 范围通常为 `0~100`
- 当前周期上报默认未启用该字段，但枚举中保留

#### 5.4.5 `0x8B` 电池电压

格式：

```text
[8B][VolH][VolL]
```

说明：

- 大端
- 单位：`mV`

解码公式：

```text
voltage_mv = (VolH << 8) | VolL
```

#### 5.4.6 `0x49` 胃动量

格式：

```text
[49][B3][B2][B1][B0]
```

说明：

- 大端 32 位无符号整数

#### 5.4.7 `0x4A` `0x4B` `0x4C` 三轴加速度

格式：

```text
[4A][AX]
[4B][AY]
[4C][AZ]
```

说明：

- 分别表示 X、Y、Z 轴加速度
- 当前代码中由 `FS_4g_HR_TO_mg()` 或 `FS_2g_HR_TO_mg()` 结果写入 `u8`
- 由于字段类型为 `u8`，平台侧建议先按原始 `0~255` 值处理
- 若后续需要物理量换算，建议再结合传感器算法做专项确认

#### 5.4.8 `0x86` 上报周期

格式：

```text
[86][PeriodH][PeriodL]
```

说明：

- 单位：分钟
- 取值范围：`10~1440`
- 特例：`0` 也被代码接受

解码公式：

```text
report_interval_min = (PeriodH << 8) | PeriodL
```

#### 5.4.9 `0xFF` 通讯 ACK

说明：

- 用于标准协议中对服务端下发命令的应答
- 当前设备在收到需要应答的下行命令时，会回传 `0xFF` 类型数据项

## 6. 与解码脚本的关系

`Compents/Decode/cattle_sheep_track.js` 中的解码逻辑具有以下特征：

- 只识别 `68 6B 74` 同步头
- 解析的字段类型包括 `0x01`、`0x02`、`0x03`、`0x10`、`0x11`、`0x15`
- 文件头标注的产品为 `HKT-CT02`

因此可以判断：

- 该脚本属于旧项目或其他产品线的解码样例
- 不能直接用于当前默认启用的瘤胃胶囊“在那协议”
- 若平台当前接收到的是以 `C1` 开头的 14 字节报文，应按本文第 4 章解码

## 7. 接入建议

- 平台侧优先按 `FPort = 10` 接收当前设备上行数据。
- 若 `payload[0] == 0xC1`，按“在那协议”处理。
- 若 `payload[0..2] == 68 6B 74`，按历史标准 TLV 协议处理。
- 对 `GastricMotility`、三轴加速度等业务字段，建议先按原始值存储，再由业务层解释。
- 若需要对“在那协议”输出服务端解码脚本，建议以本文第 4 章的公式为准单独实现。

## 8. 已知注意事项

- 当前仓库未提供“在那协议”的现成解码脚本。
- `communicate.c` 中温度编码示例注释与公式推导结果存在轻微不一致，建议平台实现时以实际代码公式为准。
- 标准协议中的三轴加速度字段定义为 `u8`，不适合直接表达有符号加速度，若平台需要精确物理量，建议与算法实现再核对。
- 若后续修改 `ZN_COM_ENABLE`、`LoRaWAN_DEFAULT_PORT` 或温度编码公式，本文档需同步更新。
