#!/usr/bin/env python3
"""NIX-256 Task 2 (L1) calibration entry point.

Reproduces the three detection methods of Aube et al. 2025 on the open
dataset (DOI 10.57745/H2SPNR, licence Etalab 2.0), then grid-searches the
combined detector of our spec (FallST slope AND per cow-day mu-k*sigma,
with V-shape recovery confirmation; merge-gap configurable, default 15 min).

Two dataset findings drive the harness (documented in the report):
1. The drinking signal lives in the `ruminal_temperature` column; the
   `corrected_temperature` column has drinking-induced drops smoothed out
   (metadata descriptions are swapped relative to the actual contents).
2. Video observations cover only ~96h per series; detections outside the
   per-series observation window (+/-30 min margin) have no gold standard
   and are excluded from evaluation, otherwise uncountable FPs appear.

Outputs (under <repo>/output/drinking-l1/results/):
- reproduction.txt : three-method reproduction vs paper reference table
- grid_results.csv : all grid combinations x sampling intervals
- selection.json   : selected parameters + neighbourhood robustness

Usage (Aube calibration, default):
    python3 calibrate.py [--data DIR] [--out DIR]

Usage (platform-label mode, NIX-256 Task 6 / spec §15.4):
    python3 calibrate.py --labels export.csv --series series.csv [--out DIR]
"""

import argparse
import json
import os
import sys

import numpy as np
import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import paper_methods
from combined_detector import detect_combined
from data_io import (
    attach_day_stats,
    load_observations,
    load_temperatures,
    resample,
    split_into_series,
)
import matching

# Paper reference numbers (TP / FP / FN / Se% / PPV% / F%), N = 730 bouts.
PAPER_REF = {
    "FixT": (657, 26, 73, 90.0, 96.2, 93.0),
    "Cow-dT": (646, 10, 84, 88.5, 98.5, 93.2),
    "FallST": (659, 5, 71, 90.3, 99.2, 94.5),
}

S_TH_GRID = [0.06, 0.08, 0.10, 0.12, 0.15]  # degC/min, gap-normalised
K_GRID = [0.5, 1, 2, 3, 5]
R_TH_GRID = [0.5, 0.6, 0.7, 0.75, 0.8]
INTERVALS = [5, 6, 10]  # minutes; 6 min = our platform effective resolution
F_GATE = 0.90
EVAL_MARGIN_MIN = 30  # evaluation window margin around observation coverage
PRIMARY_COL = "ruminal"  # column carrying the drinking signal (see docstring)
SECONDARY_COL = "corrected"

# ── Platform-label mode (NIX-256 Task 6, spec §15.4) ─────────────────────
# Re-runs the combined-detector grid on platform-exported drinking labels
# (GET /api/v1/admin/drinking-labels/export) against the raw temperature
# series, scoring Se/PPV/F under spec §15.3 offline semantics:
#   CONFIRMED (incl. source=MANUAL back-fills) = positive truth,
#   REJECTED = negative truth. A MANUAL back-fill therefore counts TP
#   when a detection matches it (the missed event was recovered) and FN
#   when nothing matches it — it is not automatically FN.
RANCH_ZONE = "Asia/Shanghai"
LABELS_GAP_GRID = [10, 15, 20, 25, 30]  # merge-gap axis; production 15 included
PRODUCTION_POINT = {"S_th": 0.06, "k": 0.5, "R_th": 0.7, "gap": 15}
# N7 acceptance guardrail: the grid best must beat the CURRENT production
# point by >= ACCEPT_EPS in F (0.5pp) before a formal parameter change is
# recommended; exact F ties keep the production point.
ACCEPT_EPS = 0.005
# Production-parity gating, FIXED in labels mode (kernel constants, not
# grid axes): in-body gate 35-43C + depth margin 1.0C below mu-k*sigma.
LABELS_IN_BODY_GATE = True
LABELS_DEPTH_MARGIN_C = 1.0
FARM_ACCEPT_MIN = 100  # spec §15.4: per-farm CONFIRMED+REJECTED >= 100


def prepare_series(df):
    """Attach per-day stats for both columns and split into series.

    day_mu/day_sigma refer to the ruminal column (detection input);
    day_mu_c/day_sigma_c to the corrected column.
    """
    df = attach_day_stats(df, "ruminal")
    df = attach_day_stats(df, "corrected", "_c")
    series = split_into_series(df)
    series_index = []
    for sid, s in enumerate(series):
        t0 = int(s["ts"][0].astype("datetime64[s]").astype(np.int64))
        t1 = int(s["ts"][-1].astype("datetime64[s]").astype(np.int64))
        series_index.append((s["cow_id"], t0, t1, sid))
    return series, series_index


