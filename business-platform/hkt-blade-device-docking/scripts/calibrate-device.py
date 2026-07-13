#!/usr/bin/env python3
"""
设备出厂标定脚本

输入: blade 平台遥测数据文件 + 设备 EUI 列表 + 对应 RTK 坐标
输出: 每台设备的标定参数 JSON

用法:
  python3 calibrate-device.py <telemetry_file> [--eui EUI] [--output calibrations.json]

示例:
  # 标定所有已知设备
  python3 calibrate-device.py 20260713.txt

  # 标定单台设备
  python3 calibrate-device.py 20260713.txt --eui 00956906000285d8

  # 指定输出文件
  python3 calibrate-device.py 20260713.txt -o calibrations.json

设备标定点位（RTK 实测）:
  00956906000285d8 → 点位11: (28.246594, 112.851611)
  00956906000285d4 → 点位16: (28.246636, 112.851446)
  00956906000289f0 → 点位20: (28.246565, 112.851191)
  00956906000285b9 → 点位21: (28.246580, 112.851142)
  0095690600028ed2 → 点位22: (28.246589, 112.851087)

  RTK 坐标来自 customer-journey.md §8，通过 RTK 设备在固定点位实测。
  设备静止放置在这些点位上采集数据，因此已知 ground truth。
"""

import re, math, statistics, sys, json, argparse
from dataclasses import dataclass, field, asdict
from typing import List, Tuple, Optional, Dict

# ═══════════════════════════════════════════════════════════════
# RTK 标定点位（ground truth）
# ═══════════════════════════════════════════════════════════════

CALIBRATION_POINTS = {
    "00956906000285d8": {
        "point": 11,
        "rtk_lat": 28.246594,
        "rtk_lon": 112.851611,
        "location": "一期楼顶 11号位",
        "device_id": "2075561438264500224",
    },
    "00956906000285d4": {
        "point": 16,
        "rtk_lat": 28.246636,
        "rtk_lon": 112.851446,
        "location": "一期楼顶 16号位",
        "device_id": "2075561685921374208",
    },
    "00956906000289f0": {
        "point": 20,
        "rtk_lat": 28.246565,
        "rtk_lon": 112.851191,
        "location": "一期楼顶 20号位",
        "device_id": "2075561842033369088",
    },
    "00956906000285b9": {
        "point": 21,
        "rtk_lat": 28.246580,
        "rtk_lon": 112.851142,
        "location": "一期楼顶 21号位",
        "device_id": "2075561968718127104",
    },
    "0095690600028ed2": {
        "point": 22,
        "rtk_lat": 28.246589,
        "rtk_lon": 112.851087,
        "location": "一期楼顶 22号位",
        "device_id": "2075562094404640768",
    },
}

# ═══════════════════════════════════════════════════════════════
# 工具函数
# ═══════════════════════════════════════════════════════════════

def haversine(lat1, lon1, lat2, lon2) -> float:
    R = 6371000.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = (math.sin(dphi/2)**2 +
         math.cos(phi1)*math.cos(phi2)*math.sin(dlam/2)**2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))


@dataclass
class TelemetryRecord:
    timestamp: str
    lat: float
    lon: float
    step: int
    accel_mag: float      # |mag| in g
    activity_class: str    # rest / light / active / intense
    motion_intensity: Optional[float] = None  # only in snapshot


@dataclass
class DeviceCalibration:
    """单台设备的标定结果"""
    eui: str
    device_id: str
    point: int
    location: str
    rtk_lat: float
    rtk_lon: float

    # 标定元信息
    sample_count: int = 0
    sample_duration_hours: float = 0.0
    calibration_quality: float = 0.0   # 0-1

    # GPS 参数
    gps_jitter_radius: float = 0.0      # P95 偏差 (m)
    gps_median_error: float = 0.0       # 中值偏差 (m)
    gps_mean_error: float = 0.0         # 均值偏差 (m)
    gps_p90_error: float = 0.0          # P90 偏差 (m)
    gps_max_error: float = 0.0          # 最大偏差 (m)
    gps_outlier_threshold: float = 0.0  # 野点判定阈值 (m)
    gps_jitter_diameter: float = 0.0    # 抖动直径 (m)

    # 加速度计参数（从静止数据提取的本底特征）
    accel_rest_max_motion: float = 0.0         # 静止时 motion_intensity 上界
    accel_false_active_rate: float = 0.0       # activity_class 误报率
    accel_mag_rest_mean: float = 0.0           # 静止时 |mag| 均值
    accel_activity_distribution: Dict[str, float] = field(default_factory=dict)

    # 元数据
    calibrated_at: str = ""
    calibration_data_source: str = ""


