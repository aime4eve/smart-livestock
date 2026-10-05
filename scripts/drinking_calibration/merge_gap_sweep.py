#!/usr/bin/env python3
"""NIX-256 T2 supplementary: merge-gap sensitivity sweep.

Spec pinned merge-gap-min:30 came from misreading Aube's "at least 30 min
apart" (which describes detection resolution, not a merge rule — the paper
has no merging; splitting is handled by the local-peak criterion). At 30 min
the Se is ceiling-bound (~86.7%). This sweep quantifies Se/PPV/F for
merge-gap in {0,10,15,20,25,30} at the selected params (S=0.06, k=0.5,
R=0.7) on 5-min and 6-min data.
"""

import argparse
import os
import sys

import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from calibrate import eval_windows, prepare_series
from combined_detector import detect_combined
from data_io import load_observations, load_temperatures, resample
from matching import bouts_from_series, match, obs_records

SELECTED = dict(s_th=0.06, k=0.5, r_th=0.7)
GAPS = [0, 10, 15, 20, 25, 30]
INTERVALS = [5, 6]


def run(df, obs, interval, gap):
    d = resample(df, interval) if interval != 5 else df
    series, series_index = prepare_series(d)
    obs_recs = obs_records(obs, series_index)
    win = eval_windows(obs, obs_recs)
    per_series = []
    for sid, s in enumerate(series):
        bouts = []
        if sid in win:
            lo, hi = win[sid]
            for b in detect_combined(
                s["ts"],
                s["T_raw"],
                s["day_mu"],
                s["day_sigma"],
                SELECTED["s_th"],
                SELECTED["k"],
                SELECTED["r_th"],
                merge_gap_min=gap,
            ):
                st = pd.Timestamp(b["start_ts"])
                if lo <= st <= hi:
                    bouts.append(b)
        per_series.append({"cow_id": s["cow_id"], "series_id": sid, "bouts": bouts})
    return match(bouts_from_series(per_series), obs_recs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    repo = os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    )
    parser.add_argument("--data", default=os.path.join(repo, "output/drinking-l1/dataset"))
    args = parser.parse_args()

    df = load_temperatures(os.path.join(args.data, "temperature_bolus.tab"))
    obs = load_observations(os.path.join(args.data, "observed_drinking_bouts.tab"))

    print("merge-gap sweep at S=0.06/k=0.5/R=0.7 (N=730)")
    print("interval  gap_min  TP   FP   FN   Se%    PPV%   F%")
    for interval in INTERVALS:
        for gap in GAPS:
            m = run(df, obs, interval, gap)
            print(
                f"{interval:>4}-min  {gap:>6}  {m['tp']:>3}  {m['fp']:>3}  {m['fn']:>3}"
                f"  {m['Se']*100:>5.1f}  {m['PPV']*100:>5.1f}  {m['F']*100:>5.2f}"
            )
        print()


if __name__ == "__main__":
    main()