def eval_windows(obs, obs_recs):
    """Per-series evaluation window = observation coverage +/- margin."""
    by_sid = {}
    for r, row in zip(obs_recs, obs.itertuples()):
        by_sid.setdefault(r["series_id"], []).append((row.start, row.end))
    win = {}
    for sid, v in by_sid.items():
        if sid < 0:
            continue
        lo = min(x[0] for x in v) - pd.Timedelta(minutes=EVAL_MARGIN_MIN)
        hi = max(x[1] for x in v) + pd.Timedelta(minutes=EVAL_MARGIN_MIN)
        win[sid] = (lo, hi)
    return win


def collect_bouts(series, runner, temp_col, win):
    """Run a detector over all series, keep detections inside eval windows."""
    per_series = []
    for sid, s in enumerate(series):
        if temp_col == "ruminal":
            s = dict(s, T=s["T_raw"], day_mu=s["day_mu"], day_sigma=s["day_sigma"])
        else:
            s = dict(
                s, T=s["T"], day_mu=s.get("day_mu_c"), day_sigma=s.get("day_sigma_c")
            )
        bouts = []
        if sid in win:
            lo, hi = win[sid]
            for b in runner(s):
                st = pd.Timestamp(s["ts"][b["start_idx"]])
                if lo <= st <= hi:
                    bouts.append(
                        {"start_ts": s["ts"][b["start_idx"]], "end_ts": s["ts"][b["end_idx"]]}
                    )
        per_series.append({"cow_id": s["cow_id"], "series_id": sid, "bouts": bouts})
    return matching.bouts_from_series(per_series)


def run_paper_methods(series, obs_recs, temp_col, win):
    """Run the three reproduced methods and return {method: metrics}."""
    runners = {
        "FixT": lambda s: paper_methods.detect_fixt(s["ts"], s["T"]),
        "Cow-dT": lambda s: paper_methods.detect_cowdt(
            s["ts"], s["T"], s["day_mu"], s["day_sigma"]
        ),
        "FallST": lambda s: paper_methods.detect_fallst(s["ts"], s["T"]),
    }
    results = {}
    for name, runner in runners.items():
        det = collect_bouts(series, runner, temp_col, win)
        results[name] = matching.match(det, obs_recs)
    return results


def run_combined(series, obs_recs, win, s_th, k, r_th,
                 merge_gap_min=15.0, in_body_gate=False, depth_margin_c=0.0):
    """Run the combined detector with one grid point, then match."""
    per_series = []
    for sid, s in enumerate(series):
        bouts = []
        if sid in win:
            lo, hi = win[sid]
            for b in detect_combined(
                s["ts"], s["T_raw"], s["day_mu"], s["day_sigma"], s_th, k, r_th,
                merge_gap_min=merge_gap_min, in_body_gate=in_body_gate,
                depth_margin_c=depth_margin_c,
            ):
                st = pd.Timestamp(b["start_ts"])
                if lo <= st <= hi:
                    bouts.append(b)
        per_series.append({"cow_id": s["cow_id"], "series_id": sid, "bouts": bouts})
    det = matching.bouts_from_series(per_series)
    return matching.match(det, obs_recs)


# ════════════════════════════════════════════════════════════════════════
# Platform-label mode (NIX-256 Task 6, spec §15.4)
# ════════════════════════════════════════════════════════════════════════

def to_ranch_naive(raw):
    """Parse ISO-8601 strings to naive Asia/Shanghai wall-clock datetimes.

    Accepts offset-carrying values (platform export: '+08:00'), naive wall
    clock (backfill tools), or a mix; offset-carrying values are converted,
    naive ones are taken as ranch wall clock as-is.
    """
    s = raw.astype(str).str.strip()
    has_off = s.str.contains(r"(Z|[+-]\d{2}:?\d{2})$", regex=True)
    out = pd.Series(pd.NaT, index=s.index, dtype="datetime64[ns]")
    if (has_off).any():
        out[has_off] = pd.to_datetime(s[has_off], format="ISO8601", utc=True).dt.tz_convert(
            RANCH_ZONE).dt.tz_localize(None)
    if (~has_off).any():
        out[~has_off] = pd.to_datetime(s[~has_off], format="ISO8601")
    return out


