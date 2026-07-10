"""ai-platform 配置。所有阈值/权重/窗口集中于此（design §4.3 N_eff 分档、§4.4 融合权重）。"""
import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    # PostgreSQL 只读连接（账号由 Plan 2 V38 创建，Phase A 临时用 postgres 跑通）
    db_host: str = os.getenv("AI_DB_HOST", "postgres")
    db_port: int = int(os.getenv("AI_DB_PORT", "5432"))
    db_name: str = os.getenv("AI_DB_NAME", "smart_livestock")
    db_user: str = os.getenv("AI_DB_USER", "postgres")
    db_password: str = os.getenv("AI_DB_PASSWORD", "postgres")

    # 融合权重（design §4.4 初始值；联合层略高，捕获多维耦合盲区）
    w_stl: float = float(os.getenv("AI_W_STL", "0.3"))
    w_cusum: float = float(os.getenv("AI_W_CUSUM", "0.3"))
    w_joint: float = float(os.getenv("AI_W_JOINT", "0.4"))

    # N_eff 分档阈值（design §4.3）；迟滞 Phase A 不实现（见 router.route_by_neff）
    neff_mahalanobis_min: int = int(os.getenv("AI_NEFF_MAH_MIN", "30"))
    neff_iforest_min: int = int(os.getenv("AI_NEFF_IFOREST_MIN", "200"))

    # 时序窗口与粒度（design §4.1）
    detection_window_hours: int = int(os.getenv("AI_DETECT_WINDOW_H", "24"))
    baseline_window_days: int = int(os.getenv("AI_BASELINE_WINDOW_D", "14"))
    slot_minutes: int = int(os.getenv("AI_SLOT_MIN", "30"))

    # 告警阈值（融合分数超此值由 Java 端写 alerts）
    alert_threshold: float = float(os.getenv("AI_ALERT_THRESHOLD", "0.7"))

    def __post_init__(self):
        for fld in ("detection_window_hours", "baseline_window_days", "slot_minutes",
                    "neff_mahalanobis_min", "neff_iforest_min"):
            v = getattr(self, fld)
            if not isinstance(v, int) or v <= 0:
                raise ValueError(f"{fld} must be a positive integer, got {v!r}")
        if not (0.0 < self.alert_threshold < 1.0):
            raise ValueError(f"alert_threshold must be in (0,1), got {self.alert_threshold!r}")
        wsum = self.w_stl + self.w_cusum + self.w_joint
        if abs(wsum - 1.0) > 0.01:
            raise ValueError(f"fusion weights must sum to ~1.0, got {wsum!r}")


settings = Settings()