def parse_telemetry(filepath: str, target_eui: Optional[str] = None
                    ) -> Dict[str, List[TelemetryRecord]]:
    """
    解析 blade 遥测文件，提取每个设备的 GPS + 加速度计历史数据。

    返回: {eui: [TelemetryRecord, ...]}
    """
    devices = {}
    current_eui = None
    in_data_section = False

    # 构建 device_id → eui 反向映射
    id_to_eui = {v["device_id"]: k for k, v in CALIBRATION_POINTS.items()}

    with open(filepath, 'r') as f:
        for line in f:
            # 检测设备 section 头
            m = re.match(r'\s+Device:\s+(\d+)\s+\|\s+Total records:', line)
            if m:
                device_id = m.group(1)
                if device_id in id_to_eui:
                    eui = id_to_eui[device_id]
                    if target_eui and eui != target_eui:
                        current_eui = None
                        in_data_section = False
                        continue
                    current_eui = eui
                    in_data_section = False
                    if eui not in devices:
                        devices[eui] = []
                else:
                    current_eui = None
                    in_data_section = False
                continue

            # 检测数据表头
            if 'ReportTime' in line and 'Lat' in line:
                in_data_section = True
                continue

            # 解析数据行:
            # 07/11/2026 17:19:02  28.246609 112.851641    0 | -0.408 -0.408 0.000 0.577g -90.0d 45.0d rest
            if in_data_section and current_eui and current_eui in devices:
                m = re.match(
                    r'\s*(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2})\s+'
                    r'(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+)\s+\|\s+'
                    r'[-]?\d+\.\d+\s+[-]?\d+\.\d+\s+[-]?\d+\.\d+\s+'
                    r'(\d+\.\d+)g\s+[-]?\d+\.\d+d\s+[-]?\d+\.\d+d\s+'
                    r'(\w+)',
                    line)
                if m:
                    ts = m.group(1)
                    lat = float(m.group(2))
                    lon = float(m.group(3))
                    step = int(m.group(4))
                    accel_mag = float(m.group(5))
                    activity = m.group(6)

                    # 过滤无效 GPS (0,0)
                    if lat == 0.0 and lon == 0.0:
                        continue

                    devices[current_eui].append(TelemetryRecord(
                        timestamp=ts, lat=lat, lon=lon,
                        step=step, accel_mag=accel_mag,
                        activity_class=activity))

    return devices


