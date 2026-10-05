#!/usr/bin/env python3
"""NIX-256 Task 6 offline backfill generator: a simulated 30-day herd.

Produces the CSV artifacts ops need to replay drinking detection on
planted ground truth (spec §15.5 simulation ladder):

  series.csv           raw temperature series (device_id,recorded_at,
                       temperature; Asia/Shanghai wall clock) — feeds
                       `calibrate.py --labels --series ...`
  truth.csv            planted-bout ground truth (device, livestock, farm,
                       bout window, depth, borderline/fever flags)
  temperature_logs.csv rows aligned with the platform `temperature_logs`
                       table (source=DATAGEN); \copy into the PARTITIONED
                       parent table, PostgreSQL routes to time partitions
  alerts.csv           one TEMPERATURE_ABNORMAL alert row covering the
                       fever window of the designated fever cow — shaped
                       exactly like the rows DrinkingEventDetectionService
                       consumes as exclusion windows (farm-scoped query,
                       status AUTO_RESOLVED, resolved_at = fever end)
  README.md            reproduction + \copy import commands + counts

Design decisions:
- Side-effect free: the tool NEVER writes to the database. Import is an
  explicit ops action via psql \copy — rerunning the generator cannot
  corrupt data, and every imported row is traceable to a generated file.
- Capsule bindings come from the local platform DB via a psql subprocess
  (no new Python deps: pandas/numpy only), mirroring the health-context
  DeviceQueryPort ACL: an installation with removed_at IS NULL whose
  device is an ACTIVE capsule, joined through livestock for farm
  attribution (soft-deleted livestock excluded).
- recorded_at in temperature_logs.csv is UTC WALL CLOCK: the platform JVM
  runs with TZ=UTC (docker-compose), so Hibernate reads the naive
  timestamp column as UTC and the §15.4 export then renders it back as
  the same Asia/Shanghai wall clock used in series.csv.
- Bout depth defaults (log-uniform 2.8-4.0 degC) are calibrated against
  the real Aube 2025 dataset (observed ruminal drop p10=2.9, median
  8.2 degC) so the production-parity kernel (depth margin 1.0 degC below
  mu-k*sigma) detects them like real bouts; see README for the reasoning
  and the --depth-min/--depth-max override.

Usage:
    python3 backfill_sim.py --days 30 --cows 10 --out DIR \
        [--farm-id N] [--seed 20261005] [--depth-min 2.8] [--depth-max 4.0]
"""

import argparse
import os
import subprocess
import sys
from datetime import datetime, timedelta, timezone

import numpy as np
import pandas as pd

RANCH_TZ = timezone(timedelta(hours=8))  # Asia/Shanghai (no DST)
SH_UTC_DELTA = timedelta(hours=8)

# Simulation constants (task spec; see module docstring for depth rationale).
BASELINE_C = 38.9
CIRCADIAN_AMP_C = 0.35
CIRCADIAN_PEAK_HOUR = 14.0
COW_OFFSET_SIGMA_C = 0.15
BOUT_LAMBDA = 7
BOUT_COUNT_RANGE = (3, 11)
BOUT_WINDOW_HOURS = (6.0, 21.0)
BOUT_MIN_SPACING_MIN = 45
DESCENT_MIN = (10.0, 25.0)
RECOVERY_MIN = (60.0, 120.0)
RECOVERY_FRACTION = 0.75  # recovered share at the sampled horizon (>= 0.7 spec)
NOISE_SIGMA_C = 0.06
BORDERLINE_SHARE = 0.10
BORDERLINE_RANGE_C = (0.35, 0.55)
FEVER_DAYS = 5
FEVER_BOUTS_RANGE = (2, 3)
FEVER_BASELINE_SHIFT_C = 1.2
SAMPLING_MIN = 5

# Default bout depth range — calibrated, see module docstring.
DEFAULT_DEPTH_MIN_C = 2.8
DEFAULT_DEPTH_MAX_C = 4.0

# Platform column alignment (verified against the live schema).
TEMP_LOGS_COLUMNS = ["livestock_id", "device_id", "temperature", "recorded_at", "source"]
ALERTS_COLUMNS = [
    "farm_id", "livestock_id", "device_id", "type", "status", "severity",
    "message", "resolved_type", "resolved_at", "source", "created_at", "updated_at",
]

BINDINGS_SQL = """
SELECT i.device_id, i.livestock_id, l.farm_id
FROM installations i
JOIN devices d ON d.id = i.device_id
JOIN livestock l ON l.id = i.livestock_id
WHERE i.removed_at IS NULL
  AND d.device_type = 'CAPSULE'
  AND d.status = 'ACTIVE'
  AND l.deleted_at IS NULL
ORDER BY l.farm_id, i.device_id
"""


