#!/usr/bin/env python3
"""从在线瓦片服务下载指定区域瓦片并打包为 MBTiles。

用法：
    # 单区域模式
    python3 tooling/generate_mbtiles.py --bbox 112.8,28.1,113.1,28.4 --zoom 11-15 --output changsha.mbtiles

    # 计划模式：按计划文件批量下载，自动更新完成状态
    python3 tooling/generate_mbtiles.py --plan tooling/tile-download-plan.json --outdir tooling/mbtiles

    # 任务模式：从 API 读取任务参数，生成后回调更新状态
    export SMART_LIVESTOCK_API_KEY="sk_live_xxxxx"
    python3 tooling/generate_mbtiles.py --task-id 7

支持断点续传：对已存在的 .mbtiles 文件会跳过已下载的瓦片。
"""
import argparse
import json
import math
import os
import sqlite3
import sys
import time
from datetime import datetime, timezone
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

TILE_SERVERS = {
    "osm": "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    "osm_de": "https://tile.openstreetmap.de/{z}/{x}/{y}.png",
}


def lat_lon_to_tile(lat, lon, zoom):
    n = 1 << zoom
    x = int((lon + 180) / 360 * n)
    lat_rad = math.radians(lat)
    y = int((1 - math.asinh(math.tan(lat_rad)) / math.pi) / 2 * n)
    return max(0, min(x, n - 1)), max(0, min(y, n - 1))


def estimate_tile_count(bbox, zoom_range):
    min_lon, min_lat, max_lon, max_lat = [float(v) for v in bbox.split(",")]
    min_zoom, max_zoom = [int(v) for v in zoom_range.split("-")]
    total = 0
    for z in range(min_zoom, max_zoom + 1):
        x0, y0 = lat_lon_to_tile(max_lat, min_lon, z)
        x1, y1 = lat_lon_to_tile(min_lat, max_lon, z)
        total += (x1 - x0 + 1) * (y1 - y0 + 1)
    return total


def open_mbtiles(path):
    existing = os.path.exists(path)
    conn = sqlite3.connect(path)
    conn.execute("CREATE TABLE IF NOT EXISTS metadata (name TEXT, value TEXT, UNIQUE (name))")
    conn.execute(
        "CREATE TABLE IF NOT EXISTS tiles "
        "(zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB, "
        "UNIQUE (zoom_level, tile_column, tile_row))"
    )
    conn.execute("CREATE INDEX IF NOT EXISTS tile_index ON tiles (zoom_level, tile_column, tile_row)")
    if not existing:
        conn.execute("INSERT INTO metadata VALUES ('format', 'png')")
        conn.execute("INSERT INTO metadata VALUES ('type', 'baselayer')")
        conn.execute("INSERT INTO metadata VALUES ('version', '1')")
        conn.execute("INSERT INTO metadata VALUES ('attribution', '&copy; OpenStreetMap contributors')")
    conn.commit()
    return conn


def download_tile(url, retries=3):
    for attempt in range(retries):
        try:
            req = Request(url, headers={"User-Agent": "SmartLivestock/1.0"})
            with urlopen(req, timeout=30) as resp:
                if resp.status == 200:
                    return resp.read()
                if resp.status == 429:
                    wait = 2 ** (attempt + 1)
                    print(f"    Rate limited, waiting {wait}s...", flush=True)
                    time.sleep(wait)
                    continue
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1)
            else:
                print(f"    Failed {url}: {e}", flush=True)
    return None


class RuntimeTimeout(Exception):
    pass


