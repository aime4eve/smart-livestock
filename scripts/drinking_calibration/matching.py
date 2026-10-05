"""Matching protocol between detected and observed drinking bouts.

Implements the four-step protocol of Aube et al. 2025:
1. Each detected bout is first associated with the nearest observed bout
   within a +/-30 min window.
2. Per cow+series, the median observed-detected time offset (sensor drift)
   is computed and subtracted from all detected bout starts of that series.
3. After correction, detected bouts are matched to observations within a
   +/-10 min window.
4. When two detections compete for one observation, the nearest wins and
   the other is counted as a false positive (greedy nearest-first over all
   candidate pairs; each detection and each observation is used at most once).

Metrics: Se = TP / n_observed; PPV = TP / (TP + FP);
F = 2 * Se * PPV / (Se + PPV).
"""

import numpy as np

ASSOC_WINDOW_SEC = 30 * 60
MATCH_WINDOW_SEC = 10 * 60


def bouts_from_series(all_bouts):
    """Flatten per-series bout dicts into records with cow/start/series."""
    records = []
    for series in all_bouts:
        for b in series["bouts"]:
            records.append(
                {
                    "cow_id": series["cow_id"],
                    "series_id": series["series_id"],
                    "start_sec": int(
                        b["start_ts"].astype("datetime64[s]").astype(np.int64)
                    ),
                }
            )
    return records


def obs_records(obs, series_index):
    """Convert observation DataFrame to records with cow/start/series.

    series_index: list of (cow_id, t0_sec, t1_sec, series_id) segments.
    Observations outside every segment of their cow fall in series_id -1.
    """
    records = []
    by_cow = {}
    for cow, t0, t1, sid in series_index:
        by_cow.setdefault(cow, []).append((t0, t1, sid))
    for row in obs.itertuples():
        s = int((row.start - np.datetime64("1970-01-01")) / np.timedelta64(1, "s"))
        sid = -1
        for t0, t1, cand in by_cow.get(row.cow_id, []):
            if t0 <= s <= t1:
                sid = cand
                break
        records.append({"cow_id": row.cow_id, "series_id": sid, "start_sec": s})
    return records


def match(detected, observed):
    """Run the full matching protocol. Returns a metrics dict."""
    obs_by_cow = {}
    for oi, o in enumerate(observed):
        obs_by_cow.setdefault(o["cow_id"], []).append((oi, o["start_sec"]))

    # Step 1: associate each detection with nearest observation (+/-30 min).
    assoc_pairs = []  # (det_idx, obs_idx, signed offset det - obs)
    for di, d in enumerate(detected):
        best_oi, best_d = None, None
        for oi, s in obs_by_cow.get(d["cow_id"], []):
            dd = abs(s - d["start_sec"])
            if dd <= ASSOC_WINDOW_SEC and (best_d is None or dd < best_d):
                best_oi, best_d = oi, dd
        if best_oi is not None:
            assoc_pairs.append((di, best_oi, d["start_sec"] - observed[best_oi]["start_sec"]))

    # Step 2: per cow+series median drift correction.
    by_key = {}
    for di, oi, off in assoc_pairs:
        key = (detected[di]["cow_id"], detected[di]["series_id"])
        by_key.setdefault(key, []).append(off)
    drift = {k: float(np.median(v)) for k, v in by_key.items()}
    corrected = [
        d["start_sec"] - drift.get((d["cow_id"], d["series_id"]), 0.0)
        for d in detected
    ]

    # Step 3+4: greedy nearest-first matching within +/-10 min.
    cand = []
    for di, d in enumerate(detected):
        for oi, s in obs_by_cow.get(d["cow_id"], []):
            dist = abs(corrected[di] - s)
            if dist <= MATCH_WINDOW_SEC:
                cand.append((dist, di, oi))
    cand.sort(key=lambda x: (x[0], x[1], x[2]))
    used_d, used_o, tp = set(), set(), 0
    for dist, di, oi in cand:
        if di in used_d or oi in used_o:
            continue
        used_d.add(di)
        used_o.add(oi)
        tp += 1

    fp = len(detected) - tp
    fn = len(observed) - tp
    n_obs = len(observed)
    se = tp / n_obs if n_obs else float("nan")
    ppv = tp / (tp + fp) if (tp + fp) else float("nan")
    f = 2 * se * ppv / (se + ppv) if (se + ppv) else float("nan")
    return {
        "tp": tp,
        "fp": fp,
        "fn": fn,
        "n_detected": len(detected),
        "n_obs": n_obs,
        "drift": drift,
        "Se": se,
        "PPV": ppv,
        "F": f,
    }