def load_platform_labels(path):
    """Load the §15.4 export CSV (UTF-8 BOM + CRLF tolerant).

    Returns a DataFrame keyed on device_id (str) with naive ranch-wall-clock
    event_start_at/event_end_at plus source/label/farm_id.
    """
    df = pd.read_csv(path, encoding="utf-8-sig")
    need = {"device_id", "event_start_at", "event_end_at", "source", "label"}
    missing = need - set(df.columns)
    if missing:
        raise SystemExit(f"[labels] missing expected columns: {sorted(missing)}")
    df["device_id"] = df["device_id"].astype(str).str.strip()
    df["start"] = to_ranch_naive(df["event_start_at"])
    df["end"] = to_ranch_naive(df["event_end_at"])
    df["farm_id"] = df.get("farm_id", pd.Series(index=df.index, dtype="object"))
    df["farm_key"] = df["farm_id"].map(
        lambda v: "unknown" if pd.isna(v) or str(v).strip() in ("", "nan") else str(int(float(v)))
    )
    # Positive truth: CONFIRMED verdicts plus MANUAL back-fills (§15.3).
    df["polarity"] = np.select(
        [
            (df["label"] == "CONFIRMED") | (df["source"] == "MANUAL"),
            df["label"] == "REJECTED",
        ],
        ["positive", "negative"],
        default="unlabeled",
    )
    return df


def load_platform_series(path):
    """Load the raw series CSV (device_id, recorded_at, temperature)."""
    df = pd.read_csv(path)
    df["device_id"] = df["device_id"].astype(str).str.strip()
    df["recorded_at"] = to_ranch_naive(df["recorded_at"])
    return df.sort_values(["device_id", "recorded_at"]).reset_index(drop=True)


def prepare_device_arrays(series_df):
    """Pre-gate each device's series and precompute per-day mu/sigma.

    This is exactly what detect_combined(in_body_gate=True) recomputes
    internally at every call; doing it once here keeps the 625-point grid
    affordable while preserving production-parity semantics bit for bit
    (gate applied to points AND day statistics, sigma ddof=1).
    """
    devices = {}
    for dev, sub in series_df.groupby("device_id", sort=True):
        sub = sub.sort_values("recorded_at")
        T = sub["temperature"].to_numpy(dtype=float)
        keep = (T >= 35.0) & (T <= 43.0)
        sub = sub.loc[keep]
        T = T[keep]
        ts = sub["recorded_at"].to_numpy()
        if len(ts) < 2:
            continue
        day = pd.Series(ts).dt.date
        mu = pd.Series(T).groupby(day).transform("mean").to_numpy()
        sig = pd.Series(T).groupby(day).transform(lambda x: x.std(ddof=1)).to_numpy()
        devices[dev] = {"ts": ts, "T": T, "day_mu": mu, "day_sigma": sig}
    return devices


def _naive_sec(x):
    """Naive datetime -> epoch-like seconds WITHOUT machine-TZ interpretation.

    Both labels and series are naive ranch wall clock; converting through
    .timestamp() would drag the host timezone in, so subtract the naive
    epoch directly — comparisons stay consistent on any host.
    """
    return int((pd.Timestamp(x) - pd.Timestamp("1970-01-01")).total_seconds())


