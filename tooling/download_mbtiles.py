#!/usr/bin/env python3
"""从 OSM CDN 下载瓦片并打包成 MBTiles。

用法（从项目根目录执行）：
    python3 tooling/download_mbtiles.py --bbox 112.8,28.1,113.1,28.4 --zoom 11-15 --output changsha.mbtiles
"""
import argparse, math, os, sqlite3, time
from urllib.request import urlopen, Request


def lat_lon_to_tile(lat, lon, zoom):
    n = 2 ** zoom
    x = int((lon + 180) / 360 * n)
    lat_rad = math.radians(lat)
    y = int((1 - math.asinh(math.tan(lat_rad)) / math.pi) / 2 * n)
    return max(0, min(x, n - 1)), max(0, min(y, n - 1))


def download_mbtiles(bbox, zoom_range, output):
    min_lon, min_lat, max_lon, max_lat = [float(v) for v in bbox.split(",")]
    min_zoom, max_zoom = [int(v) for v in zoom_range.split("-")]
    if os.path.exists(output):
        os.remove(output)
    conn = sqlite3.connect(output)
    conn.execute("CREATE TABLE metadata (name text, value text)")
    conn.execute("CREATE TABLE tiles (zoom_level int, tile_column int, tile_row int, tile_data blob)")
    conn.execute("CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row)")
    conn.execute("INSERT INTO metadata VALUES ('name', ?)", (os.path.basename(output),))
    conn.execute("INSERT INTO metadata VALUES ('format', 'png')")
    conn.execute("INSERT INTO metadata VALUES ('bounds', ?)", (f"{min_lon},{min_lat},{max_lon},{max_lat}",))
    conn.commit()
    done, errors, total = 0, 0, 0
    for z in range(min_zoom, max_zoom + 1):
        x0, y0 = lat_lon_to_tile(max_lat, min_lon, z)
        x1, y1 = lat_lon_to_tile(min_lat, max_lon, z)
        total += (x1 - x0 + 1) * (y1 - y0 + 1)
    print(f"Total: {total} tiles to download")
    for z in range(min_zoom, max_zoom + 1):
        x0, y0 = lat_lon_to_tile(max_lat, min_lon, z)
        x1, y1 = lat_lon_to_tile(min_lat, max_lon, z)
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                tms_y = (2 ** z - 1) - y
                url = f"https://tile.openstreetmap.org/{z}/{x}/{y}.png"
                try:
                    req = Request(url, headers={"User-Agent": "SmartLivestock/1.0"})
                    data = urlopen(req, timeout=10).read()
                    conn.execute("INSERT INTO tiles VALUES (?, ?, ?, ?)", (z, x, tms_y, data))
                except Exception as e:
                    errors += 1
                    if errors <= 10:
                        print(f"  ERR {url}: {e}")
                done += 1
                if done % 50 == 0:
                    conn.commit()
                    print(f"  {done}/{total} ({errors} errors)")
                time.sleep(0.3)
        conn.commit()
    conn.commit()
    conn.close()
    print(f"Done: {output} ({done - errors}/{total}, {errors} errors, {os.path.getsize(output) / 1024 / 1024:.1f} MB)")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--bbox", required=True, help="min_lon,min_lat,max_lon,max_lat")
    p.add_argument("--zoom", default="11-15")
    p.add_argument("--output", required=True)
    a = p.parse_args()
    download_mbtiles(a.bbox, a.zoom, a.output)
