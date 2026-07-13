#!/usr/bin/env python3
"""
GPS 抖动数据治理 — 验证脚本 v2

基于 20260713.txt 中 5 个静态设备的 blade 平台遥测数据，对比 RTK 真值，
分析抖动特征，演示多种治理算法效果，生成 Markdown 报告。

用法: python3 gps-jitter-validate.py [20260713.txt] [--json]
"""

import re, math, statistics, sys, json
from dataclasses import dataclass, field
from typing import List, Tuple, Optional
from collections import Counter

# ═══════════════════════════════════════════════════════════════
# 配置
# ═══════════════════════════════════════════════════════════════

RTK = {
    "00956906000285d8": (28.246594, 112.851611, 11),
    "00956906000285d4": (28.246636, 112.851446, 16),
    "00956906000289f0": (28.246565, 112.851191, 20),
    "00956906000285b9": (28.246580, 112.851142, 21),
    "0095690600028ed2": (28.246589, 112.851087, 22),
}

DEVICE_ID_MAP = {eui: did for eui, did in [
    ("00956906000285d8", "2075561438264500224"),
    ("00956906000285d4", "2075561685921374208"),
    ("00956906000289f0", "2075561842033369088"),
    ("00956906000285b9", "2075561968718127104"),
    ("0095690600028ed2", "2075562094404640768"),
]}

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
class GpsRecord:
    timestamp: str
    lat: float
    lon: float

@dataclass
class DeviceData:
    eui: str
    point: int
    rtk_lat: float
    rtk_lon: float
    records: List[GpsRecord] = field(default_factory=list)

    @property
    def lats(self): return [r.lat for r in self.records]
    @property
    def lons(self): return [r.lon for r in self.records]
    @property
    def count(self): return len(self.records)

    def dist_to_rtk(self, lat, lon):
        return haversine(lat, lon, self.rtk_lat, self.rtk_lon)

    def all_dists(self): return [self.dist_to_rtk(r.lat, r.lon) for r in self.records]

    def jitter_diameter(self):
        if len(self.records) < 2: return 0.0
        return max(haversine(self.lats[i], self.lons[i],
                             self.lats[j], self.lons[j])
                   for i in range(len(self.records))
                   for j in range(i+1, len(self.records)))

    def dist_percentile(self, p):
        """距离 RTK 的第 p 百分位数"""
        return statistics.quantiles(self.all_dists(), n=100)[p-1] if self.records else 0


def parse_file(filepath: str) -> List[DeviceData]:
    devices = {}
    current_eui = None
    in_data = False

    with open(filepath, 'r') as f:
        for line in f:
            m = re.match(r'\s+Device:\s+(\d+)\s+\|\s+Total records:', line)
            if m:
                did = m.group(1)
                for eui, d in DEVICE_ID_MAP.items():
                    if d == did and eui in RTK:
                        current_eui = eui
                        in_data = False
                        if eui not in devices:
                            devices[eui] = DeviceData(eui, RTK[eui][2], RTK[eui][0], RTK[eui][1])
                        break
                continue

            if 'ReportTime' in line and 'Lat' in line:
                in_data = True
                continue

            if in_data and current_eui and current_eui in devices:
                m = re.match(r'\s*(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2})\s+'
                             r'(\d+\.\d+)\s+(\d+\.\d+)\s+', line)
                if m:
                    lat, lon = float(m.group(2)), float(m.group(3))
                    if lat != 0.0 and lon != 0.0:
                        devices[current_eui].records.append(GpsRecord(m.group(1), lat, lon))

    return [devices[e] for e in RTK if e in devices]

# ═══════════════════════════════════════════════════════════════
# 治理算法
# ═══════════════════════════════════════════════════════════════

class StablePositionEMA:
    """指数移动平均 — 维持一个稳定位置，位移超阈值才更新"""

    def __init__(self, threshold_m=12.0, alpha=0.3):
        self.threshold = threshold_m
        self.alpha = alpha
        self.lat = self.lon = None
        self.updates = 0
        self.total = 0
        self.filtered = 0

    def ingest(self, lat, lon) -> Tuple[bool, float, float]:
        self.total += 1
        if self.lat is None:
            self.lat, self.lon = lat, lon
            self.updates += 1
            return True, lat, lon

        dist = haversine(lat, lon, self.lat, self.lon)
        if dist >= self.threshold:
            self.lat, self.lon = lat, lon
            self.updates += 1
            return True, lat, lon
        else:
            self.lat = self.alpha * lat + (1 - self.alpha) * self.lat
            self.lon = self.alpha * lon + (1 - self.alpha) * self.lon
            self.filtered += 1
            return False, self.lat, self.lon