def run_labels_grid(devices, labels_df):
    """Run the full S_th x k x R_th x merge-gap grid over the label set.

    Returns a list of result dicts (params + TP/FP/FN/Se/PPV/F). Detections
    are matched to labels per device via interval overlap (matching.py);
    unmatched detections count neither TP nor FP (ops label a subset — see
    the report caveat), unmatched REJECTED labels count nothing (TN-like).
    """
    scored = labels_df[labels_df["polarity"] != "unlabeled"].copy()
    scored = scored[scored["device_id"].isin(devices)]
    label_records = [
        {
            "device_id": r.device_id,
            "start_sec": _naive_sec(r.start),
            "end_sec": _naive_sec(r.end),
            "polarity": r.polarity,
        }
        for r in scored.itertuples()
    ]
    n_pos = sum(1 for x in label_records if x["polarity"] == "positive")
    n_neg = len(label_records) - n_pos

    def evaluate(s_th, k, r_th, gap):
        detections = []
        for dev, arr in devices.items():
            for b in detect_combined(
                arr["ts"], arr["T"], arr["day_mu"], arr["day_sigma"],
                s_th, k, r_th, merge_gap_min=gap,
                in_body_gate=False,  # arrays pre-gated (see prepare_device_arrays)
                depth_margin_c=LABELS_DEPTH_MARGIN_C,
            ):
                detections.append(
                    {
                        "device_id": dev,
                        "start_sec": _naive_sec(b["start_ts"]),
                        "end_sec": _naive_sec(b["end_ts"]),
                    }
                )
        det_match, label_match = matching.match_labels_overlap(detections, label_records)
        tp = fp = 0
        for di, li in enumerate(det_match):
            if li is not None:
                if label_records[li]["polarity"] == "positive":
                    tp += 1
                else:
                    fp += 1
        fn = sum(
            1
            for li, matched in enumerate(label_match)
            if matched is None and label_records[li]["polarity"] == "positive"
        )
        se = tp / n_pos if n_pos else float("nan")
        ppv = tp / (tp + fp) if (tp + fp) else float("nan")
        f = 2 * se * ppv / (se + ppv) if se + ppv and n_pos else float("nan")
        return {
            "params": f"S_th={s_th}|k={k}|R_th={r_th}|gap={gap}",
            "S_th": s_th, "k": k, "R_th": r_th, "gap": gap,
            "TP": tp, "FP": fp, "FN": fn,
            "n_pos": n_pos, "n_neg": n_neg, "n_detected": len(detections),
            "Se": round(se, 4) if se == se else "",
            "PPV": round(ppv, 4) if ppv == ppv else "",
            "F": round(f, 4) if f == f else "",
        }

    rows = []
    for s_th in S_TH_GRID:
        for k in K_GRID:
            for r_th in R_TH_GRID:
                for gap in LABELS_GAP_GRID:
                    rows.append(evaluate(s_th, k, r_th, gap))
        print(f"[labels-grid] S_th={s_th} done ({len(rows)} points)", flush=True)
    return rows


def labels_acceptance_decision(best, prod_row):
    """N7 guardrail: which point to formally suggest.

    The grid best must beat the current production point by >= ACCEPT_EPS
    in F (0.5pp) to warrant a parameter change; exact F ties keep the
    production point. N13: when there is no scorable best (no positive
    labels / empty series) the decision is "none" and callers must not
    quote any best point.
    """
    prod_f = prod_row["F"] if prod_row["F"] != "" else 0.0
    if best is None:
        return {"decision": "none", "reason": "no scorable positive labels"}
    best_is_prod = (best["S_th"], best["k"], best["R_th"], best["gap"]) == (
        PRODUCTION_POINT["S_th"], PRODUCTION_POINT["k"],
        PRODUCTION_POINT["R_th"], PRODUCTION_POINT["gap"],
    )
    delta_f = round(best["F"] - prod_f, 4)
    keep = best_is_prod or delta_f < ACCEPT_EPS
    point = PRODUCTION_POINT if keep else best
    return {
        "decision": "keep_production" if keep else "change",
        "S_th": point["S_th"], "k": point["k"], "R_th": point["R_th"],
        "gap": point["gap"],
        "F": prod_row["F"] if keep else best["F"],
        "delta_F_vs_production": delta_f,
        "accept_epsilon": ACCEPT_EPS,
    }


