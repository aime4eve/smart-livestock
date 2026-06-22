"""直连 PostgreSQL 只读数据访问层（design §9.1 方案 A）。

仅 SELECT temperature_logs / rumen_motility_logs / activity_logs 三表（字段契约 design §7.3）。
只读账号由 Plan 2 V38 创建；Phase A 临时用配置账号。

时区假设（评审 M1）：recorded_at 列为 TIMESTAMP WITHOUT TIME ZONE（V20）。
pd.to_datetime(..., utc=True) 对 naive 时间戳按 UTC 解释（赋值不转换），
故假设 PG 服务器/容器 timezone='UTC'（docker-compose 默认 UTC）。部署机
172.22.1.123 若 PG GUC 非 UTC，需改查询为 `recorded_at AT TIME ZONE 'UTC' AS recorded_at`，
Plan 2 联调时用真实数据验证窗口边界。
"""
from contextlib import contextmanager
from typing import Iterator

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


@contextmanager
def connect() -> Iterator[psycopg.Connection]:
    """连接上下文：建连 → yield → 关闭。

    评审 H1：批量端点 max_length=100，若每头一次 _connect() 会产生 TCP+auth 风暴。
    调用方用 `with connect() as conn:` 批量共享一个只读连接（事务只读，无竞争）。
    conn=None 防止 _connect() 自身抛错（PG 不可达）时 finally 里 NameError 掩盖真实异常。
    """
    conn = None
    try:
        conn = _connect()
        yield conn
    finally:
        if conn is not None:
            conn.close()


def fetch_window(conn, livestock_id: int, window_hours: int) -> dict[str, pd.Series]:
    """在给定连接上查询单头家畜的三维时序窗口，返回 {dim: Series(index=recorded_at)}。

    连接由调用方管理（评审 H1 批量共享），本函数不建连/关连。
    """
    result: dict[str, pd.Series] = {}
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
    return result
