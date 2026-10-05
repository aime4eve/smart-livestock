"""Reproduction of the three detection methods of Aube et al. 2025.

Method definitions follow the paper text verbatim:
- FixT: bout starts when RT < 38.1 degC; ends when RT rises back above 38.1.
- Cow-dT: per cow per day threshold = mean(RT_day) - std(RT_day) (k=1);
  bout starts below the threshold, ends when RT rises back above it.
- FallST: bout starts when RT drops by more than 0.5 degC within a single
  5-min interval; ends when temperature recovers from the trough by 75% of
  the total drinking-induced drop D (D = T at onset - T at trough).
- Common early-termination rule (all three methods): if a point inside an
  ongoing bout is a local peak (strictly higher than both neighbours), the
  bout ends immediately there, so a second drinking event can be detected.
"""

import numpy as np

FIXT_THRESHOLD = 38.1
FALLST_DROP = 0.5
FALLST_RECOVERY_FRACTION = 0.75
COWDT_K = 1.0


def _local_peak(T, j):
    """True when point j is strictly higher than both neighbours."""
    return T[j] > T[j - 1] and T[j] > T[j + 1]


def detect_fixt(ts, T):
    """FixT on one series. Returns list of dicts with start/end indices."""
    n = len(T)
    bouts = []
    i = 0
    while i < n:
        if T[i] < FIXT_THRESHOLD:
            start = i
            end = n - 1
            j = i
            while j < n:
                # Early termination on a local peak inside the bout.
                if j > start and j < n - 1 and _local_peak(T, j):
                    end = j
                    break
                # Normal termination: recovery above the fixed threshold.
                if T[j] > FIXT_THRESHOLD:
                    end = j
                    break
                j += 1
            bouts.append({"start_idx": start, "end_idx": end})
            i = end + 1
        else:
            i += 1
    return bouts


def detect_cowdt(ts, T, day_mu, day_sigma):
    """Cow-dT (k=1) on one series with per-day mu/sigma arrays aligned to T."""
    n = len(T)
    th = day_mu - COWDT_K * day_sigma
    bouts = []
    i = 0
    while i < n:
        if T[i] < th[i]:
            start = i
            end = n - 1
            j = i
            while j < n:
                if j > start and j < n - 1 and _local_peak(T, j):
                    end = j
                    break
                if T[j] > th[j]:
                    end = j
                    break
                j += 1
            bouts.append({"start_idx": start, "end_idx": end})
            i = end + 1
        else:
            i += 1
    return bouts


def detect_fallst(ts, T):
    """FallST on one series (5-min interval drop > 0.5 degC onset).

    After a bout ends, scanning resumes at the end point itself (not the
    next point): when the bout ended on a local peak, that peak is the
    onset point of the following fall (second drinking bout). This detail
    is required to reproduce the paper's sensitivity (F 94.4 vs 94.5).
    """
    n = len(T)
    bouts = []
    i = 0
    while i < n - 1:
        if T[i] - T[i + 1] > FALLST_DROP:
            start = i
            end = n - 1
            t_start = T[i]
            t_min = T[i + 1]
            j = i + 1
            while j < n:
                # Track the trough as the running minimum.
                if T[j] < t_min:
                    t_min = T[j]
                D = t_start - t_min
                # Early termination on a local peak inside the bout.
                if j > start and j < n - 1 and _local_peak(T, j):
                    end = j
                    break
                # Normal termination: recovery of 75% of the total drop D.
                if D > 0 and T[j] >= t_min + FALLST_RECOVERY_FRACTION * D:
                    end = j
                    break
                j += 1
            bouts.append({"start_idx": start, "end_idx": end})
            i = end
        else:
            i += 1
    return bouts
