"""Combined drinking-bout detector (our spec) for grid-search calibration.

A candidate event must satisfy BOTH criteria simultaneously:
  A. FallST-style slope: fall rate between adjacent points, normalised by
     the actual time gap (degC/min), is >= S_th.
  B. Per cow per day threshold: the point after the drop is below
     mu_day - k * sigma_day (mu/sigma from that cow-day's corrected RT).

Confirmation (V-shape recovery): after the event onset, the trough is the
end of the initial descending run; within `recovery_window_min` after the
trough the temperature must rebound by >= R_th * D, where D is the total
drop from onset to trough. Candidates failing the recovery check are
discarded (fever-like or artefact shapes).

Confirmed events closer than `merge_gap_min` (default 15 min, revised from
30 by the L1 sensitivity sweep — see spec §14) are merged into a single
event (earliest start kept).
"""

import numpy as np

DEFAULT_RECOVERY_WINDOW_MIN = 120.0
DEFAULT_MERGE_GAP_MIN = 15.0  # spec §14 canonical (was 30 before T2 sweep)


def detect_combined(
    ts,
    T,
    day_mu,
    day_sigma,
    s_th,
    k,
    r_th,
    recovery_window_min=DEFAULT_RECOVERY_WINDOW_MIN,
    merge_gap_min=DEFAULT_MERGE_GAP_MIN,
    in_body_gate=False,
    depth_margin_c=0.0,
):
    """Run the combined detector on one series.

    ts: datetime64 array; T/day_mu/day_sigma: float arrays aligned with ts.
    Returns a list of confirmed bouts {start_ts, end_ts, temp_drop, min_temp}.

    Production-parity switches (NIX-256 review B1/M1 closeout):
    - in_body_gate: drop points outside 35-43C BEFORE detection (mirrors
      the Java kernel's IN_BODY gate, applied to points and day stats).
    - depth_margin_c: extra depth margin — the trough must sit at least
      this many degC below mu-k*sigma (0.0 = L1 calibration semantics;
      the Java kernel judges with an implicit 1.0C reference).
    """
    if in_body_gate:
        # Parity twin of IN_BODY_MIN/IN_BODY_MAX_TEMP in
        # DrinkingEventDetectionService.java — change both together.
        keep = (T >= 35.0) & (T <= 43.0)
        ts, T = ts[keep], T[keep]
        # Recompute per-day mu/sigma from gated points only — the Java
        # kernel gates BEFORE day stats, so parity requires the same.
        import pandas as pd
        df = pd.DataFrame({"ts": ts, "T": T})
        df["day"] = df["ts"].dt.strftime("%Y-%m-%d")
        day_mu = df.groupby("day")["T"].transform("mean").to_numpy()
        day_sigma = df.groupby("day")["T"].transform(lambda x: x.std(ddof=1)).to_numpy()

    n = len(T)
    t_sec = ts.astype("datetime64[s]").astype(np.int64)
    candidates = []
    i = 0
    while i < n - 1:
        dt_min = (t_sec[i + 1] - t_sec[i]) / 60.0
        if dt_min <= 0:
            i += 1
            continue
        fall = T[i] - T[i + 1]
        rate = fall / dt_min  # degC per minute, gap-normalised
        th = day_mu[i + 1] - k * day_sigma[i + 1]
        if rate >= s_th and T[i + 1] < th - depth_margin_c:
            # Trough = end of the initial descending run after the onset.
            j = i + 1
            while j + 1 < n and T[j + 1] <= T[j]:
                j += 1
            t_min = T[j]
            drop = T[i] - t_min
            # Recovery check: max temperature within the window after trough.
            horizon = t_sec[j] + recovery_window_min * 60.0
            m = j
            while m + 1 < n and t_sec[m + 1] <= horizon:
                m += 1
            rebound = float(np.max(T[j : m + 1])) - t_min if m >= j else 0.0
            if drop > 0 and rebound >= r_th * drop:
                candidates.append(
                    {
                        "start_ts": ts[i],
                        "end_ts": ts[j],
                        "temp_drop": drop,
                        "min_temp": t_min,
                    }
                )
        i += 1

    # Merge confirmed events closer than merge_gap_min (start-to-start).
    # Rolling anchor: the gap compares against the previous member's own
    # start, not the merged chain's first start — a chain-first anchor
    # slices a single long descent into phantom segments at exact
    # merge-gap multiples (platform-parity fix, T6 replay 2026-10-05).
    candidates.sort(key=lambda b: b["start_ts"])
    merged = []
    merge_gap_sec = merge_gap_min * 60.0
    last_member_start = None
    for ev in candidates:
        if merged:
            gap = (ev["start_ts"] - last_member_start) / np.timedelta64(1, "s")
            if gap < merge_gap_sec:
                prev = merged[-1]
                prev["end_ts"] = max(prev["end_ts"], ev["end_ts"])
                prev["temp_drop"] = max(prev["temp_drop"], ev["temp_drop"])
                prev["min_temp"] = min(prev["min_temp"], ev["min_temp"])
                last_member_start = ev["start_ts"]
                continue
        merged.append(ev)
        last_member_start = ev["start_ts"]
    return merged