def generate_mbtiles(bbox, zoom_range, output, server="osm", rate=1.0, deadline=None, progress_callback=None):
    min_lon, min_lat, max_lon, max_lat = [float(v) for v in bbox.split(",")]
    min_zoom, max_zoom = [int(v) for v in zoom_range.split("-")]
    template = TILE_SERVERS.get(server)
    if not template:
        print(f"Unknown server '{server}'. Available: {', '.join(TILE_SERVERS)}", file=sys.stderr)
        sys.exit(1)

    conn = open_mbtiles(output)
    existing = conn.execute("SELECT COUNT(*) FROM tiles").fetchone()[0]
    if existing:
        print(f"  Resuming ({existing} tiles already present)")

    total = 0
    for z in range(min_zoom, max_zoom + 1):
        x0, y0 = lat_lon_to_tile(max_lat, min_lon, z)
        x1, y1 = lat_lon_to_tile(min_lat, max_lon, z)
        total += (x1 - x0 + 1) * (y1 - y0 + 1)
    print(f"  Total: ~{total} tiles across z{min_zoom}-z{max_zoom}")

    done, errors, skipped = 0, 0, 0
    try:
        for z in range(min_zoom, max_zoom + 1):
            x0, y0 = lat_lon_to_tile(max_lat, min_lon, z)
            x1, y1 = lat_lon_to_tile(min_lat, max_lon, z)
            cols, rows = x1 - x0 + 1, y1 - y0 + 1
            zoom_total = cols * rows
            zoom_done = 0
            print(f"  z{z}: {cols}x{rows} = {zoom_total} tiles", flush=True)

            for x in range(x0, x1 + 1):
                for y in range(y0, y1 + 1):
                    if deadline and time.time() >= deadline:
                        raise RuntimeTimeout()

                    tms_y = (1 << z) - 1 - y
                    if conn.execute(
                        "SELECT 1 FROM tiles WHERE zoom_level=? AND tile_column=? AND tile_row=?",
                        (z, x, tms_y),
                    ).fetchone():
                        skipped += 1
                        zoom_done += 1
                        continue

                    url = template.replace("{z}", str(z)).replace("{x}", str(x)).replace("{y}", str(y))
                    data = download_tile(url)
                    if data:
                        conn.execute(
                            "INSERT OR REPLACE INTO tiles VALUES (?, ?, ?, ?)",
                            (z, x, tms_y, data),
                        )
                        done += 1
                    else:
                        errors += 1

                    zoom_done += 1
                    if zoom_done % 50 == 0 or zoom_done == zoom_total:
                        pct = zoom_done / zoom_total * 100
                        print(f"    z{z}: {zoom_done}/{zoom_total} ({pct:.0f}%)", flush=True)
                        if progress_callback:
                            progress_callback(f"z{z} {zoom_done}/{zoom_total} ({pct:.0f}%)")
                    if rate > 0:
                        time.sleep(rate)

            conn.commit()
    except RuntimeTimeout:
        conn.commit()
        print("  Runtime limit reached, progress saved.")
    except KeyboardInterrupt:
        conn.commit()
        print("\n  Interrupted, progress saved.")

    tile_count = done + existing
    size_mb = os.path.getsize(output) / (1024 * 1024)
    print(f"  Result: {done} downloaded, {skipped} skipped, {errors} errors")
    print(f"  File: {output} ({size_mb:.1f} MB, {tile_count} tiles)")

    conn.close()
    return {"tile_count": tile_count, "size_mb": round(size_mb, 2), "errors": errors}


