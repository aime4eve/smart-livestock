#!/bin/sh
set -u
# P2 瓦片下载 worker：轮询 pending TileGenerationTask → generate_mbtiles → SIGHUP tileserver → 同步 region
API_URL="${API_URL:-http://app:8080/api/v1}"
API_KEY="${SMART_LIVESTOCK_API_KEY:-}"
OUTDIR="${OUTDIR:-/data/mbtiles}"
TILESERVER_IMAGE="${TILESERVER_IMAGE:-maptiler/tileserver-gl}"
POLL_INTERVAL="${POLL_INTERVAL:-60}"

if [ -z "$API_KEY" ]; then echo "FATAL: SMART_LIVESTOCK_API_KEY not set" >&2; exit 1; fi
mkdir -p "$OUTDIR"
echo "[worker] start: API=$API_URL OUTDIR=$OUTDIR interval=${POLL_INTERVAL}s"

sync_regions() {
  for f in "$OUTDIR"/*.mbtiles; do
    [ -f "$f" ] || continue
    base=$(basename "$f" .mbtiles)
    size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f")
    md5hash=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1 || md5 -r "$f" 2>/dev/null | cut -d' ' -f1)
    bounds=$(python3 -c "import sqlite3;c=sqlite3.connect('$f');r=c.execute(\"SELECT value FROM metadata WHERE name='bounds'\").fetchone();print(r[0] if r else '');c.close()" 2>/dev/null)
    [ -z "$bounds" ] && continue
    payload=$(python3 - "$base" "$bounds" "$size" "$md5hash" <<'PY'
import json,sys
base,bounds,size,md5=sys.argv[1:5]
mnlo,mnla,mxlo,mxla=[float(x) for x in bounds.split(',')]
print(json.dumps({'name':base,'minLon':mnlo,'minLat':mnla,'maxLon':mxlo,'maxLat':mxla,'fileName':base+'.mbtiles','fileSize':int(size),'md5':md5,'status':'ready'}))
PY
)
    if curl -sf -X POST "$API_URL/admin/tiles/regions" -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" -d "$payload" >/dev/null; then
      echo "  region synced: $base"
    else
      echo "  region sync FAILED: $base" >&2
    fi
  done
}

# Reclaim tasks left in 'running' by a previous worker instance (crash /
# restart / OOM). The worker main loop only polls 'pending', so without
# this a running task orphaned by a restart would never be picked up again.
# generate_mbtiles resumes from the existing .mbtiles file and skips tiles
# already downloaded, so the reclaim is cheap and idempotent.
echo "[worker] reclaiming stale running tasks..."
_reclaim_resp=$(curl -sf -H "X-API-Key: $API_KEY" "$API_URL/admin/tiles/tasks?status=running" 2>/dev/null || echo '')
for _tid in $(echo "$_reclaim_resp" | jq -r '.data // [] | .[].id' 2>/dev/null); do
  [ -z "$_tid" ] && continue
  if curl -sf -X PUT "$API_URL/admin/tiles/tasks/$_tid/status" \
      -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
      -d '{"status":"pending"}' >/dev/null 2>&1; then
    echo "[worker] reclaimed task $_tid (running -> pending)"
  fi
done

while true; do
  resp=$(curl -sf -H "X-API-Key: $API_KEY" "$API_URL/admin/tiles/tasks?status=pending" 2>/dev/null || echo '')
  task_ids=$(echo "$resp" | jq -r '.data // [] | .[].id' 2>/dev/null || true)
  for tid in $task_ids; do
    [ -z "$tid" ] && continue
    echo "[$(date '+%F %T')] === task $tid ==="
    if python3 /tooling/generate_mbtiles.py --task-id "$tid" --outdir "$OUTDIR" --api-url "$API_URL" --server "${TILE_SERVER:-osm_de}"; then
     python3 -c "import json,glob,os;f=sorted(glob.glob('$OUTDIR/*.mbtiles'));d={os.path.splitext(os.path.basename(x))[0]:{'mbtiles':os.path.basename(x)} for x in f};json.dump({'data':d,'options':{'port':8080}},open('$OUTDIR/config.json','w'),indent=2);print('  config.json sources:',list(d))"
      # Reload tileserver to pick up new config.json. tileserver-gl has no
      # hot-reload, so a container restart is required. This depends on:
      #   1. /var/run/docker.sock mounted into the worker (see docker-compose)
      #   2. docker CLI available in the worker image
      #   3. container name matching "tileserver" (compose generates
      #      smart-livestock-server-tileserver-1, filter still matches)
     cid=$(docker ps -q --filter "name=tileserver" 2>/dev/null | head -1)
      if [ -n "$cid" ]; then docker restart "$cid" >/dev/null 2>&1 && echo "  tileserver restarted ($cid) to load config.json" && sleep 5; fi
      sync_regions
    else
      echo "[$(date '+%F %T')] task $tid generate failed (status 已由脚本标记 failed)" >&2
    fi
  done
  sleep "$POLL_INTERVAL"
done