def labels_report_lines(rows, labels_df, series_path, labels_path, skipped_devices):
    """Render labels_suggestion.txt content; returns (lines, selection)."""
    L = []
    L.append("Drinking-event label-mode calibration report (NIX-256 Task 6, spec §15.4)")
    L.append("=" * 72)
    L.append(f"labels : {labels_path}")
    L.append(f"series : {series_path}")
    L.append(f"gating : in-body gate ON, depth margin {LABELS_DEPTH_MARGIN_C} degC "
             f"(production parity, fixed; merge-gap is a grid axis)")
    L.append(f"grid   : S_th {S_TH_GRID} x k {K_GRID} x R_th {R_TH_GRID} x gap {LABELS_GAP_GRID}")
    L.append("")
    L.append("== Label sample ==")
    total = len(labels_df)
    pos = int((labels_df["polarity"] == "positive").sum())
    neg = int((labels_df["polarity"] == "negative").sum())
    unl = int((labels_df["polarity"] == "unlabeled").sum())
    manual = int((labels_df["source"] == "MANUAL").sum())
    L.append(f"total rows          : {total}")
    L.append(f"CONFIRMED (pos.)    : {pos}  (incl. MANUAL back-fills: {manual})")
    L.append(f"REJECTED (neg.)     : {neg}")
    L.append(f"UNLABELED (ignored) : {unl}")
    L.append("per farm:")
    for farm, grp in labels_df.groupby("farm_key", sort=True):
        c = int((grp["polarity"] == "positive").sum())
        r = int((grp["polarity"] == "negative").sum())
        L.append(f"  farm {farm}: positives={c}, REJECTED={r}, "
                 f"CONFIRMED+REJECTED={c + r}")
    if skipped_devices:
        L.append(f"[warn] labels of devices absent from the series were excluded from "
                 f"scoring: {sorted(skipped_devices)}")
    L.append("")

    def row_of(point):
        for r in rows:
            if (r["S_th"], r["k"], r["R_th"], r["gap"]) == (
                point["S_th"], point["k"], point["R_th"], point["gap"]
            ):
                return r
        return None

    L.append("== Current production parameters on this label set ==")
    p = row_of(PRODUCTION_POINT)
    if p is None:
        raise SystemExit("[labels] internal error: production point not on the grid")
    L.append(f"S_th={PRODUCTION_POINT['S_th']}, k={PRODUCTION_POINT['k']}, "
             f"R_th={PRODUCTION_POINT['R_th']}, merge-gap={PRODUCTION_POINT['gap']}")
    L.append(f"TP={p['TP']}  FP={p['FP']}  FN={p['FN']}  "
             f"Se={p['Se']}  PPV={p['PPV']}  F={p['F']}")
    L.append("")

    valid = [r for r in rows if r["F"] != ""]
    best = max(valid, key=lambda r: r["F"]) if valid else None
    L.append("== Grid best (F desc) ==")
    if best:
        L.append(f"S_th={best['S_th']}, k={best['k']}, R_th={best['R_th']}, "
                 f"merge-gap={best['gap']}")
        L.append(f"TP={best['TP']}  FP={best['FP']}  FN={best['FN']}  "
                 f"Se={best['Se']}  PPV={best['PPV']}  F={best['F']}")
    L.append("")
    L.append("Top-10 grid points:")
    L.append("params                               TP   FP   FN   Se      PPV     F")
    for r in sorted(valid, key=lambda x: x["F"], reverse=True)[:10]:
        L.append(f"{r['params']:<35} {r['TP']:>4} {r['FP']:>4} {r['FN']:>4} "
                 f"{r['Se']:>7} {r['PPV']:>7} {r['F']:>7}")
    L.append("")

    L.append("== Acceptance (spec §15.4: per-farm CONFIRMED+REJECTED >= "
             f"{FARM_ACCEPT_MIN}) ==")
    per_farm_ok = True
    farms_with_verdicts = []
    for farm, grp in labels_df.groupby("farm_key", sort=True):
        c = int((grp["polarity"] == "positive").sum())
        r = int((grp["polarity"] == "negative").sum())
        ok = c + r >= FARM_ACCEPT_MIN
        per_farm_ok = per_farm_ok and ok
        farms_with_verdicts.append((farm, c + r, ok))
        L.append(f"farm {farm}: CONFIRMED+REJECTED={c + r} -> "
                 f"{'sufficient' if ok else 'INSUFFICIENT'}")
    L.append("")
    if not farms_with_verdicts:
        per_farm_ok = False
    decision = labels_acceptance_decision(best, p)
    if not valid:
        # N13: F is undefined on every grid point (no positive labels or
        # no detections) — never quote the grid best here.
        L.append("采信判定：无可评估的正样本标签，不出建议。")
    elif per_farm_ok:
        if decision["decision"] == "keep_production":
            L.append(f"采信判定：通过。维持现产参数（最优提升 ΔF="
                     f"{decision['delta_F_vs_production']:.4f} 低于采信阈值 "
                     f"{ACCEPT_EPS}）。")
            L.append(f"  fall-threshold={PRODUCTION_POINT['S_th']}  "
                     f"k-sigma={PRODUCTION_POINT['k']}  "
                     f"recovery-ratio={PRODUCTION_POINT['R_th']}  "
                     f"merge-gap-min={PRODUCTION_POINT['gap']}")
        else:
            L.append("采信判定：通过。建议参数（供运维修改 health.drinking.* 配置）：")
            L.append(f"  fall-threshold={decision['S_th']}  k-sigma={decision['k']}  "
                     f"recovery-ratio={decision['R_th']}  merge-gap-min={decision['gap']}")
            L.append(f"  （相对现产参数 F 提升 ΔF={decision['delta_F_vs_production']:.4f} "
                     f"≥ 采信阈值 {ACCEPT_EPS}）")
        L.append(f"  样本量：CONFIRMED+MANUAL {pos}（含 MANUAL 补录 {manual}）、"
                 f"REJECTED {neg}；分牧场样本见上方统计。")
    else:
        L.append("采信判定：样本量不足，仅供参考，不出正式建议。")
        L.append("  (spec §15.4: 单牧场 CONFIRMED+REJECTED 合计 ≥ "
                 f"{FARM_ACCEPT_MIN} 方出建议参数)")
    L.append("")
    L.append("== Caveats ==")
    L.append("- Detections with no overlapping label count neither TP nor FP:")
    L.append("  operators label a subset, so unmatched detections have unknown")
    L.append("  polarity; PPV is conditional on labelled regions.")
    L.append("- UNLABELED rows are ignored; MANUAL back-fills are positive truth.")
    L.append("- Matching is per-device interval overlap, greedy nearest-center")
    L.append("  (matching.match_labels_overlap).")

    # Selection record for labels_selection.json (N10: carries the caliber
    # keys like the Aube-flow selection.json; labels-mode gating is FIXED
    # at production parity and the merge anchor is the current detector
    # semantics, i.e. rolling).
    sel = dict(decision)
    if valid and not per_farm_ok:
        sel["decision"] = "insufficient_sample"  # params above are reference-only
    sel["mode"] = "labels"
    sel["in_body_gate"] = LABELS_IN_BODY_GATE
    sel["depth_margin_c"] = LABELS_DEPTH_MARGIN_C
    sel["merge_gap_min"] = sel.get("gap", PRODUCTION_POINT["gap"])
    sel["merge_anchor"] = "rolling"
    sel["sample"] = {
        "positive_confirmed_manual": pos,
        "of_which_manual": manual,
        "rejected": neg,
        "total_rows": total,
    }
    return L, sel


