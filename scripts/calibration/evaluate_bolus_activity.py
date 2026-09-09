#!/usr/bin/env python3
"""Offline calibration: Strathclyde bolus CSV vs system activity thresholds.

Pipeline (mirrors Hamilton 2019 methods where applicable):
  raw CSV (14.5Hz) -> downsample to ~5Hz -> per-axis jerk (x(t)-x(t-1/fs))
  -> jerk vector magnitude -> 60s windows (RMS + majority label)
  -> percentile-normalised activityIndex (0-100)
  -> system threshold function (assessActivityStatus) -> confusion vs labels

Ground truth labels: 0=other, 1=ruminating, 2=grazing.

Usage:
  python3 scripts/calibration/evaluate_bolus_activity.py \
      [--csv data/datasets/strathclyde-bolus/bolus_sample_data.csv] \
      [--report docs/calibration/<name>.md]
"""
import argparse
import pathlib
import sys

import numpy as np
import pandas as pd

LABEL_NAMES = {0: "other", 1: "ruminating", 2: "grazing"}
DOWNSAMPLE = 3          # 14.5Hz -> ~4.83Hz, close to the paper's 5Hz
WINDOW_SECONDS = 60
PCT_LOW, PCT_HIGH = 2, 98  # percentile mapping range for activityIndex


def assess_activity_status(idx: float) -> str:
    """Replica of HealthApplicationService.assessActivityStatus."""
    if idx > 80:
        return "ELEVATED"
    if idx > 40:
        return "NORMAL"
    if idx > 20:
        return "LOW"
    return "ABNORMAL"


def load_windows(csv_path: str) -> pd.DataFrame:
    # File mixes second/millisecond timestamp precision past 07-26 06:05;
    # parse_dates would fall back to object, so parse explicitly as mixed.
    df = pd.read_csv(csv_path)
    df["t"] = pd.to_datetime(df["t"], format="mixed")
    df = df.iloc[::DOWNSAMPLE].copy()

    fs = 1.0 / DOWNSAMPLE  # effective Hz after slicing
    for axis in ("x", "y", "z"):
        df[f"j{axis}"] = df[axis].diff()

    df["jmag"] = np.sqrt(df["jx"] ** 2 + df["jy"] ** 2 + df["jz"] ** 2)
    df = df.dropna(subset=["jmag"])

    df = df.set_index("t")
    g = df.resample(f"{WINDOW_SECONDS}s")
    windows = g["jmag"].apply(lambda s: float(np.sqrt((s ** 2).mean()))).to_frame("rms")
    windows["label"] = g["classification"].agg(lambda s: int(s.mode().iloc[0]))
    windows = windows.dropna()

    lo, hi = np.percentile(windows["rms"], [PCT_LOW, PCT_HIGH])
    span = max(hi - lo, 1e-9)
    windows["activityIndex"] = ((windows["rms"] - lo) / span * 100).clip(0, 100).round(1)
    windows["status"] = windows["activityIndex"].apply(assess_activity_status)
    print(f"windows: {len(windows)}, span {windows.index.min()} .. {windows.index.max()}", file=sys.stderr)
    return windows


