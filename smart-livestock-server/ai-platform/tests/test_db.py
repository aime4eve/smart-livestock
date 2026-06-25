import pandas as pd
import pytest
from datetime import datetime, timezone
import app.db as dbmod


class FakeCursor:
    def __init__(self, rows_by_table):
        self._rows = rows_by_table
        self._last_sql = ""
    def execute(self, sql, params=None):
        self._last_sql = sql
    def fetchall(self):
        return self._rows.pop(0) if self._rows else []
    def __enter__(self): return self
    def __exit__(self, *a): return False


class FakeConn:
    def __init__(self, rows_by_table):
        self._rows = rows_by_table
        self.queries = []
        self.closed = False
    def cursor(self):
        c = FakeCursor(self._rows)
        return c
    def close(self):
        self.closed = True


def test_fetch_window_returns_three_series():
    temp_rows = [(10, 38.5, datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc)),
                 (10, 38.6, datetime(2026, 6, 1, 0, 30, tzinfo=timezone.utc))]
    mot_rows = [(10, 3.0, datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc))]
    act_rows = [(10, 50.0, datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc))]
    fake = FakeConn([temp_rows, mot_rows, act_rows])

    series_map = dbmod.fetch_window(fake, livestock_id=10, window_hours=24)
    assert set(series_map.keys()) == {"temperature", "motility", "activity"}
    assert isinstance(series_map["temperature"], pd.Series)
    assert len(series_map["temperature"]) == 2


def test_fetch_window_handles_empty():
    fake = FakeConn([[], [], []])
    series_map = dbmod.fetch_window(fake, livestock_id=999, window_hours=24)
    assert len(series_map["temperature"]) == 0


def test_fetch_window_empty_dim_returns_datetime_index():
    # 阻断1：部分维缺失（如 activity）时空维须返回 DatetimeIndex，
    # 否则下游 resample_to_slots 遇 RangeIndex 崩（真实数据三维常不齐）
    temp_rows = [(10, 38.5, datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc))]
    fake = FakeConn([temp_rows, [], []])  # motility + activity 空
    s = dbmod.fetch_window(fake, livestock_id=10, window_hours=24)
    assert len(s["temperature"]) == 1
    for d in ("motility", "activity"):
        assert len(s[d]) == 0
        assert isinstance(s[d].index, pd.DatetimeIndex), f"{d} 空维须 DatetimeIndex"


def test_connect_closes_connection(monkeypatch):
    # 评审 H1：connect() 上下文退出后连接关闭
    fake = FakeConn([])
    monkeypatch.setattr(dbmod, "_connect", lambda: fake)
    with dbmod.connect() as conn:
        assert conn is fake
    assert fake.closed is True


def test_connect_does_not_mask_connect_failure(monkeypatch):
    # 评审 H1：_connect() 自身抛错（PG 不可达）时，connect() 不应 NameError 掩盖真实异常
    def boom():
        raise RuntimeError("pg unreachable")
    monkeypatch.setattr(dbmod, "_connect", boom)
    with pytest.raises(RuntimeError, match="pg unreachable"):
        with dbmod.connect():
            pass