def calibrate_device(eui: str, point_info: dict,
                     records: List[TelemetryRecord]) -> DeviceCalibration:
    """对单台设备执行标定计算"""

    cal = DeviceCalibration(
        eui=eui,
        device_id=point_info["device_id"],
        point=point_info["point"],
        location=point_info["location"],
        rtk_lat=point_info["rtk_lat"],
        rtk_lon=point_info["rtk_lon"],
    )

    if not records:
        cal.calibration_quality = 0.0
        return cal

    rtk_lat, rtk_lon = point_info["rtk_lat"], point_info["rtk_lon"]
    cal.sample_count = len(records)

    # 计算时间跨度
    # (简化: 按首尾记录的时间差估算)
    cal.sample_duration_hours = cal.sample_count * 0.5  # 30min 间隔

    # ── GPS 参数 ──

    # 所有点到 RTK 的距离
    dists_to_rtk = [haversine(r.lat, r.lon, rtk_lat, rtk_lon)
                    for r in records]
    dists_sorted = sorted(dists_to_rtk)

    def percentile(data, p):
        """计算第 p 百分位数"""
        if not data: return 0.0
        idx = int(math.ceil(p / 100.0 * len(data))) - 1
        return data[max(0, min(idx, len(data)-1))]

    cal.gps_median_error = statistics.median(dists_to_rtk)
    cal.gps_mean_error = statistics.mean(dists_to_rtk)
    cal.gps_p90_error = percentile(dists_sorted, 90)
    cal.gps_jitter_radius = percentile(dists_sorted, 95)  # P95
    cal.gps_max_error = max(dists_to_rtk)

    # 野点阈值: max(P99, 3×P95)，但不低于 30m
    p99 = percentile(dists_sorted, 99)
    cal.gps_outlier_threshold = max(p99, 3.0 * cal.gps_jitter_radius, 30.0)

    # 抖动直径（所有点两两之间的最大距离）
    if len(records) >= 2:
        max_diam = 0.0
        lats = [r.lat for r in records]
        lons = [r.lon for r in records]
        for i in range(len(records)):
            for j in range(i+1, len(records)):
                d = haversine(lats[i], lons[i], lats[j], lons[j])
                max_diam = max(max_diam, d)
        cal.gps_jitter_diameter = max_diam

    # ── 加速度计参数 ──

    # activity_class 分布
    activity_counts = {}
    for r in records:
        cls = r.activity_class
        activity_counts[cls] = activity_counts.get(cls, 0) + 1
    total = len(records)
    cal.accel_activity_distribution = {
        k: round(v / total, 3) for k, v in activity_counts.items()
    }

    # 误报率 = 静止设备非 rest 的比例
    non_rest = sum(v for k, v in activity_counts.items() if k != "rest")
    cal.accel_false_active_rate = round(non_rest / total, 3)

    # |mag| 均值（静止时的重力基准）
    mags = [r.accel_mag for r in records]
    cal.accel_mag_rest_mean = round(statistics.mean(mags), 3)

    # motion_intensity 上界（从 snapshot 获取，这里是近似值）
    # 注: motion_intensity 只在 snapshot 中有，历史数据没有。此处用 |mag| 偏离 1g 的程度作为代理
    mag_deviations = [abs(m - 1.0) for m in mags]
    cal.accel_rest_max_motion = round(percentile(sorted(mag_deviations), 90), 3)

    # ── 标定质量分 ──
    # 基于: 样本量足够 (>40 个点)、数据一致性 (P50/P95 比合理)
    quality = 1.0
    if cal.sample_count < 40:
        quality *= cal.sample_count / 40.0
    # P95/P50 比 > 5 说明数据中有大量野点，标定质量降低
    if cal.gps_median_error > 0:
        ratio = cal.gps_jitter_radius / cal.gps_median_error
        if ratio > 5:
            quality *= 0.7
    cal.calibration_quality = round(min(quality, 1.0), 3)

    return cal


def generate_console_report(calibrations: List[DeviceCalibration]):
    """生成控制台可读报告"""
    print("=" * 75)
    print("设备出厂标定报告")
    print("=" * 75)

    for cal in calibrations:
        print(f"\n{'─'*60}")
        print(f"设备: {cal.eui} (点位{cal.point}, {cal.location})")
        print(f"device_id: {cal.device_id}")
        print(f"RTK 真值: ({cal.rtk_lat:.6f}, {cal.rtk_lon:.6f})")
        print(f"标定质量: {cal.calibration_quality:.0%}  "
              f"({cal.sample_count} 样本, ~{cal.sample_duration_hours:.0f}h)")

        print(f"\n  GPS 参数:")
        print(f"    抖动半径 (P95):    {cal.gps_jitter_radius:.1f}m")
        print(f"    中值偏差:           {cal.gps_median_error:.1f}m")
        print(f"    均值偏差:           {cal.gps_mean_error:.1f}m")
        print(f"    P90 偏差:           {cal.gps_p90_error:.1f}m")
        print(f"    最大偏差:           {cal.gps_max_error:.1f}m")
        print(f"    野点阈值:           {cal.gps_outlier_threshold:.1f}m")
        print(f"    抖动直径:           {cal.gps_jitter_diameter:.1f}m")

        print(f"\n  加速度计参数:")
        print(f"    静止 |mag| 均值:    {cal.accel_mag_rest_mean:.3f}g")
        print(f"    静止 motion 上界:   {cal.accel_rest_max_motion:.3f}g")
        print(f"    activity_class 误报率: {cal.accel_false_active_rate:.0%}")
        print(f"    分布: {cal.accel_activity_distribution}")

    # 汇总
    print(f"\n{'='*75}")
    print("汇总对比")
    print(f"{'='*75}")
    print(f"{'设备':<20} {'质量':<6} {'P50':<8} {'P90':<8} {'P95':<8} "
          f"{'野点阈值':<10} {'误报率':<8}")
    print("-" * 65)
    for cal in calibrations:
        print(f"{cal.eui:<20} {cal.calibration_quality:<6.0%} "
              f"{cal.gps_median_error:<8.0f}m {cal.gps_p90_error:<8.0f}m "
              f"{cal.gps_jitter_radius:<8.0f}m {cal.gps_outlier_threshold:<10.0f}m "
              f"{cal.accel_false_active_rate:<8.0%}")

    # 保守默认值（用于未标定设备）
    if calibrations:
        print(f"\n{'='*75}")
        print("保守默认值（用于未标定设备）")
        print(f"{'='*75}")
        max_p95 = max(c.gps_jitter_radius for c in calibrations)
        max_outlier = max(c.gps_outlier_threshold for c in calibrations)
        max_false_rate = max(c.accel_false_active_rate for c in calibrations)
        max_motion = max(c.accel_rest_max_motion for c in calibrations)
        print(f"  gps_jitter_radius:       {max_p95 * 1.2:.0f}m")
        print(f"  gps_outlier_threshold:   {max_outlier:.0f}m")
        print(f"  accel_rest_max_motion:   {max_motion * 1.5:.3f}g")
        print(f"  accel_false_active_rate: {max_false_rate:.0%}")