def q(series, p):
    return round(float(np.percentile(series, p)), 1)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default="data/datasets/strathclyde-bolus/bolus_sample_data.csv")
    ap.add_argument("--report", default="docs/calibration/2026-09-10-bolus-activity-threshold-report.md")
    args = ap.parse_args()

    windows = load_windows(args.csv)
    total = len(windows)

    lines = []
    lines.append("# Bolus 数据集 vs 系统活动阈值校准报告（离线评估）")
    lines.append("")
    lines.append(f"- 数据窗口：{total} 个 {WINDOW_SECONDS}s 窗口（{DOWNSAMPLE} 倍降采样至 ≈4.8Hz，jerk 差分按论文公式）")
    lines.append(f"- activityIndex 映射：窗口 jerk-RMS 的 P{PCT_LOW}–P{PCT_HIGH} 百分位线性映射到 0–100")
    lines.append(f"- 系统阈值函数：HealthApplicationService.assessActivityStatus（>80 ELEVATED / >40 NORMAL / >20 LOW / 其余 ABNORMAL）")
    lines.append("")

    lines.append("## 1. 各真值行为的活动指数分布")
    lines.append("")
    lines.append("| 真值行为 | 窗口数 | 占比 | P10 | P25 | P50 | P75 | P90 |")
    lines.append("|---|---|---|---|---|---|---|---|")
    for label in (2, 1, 0):
        s = windows[windows["label"] == label]["activityIndex"]
        lines.append(
            f"| {LABEL_NAMES[label]} | {len(s)} | {len(s)*100/total:.1f}% "
            f"| {q(s,10)} | {q(s,25)} | {q(s,50)} | {q(s,75)} | {q(s,90)} |"
        )
    lines.append("")

    lines.append("## 2. 现行阈值下的混淆矩阵（行=真值，列=系统判定，%）")
    lines.append("")
    statuses = ["ELEVATED", "NORMAL", "LOW", "ABNORMAL"]
    lines.append("| 真值 \\ 系统 | " + " | ".join(statuses) + " |")
    lines.append("|---|" + "---|" * len(statuses))
    for label in (2, 1, 0):
        sub = windows[windows["label"] == label]
        row = []
        for st in statuses:
            pct = (sub["status"] == st).mean() * 100 if len(sub) else 0
            row.append(f"{pct:.1f}%")
        lines.append(f"| {LABEL_NAMES[label]} | " + " | ".join(row) + " |")
    lines.append("")

    # Key expectations: grazing should read high (ELEVATED/NORMAL),
    # ruminating moderate (NORMAL), other/rest lowest (LOW/ABNORMAL).
    lines.append("## 3. 现行阈值的关键错判率")
    lines.append("")
    def pct(label, sts):
        sub = windows[windows["label"] == label]
        return (sub["status"].isin(sts)).mean() * 100 if len(sub) else 0
    lines.append(f"- 进食被误判为低活动（LOW/ABNORMAL）：**{pct(2, ['LOW','ABNORMAL']):.1f}%**")
    lines.append(f"- 反刍被误判为异常低（ABNORMAL）：**{pct(1, ['ABNORMAL']):.1f}%**")
    lines.append(f"- 休息(其他)被误判为正常以上（NORMAL/ELEVATED）：**{pct(0, ['NORMAL','ELEVATED']):.1f}%**")
    lines.append("")

    lines.append("## 4. 阈值判读与建议（人工判读分布，2026-09-10）")
    lines.append("")
    graz = windows[windows["label"] == 2]["activityIndex"]
    rumi = windows[windows["label"] == 1]["activityIndex"]
    oth = windows[windows["label"] == 0]["activityIndex"]
    lines.append(f"- **低活动侧误报（最主要问题）**：现行 ABNORMAL(<20) 把 14–15% 的反刍/休息窗口判为“严重异常”，"
                 f"而两类行为的 P10 都在 16–18——20 这条线落在正常行为分布内部，纯误报源。"
                 f"建议 ABNORMAL 下调至 <8（≈全量最低 2% 运动水平），LOW 下调至 <18（≈行为最低 P10）。")
    lines.append(f"- **NORMAL 下线**：反刍 P50 ≈ {q(rumi,50)}、休息 P50 ≈ {q(oth,50)}——低于典型行为中位水平（≈30）"
                 f"即为偏低，建议 NORMAL 下线 40 → **30**。")
    lines.append(f"- **高活动侧**：现行 ELEVATED(>80) 全场仅 2–5% 触发，接近失效；采食 P90 ≈ {q(graz,90)}，"
                 f"建议 ELEVATED 下调至 **≈60**（显著高于采食水平才算异常活跃）。")
    lines.append(f"- 现行值对照：ELEVATED 80 / NORMAL 40 / LOW 20 / ABNORMAL 20。")
    lines.append("")
    lines.append("## 5. 局限性与结论（必读）")
    lines.append("")
    lines.append("1. **反刍与休息几乎不可分**（P50 30.2 vs 30.9，分布高度重叠）——jerk-RMS 单特征对该传感器形态"
                 "的天花板；绝对分档天然不可靠，活动状态长期方向应为**个体相对基线**（与瘤胃护栏同思路）。")
    lines.append("2. 本报告口径为 jerk-RMS 百分位映射（P2–P98→0–100），**设备上报的 activityIndex 是设备端算法口径**，"
                 "两套数字不能直接互搬；本报告价值在于证明现行绝对阈值错判率过高（进食 60.5% 被判低活动），"
                 "并给出该口径下的相对修正方向，而非可直接抄进代码的绝对值。")
    lines.append("3. 单头牛、4.5 天、2015 年单一实验，代表性有限。")

    report = "\n".join(lines) + "\n"
    out = pathlib.Path(args.report)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(report, encoding="utf-8")
    print(report)


if __name__ == "__main__":
    main()
