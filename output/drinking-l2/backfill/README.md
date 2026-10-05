# NIX-256 Task 6 backfill 数据包（仿真，source=DATAGEN）

本目录由 `scripts/drinking_calibration/backfill_sim.py` 生成，**只产文件、不写库**（设计要求：工具保持无副作用，导入是运维的显式动作，重跑生成器不会污染数据）。

## 生成命令（可复现，--seed 固定）

```bash
python3 backfill_sim.py --days 30 --cows 10 --farm-id 1 --seed 20261005 \
  --depth-min 2.8 --depth-max 4.0 --out <DIR>
```

- 牧场 farm_id=1，绑定胶囊 device_id：51, 52, 53, 54, 55...
- 特殊牛：最后一头为发热牛（连续 5 天基线 +1.2°C、bout 降为 2–3/天）；倒数第二头第 15 天 0 bout。

## 文件与预期行数

| 文件 | 行数（含表头） | 说明 |
|---|---|---|
| series.csv | 86401 | 10 牛 × 30 天 × 288 点（5 分钟粒度）；Asia/Shanghai 墙钟 |
| truth.csv | 1986 | 植入 bout 真值（数量级 ~2100）|
| temperature_logs.csv | 86401 | 平台表行（UTC 墙钟，见下）|
| alerts.csv | 2 | 发热牛 TEMPERATURE_ABNORMAL 告警 1 行 |

行数校验：series 应为 86400 数据行（发热牛 0-bout 日不影响温度行数）。

## 导入命令（psql \copy，列序精确对齐）

> 分区表直接 \copy 到父表 `temperature_logs`，PostgreSQL 自动路由到时间分区。
> `id/baseline_temp/delta/created_at` 走默认值/生成列，不在文件中。

```bash
# 本地开发库（postgresql@16, 127.0.0.1:55432, smart_livestock / postgres）
psql -h 127.0.0.1 -p 55432 -U postgres -d smart_livestock <<'SQL'
\copy temperature_logs (livestock_id, device_id, temperature, recorded_at, source) FROM 'temperature_logs.csv' WITH (FORMAT csv, HEADER true)
\copy alerts (farm_id, livestock_id, device_id, type, status, severity, message, resolved_type, resolved_at, source, created_at, updated_at) FROM 'alerts.csv' WITH (FORMAT csv, HEADER true)
SQL
```

> 注意：`\copy FROM` 的路径相对于 **psql 客户端** 当前目录；cd 到本目录或写绝对路径。
> 导入前确认目标环境（dev=sl-dev-postgres-1 / test=smart-livestock-server-postgres-1）。

## 时间口径（重要）

- `series.csv` / `truth.csv`：**Asia/Shanghai 墙钟**（供 `calibrate.py --labels` 离线消费）。
- `temperature_logs.csv.recorded_at` / `alerts.created_at`：**UTC 墙钟**——平台 JVM 以 TZ=UTC 运行（docker-compose `JAVA_TOOL_OPTIONS=-Duser.timezone=UTC`），Hibernate 把 naive timestamp 列按 UTC 墙钟读为 Instant，§15.4 导出再渲染回 +08:00，与 series.csv 墙钟一致。
- `alerts.resolved_at` 是 timestamptz，值带显式 `+00` 偏移。

## 发热告警如何被检测消费（排除窗口链路）

`DrinkingEventDetectionService.alertWindowsByLivestock` → `ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(farmId, ['TEMPERATURE_ABNORMAL'], since)` → status IN (AUTO_RESOLVED, DISMISSED) AND resolved_at >= since → 窗口 `[created_at, resolved_at]`，内核再加 +6h 退热缓冲。本包告警行满足全部条件：farm_id 与牛一致、type=TEMPERATURE_ABNORMAL、status=AUTO_RESOLVED、resolved_at 落在回算窗口内。发热期（以及结束后 6h 内）的检出会被排除——这是预期行为。

## bout 深度默认值的说明（--depth-min/--depth-max）

默认 D ~ log-uniform[2.8, 4.0]°C，依据：Aubé 2025 真实数据集实测 ruminal 谷深 p10=2.9 / 中位 8.2°C，而生产口径深度判据（谷底低于 μ−kσ 再低 ≥1.0°C）要求谷深显著超过 ~2.3–3.0°C 才可能被判中。若按斜率算术区间取 0.6–1.8°C，绝大多数 bout 无法通过深度判据（自闭环 F≈0.1），仿真就失去“检出理应良好”的验收意义。如需复现该行为：`--depth-min 0.6 --depth-max 1.8`。

## 离线自闭环（两件工具交叉自测）

```bash
# truth.csv -> labels.csv（全 CONFIRMED）后：
python3 calibrate.py --labels labels.csv --series series.csv --out <DIR>
```