class SlidingWindowMedian:
    """滑动窗口中值滤波 — 最近 N 个点的中值作为输出"""

    def __init__(self, window_size=5):
        self.window = window_size
        self.lat_buf = []
        self.lon_buf = []
        self.total = 0

    def ingest(self, lat, lon) -> Tuple[float, float]:
        self.total += 1
        self.lat_buf.append(lat)
        self.lon_buf.append(lon)
        if len(self.lat_buf) > self.window:
            self.lat_buf.pop(0)
            self.lon_buf.pop(0)
        return (statistics.median(self.lat_buf),
                statistics.median(self.lon_buf))


class SpeedGate:
    """物理可行性门控 — 过滤掉速度异常的点"""

    def __init__(self, max_speed_ms=3.0):
        self.max_speed = max_speed_ms
        self.last_lat = self.last_lon = self.last_ts = None
        self.filtered = 0
        self.total = 0

    def ingest(self, lat, lon, ts_seconds) -> bool:
        """返回 True 表示通过（合理），False 表示过滤"""
        self.total += 1
        if self.last_lat is None:
            self.last_lat, self.last_lon, self.last_ts = lat, lon, ts_seconds
            return True

        dt = ts_seconds - self.last_ts
        if dt <= 0:
            self.last_lat, self.last_lon, self.last_ts = lat, lon, ts_seconds
            return True  # 时间倒退，放行

        dist = haversine(lat, lon, self.last_lat, self.last_lon)
        speed = dist / dt
        if speed > self.max_speed:
            self.filtered += 1
            return False

        self.last_lat, self.last_lon, self.last_ts = lat, lon, ts_seconds
        return True

# ═══════════════════════════════════════════════════════════════
# 报告生成
# ═══════════════════════════════════════════════════════════════

