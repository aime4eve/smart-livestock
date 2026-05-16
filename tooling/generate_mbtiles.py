#!/usr/bin/env python3
"""按 bbox + zoom 范围从 OSM Planet 数据生成 MBTiles 文件。

用法：
    python generate_mbtiles.py --bbox 112.8,28.1,113.1,28.4 --zoom 11-15 --output changsha.mbtiles
"""
import argparse
import json
import hashlib
import subprocess
import sqlite3
from datetime import datetime, timezone
from pathlib import Path


def generate_mbtiles(bbox: str, zoom: str, output: str):
    min_lon, min_lat, max_lon, max_lat = [float(x) for x in bbox.split(",")]
    min_zoom, max_zoom = [int(x) for x in zoom.split("-")]

    subprocess.run([
        "render_list",
        "-n", "4",
        "-z", str(min_zoom), "-Z", str(max_zoom),
        "-a", f"{min_lat},{min_lon},{max_lat},{max_lon}",
        "-o", output,
    ], check=True)

    mbtiles = Path(output)
    file_hash = hashlib.md5(mbtiles.read_bytes()).hexdigest()
    conn = sqlite3.connect(output)
    cur = conn.execute("SELECT COUNT(*) FROM tiles")
    tile_count = cur.fetchone()[0]
    conn.close()

    metadata = {
        "name": mbtiles.stem,
        "bounds": [min_lon, min_lat, max_lon, max_lat],
        "minzoom": min_zoom,
        "maxzoom": max_zoom,
        "tile_count": tile_count,
        "md5": file_hash,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }
    mbtiles.with_suffix(".metadata.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )
    print(f"Generated: {output} ({tile_count} tiles, {mbtiles.stat().st_size / 1024 / 1024:.1f} MB)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bbox", required=True, help="min_lon,min_lat,max_lon,max_lat")
    parser.add_argument("--zoom", default="11-15")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    generate_mbtiles(args.bbox, args.zoom, args.output)