def run_psql(pg_args, sql):
    """Run one query through psql, returning pipe-separated row strings."""
    cmd = [
        "psql", "-h", pg_args.pg_host, "-p", str(pg_args.pg_port),
        "-U", pg_args.pg_user, "-d", pg_args.pg_db,
        "-A", "-t", "-F", "|", "-c", sql,
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
    except FileNotFoundError:
        raise SystemExit(
            "[backfill] psql not found on PATH — install postgresql client "
            "or extend PATH (e.g. /opt/homebrew/opt/postgresql@16/bin)"
        )
    except subprocess.CalledProcessError as exc:
        raise SystemExit(f"[backfill] psql failed: {exc.stderr.strip()}")
    return [line for line in proc.stdout.splitlines() if line.strip()]


def fetch_bindings(pg_args, farm_id, limit):
    """Active capsule bindings (device, livestock, farm) from the platform DB."""
    rows = run_psql(pg_args, BINDINGS_SQL)
    bindings = []
    for line in rows:
        dev, livestock, farm = line.split("|")
        bindings.append((int(dev), int(livestock), int(farm)))
    if farm_id is None:
        if not bindings:
            raise SystemExit("[backfill] no active capsule bindings found in the database")
        counts = pd.Series([b[2] for b in bindings]).value_counts()
        farm_id = int(counts.idxmax())
        print(f"[backfill] --farm-id not given; picking farm {farm_id} "
              f"({counts.max()} bindings, the largest)")
    selected = [b for b in bindings if b[2] == farm_id]
    if not selected:
        raise SystemExit(f"[backfill] farm {farm_id} has no active capsule bindings")
    if len(selected) < limit:
        print(f"[backfill] WARNING: farm {farm_id} has only {len(selected)} bindings, "
              f"fewer than --cows {limit}; using all of them")
    return selected[:limit], farm_id


def sample_bout_times(rng, n):
    """N bout start minutes uniform in the day window, min-spacing enforced."""
    lo, hi = BOUT_WINDOW_HOURS[0] * 60.0, BOUT_WINDOW_HOURS[1] * 60.0
    for _ in range(80):
        times = np.sort(rng.uniform(lo, hi, n)) if n else np.array([])
        if n < 2 or np.all(np.diff(times) >= BOUT_MIN_SPACING_MIN):
            return times
    return times  # accept the last draw (rare, only for dense days)


def simulate_herd(bindings, days, rng, depth_min, depth_max):
    """Generate the herd series and planted-bout truth.

    Special animals: the LAST binding carries a 5-day fever at the end of
    the window (baseline +1.2 degC, bouts reduced to 2-3/day); the
    second-to-last has one zero-bout day at the midpoint.
    """
    today = datetime.now(RANCH_TZ).date()
    start_day = today - timedelta(days=days)
    fever_idx = len(bindings) - 1
    zero_idx = len(bindings) - 2 if len(bindings) > 1 else -1
    zero_day_idx = days // 2

    series_rows = []
    truth_rows = []
    for cow, (device_id, livestock_id, farm_id) in enumerate(bindings):
        cow_offset = rng.normal(0.0, COW_OFFSET_SIGMA_C)
        for day in range(days):
            fever = cow == fever_idx and day >= days - FEVER_DAYS
            if cow == zero_idx and day == zero_day_idx:
                n_bouts = 0
            elif fever:
                n_bouts = int(rng.integers(FEVER_BOUTS_RANGE[0], FEVER_BOUTS_RANGE[1] + 1))
            else:
                n_bouts = int(np.clip(rng.poisson(BOUT_LAMBDA), *BOUT_COUNT_RANGE))
            bouts = []
            for t0 in sample_bout_times(rng, n_bouts):
                if rng.random() < BORDERLINE_SHARE:
                    depth = rng.uniform(*BORDERLINE_RANGE_C)
                    borderline = True
                else:
                    depth = np.exp(rng.uniform(np.log(depth_min), np.log(depth_max)))
                    borderline = False
                descent = rng.uniform(*DESCENT_MIN)
                horizon = rng.uniform(*RECOVERY_MIN)
                # Exponential recovery reaching RECOVERY_FRACTION*depth at
                # `horizon` minutes (>= 0.7*depth within 60-120 min, spec).
                tau = horizon / np.log(1.0 / (1.0 - RECOVERY_FRACTION))
                bouts.append((t0, depth, descent, tau, borderline))
            day0 = datetime.combine(start_day + timedelta(days=day), datetime.min.time())
            for minute in range(0, 24 * 60, SAMPLING_MIN):
                hour = minute / 60.0
                base = (
                    BASELINE_C
                    + CIRCADIAN_AMP_C * np.sin(2 * np.pi * (hour - CIRCADIAN_PEAK_HOUR) / 24.0)
                    + cow_offset
                    + (FEVER_BASELINE_SHIFT_C if fever else 0.0)
                )
                temp = base
                for t0, depth, descent, tau, _ in bouts:
                    dt = minute - t0
                    if 0 <= dt < descent:
                        temp = min(temp, base - depth * dt / descent)
                    elif dt >= descent:
                        temp = min(temp, base - depth * np.exp(-(dt - descent) / tau))
                temp += rng.normal(0.0, NOISE_SIGMA_C)
                wall = day0 + timedelta(minutes=minute)
                series_rows.append(
                    (device_id, wall.strftime("%Y-%m-%dT%H:%M:%S"), round(float(temp), 2))
                )
            for t0, depth, descent, tau, borderline in bouts:
                bout_start = day0 + timedelta(minutes=int(round(t0)))
                bout_end = day0 + timedelta(minutes=int(round(t0 + descent)))
                truth_rows.append(
                    (
                        device_id, livestock_id, farm_id,
                        bout_start.strftime("%Y-%m-%dT%H:%M:%S"),
                        bout_end.strftime("%Y-%m-%dT%H:%M:%S"),
                        round(float(depth), 2), borderline, fever,
                    )
                )
    series = pd.DataFrame(series_rows, columns=["device_id", "recorded_at", "temperature"])
    truth = pd.DataFrame(
        truth_rows,
        columns=["device_id", "livestock_id", "farm_id", "bout_start", "bout_end",
                 "depth", "is_borderline", "is_fever_period"],
    )
    fever_window = None
    if bindings and fever_idx >= 0:
        fever_livestock = bindings[fever_idx][1]
        fever_device = bindings[fever_idx][0]
        fever_start = datetime.combine(start_day + timedelta(days=days - FEVER_DAYS), datetime.min.time())
        fever_end = datetime.combine(start_day + timedelta(days=days), datetime.min.time())
        fever_window = {
            "farm_id": bindings[fever_idx][2],
            "livestock_id": fever_livestock,
            "device_id": fever_device,
            "start": fever_start,
            "end": fever_end,
        }
    return series, truth, fever_window


def build_platform_frames(series, fever_window, farm_id):
    """Render temperature_logs.csv and alerts.csv frames.

    Timestamps are converted to UTC wall clock (platform JVM runs TZ=UTC,
    so the naive DB column round-trips as the same ranch wall clock the
    §15.4 export renders). The alert row is AUTO_RESOLVED at the fever end
    — exactly the shape DrinkingEventDetectionService.alertWindowsByLivestock
    reads: farm_id scoped, type TEMPERATURE_ABNORMAL, window
    [created_at, resolved_at]; the kernel later applies its +6h buffer.
    """
    wall = pd.to_datetime(series["recorded_at"], format="%Y-%m-%dT%H:%M:%S")
    utc_wall = (wall - pd.Timedelta(SH_UTC_DELTA)).dt.strftime("%Y-%m-%d %H:%M:%S")
    temp_logs = pd.DataFrame(
        {
            "livestock_id": series["device_id"].map(lambda _d: None),  # filled by caller
            "device_id": series["device_id"],
            "temperature": series["temperature"],
            "recorded_at": utc_wall,
            "source": "DATAGEN",
        }
    )
    alerts = pd.DataFrame(columns=ALERTS_COLUMNS)
    if fever_window:
        utc_naive = "%Y-%m-%d %H:%M:%S"
        alerts = pd.DataFrame(
            [
                {
                    "farm_id": fever_window["farm_id"],
                    "livestock_id": fever_window["livestock_id"],
                    "device_id": fever_window["device_id"],
                    "type": "TEMPERATURE_ABNORMAL",
                    "status": "AUTO_RESOLVED",
                    "severity": "CRITICAL",
                    "message": (
                        "datagen backfill: simulated 5-day fever period "
                        "(baseline +1.2C); drives drinking-detection exclusion window"
                    ),
                    "resolved_type": "AUTO",
                    "resolved_at": (fever_window["end"] - SH_UTC_DELTA).strftime(utc_naive) + "+00",
                    "source": "DATAGEN",
                    "created_at": (fever_window["start"] - SH_UTC_DELTA).strftime(utc_naive),
                    "updated_at": (fever_window["end"] - SH_UTC_DELTA).strftime(utc_naive),
                }
            ],
            columns=ALERTS_COLUMNS,
        )
    return temp_logs, alerts


def write_readme(path, args, farm_id, bindings, series, truth, temp_logs, alerts):
    n_days_rows = len(series)
    expected = args.cows * args.days * (24 * 60 // SAMPLING_MIN)
    dev = ", ".join(str(b[0]) for b in bindings[:5]) + ("..." if len(bindings) > 5 else "")
    lines = [
        "# NIX-256 Task 6 backfill 数据包（仿真，source=DATAGEN）",
        "",
        "本目录由 `scripts/drinking_calibration/backfill_sim.py` 生成，**只产文件、不写库**"
        "（设计要求：工具保持无副作用，导入是运维的显式动作，重跑生成器不会污染数据）。",
        "",
        "## 生成命令（可复现，--seed 固定）",
        "",
        "```bash",
        f"python3 backfill_sim.py --days {args.days} --cows {args.cows} "
        f"--farm-id {farm_id} --seed {args.seed} \\",
        f"  --depth-min {args.depth_min} --depth-max {args.depth_max} --out <DIR>",
        "```",
        "",
        f"- 牧场 farm_id={farm_id}，绑定胶囊 device_id：{dev}",
        f"- 特殊牛：最后一头为发热牛（连续 {FEVER_DAYS} 天基线 +{FEVER_BASELINE_SHIFT_C}°C、"
        f"bout 降为 {FEVER_BOUTS_RANGE[0]}–{FEVER_BOUTS_RANGE[1]}/天）；"
        f"倒数第二头第 {args.days // 2} 天 0 bout。",
        "",
        "## 文件与预期行数",
        "",
        f"| 文件 | 行数（含表头） | 说明 |",
        f"|---|---|---|",
        f"| series.csv | {n_days_rows + 1} | {args.cows} 牛 × {args.days} 天 × "
        f"{24 * 60 // SAMPLING_MIN} 点（5 分钟粒度）；Asia/Shanghai 墙钟 |",
        f"| truth.csv | {len(truth) + 1} | 植入 bout 真值（数量级 ~{args.cows * args.days * BOUT_LAMBDA}）|",
        f"| temperature_logs.csv | {len(temp_logs) + 1} | 平台表行（UTC 墙钟，见下）|",
        f"| alerts.csv | {len(alerts) + 1} | 发热牛 TEMPERATURE_ABNORMAL 告警 1 行 |",
        "",
        f"行数校验：series 应为 {expected} 数据行（发热牛 0-bout 日不影响温度行数）。",
        "",
        "## 导入命令（psql \\copy，列序精确对齐）",
        "",
        "> 分区表直接 \\copy 到父表 `temperature_logs`，PostgreSQL 自动路由到时间分区。",
        "> `id/baseline_temp/delta/created_at` 走默认值/生成列，不在文件中。",
        "",
        "```bash",
        "# 本地开发库（postgresql@16, 127.0.0.1:55432, smart_livestock / postgres）",
        "psql -h 127.0.0.1 -p 55432 -U postgres -d smart_livestock <<'SQL'",
        "\\copy temperature_logs (livestock_id, device_id, temperature, recorded_at, source) "
        "FROM 'temperature_logs.csv' WITH (FORMAT csv, HEADER true)",
        "\\copy alerts (" + ", ".join(ALERTS_COLUMNS) + ") "
        "FROM 'alerts.csv' WITH (FORMAT csv, HEADER true)",
        "SQL",
        "```",
        "",
        "> 注意：`\\copy FROM` 的路径相对于 **psql 客户端** 当前目录；cd 到本目录或写绝对路径。",
        "> 导入前确认目标环境（dev=sl-dev-postgres-1 / test=smart-livestock-server-postgres-1）。",
        "",
        "## 时间口径（重要）",
        "",
        "- `series.csv` / `truth.csv`：**Asia/Shanghai 墙钟**（供 `calibrate.py --labels` 离线消费）。",
        "- `temperature_logs.csv.recorded_at` / `alerts.created_at`：**UTC 墙钟**——平台 JVM 以 "
        "TZ=UTC 运行（docker-compose `JAVA_TOOL_OPTIONS=-Duser.timezone=UTC`），Hibernate 把 "
        "naive timestamp 列按 UTC 墙钟读为 Instant，§15.4 导出再渲染回 +08:00，与 series.csv "
        "墙钟一致。",
        "- `alerts.resolved_at` 是 timestamptz，值带显式 `+00` 偏移。",
        "",
        "## 发热告警如何被检测消费（排除窗口链路）",
        "",
        "`DrinkingEventDetectionService.alertWindowsByLivestock` → "
        "`ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(farmId, ['TEMPERATURE_ABNORMAL'], since)`"
        " → status IN (AUTO_RESOLVED, DISMISSED) AND resolved_at >= since → 窗口 "
        "`[created_at, resolved_at]`，内核再加 +6h 退热缓冲。本包告警行满足全部条件："
        "farm_id 与牛一致、type=TEMPERATURE_ABNORMAL、status=AUTO_RESOLVED、resolved_at 落在"
        "回算窗口内。发热期（以及结束后 6h 内）的检出会被排除——这是预期行为。",
        "",
        "## bout 深度默认值的说明（--depth-min/--depth-max）",
        "",
        "默认 D ~ log-uniform[2.8, 4.0]°C，依据：Aubé 2025 真实数据集实测 ruminal 谷深"
        " p10=2.9 / 中位 8.2°C，而生产口径深度判据（谷底低于 μ−kσ 再低 ≥1.0°C）要求谷深"
        "显著超过 ~2.3–3.0°C 才可能被判中。若按斜率算术区间取 0.6–1.8°C，绝大多数 bout "
        "无法通过深度判据（自闭环 F≈0.1），仿真就失去“检出理应良好”的验收意义。如需复现"
        "该行为：`--depth-min 0.6 --depth-max 1.8`。",
        "",
        "## 离线自闭环（两件工具交叉自测）",
        "",
        "```bash",
        "# truth.csv -> labels.csv（全 CONFIRMED）后：",
        "python3 calibrate.py --labels labels.csv --series series.csv --out <DIR>",
        "```",
    ]
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    parser.add_argument("--days", type=int, default=30)
    parser.add_argument("--cows", type=int, default=10)
    parser.add_argument("--out", default=os.path.join(repo, "output/drinking-l2/backfill"))
    parser.add_argument("--farm-id", type=int, default=None,
                        help="farm to draw bindings from (default: farm with most bindings)")
    parser.add_argument("--seed", type=int, default=20261005)
    parser.add_argument("--depth-min", type=float, default=DEFAULT_DEPTH_MIN_C,
                        help="regular bout depth lower bound, degC (log-uniform axis)")
    parser.add_argument("--depth-max", type=float, default=DEFAULT_DEPTH_MAX_C,
                        help="regular bout depth upper bound, degC (log-uniform axis)")
    parser.add_argument("--pg-host", default="127.0.0.1")
    parser.add_argument("--pg-port", type=int, default=55432)
    parser.add_argument("--pg-db", default="smart_livestock")
    parser.add_argument("--pg-user", default="postgres")
    args = parser.parse_args()

    if args.depth_min >= args.depth_max:
        parser.error("--depth-min must be below --depth-max")

    bindings, farm_id = fetch_bindings(args, args.farm_id, args.cows)
    print(f"[backfill] farm {farm_id}: {len(bindings)} devices -> "
          + ", ".join(f"dev {b[0]}/ls {b[1]}" for b in bindings))

    rng = np.random.default_rng(args.seed)
    series, truth, fever_window = simulate_herd(
        bindings, args.days, rng, args.depth_min, args.depth_max
    )

    # Platform frames: fill livestock attribution from the binding map.
    temp_logs, alerts = build_platform_frames(series, fever_window, farm_id)
    livestock_by_device = {b[0]: b[1] for b in bindings}
    temp_logs["livestock_id"] = temp_logs["device_id"].map(livestock_by_device)

    os.makedirs(args.out, exist_ok=True)
    series.to_csv(os.path.join(args.out, "series.csv"), index=False)
    truth.to_csv(os.path.join(args.out, "truth.csv"), index=False)
    temp_logs.to_csv(os.path.join(args.out, "temperature_logs.csv"), index=False)
    alerts.to_csv(os.path.join(args.out, "alerts.csv"), index=False)
    write_readme(os.path.join(args.out, "README.md"), args, farm_id, bindings,
                 series, truth, temp_logs, alerts)

    n_b = int(truth["is_borderline"].sum())
    n_f = int(truth["is_fever_period"].sum())
    print(f"[backfill] series rows={len(series)} (expected {args.cows * args.days * (24 * 60 // SAMPLING_MIN)})")
    print(f"[backfill] truth bouts={len(truth)} (borderline={n_b}, fever-period={n_f})")
    print(f"[backfill] temperature_logs rows={len(temp_logs)}, alerts rows={len(alerts)}")
    print(f"[backfill] wrote artifacts to {args.out}")


if __name__ == "__main__":
    main()