def generate_report(devices: List[DeviceData]) -> str:
    lines = []
    a = lines.append

    a("# GPS 抖动数据治理 — 5 设备验证报告")
    a("")
    a(f"**数据源**: `20260713.txt`（blade 平台遥测历史）")
    a(f"**设备数**: {len(devices)}（一期楼顶静态点位，RTK 实测真值）")
    a(f"**采样间隔**: ~30 分钟")
    a("")

    # ── Part 1: 各设备统计 ──
    a("## 1. 原始数据统计")
    a("")
    a("| 设备EUI | 点位 | 记录数 | 唯一点 | 抖动直径 | 均值距RTK | 中值距RTK | P50 | P90 | P95 | max |")
    a("|---------|------|--------|--------|----------|-----------|-----------|-----|-----|-----|-----|")

    for ds in devices:
        if ds.count == 0: continue
        dists = ds.all_dists()
        mean_d = statistics.mean(dists)
        median_d = statistics.median(dists)
        p90_d = ds.dist_percentile(90)
        p95_d = ds.dist_percentile(95)
        max_d = max(dists)
        diam = ds.jitter_diameter()
        mean_center = (statistics.mean(ds.lats), statistics.mean(ds.lons))
        median_center = (statistics.median(ds.lats), statistics.median(ds.lons))
        mean_to_rtk = ds.dist_to_rtk(*mean_center)
        median_to_rtk = ds.dist_to_rtk(*median_center)

        a(f"| {ds.eui} | {ds.point} | {ds.count} | {len(set((r.lat,r.lon) for r in ds.records))} "
          f"| {diam:.0f}m | {mean_to_rtk:.1f}m | {median_to_rtk:.1f}m "
          f"| {median_d:.0f}m | {p90_d:.0f}m | {p95_d:.0f}m | {max_d:.0f}m |")

    a("")
    a("> **关键发现**: 大部分点到 RTK 的中位距离在 3-9m，但 P95 可达 30-100m+。")
    a("> 说明数据中存在少量大幅偏离的野点（可能由卫星几何劣化、多径效应导致），")
    a("> 拉高了抖动直径。**中值/百分位数比极值更能反映真实抖动特征。**")
    a("")

    # ── Part 2: 对比 gps_logs ──
    a("## 2. 与 gps_logs 数据对比")
    a("")
    a("| 数据源 | 设备 | 记录数 | 抖动直径 | 唯一点 | 特点 |")
    a("|--------|------|--------|----------|--------|------|")
    a("| `gps_logs` (DB) | HKT-11-01 (device 104) | 536 | 11m | 13 | 反复出现有限个离散位置 |")
    for ds in devices:
        if ds.count == 0: continue
        a(f"| `blade 平台` | {ds.eui} (点位{ds.point}) | {ds.count} | {ds.jitter_diameter():.0f}m "
          f"| {len(set((r.lat,r.lon) for r in ds.records))} | 几乎每个点都是唯一坐标 |")
    a("")
    a("> **差异原因分析**:")
    a("> 1. `gps_logs` 数据经过数据库层写入（可能截断精度），出现有限个离散值重复")
    a("> 2. blade 平台原始数据保留了更高精度的浮点值，每次上报坐标都略有不同")
    a("> 3. blade 平台的某些上报间隔异常（出现非整30分钟的采样），可能导致 GPS 芯片在不同卫星几何下锁定差异更大的位置")
    a("")

    # ── Part 3: 治理算法效果 ──
    a("## 3. 治理算法效果对比")
    a("")

    for ds in devices:
        if ds.count == 0: continue
        a(f"### 3.{devices.index(ds)+1} 设备 {ds.eui}（点位{ds.point}）")
        a("")
        a(f"- RTK 真值: `({ds.rtk_lat:.6f}, {ds.rtk_lon:.6f})`")
        a(f"- 记录数: {ds.count}")
        a(f"- 中值距 RTK: {statistics.median(ds.all_dists()):.1f}m")
        a("")
        a("#### 3a. EMA 稳定位置（不同阈值）")
        a("")
        a("| 阈值 | 位置更新 | 过滤率 | 最终位置 | 距RTK |")
        a("|------|----------|--------|----------|-------|")

        for th in [8, 10, 12, 15, 20, 30]:
            t = StablePositionEMA(threshold_m=th)
            for r in ds.records:
                t.ingest(r.lat, r.lon)
            fd = ds.dist_to_rtk(t.lat, t.lon)
            filter_rate = t.filtered / t.total * 100 if t.total else 0
            a(f"| {th}m | {t.updates} | {filter_rate:.0f}% "
              f"| `({t.lat:.6f}, {t.lon:.6f})` | {fd:.1f}m |")

        a("")
        a("#### 3b. 滑动窗口中值滤波")
        a("")
        a("| 窗口 | 输出均值距RTK | 输出中值距RTK |")
        a("|------|-------------|-------------|")
        for w in [3, 5, 7, 10]:
            sm = SlidingWindowMedian(window_size=w)
            outputs = [sm.ingest(r.lat, r.lon) for r in ds.records]
            out_dists = [ds.dist_to_rtk(o[0], o[1]) for o in outputs[w-1:]]
            if out_dists:
                a(f"| {w} | {statistics.mean(out_dists):.1f}m "
                  f"| {statistics.median(out_dists):.1f}m |")
        a("")

    # ── Part 4: 分层过滤策略 ──
    a("## 4. 推荐的治理策略")
    a("")
    a("基于以上分析，建议对 blade 平台 GPS 数据采用**三层过滤管道**：")
    a("")
    a("### Layer 1: 速度门控（Speed Gate）")
    a("- 过滤物理不可能的速度（如牛 > 3 m/s 的瞬间位移）")
    a("- 使用相邻点间的 haversine 距离 / 时间间隔计算速度")
    a("- 过滤掉极端野点（如突然跳到 200m 外再跳回来）")
    a("")
    a("### Layer 2: 滑动窗口中值滤波（Median Filter）")
    a("- 窗口大小 3-5 个点（1.5-2.5 小时）")
    a("- 对经度和纬度分别取中值")
    a("- 有效消除孤立野点，不模糊真实移动边界")
    a("")
    a("### Layer 3: EMA 稳定位置（Stable Position）")
    a("- 阈值基于设备 P90 抖动距离设定（建议 15-20m）")
    a("- 只有位移超过阈值才触发围栏检测")
    a("- 稳定位置用 EMA 微调，平滑小幅度漂移")
    a("")
    a("```")
    a("  blade平台GPS → [速度门控] → [中值滤波] → [EMA稳定位置] → 围栏检测")
    a("                    ↓ 野点丢弃       ↓ 去孤点        ↓ 去抖动")
    a("```")
    a("")

    # ── Part 5: 速度门控实际效果 ──
    a("## 5. 速度门控实际过滤量")
    a("")
    a("| 设备 | 总点数 | 过滤数 | 过滤率 | 最大速度 |")
    a("|------|--------|--------|--------|----------|")
    for ds in devices:
        if ds.count < 2: continue
        gate = SpeedGate(max_speed_ms=3.0)
        filtered = 0
        max_speed = 0
        records_sorted = sorted(ds.records, key=lambda r: r.timestamp)
        for i, r in enumerate(records_sorted):
            if i == 0:
                # 简单时间戳解析 (MM/DD/YYYY HH:MM:SS)
                parts = r.timestamp.split()
                if len(parts) == 2:
                    date_parts = parts[0].split('/')
                    time_parts = parts[1].split(':')
                    ts = (int(date_parts[2])*365*86400 + int(date_parts[0])*30*86400 +
                          int(date_parts[1])*86400 + int(time_parts[0])*3600 +
                          int(time_parts[1])*60 + int(time_parts[2]))
                else:
                    ts = 0
                gate.last_lat, gate.last_lon, gate.last_ts = r.lat, r.lon, ts
                gate.total += 1
                continue
            parts = r.timestamp.split()
            date_parts = parts[0].split('/')
            time_parts = parts[1].split(':')
            ts = (int(date_parts[2])*365*86400 + int(date_parts[0])*30*86400 +
                  int(date_parts[1])*86400 + int(time_parts[0])*3600 +
                  int(time_parts[1])*60 + int(time_parts[2]))
            dt = ts - gate.last_ts
            if dt > 0:
                dist = haversine(r.lat, r.lon, gate.last_lat, gate.last_lon)
                speed = dist / dt
                max_speed = max(max_speed, speed)
            passed = gate.ingest(r.lat, r.lon, ts)
            if not passed:
                filtered += 1

        a(f"| {ds.eui} | {ds.count} | {filtered} "
          f"| {filtered/ds.count*100:.0f}% | {max_speed:.1f} m/s |")

    a("")
    a("---")
    a("")
    a("## 结论")
    a("")
    a("1. **blade 平台原始数据比 gps_logs 抖动更大**（80-335m vs 11m），")
    a("   可能存在精度截断差异或上报间隔不均匀")
    a("2. **中值距 RTK 仅 3-9m**，说明大部分数据质量可用，问题在于野点")
    a("3. **三层过滤策略**可以有效治理：速度门控去野点 → 中值滤波平滑 → EMA 稳定位置用于围栏")
    a("4. **推荐阈值**: 滑动窗口 3-5 个点，EMA 阈值 15-20m")
    a("")

    return "\n".join(lines)


def main():
    filepath = sys.argv[1] if len(sys.argv) > 1 else "20260713.txt"
    output_json = "--json" in sys.argv

    devices = parse_file(filepath)

    if output_json:
        result = {}
        for ds in devices:
            if ds.count == 0: continue
            dists = ds.all_dists()
            result[ds.eui] = {
                "point": ds.point,
                "rtk": [ds.rtk_lat, ds.rtk_lon],
                "count": ds.count,
                "unique_positions": len(set((r.lat, r.lon) for r in ds.records)),
                "jitter_diameter_m": round(ds.jitter_diameter(), 1),
                "median_dist_to_rtk_m": round(statistics.median(dists), 1),
                "p90_dist_m": round(ds.dist_percentile(90), 1),
                "p95_dist_m": round(ds.dist_percentile(95), 1),
                "max_dist_m": round(max(dists), 1),
                "records": [{"ts": r.timestamp, "lat": r.lat, "lon": r.lon}
                           for r in ds.records]
            }
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(generate_report(devices))


if __name__ == "__main__":
    main()