def run_plan(plan_path, outdir, server="osm", rate=1.0, dry_run=False, max_runtime=None):
    with open(plan_path, "r", encoding="utf-8") as f:
        plan = json.load(f)

    regions = plan["regions"]
    print(f"Plan: {plan['name']}")
    print(f"Regions: {len(regions)}")

    if dry_run:
        print(f"\n{'ID':<25} {'Name':<20} {'Zoom':<8} {'Est.Tiles':>10} {'Status':<10} {'Note'}")
        print("-" * 95)
        total_all = 0
        for r in regions:
            est = estimate_tile_count(r["bbox"], r["zoom"])
            total_all += est
            status = r.get("status", "pending")
            note = r.get("note", "")
            print(f"{r['id']:<25} {r['name']:<20} {r['zoom']:<8} {est:>10,} {status:<10} {note}")
        print(f"\nTotal estimated: {total_all:,} tiles (~{total_all * rate / 3600:.1f}h at {rate}s/tile)")
        return

    deadline = time.time() + max_runtime * 60 if max_runtime else None
    if deadline:
        eta = datetime.fromtimestamp(deadline).strftime("%H:%M:%S")
        print(f"Max runtime: {max_runtime} minutes (deadline: {eta})")

    os.makedirs(outdir, exist_ok=True)
    completed = sum(1 for r in regions if r.get("status") == "done")
    print(f"Already completed: {completed}/{len(regions)}")

    timed_out = False
    for i, r in enumerate(regions):
        if r.get("status") == "done":
            print(f"\n[{i+1}/{len(regions)}] SKIP {r['name']} (already done)")
            continue
        if timed_out:
            print(f"\n[{i+1}/{len(regions)}] SKIP {r['name']} (runtime limit reached)")
            continue

        output = os.path.join(outdir, f"{r['id']}.mbtiles")
        print(f"\n[{i+1}/{len(regions)}] {r['name']} — {r['bbox']} z{r['zoom']}")
        print(f"  Output: {output}")

        try:
            result = generate_mbtiles(r["bbox"], r["zoom"], output, server, rate, deadline)
            if deadline and time.time() >= deadline:
                r["status"] = "partial"
                r["tile_count"] = result["tile_count"]
                r["file_size_mb"] = result["size_mb"]
                timed_out = True
                print(f"  Runtime limit reached after finishing region.")
            else:
                r["status"] = "done"
                r["tile_count"] = result["tile_count"]
                r["file_size_mb"] = result["size_mb"]
                r["completed_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        except KeyboardInterrupt:
            r["status"] = "interrupted"
            with open(plan_path, "w", encoding="utf-8") as f:
                json.dump(plan, f, indent=2, ensure_ascii=False)
            print("\n\nInterrupted. Progress saved. Re-run to resume.")
            sys.exit(1)
        except Exception as e:
            r["status"] = "failed"
            r["error"] = str(e)
            print(f"  FAILED: {e}")

        with open(plan_path, "w", encoding="utf-8") as f:
            json.dump(plan, f, indent=2, ensure_ascii=False)
        print(f"  Plan updated: {r['id']} → {r['status']}")

    done_count = sum(1 for r in regions if r.get("status") == "done")
    partial_count = sum(1 for r in regions if r.get("status") == "partial")
    fail_count = sum(1 for r in regions if r.get("status") == "failed")
    pending_count = len(regions) - done_count - partial_count - fail_count
    print(f"\n{'='*50}")
    print(f"Session result: {done_count} done, {partial_count} partial, {fail_count} failed, {pending_count} pending")
    if pending_count > 0:
        print(f"Re-run the same command to continue.")


# --- Task-driven mode ---

def _resolve_api_key(args):
    key = os.environ.get("SMART_LIVESTOCK_API_KEY")
    if key:
        return key
    if args.api_key_file:
        try:
            with open(args.api_key_file, "r") as f:
                return f.read().strip()
        except FileNotFoundError:
            print(f"API key file not found: {args.api_key_file}", file=sys.stderr)
            sys.exit(1)
    if args.api_key:
        print("WARNING: --api-key exposes key in process list. Use env var or --api-key-file instead.", file=sys.stderr)
        return args.api_key
    print("No API key. Set SMART_LIVESTOCK_API_KEY, --api-key-file, or --api-key.", file=sys.stderr)
    sys.exit(1)


def _api_call(url, api_key, method="GET", body=None):
    data = json.dumps(body).encode("utf-8") if body else None
    req = Request(url, data=data, method=method)
    req.add_header("X-API-Key", api_key)
    req.add_header("Content-Type", "application/json")
    try:
        with urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except HTTPError as e:
        body_text = e.read().decode("utf-8", errors="replace")
        print(f"API error {e.code}: {body_text}", file=sys.stderr)
        raise
    except URLError as e:
        print(f"API connection error: {e}", file=sys.stderr)
        raise


def run_task_mode(args):
    api_key = _resolve_api_key(args)
    api_url = args.api_url.rstrip("/")
    task_url = f"{api_url}/admin/tiles/tasks/{args.task_id}"

    # 1. Fetch task details
    print(f"Fetching task {args.task_id}...")
    resp = _api_call(task_url, api_key)
    task = resp.get("data", resp)

    region_name = task.get("regionName", f"task-{args.task_id}")
    min_lon = task.get("minLon")
    min_lat = task.get("minLat")
    max_lon = task.get("maxLon")
    max_lat = task.get("maxLat")
    min_zoom = task.get("minZoom", 11)
    max_zoom = task.get("maxZoom", 15)

    if None in (min_lon, min_lat, max_lon, max_lat):
        print(f"Task {args.task_id} missing bbox coordinates", file=sys.stderr)
        sys.exit(1)

    bbox = f"{min_lon},{min_lat},{max_lon},{max_lat}"
    zoom = f"{min_zoom}-{max_zoom}"
    output = os.path.join(args.outdir, f"{region_name}.mbtiles")

    print(f"Task {args.task_id}: {region_name}")
    print(f"  bbox={bbox}, zoom={zoom}")
    print(f"  output={output}")

    # 2. Mark running
    _api_call(f"{task_url}/status", api_key, method="PUT",
              body={"status": "running"})
    print("Status → running")

    # 3. Generate
    def _report_progress(text):
        try:
            _api_call(f"{task_url}/status", api_key, method="PUT",
                      body={"status": "running", "progress": text})
        except Exception:
            pass

    try:
        os.makedirs(args.outdir, exist_ok=True)
        result = generate_mbtiles(bbox, zoom, output, args.server, args.rate,
                                  progress_callback=_report_progress)

        # 4. Mark done
        _api_call(f"{task_url}/status", api_key, method="PUT",
                  body={"status": "done", "tileCount": result["tile_count"],
                        "fileSizeMb": result["size_mb"]})
        print(f"Status → done ({result['tile_count']} tiles, {result['size_mb']} MB)")

    except Exception as e:
        # 5. Mark failed
        try:
            _api_call(f"{task_url}/status", api_key, method="PUT",
                      body={"status": "failed", "errorMessage": str(e)})
        except Exception:
            pass
        print(f"Status → failed: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description="Download tiles and package as MBTiles")
    p.add_argument("--plan", help="plan JSON file for batch download")
    p.add_argument("--outdir", default="tooling/mbtiles", help="output directory (default: tooling/mbtiles)")
    p.add_argument("--dry-run", action="store_true", help="preview plan without downloading")
    p.add_argument("--max-runtime", type=float, default=0, help="max runtime in minutes (0=unlimited)")
    p.add_argument("--bbox", help="min_lon,min_lat,max_lon,max_lat")
    p.add_argument("--zoom", default="11-15", help="zoom range (default: 11-15)")
    p.add_argument("--output", help="output .mbtiles file (single region mode)")
    p.add_argument("--server", default="osm", choices=list(TILE_SERVERS.keys()), help="tile server")
    p.add_argument("--rate", type=float, default=1.0, help="delay between requests in seconds")
    # Task-driven mode
    p.add_argument("--task-id", type=int, help="task ID from tile_generation_tasks (API-driven mode)")
    p.add_argument("--api-url", default="http://172.22.1.123:18080/api/v1", help="backend API base URL")
    p.add_argument("--api-key-file", help="file path containing API key")
    p.add_argument("--api-key", help="API key directly (NOT recommended for production)")
    args = p.parse_args()

    if args.task_id:
        run_task_mode(args)
    elif args.plan:
        run_plan(args.plan, args.outdir, args.server, args.rate, args.dry_run, args.max_runtime or None)
    elif args.bbox and args.output:
        generate_mbtiles(args.bbox, args.zoom, args.output, args.server, args.rate)
    else:
        p.print_help()
        sys.exit(1)
