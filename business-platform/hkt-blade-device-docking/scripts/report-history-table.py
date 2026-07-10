#!/usr/bin/env python3
"""Fetch all uplink records for a device from blade and output a time-sorted
table of GPS coordinates, step counts, and 3-axis accelerometer values
(raw + g + tilt angles + activity classification).

Usage: python3 report-history-table.py <device_id> <device_host> <device_port> <token> <tenant_id>
"""
import sys
import json
import datetime
import math
import urllib.request
import urllib.parse
import statistics

if len(sys.argv) != 6:
    print("Usage: report-history-table.py <device_id> <host> <port> <token> <tenant_id>")
    sys.exit(1)

device_id, host, port, token, tenant_id = sys.argv[1:6]
base_url = f"http://{host}:{port}"

# LIS3DH ±2g Low Power mode (8-bit), ~4mg/digit (firmware confirmed)
MG_PER_DIGIT = 4.0

def to_g(raw):
    signed = raw - 65536 if raw > 32767 else raw
    return signed * MG_PER_DIGIT / 1000.0

def fetch_page(page, size=100):
    params = urllib.parse.urlencode({
        "deviceId": device_id,
        "current": page,
        "size": size,
    })
    url = f"{base_url}/device/report-record/page?{params}"
    req = urllib.request.Request(url, headers={
        "token": token,
        "Tenant-Id": tenant_id,
    })
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))

# paginate
all_records = []
page = 1
total = 0
while True:
    data = fetch_page(page)
    page_data = data.get("data") or {}
    total = page_data.get("total", 0)
    records = page_data.get("records") or []
    if not records:
        break
    all_records.extend(records)
    if len(all_records) >= total:
        break
    page += 1

# extract rows
rows = []
for r in all_records:
    try:
        dd = json.loads(r["decodeData"])["properties"]["properties"]
    except (json.JSONDecodeError, KeyError, TypeError):
        continue
    raw_x = dd.get("xAxisDirectionAccelerationValue", 0)
    raw_y = dd.get("yAxisDirectionAccelerationValue", 0)
    raw_z = dd.get("zAxisDirectionAccelerationValue", 0)
    gx = to_g(raw_x)
    gy = to_g(raw_y)
    gz = to_g(raw_z)
    mag = math.sqrt(gx**2 + gy**2 + gz**2)
    mi = abs(mag - 1.0)
    roll = math.degrees(math.atan2(gy, gz))
    pitch = math.degrees(math.atan2(-gx, math.sqrt(gy**2 + gz**2)))
    rows.append((
        r.get("reportTime", ""),
        dd.get("latitude", ""),
        dd.get("longitude", ""),
        dd.get("stepNumber", ""),
        gx, gy, gz, mag, mi,
        roll, pitch,
        raw_x, raw_y, raw_z,
    ))

# sort chronologically (MM/DD/YYYY HH:MM:SS)
rows.sort(key=lambda x: datetime.datetime.strptime(x[0], "%m/%d/%Y %H:%M:%S"))

# summary stats
stationary = [r for r in rows if r[3] == 0]
active = [r for r in rows if r[3] and r[3] > 0]

# print table with g values + tilt + activity
print(f"  Device: {device_id}  |  Total records: {len(rows)}  |  Sensor: LIS3DH ±2g Low Power 8-bit (~4mg/digit)")
if stationary:
    sm = statistics.mean([r[7] for r in stationary]) if len(stationary) > 1 else stationary[0][7]
    print(f"  Stationary: {len(stationary)} samples, mean|mag|={sm:.3f}g", end="")
    if active:
        am = statistics.mean([r[7] for r in active]) if len(active) > 1 else active[0][7]
        print(f"  |  Active: {len(active)} samples, mean|mag|={am:.3f}g ({am/sm:.2f}x)")
    else:
        print()
print()

# Table 1: GPS + Steps + Acceleration (g values + tilt)
print(f"  {'ReportTime':<20} {'Lat':>6} {'Lon':>6} {'Step':>4} | {'AccX(g)':>8} {'AccY(g)':>8} {'AccZ(g)':>8} {'|Mag|':>6} {'Roll':>6} {'Pitch':>6} {'Activity':>8}")
print(f"  {'-'*20} {'-'*6} {'-'*6} {'-'*4} | {'-'*8} {'-'*8} {'-'*8} {'-'*6} {'-'*6} {'-'*6} {'-'*8}")
for ts, lat, lon, steps, gx, gy, gz, mag, mi, roll, pitch, rx, ry, rz in rows:
    if mag < 1.15: activity = "rest"
    elif mag < 1.5: activity = "light"
    elif mag < 2.5: activity = "active"
    else: activity = "intense"
    print(f"  {ts:<20} {str(lat):>6} {str(lon):>6} {str(steps):>4} | {gx:>8.3f} {gy:>8.3f} {gz:>8.3f} {mag:>5.3f}g {roll:>5.1f}d {pitch:>5.1f}d {activity:>8}")
