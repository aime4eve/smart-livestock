"""L1 health_anomaly capability（design §4 ★核心）。编排 features + detectors + fusion。"""
import numpy as np
import pandas as pd

from app.capability.base import Capability, CapabilityContext, CapabilityLevel
from app.capability.router import route_by_neff
from app.l1.features import (compute_neff, robust_baseline, cohort_baseline,
                             build_feature_vector, _DIM_NAMES)
from app.l1.detectors import stl_layer_score, cusum_score, fit_mahalanobis, mahalanobis_distance
from app.l1.fusion import (normalize_stl, normalize_cusum, normalize_mahalanobis,
                           fuse, decide_anomaly_type)
from app.schemas import Contributions, PredictRequest, PredictResponse

from app.config import settings


class HealthAnomalyL1(Capability):
    """L1 无监督健康异常检测（design §4）。"""

    @property
    def level(self) -> CapabilityLevel:
        return CapabilityLevel.L1

    def is_available(self, ctx: CapabilityContext) -> bool:
        # L1 始终可用：N_eff<30 内部降级到"纯规则 + 群体基线"档（design §4.3 冷启动）
        return True

    def predict(self, req: PredictRequest, ctx: CapabilityContext) -> PredictResponse:
        # HTTP 层负责取数后调 predict_series；predict 在 engine 透传链路保留
        raise NotImplementedError("Use predict_series with pre-fetched window data")

    def predict_series(self, req: PredictRequest, slots_df: pd.DataFrame,
                       cohort_baselines: list[tuple[float, float]]) -> PredictResponse:
        livestock_id = req.livestock_ids[0] if req.livestock_ids else 0
        n_eff = compute_neff(slots_df)
        router_state: dict = {}
        algo = route_by_neff(n_eff, state=router_state)
        if algo == "iforest":
            # Phase A 未实现 iForest（design §4.3 预留 Phase B），数据足够时降级 mahalanobis
            algo = "mahalanobis"

        # 个体基线（每维），冷启动用群体兜底
        baselines: dict[str, tuple[float, float]] = {}
        for dim in _DIM_NAMES:
            med, mad = robust_baseline(slots_df[dim].to_numpy())
            if np.isnan(med) and cohort_baselines:
                med, mad = cohort_baseline(cohort_baselines)
            baselines[dim] = (med, mad)

        # L1a STL（温度维主导节律剥离分数；三维取均值增强信号）
        stl_scores = [stl_layer_score(slots_df[d]) for d in _DIM_NAMES]
        stl_raw = float(np.mean(stl_scores))

        # 历史段：排除最近检测窗口（评审 #4 防异常自稀释 + 评审 #7 CUSUM 历史基准）
        win = settings.detection_window_hours * 2
        # 退化边界（复审 N2）：仅当 slots_df≤win(48) 槽时 history_df 回退为含当前窗口的整段，
        # 此时若 n_eff≥30 仍走 mahalanobis 档会有自稀释——属已知边缘情况（正常 14 天 672 槽不触发），Phase A 不特殊处理
        history_df = slots_df.iloc[:-win] if len(slots_df) > win else slots_df

        # L1b CUSUM（温度残差变点）；history_max 用历史段滚动 CUSUM 最大值，
        # 避免用"当前值×2"导致 CUSUM 维度退化为常数（评审 #7）
        from app.l1.features import stl_residual
        cusum_raw = cusum_score(stl_residual(slots_df["temperature"]))
        hist_win = max(win, 24)
        history_cusums = [
            cusum_score(stl_residual(history_df.iloc[s:s + hist_win]["temperature"]))
            for s in range(0, max(1, len(history_df) - hist_win), 12)
            if len(history_df.iloc[s:s + hist_win]) >= hist_win // 2
        ]
        history_max = max(max(history_cusums) if history_cusums else 1.0, 1.0)

        # L1c Mahalanobis（历史矩阵排除当前检测窗口，评审 #4；rules 档跳过）
        joint_norm = 0.0
        df_keep = 0
        if algo != "rules":
            feats = []
            for start in range(0, max(1, len(history_df) - win), 12):
                window = history_df.iloc[start:start + win]
                if len(window) >= win // 2:
                    v, _ = build_feature_vector(window, baselines)
                    feats.append(v)
            if len(feats) >= 2:
                X = np.array(feats)
                model = fit_mahalanobis(X)
                if model is not None:
                    # 当前特征向量 = 最后 detect_n 槽（build_feature_vector 内部 tail）
                    cur, _ = build_feature_vector(slots_df, baselines)
                    d2 = float(mahalanobis_distance(model, cur.reshape(1, -1))[0])
                    df_keep = int(model["keep_mask"].sum())
                    joint_norm = normalize_mahalanobis(d2, df=df_keep)

        stl_norm = normalize_stl(stl_raw)
        cusum_norm = normalize_cusum(cusum_raw, history_max)
        score = fuse(stl_norm, cusum_norm, joint_norm)
        atype = decide_anomaly_type(stl_norm, cusum_norm, joint_norm)

        return PredictResponse(
            livestock_id=livestock_id,
            anomaly_score=score,
            anomaly_type=atype,
            contributions=Contributions(stl=stl_norm, cusum=cusum_norm, joint=joint_norm),
            capability_used="health_l1",
            n_eff=n_eff,
            model_meta={"router": algo, "weights": [settings.w_stl, settings.w_cusum, settings.w_joint]},
        )
