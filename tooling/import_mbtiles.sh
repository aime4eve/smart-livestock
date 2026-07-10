#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="${1:?Usage: $0 <remote-host> [remote-path]}"
REMOTE_PATH="${2:-/data/mbtiles}"
LOCAL_DIR="$(cd "$(dirname "$0")/.." && pwd)/smart-livestock-server/infrastructure/tileserver/data"

mkdir -p "$LOCAL_DIR"

# 1. rsync MBTiles + metadata
rsync -avz --progress "$REMOTE_HOST:$REMOTE_PATH/*.mbtiles" "$LOCAL_DIR/"
rsync -avz "$REMOTE_HOST:$REMOTE_PATH/*.metadata.json" "$LOCAL_DIR/"

# 2. 验证 MD5
for meta in "$LOCAL_DIR"/*.metadata.json; do
    mbtiles="${meta%.metadata.json}.mbtiles"
    [ -f "$mbtiles" ] || continue
    expected=$(python3 -c "import json; print(json.load(open('$meta'))['md5'])")
    actual=$(md5 -q "$mbtiles" 2>/dev/null || md5sum "$mbtiles" | cut -d' ' -f1)
    if [ "$expected" != "$actual" ]; then
        echo "MD5 mismatch for $mbtiles: expected $expected, got $actual"
        exit 1
    fi
    echo "OK: $mbtiles"
done

# 3. 自动生成 config.json + regions.json
python3 -c "
import json, glob, sqlite3, os
files = sorted(glob.glob('$LOCAL_DIR/*.mbtiles'))

data_sources = {}
for i, f in enumerate(files):
    key = 'v3' if i == 0 else os.path.splitext(os.path.basename(f))[0]
    data_sources[key] = {'mbtiles': os.path.basename(f)}
config = {'data': data_sources, 'options': {'port': 8080}}
json.dump(config, open('$LOCAL_DIR/config.json', 'w'), indent=2)

regions = []
for f in files:
    try:
        conn = sqlite3.connect(f)
        row = conn.execute(\"SELECT value FROM metadata WHERE name = 'bounds'\").fetchone()
        if row:
            bounds = [float(x) for x in row[0].split(',')]
            regions.append({'file': os.path.basename(f), 'bounds': bounds})
        conn.close()
    except Exception:
        pass
json.dump(regions, open('$LOCAL_DIR/regions.json', 'w'), indent=2)
print(f'config.json + regions.json updated: {list(data_sources.keys())}')
"

# 4. 重载 tileserver-gl
if command -v docker &> /dev/null; then
    docker kill --signal=SIGHUP $(docker ps -q --filter "ancestor=maptiler/tileserver-gl") 2>/dev/null || true
fi
echo "Import complete."

# 5. 同步 tile_regions 到数据库
API_URL="${API_URL:-http://172.22.1.123:18080/api/v1}"
API_KEY="${SMART_LIVESTOCK_API_KEY:-}"
if [ -z "$API_KEY" ] && [ -n "${API_KEY_FILE:-}" ]; then
    API_KEY=$(cat "$API_KEY_FILE" 2>/dev/null || true)
fi

if [ -z "$API_KEY" ]; then
    echo "Skipping DB sync: no API key. Set SMART_LIVESTOCK_API_KEY."
    exit 0
fi

echo "Syncing tile_regions to DB..."
fail_count=0
for f in "$LOCAL_DIR"/*.mbtiles; do
    base=$(basename "$f" .mbtiles)
    size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
    md5hash=$(md5 -q "$f" 2>/dev/null || md5sum "$f" | cut -d' ' -f1)
    bounds=$(python3 -c "import sqlite3; c=sqlite3.connect('$f'); r=c.execute(\"SELECT value FROM metadata WHERE name='bounds'\").fetchone(); print(r[0] if r else ''); c.close()")

    [ -z "$bounds" ] && continue
    IFS=',' read -r min_lon min_lat max_lon max_lat <<< "$bounds"

    payload=$(python3 -c "import json,sys; print(json.dumps({
        'name': sys.argv[1], 'minLon': float(sys.argv[2]), 'minLat': float(sys.argv[3]),
        'maxLon': float(sys.argv[4]), 'maxLat': float(sys.argv[5]),
        'fileName': sys.argv[1] + '.mbtiles', 'fileSize': int(sys.argv[6]),
        'md5': sys.argv[7], 'status': 'ready'
    }))" "$base" "$min_lon" "$min_lat" "$max_lon" "$max_lat" "$size" "$md5hash")
    if curl -sf -X POST "$API_URL/admin/tiles/regions" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload"; then
        echo "Synced: $base"
    else
        echo "Failed: $base"
        fail_count=$((fail_count + 1))
    fi
done

if [ "$fail_count" -gt 0 ]; then
    echo "WARNING: $fail_count region(s) failed to sync."
    exit 1
fi
echo "DB sync complete."
