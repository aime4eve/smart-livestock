#!/usr/bin/env python3
"""Generate a sample MBTiles file for offline map tech spike testing.

Downloads tiles from OSM CDN for a small area around Changsha (zoom 12-14)
and writes them to MBTiles SQLite format.

Usage:
    python3 generate_sample_mbtiles.py [output_path]

Output defaults to ../assets/map/sample.mbtiles
"""

import math
import os
import sqlite3
import sys
import time
import urllib.request

# Changsha center
CENTER_LAT = 28.2282
CENTER_LON = 112.9388
MIN_ZOOM = 12
MAX_ZOOM = 14

TILE_URL = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
OUTPUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(__file__), "..", "assets", "map", "sample.mbtiles"
)


def lat_lon_to_tile(lat, lon, zoom):
    x = int((lon + 180) / 360 * (2 ** zoom))
    y = int(
        (1 - math.log(math.tan(math.radians(lat)) + 1 / math.cos(math.radians(lat))) / math.pi)
        / 2 * (2 ** zoom)
    )
    return x, y


def download_tile(z, x, y, retries=2):
    url = TILE_URL.format(z=z, x=x, y=y)
    for attempt in range(retries + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "SmartLivestock/0.1"})
            with urllib.request.urlopen(req, timeout=15) as resp:
                return resp.read()
        except Exception:
            if attempt < retries:
                time.sleep(1)
    return None


def generate():
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    if os.path.exists(OUTPUT):
        os.remove(OUTPUT)

    db = sqlite3.connect(OUTPUT)
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("CREATE TABLE metadata (name TEXT, value TEXT)")
    db.execute(
        "CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB)"
    )
    db.execute(
        "CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row)"
    )

    # Calculate tile ranges per zoom
    all_tiles = []
    for z in range(MIN_ZOOM, MAX_ZOOM + 1):
        cx, cy = lat_lon_to_tile(CENTER_LAT, CENTER_LON, z)
        # Small radius: 1 tile at z12, 2 at z13, 3 at z14
        radius = z - MIN_ZOOM + 1
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                all_tiles.append((z, cx + dx, cy + dy))

    print(f"Downloading {len(all_tiles)} tiles (zoom {MIN_ZOOM}-{MAX_ZOOM})...")

    downloaded = 0
    for z, x, y in all_tiles:
        data = download_tile(z, x, y)
        if data:
            # MBTiles uses TMS Y: flip Y axis
            tms_y = (2 ** z - 1) - y
            db.execute(
                "INSERT OR IGNORE INTO tiles (zoom_level, tile_column, tile_row, tile_data) VALUES (?, ?, ?, ?)",
                (z, x, tms_y, data),
            )
            downloaded += 1
            if downloaded % 10 == 0:
                print(f"  {downloaded}/{len(all_tiles)}")
                db.commit()
        time.sleep(0.3)  # Respect OSM tile usage policy

    # Metadata
    bounds = f"{CENTER_LON - 0.08},{CENTER_LAT - 0.06},{CENTER_LON + 0.08},{CENTER_LAT + 0.06}"
    for name, value in [
        ("name", "smart-livestock-sample"),
        ("format", "png"),
        ("bounds", bounds),
        ("minzoom", str(MIN_ZOOM)),
        ("maxzoom", str(MAX_ZOOM)),
        ("attribution", "© OpenStreetMap contributors"),
    ]:
        db.execute("INSERT INTO metadata (name, value) VALUES (?, ?)", (name, value))

    db.commit()

    count = db.execute("SELECT COUNT(*) FROM tiles").fetchone()[0]
    db.close()

    size_mb = os.path.getsize(OUTPUT) / (1024 * 1024)
    print(f"\nDone: {count} tiles, {size_mb:.1f} MB → {OUTPUT}")


if __name__ == "__main__":
    generate()
