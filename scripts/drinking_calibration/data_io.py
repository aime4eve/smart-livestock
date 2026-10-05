"""Data loading and resampling for the Aube 2025 drinking-bout dataset.

Dataset: "Accurate method for detecting drinking bouts in dairy cows based on
reticulorumen temperature" (Aube et al. 2025), DOI 10.57745/H2SPNR,
licence Etalab 2.0 (Licence Ouverte).
"""

import pandas as pd

# A new series starts when the temperature record is interrupted for more than
# this duration (per the paper's matching protocol).
SERIES_GAP = pd.Timedelta("6h")


def load_temperatures(path):
    """Load temperature_bolus.tab into a tidy DataFrame.

    Returns columns: cow_id, ts (datetime64), ruminal, corrected.
    French dd/mm/yyyy quoted timestamps are parsed explicitly.
    """
    df = pd.read_csv(path, sep="\t")
    df["ts"] = pd.to_datetime(df["date_time"], format="%d/%m/%Y %H:%M")
    df = df[["cow_id", "ts", "ruminal_temperature", "corrected_temperature"]]
    df = df.rename(
        columns={
            "ruminal_temperature": "ruminal",
            "corrected_temperature": "corrected",
        }
    )
    return df.sort_values(["cow_id", "ts"]).reset_index(drop=True)


def load_observations(path):
    """Load observed_drinking_bouts.tab (video-labelled gold standard).

    Returns columns: cow_id, start, end, duration_s, ... (start/end datetimes).
    """
    obs = pd.read_csv(path, sep="\t")
    obs["start"] = pd.to_datetime(
        obs["DB_start_date"].str.strip('"') + " " + obs["DB_start_time"].str.strip('"'),
        format="%d/%m/%Y %H:%M:%S",
    )
    obs["end"] = pd.to_datetime(
        obs["DB_start_date"].str.strip('"') + " " + obs["DB_end_time"].str.strip('"'),
        format="%d/%m/%Y %H:%M:%S",
    )
    return obs


def resample(df, minutes):
    """Resample to fixed buckets of `minutes` by averaging (per cow, per column).

    Bucket edges are anchored at each cow's series start so that day
    boundaries stay aligned for divisors of 24h (6min, 10min).
    """
    out = []
    for cow, sub in df.groupby("cow_id", sort=True):
        g = sub.set_index("ts")[["ruminal", "corrected"]].resample(
            f"{minutes}min", origin="start"
        ).mean()
        g = g.dropna(how="all").reset_index()
        g.insert(0, "cow_id", cow)
        out.append(g)
    res = pd.concat(out, ignore_index=True)
    return res.sort_values(["cow_id", "ts"]).reset_index(drop=True)


def attach_day_stats(df, temp_col, suffix=""):
    """Attach per cow per local calendar day mean/std of `temp_col`.

    Adds columns: day, day_mu{suffix}, day_sigma{suffix} (sigma ddof=1).
    """
    df = df.copy()
    df["day"] = df["ts"].dt.date
    stats = df.groupby(["cow_id", "day"])[temp_col].agg(["mean", "std"]).reset_index()
    stats = stats.rename(
        columns={"mean": f"day_mu{suffix}", "std": f"day_sigma{suffix}"}
    )
    return df.merge(stats, on=["cow_id", "day"], how="left")


def split_into_series(df):
    """Split each cow's record into contiguous series (gap > SERIES_GAP).

    Returns list of dicts: {cow_id, ts, T (corrected), T_raw (ruminal),
    day_mu/day_sigma, day_mu_raw/day_sigma_raw} sorted by ts.
    Missing stat columns are filled with None so callers choose what they use.
    """
    import numpy as np

    def _col(sub, name, s, e):
        return sub[name].to_numpy()[s:e] if name in sub else None

    # Forward every day_* stat column plus both temperature columns.
    passthrough = [
        c for c in df.columns if c.startswith("day_")
    ]

    series = []
    for cow, sub in df.groupby("cow_id", sort=True):
        sub = sub.sort_values("ts")
        ts = sub["ts"].to_numpy()
        gaps = np.diff(ts) > SERIES_GAP.to_timedelta64()
        boundaries = np.flatnonzero(gaps)
        starts = np.concatenate(([0], boundaries + 1))
        ends = np.concatenate((boundaries + 1, [len(ts)]))
        for s, e in zip(starts, ends):
            entry = {
                "cow_id": cow,
                "ts": ts[s:e],
                "T": _col(sub, "corrected", s, e),
                "T_raw": _col(sub, "ruminal", s, e),
            }
            for c in passthrough:
                entry[c] = _col(sub, c, s, e)
            series.append(entry)
    return series