def main():
    parser = argparse.ArgumentParser(description="设备出厂标定脚本")
    parser.add_argument("telemetry_file", help="blade 平台遥测数据文件")
    parser.add_argument("--eui", help="仅标定指定设备 EUI")
    parser.add_argument("-o", "--output", default="calibrations.json",
                        help="输出 JSON 文件路径 (默认: calibrations.json)")
    parser.add_argument("--json-only", action="store_true",
                        help="仅输出 JSON，不打印控制台报告")
    args = parser.parse_args()

    # 解析数据
    records_by_eui = parse_telemetry(args.telemetry_file, args.eui)

    # 标定每台设备
    calibrations = []
    for eui in (CALIBRATION_POINTS if not args.eui else [args.eui]):
        if eui not in CALIBRATION_POINTS:
            print(f"错误: 未知设备 EUI '{eui}'，不在标定点位列表中", file=sys.stderr)
            continue
        records = records_by_eui.get(eui, [])
        cal = calibrate_device(eui, CALIBRATION_POINTS[eui], records)
        calibrations.append(cal)

    # 输出 JSON
    output = {
        "calibrated_at": "2026-07-13",
        "calibration_data_source": args.telemetry_file,
        "devices": {}
    }
    for cal in calibrations:
        d = asdict(cal)
        # 清理不需要序列化的字段
        output["devices"][cal.eui] = {
            "eui": cal.eui,
            "device_id": cal.device_id,
            "point": cal.point,
            "location": cal.location,
            "rtk": {"lat": cal.rtk_lat, "lon": cal.rtk_lon},
            "calibration": {
                "quality": cal.calibration_quality,
                "sample_count": cal.sample_count,
                "sample_duration_hours": cal.sample_duration_hours,
            },
            "gps": {
                "jitter_radius_m": round(cal.gps_jitter_radius, 1),
                "median_error_m": round(cal.gps_median_error, 1),
                "mean_error_m": round(cal.gps_mean_error, 1),
                "p90_error_m": round(cal.gps_p90_error, 1),
                "max_error_m": round(cal.gps_max_error, 1),
                "outlier_threshold_m": round(cal.gps_outlier_threshold, 1),
                "jitter_diameter_m": round(cal.gps_jitter_diameter, 1),
            },
            "accelerometer": {
                "rest_mag_mean_g": round(cal.accel_mag_rest_mean, 3),
                "rest_max_motion_g": round(cal.accel_rest_max_motion, 3),
                "false_active_rate": round(cal.accel_false_active_rate, 3),
                "activity_distribution": cal.accel_activity_distribution,
            },
        }

    # 添加保守默认值
    if calibrations:
        output["fallback_defaults"] = {
            "gps_jitter_radius_m":
                round(max(c.gps_jitter_radius for c in calibrations) * 1.2, 1),
            "gps_outlier_threshold_m":
                round(max(c.gps_outlier_threshold for c in calibrations), 1),
            "accel_rest_max_motion_g":
                round(max(c.accel_rest_max_motion for c in calibrations) * 1.5, 3),
            "accel_false_active_rate":
                max(c.accel_false_active_rate for c in calibrations),
        }

    with open(args.output, 'w') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    print(f"\n标定结果已保存到: {args.output}")

    if not args.json_only:
        generate_console_report(calibrations)


if __name__ == "__main__":
    main()
