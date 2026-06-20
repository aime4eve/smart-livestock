"""直连 PostgreSQL 只读数据访问层（design §9.1 方案 A）。

仅 SELECT temperature_logs / rumen_motility_logs / activity_logs 三表（字段契约 design §7.3）。
只读账号由 Plan 2 V38 创建；Phase A 临时用配置账号。
"""
import pandas as pd
import psycopg

from app.config import settings

# design §7.3 字段契约
_QUERIES = {
    "temperature": (
        "SELECT livestock_id, temperature, recorded_at FROM temperature_logs "
        "WHERE livestock_id = %s AND recorded_at >= NOW() - make_interval(hours => %s) "
        "ORDER BY recorded_at"),
    "motility": (
        "SELECT livestock_id, frequency, recorded_at FROM rumen_motility_logs "
        "WHERE livestock_id = %s AND recorded_at >= NOW() - make_interval(hours => %s) "
        "ORDER BY recorded_at"),
    "activity": (
        "SELECT livestock_id, activity_index, recorded_at FROM activity_logs "
        "WHERE livestock_id = %s AND recorded_at >= NOW() - make_interval(hours => %s) "
        "ORDER BY recorded_at"),
}


def _connect():
    return psycopg.connect(
        host=settings.db_host, port=settings.db_port, dbname=settings.db_name,
        user=settings.db_user, password=settings.db_password,
    )


def fetch_window(livestock_id: int, window_hours: int) -> dict[str, pd.Series]:
    """查询单头家畜的三维时序窗口，返回 {dim: Series(index=recorded_at)}。"""
    result: dict[str, pd.Series] = {}
    conn = _connect()
    try:
        for dim, sql in _QUERIES.items():
            with conn.cursor() as cur:
                cur.execute(sql, (livestock_id, window_hours))
                rows = cur.fetchall()
            if rows:
                values = [r[1] for r in rows]
                idx = pd.to_datetime([r[2] for r in rows], utc=True)
                result[dim] = pd.Series(values, index=idx, name=dim)
            else:
                result[dim] = pd.Series([], dtype=float, name=dim)
    finally:
        conn.close()
    return result
