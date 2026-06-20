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
    def cursor(self):
        c = FakeCursor(self._rows)
        return c
    def close(self): pass


def test_fetch_window_returns_three_series(monkeypatch):
    temp_rows = [(10, 38.5, datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc)),
                 (10, 38.6, datetime(2026, 6, 1, 0, 30, tzinfo=timezone.utc))]
    mot_rows = [(10, 3.0, datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc))]
    act_rows = [(10, 50.0, datetime(2026, 6, 1, 0, 0, tzinfo=timezone.utc))]
    fake = FakeConn([temp_rows, mot_rows, act_rows])
    monkeypatch.setattr(dbmod, "_connect", lambda: fake)

    series_map = dbmod.fetch_window(livestock_id=10, window_hours=24)
    assert set(series_map.keys()) == {"temperature", "motility", "activity"}
    assert isinstance(series_map["temperature"], pd.Series)
    assert len(series_map["temperature"]) == 2


def test_fetch_window_handles_empty(monkeypatch):
    fake = FakeConn([[], [], []])
    monkeypatch.setattr(dbmod, "_connect", lambda: fake)
    series_map = dbmod.fetch_window(livestock_id=999, window_hours=24)
    assert len(series_map["temperature"]) == 0