def run_labels_mode(args, repo):
    out = args.out or os.path.join(repo, "output/drinking-l2/labels-mode")
    os.makedirs(out, exist_ok=True)
    labels_df = load_platform_labels(args.labels)
    series_df = load_platform_series(args.series)
    devices = prepare_device_arrays(series_df)
    scored_devs = set(labels_df.loc[labels_df["polarity"] != "unlabeled", "device_id"])
    skipped = scored_devs - set(devices)
    if skipped:
        print(f"[labels] WARNING: {len(skipped)} labeled device(s) missing from series, "
              f"their labels are excluded from scoring: {sorted(skipped)}")
    if not (scored_devs - skipped):
        raise SystemExit("[labels] no scorable labels: none of the labeled devices "
                         "appear in the series file")

    rows = run_labels_grid(devices, labels_df)
    grid = pd.DataFrame(rows)
    grid_path = os.path.join(out, "labels_grid_results.csv")
    grid.to_csv(grid_path, index=False)

    report, sel = labels_report_lines(
        rows, labels_df, args.series, args.labels, skipped
    )
    report_path = os.path.join(out, "labels_suggestion.txt")
    with open(report_path, "w") as f:
        f.write("\n".join(report) + "\n")
    sel_path = os.path.join(out, "labels_selection.json")
    with open(sel_path, "w") as f:
        json.dump(sel, f, indent=2, default=str)

    print("\n".join(report))
    print(f"\n[labels] wrote {grid_path}")
    print(f"[labels] wrote {report_path}")
    print(f"[labels] wrote {sel_path}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    parser.add_argument(
        "--data", default=os.path.join(repo, "output/drinking-l1/dataset")
    )
    parser.add_argument(
        "--out", default=None,
        help="output dir (default: output/drinking-l1/results for the Aube flow, "
             "output/drinking-l2/labels-mode for --labels)"
    )
    parser.add_argument("--merge-gap", type=float, default=15.0,
                        help="merge gap minutes (spec 14 canonical 15; 30 = pre-sweep L1)")
    parser.add_argument("--in-body-gate", action="store_true",
                        help="apply the Java kernel 35-43C gate before detection (production parity)")
    parser.add_argument("--depth-margin", type=float, default=0.0,
                        help="extra depth margin below mu-k*sigma in degC (Java kernel 1.0; L1 semantics 0.0)")
    parser.add_argument("--labels", default=None,
                        help="platform label export CSV (GET /api/v1/admin/drinking-labels/export); "
                             "enables the spec §15.4 label-mode grid")
    parser.add_argument("--series", default=None,
                        help="raw temperature series CSV (device_id,recorded_at,temperature), "
                             "required with --labels")
    args = parser.parse_args()

    if args.labels:
        if not args.series:
            parser.error("--labels requires --series (device_id,recorded_at,temperature)")
        run_labels_mode(args, repo)
        return

    if args.out is None:
        args.out = os.path.join(repo, "output/drinking-l1/results")
    os.makedirs(args.out, exist_ok=True)
    df5 = load_temperatures(os.path.join(args.data, "temperature_bolus.tab"))
    obs = load_observations(os.path.join(args.data, "observed_drinking_bouts.tab"))

    repro_lines = [
        f"Reproduction of Aube et al. 2025 three methods (gold standard N={len(obs)} bouts)",
        "Evaluation window: per-series observation coverage +/- 30 min",
    ]
    grid_rows = []

    def repro_block(temp_col):
        repro_lines.append("")
        repro_lines.append(f"### temperature column: {temp_col} ###")

    def repro_rows(res, interval):
        repro_lines.append(
            f"interval {interval} min | "
            f"{'method':8s} {'TP':>4s} {'FP':>4s} {'FN':>4s} "
            f"{'Se%':>6s} {'PPV%':>6s} {'F%':>6s}   | paper TP/FP/FN Se PPV F | dF(pp)"
        )
        for name in ["FixT", "Cow-dT", "FallST"]:
            m = res[name]
            tp, fp, fn, se, ppv, f = PAPER_REF[name]
            repro_lines.append(
                f"{'':16s} {name:8s} {m['tp']:4d} {m['fp']:4d} {m['fn']:4d} "
                f"{100 * m['Se']:6.1f} {100 * m['PPV']:6.1f} {100 * m['F']:6.1f}   "
                f"| {tp}/{fp}/{fn} {se:.1f}/{ppv:.1f}/{f:.1f} "
                f"| {100 * m['F'] - f:+.1f}"
            )

    # --- Part 1: reproduction on both temperature columns ---
    prepared = {}
    for temp_col in [PRIMARY_COL, SECONDARY_COL]:
        repro_block(temp_col)
        for interval in INTERVALS:
            if interval not in prepared:
                df = df5 if interval == 5 else resample(df5, interval)
                series, series_index = prepare_series(df)
                obs_recs = matching.obs_records(obs, series_index)
                win = eval_windows(obs, obs_recs)
                prepared[interval] = (series, series_index, obs_recs, win)
            series, series_index, obs_recs, win = prepared[interval]
            res = run_paper_methods(series, obs_recs, temp_col, win)
            repro_rows(res, interval)

    # --- Part 2: combined detector grid on the signal column ---
    for interval in INTERVALS:
        series, series_index, obs_recs, win = prepared[interval]
        for s_th in S_TH_GRID:
            for k in K_GRID:
                for r_th in R_TH_GRID:
                    m = run_combined(series, obs_recs, win, s_th, k, r_th,
                        merge_gap_min=args.merge_gap, in_body_gate=args.in_body_gate,
                        depth_margin_c=args.depth_margin)
                    grid_rows.append(
                        {
                            "interval_min": interval,
                            "S_th": s_th,
                            "k": k,
                            "R_th": r_th,
                            "TP": m["tp"],
                            "FP": m["fp"],
                            "FN": m["fn"],
                            "n_detected": m["n_detected"],
                            "Se": round(m["Se"], 4),
                            "PPV": round(m["PPV"], 4),
                            "F": round(m["F"], 4),
                        }
                    )
        print(f"[grid] interval {interval} min done", flush=True)

    grid = pd.DataFrame(grid_rows)
    grid.to_csv(os.path.join(args.out, "grid_results.csv"), index=False)

    # --- Part 3: parameter selection on the native 5-min interval ---
    g5 = grid[grid["interval_min"] == 5].copy()
    eligible = g5[g5["F"] >= F_GATE].copy()
    gate_met = len(eligible) > 0
    if not gate_met:
        print(f"[selection] WARNING: no combination reaches F >= {F_GATE} at 5 min")
        eligible = g5.copy()  # report best anyway

    def center_dist(row):
        return (
            abs(S_TH_GRID.index(row["S_th"]) - 2)
            + abs(K_GRID.index(row["k"]) - 2)
            + abs(R_TH_GRID.index(row["R_th"]) - 2)
        )

    eligible["center_dist"] = eligible.apply(center_dist, axis=1)
    # Round F for tie detection, then prefer grid-centre proximity.
    eligible["F_key"] = eligible["F"].round(6)
    eligible = eligible.sort_values(
        ["F_key", "center_dist"], ascending=[False, True], kind="mergesort"
    )
    best = eligible.iloc[0]
    sel = {
        "S_th": float(best["S_th"]),
        "k": float(best["k"]),
        "R_th": float(best["R_th"]),
        "gate_met": bool(gate_met),
    }
    # N10: caliber metadata — every selection.json must self-describe the
    # kernel semantics it was produced under. Current detector merges with
    # a rolling anchor; pre-2026-10-05 legacy files were chain_first and
    # are annotated by hand.
    sel["in_body_gate"] = bool(args.in_body_gate)
    sel["depth_margin_c"] = float(args.depth_margin)
    sel["merge_gap_min"] = int(args.merge_gap)
    sel["merge_anchor"] = "rolling"

    def f_at(interval, s_th, k, r_th):
        row = grid[
            (grid["interval_min"] == interval)
            & (grid["S_th"] == s_th)
            & (grid["k"] == k)
            & (grid["R_th"] == r_th)
        ]
        return float(row["F"].iloc[0]) if len(row) else None

    # Neighbourhood robustness (+/-1 grid step per axis, 5-min interval).
    neighborhood = {}
    for axis, values in [("S_th", S_TH_GRID), ("k", K_GRID), ("R_th", R_TH_GRID)]:
        idx = values.index(sel[axis])
        for step in (-1, 1):
            j = idx + step
            if 0 <= j < len(values):
                params = dict(sel)
                params[axis] = values[j]
                neighborhood[f"{axis}={values[j]}"] = f_at(
                    5, params["S_th"], params["k"], params["R_th"]
                )
    nb_vals = [v for v in neighborhood.values() if v is not None]
    sel["F_5min"] = f_at(5, sel["S_th"], sel["k"], sel["R_th"])
    sel["neighborhood_F"] = neighborhood
    sel["neighborhood_min"] = min(nb_vals)
    sel["neighborhood_max"] = max(nb_vals)
    sel["neighborhood_range_pp"] = round(100 * (max(nb_vals) - min(nb_vals)), 2)

    # Cross-interval performance of the selected parameters.
    sel["F_by_interval"] = {
        str(i): f_at(i, sel["S_th"], sel["k"], sel["R_th"]) for i in INTERVALS
    }
    sel["cross_interval_range_pp"] = round(
        100 * (max(sel["F_by_interval"].values()) - min(sel["F_by_interval"].values())), 2
    )

    # Best combination per interval (for the generalisation table).
    per_interval_best = {}
    for i in INTERVALS:
        gi = grid[grid["interval_min"] == i].sort_values("F", ascending=False).iloc[0]
        per_interval_best[str(i)] = {
            "S_th": float(gi["S_th"]),
            "k": float(gi["k"]),
            "R_th": float(gi["R_th"]),
            "F": float(gi["F"]),
            "Se": float(gi["Se"]),
            "PPV": float(gi["PPV"]),
        }
    sel["best_per_interval"] = per_interval_best

    with open(os.path.join(args.out, "selection.json"), "w") as f:
        json.dump(sel, f, indent=2, default=str)
    with open(os.path.join(args.out, "reproduction.txt"), "w") as f:
        f.write("\n".join(repro_lines) + "\n")

    print("\n".join(repro_lines))
    print("\n[selection]", json.dumps(sel, indent=2, default=str))
    top20 = eligible.head(20)[
        ["S_th", "k", "R_th", "TP", "FP", "FN", "Se", "PPV", "F", "center_dist"]
    ]
    print("\nTop-20 (5 min, F desc then centre distance):")
    print(top20.to_string(index=False))


if __name__ == "__main__":
    main()
