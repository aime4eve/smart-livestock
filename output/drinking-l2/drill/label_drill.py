#!/usr/bin/env python3
"""T6 marking-loop drill (NIX-256, spec §15): label events via the farm
APIs as a farmer would, driven by the backfill ground truth.

Lanes exercised:
- detected events matching a planted bout  -> PATCH CONFIRMED
- ALGORITHM_CANDIDATE matching a borderline bout -> PATCH CONFIRMED (promotion)
- ALGORITHM_CANDIDATE matching nothing     -> PATCH REJECTED
- 3 missed planted bouts (the "other-FN" set) -> POST manual (source=MANUAL)

Usage: label_drill.py <export.csv> <truth.csv>

Execution note (2026-10-05): in the actual drill the 3 MANUAL entries were
posted by an ad-hoc script of identical logic (same [:16] minute-precision
timestamp format); this file is the reproducible version retroactively
placed here after the drill.
"""
import csv
import json
import sys
import urllib.request
from datetime import timedelta

BASE = "http://localhost:8080/api/v1"
OWNER_PHONE, OWNER_PASS = "13800138000", "123"


def api(method, path, token, body=None):
    req = urllib.request.Request(BASE + path, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    data = json.dumps(body).encode() if body is not None else None
    try:
        with urllib.request.urlopen(req, data=data) as r:
            return r.status, json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:200]


def main():
    export_csv, truth_csv = sys.argv[1], sys.argv[2]
    status, resp = api("POST", "/auth/login", None, {"phone": OWNER_PHONE, "password": OWNER_PASS})
    assert status == 200, resp
    token = resp["data"]["accessToken"]
    print("owner login ok")

    with open(export_csv, encoding="utf-8-sig") as f:
        events = list(csv.DictReader(f))
    truth = []
    with open(truth_csv) as f:
        for r in csv.DictReader(f):
            truth.append({
                "device_id": int(r["device_id"]),
                "livestock_id": int(r["livestock_id"]),
                "farm_id": int(r["farm_id"]),
                "start": r["bout_start"],  # Shanghai wall clock
            })
    from datetime import datetime
    for t in truth:
        t["dt"] = datetime.fromisoformat(t["start"]).replace(tzinfo=None)

    stats = {"confirmed": 0, "promoted": 0, "rejected": 0, "manual": 0, "patch_fail": 0, "manual_fail": 0}
    unmatched_truth = []

    def nearest_truth_center(dev, start_iso, end_iso):
        s = datetime.fromisoformat(start_iso).replace(tzinfo=None)  # Shanghai wall == truth axis
        e = datetime.fromisoformat(end_iso).replace(tzinfo=None)
        c = s + (e - s) / 2
        best, bd = None, 1e9
        for t in truth:
            if t["device_id"] != dev:
                continue
            d = abs((t["dt"] - c).total_seconds()) / 60
            if d < bd:
                best, bd = t, d
        return best, bd

    # 1-2. label every exported row
    for ev in events:
        dev, lid = int(ev["device_id"]), int(ev["livestock_id"])
        t, dist = nearest_truth_center(dev, ev["event_start_at"], ev["event_end_at"])
        matched = t is not None and dist <= 20
        if ev["source"] == "ALGORITHM_CANDIDATE":
            label = "CONFIRMED" if matched else "REJECTED"
            key = "promoted" if matched else "rejected"
        else:
            label = "CONFIRMED" if matched else "REJECTED"
            key = "confirmed" if matched else "rejected"
        code, resp = api("PATCH",
                         f"/farms/1/livestock/{lid}/drinking-events/{ev['id']}/label",
                         token, {"label": label})
        if code == 200:
            stats[key] += 1
        else:
            stats["patch_fail"] += 1
            if stats["patch_fail"] <= 3:
                print("PATCH fail", ev["id"], code, resp)

    # 3. manual entries: pick 3 FN bouts (heuristic: any truth bout is fine if
    # no detection lies within 30 min — reuse nearest over events)
    dev_events = {}
    for ev in events:
        dev_events.setdefault(int(ev["device_id"]), []).append(ev)
    picked = 0
    for t in truth:
        if picked >= 3:
            break
        evs = dev_events.get(t["device_id"], [])
        near = False
        for ev in evs:
            s = datetime.fromisoformat(ev["event_start_at"])
            if abs((s.replace(tzinfo=None) - t["dt"]).total_seconds()) / 60 <= 30:
                near = True
                break
        if near:
            continue
        code, resp = api("POST", f"/farms/1/livestock/{t['livestock_id']}/drinking-events/manual",
                         # [:16] -> minute precision, matches the backend's
                         # yyyy-MM-dd HH:mm expectation (N4).
                         token, {"eventStartAt": t["start"][:16], "note": "T6 drill: missed bout backfill"})
        if code == 200:
            stats["manual"] += 1
            picked += 1
        else:
            stats["manual_fail"] += 1
            print("MANUAL fail", code, resp)
    print(json.dumps(stats, ensure_ascii=False))


if __name__ == "__main__":
    main()
