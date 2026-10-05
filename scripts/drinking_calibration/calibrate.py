#!/usr/bin/env python3
"""NIX-256 Task 2 (L1) calibration entry point.

Reproduces the three detection methods of Aube et al. 2025 on the open
dataset (DOI 10.57745/H2SPNR, licence Etalab 2.0), then grid-searches the
combined detector of our spec (FallST slope AND per cow-day mu-k*sigma,
with V-shape recovery confirmation and 30-min merge).

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

Usage:
    python3 calibrate.py [--data DIR] [--out DIR]
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


def run_combined(series, obs_recs, win, s_th, k, r_th):
    """Run the combined detector with one grid point, then match."""
    per_series = []
    for sid, s in enumerate(series):
        bouts = []
        if sid in win:
            lo, hi = win[sid]
            for b in detect_combined(
                s["ts"], s["T_raw"], s["day_mu"], s["day_sigma"], s_th, k, r_th
            ):
                st = pd.Timestamp(b["start_ts"])
                if lo <= st <= hi:
                    bouts.append(b)
        per_series.append({"cow_id": s["cow_id"], "series_id": sid, "bouts": bouts})
    det = matching.bouts_from_series(per_series)
    return matching.match(det, obs_recs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    parser.add_argument(
        "--data", default=os.path.join(repo, "output/drinking-l1/dataset")
    )
    parser.add_argument(
        "--out", default=os.path.join(repo, "output/drinking-l1/results")
    )
    args = parser.parse_args()

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
                    m = run_combined(series, obs_recs, win, s_th, k, r_th)
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
