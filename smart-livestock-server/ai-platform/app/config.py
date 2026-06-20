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

    # N_eff 分档阈值（design §4.3）
    neff_mahalanobis_min: int = int(os.getenv("AI_NEFF_MAH_MIN", "30"))
    neff_iforest_min: int = int(os.getenv("AI_NEFF_IFOREST_MIN", "200"))
    neff_hysteresis: float = float(os.getenv("AI_NEFF_HYST", "0.2"))  # ±20% 迟滞

    # 时序窗口与粒度（design §4.1）
    detection_window_hours: int = int(os.getenv("AI_DETECT_WINDOW_H", "24"))
    baseline_window_days: int = int(os.getenv("AI_BASELINE_WINDOW_D", "14"))
    slot_minutes: int = int(os.getenv("AI_SLOT_MIN", "30"))

    # 告警阈值（融合分数超此值由 Java 端写 alerts）
    alert_threshold: float = float(os.getenv("AI_ALERT_THRESHOLD", "0.7"))


settings = Settings()
