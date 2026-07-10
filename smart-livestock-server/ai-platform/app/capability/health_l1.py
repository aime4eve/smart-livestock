"""L1 health_anomaly capability（design §4 ★核心）。编排 features + detectors + fusion。"""
import numpy as np
import pandas as pd

from app.capability.base import Capability, CapabilityContext, CapabilityLevel
from app.capability.router import route_by_neff
from app.l1.features import (compute_neff, robust_baseline, cohort_baseline,
                             build_feature_vector, _DIM_NAMES)
from app.l1.detectors import stl_layer_score, cusum_score, fit_mahalanobis, mahalanobis_distance
from app.l1.fusion import normalize_stl, fuse, decide_anomaly_type
from app.schemas import Contributions, PredictRequest, PredictResponse, CapabilityUsed

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
        # req.tenant_id/farm_id 有意不读：ai-platform 是内部服务，租户/牧场 scope 由 Java 边缘
        # 做（design §3，Plan 2 V38 只读账号 + tenant filter）。cohort_baselines Phase A 传 []，
        # 群体兜底分支（见下 robust_baseline NaN 回退）当前为死路径，Plan 2 cohort DB 接入后激活。
        livestock_id = req.livestock_ids[0] if req.livestock_ids else 0
        n_eff = compute_neff(slots_df)
        # 纯阈值路由，无跨次记忆（design §4.3 迟滞 Phase A 不实现，见 router.route_by_neff）
        algo = route_by_neff(n_eff)
        if algo == "iforest":
            # Phase A 未实现 iForest（design §4.3 预留 Phase B），数据足够时降级 mahalanobis
            algo = "mahalanobis"

        # 历史段：排除最近检测窗口（评审 #4 防异常自稀释 + 评审 #7 CUSUM 历史基准）
        win = settings.detection_window_hours * 2
        # 退化边界（复审 N2）：仅当 slots_df≤win(48) 槽时 history_df 回退为含当前窗口的整段，
        # 此时若 n_eff≥30 仍走 mahalanobis 档会有自稀释——属已知边缘情况（正常 14 天 672 槽不触发），Phase A 不特殊处理
        history_df = slots_df.iloc[:-win] if len(slots_df) > win else slots_df

        # 个体基线（每维）：从历史段算，排除当前检测窗口防 self-leak（评审 #4 延伸至基线层）。
        # 退化情况（len≤win）history_df==slots_df，此时整个短序列即历史，无 self-leak。
        # 冷启动用群体兜底。
        baselines: dict[str, tuple[float, float]] = {}
        for dim in _DIM_NAMES:
            med, mad = robust_baseline(history_df[dim].to_numpy())
            if np.isnan(med) and cohort_baselines:
                med, mad = cohort_baseline(cohort_baselines)
            baselines[dim] = (med, mad)

        # L1a STL（温度维主导节律剥离分数；三维取均值增强信号）
        # STL 仍用整个 slots_df（节律分解需要完整周期；STL 残差即目标信号，非基线自引用）
        stl_scores = [stl_layer_score(slots_df[d]) for d in _DIM_NAMES]
        stl_raw = float(np.mean(stl_scores))

        # L1b CUSUM（变点检测）；当前检测窗口与历史段同尺度同预处理（评审 #7）。
        # 去窗口中位数保留 level-shift 信号（STL residual 会吸收阶跃，致信号损失）。
        current_temp = slots_df["temperature"].tail(win)
        cusum_raw = cusum_score(pd.Series(current_temp.to_numpy() - np.median(current_temp.to_numpy())))
        hist_win = max(win, 24)
        history_cusums = []
        for s in range(0, max(1, len(history_df) - hist_win), 12):
            w = history_df.iloc[s:s + hist_win]["temperature"].to_numpy()
            if len(w) >= hist_win // 2:
                history_cusums.append(cusum_score(pd.Series(w - np.median(w))))

        # L1c Mahalanobis（历史矩阵排除当前检测窗口，评审 #4；rules 档或历史不足时跳过，I3 防 self-leak）
        joint_norm = 0.0
        df_keep = 0
        if algo != "rules" and len(slots_df) >= 2 * win:
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
                    # 经验排名归一化：current d2 在历史 d2 分布中的分位数
                    # （解决 chi2.cdf 对病态协方差过敏感；典型正常窗口应落在历史分布中部 ~0.5）。
                    d2_hist = model["d2_hist"]
                    if len(d2_hist) > 0:
                        joint_norm = float(
                            np.searchsorted(np.sort(d2_hist), d2, side="right")
                            / len(d2_hist)
                        )
                    else:
                        joint_norm = 0.0

        stl_norm = normalize_stl(stl_raw)
        # 经验排名归一化（数据驱动）：current CUSUM 在历史 CUSUM 分布中的分位数。
        # 解决 max-normalization 对典型值不敏感的问题（典型窗口 raw≈history_max→饱和 0.93）。
        # fusion.normalize_cusum(max-normalization) 保留为通用工具，此处用经验排名更适配时序场景。
        if history_cusums:
            cusum_norm = float(
                np.searchsorted(np.sort(history_cusums), cusum_raw, side="right")
                / len(history_cusums)
            )
        else:
            cusum_norm = 0.0
        score = fuse(stl_norm, cusum_norm, joint_norm)
        atype = decide_anomaly_type(stl_norm, cusum_norm, joint_norm)

        return PredictResponse(
            livestock_id=livestock_id,
            anomaly_score=score,
            anomaly_type=atype,
            contributions=Contributions(stl=stl_norm, cusum=cusum_norm, joint=joint_norm),
            capability_used=CapabilityUsed.HEALTH_L1,
            n_eff=n_eff,
            model_meta={"router": algo, "weights": [settings.w_stl, settings.w_cusum, settings.w_joint]},
        )
