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

# tileserver-gl v5: each MBTiles is a separate data source with string mbtiles path
# First file is always named 'v3' for nginx/Flutter backward compatibility
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
