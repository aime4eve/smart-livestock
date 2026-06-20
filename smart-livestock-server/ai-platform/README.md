# ai-platform

Phase A：无监督健康异常检测 Python 微服务（design `docs/superpowers/specs/2026-06-19-ai-health-anomaly-detection-design.md`）。

## 本地开发

```bash
cd smart-livestock-server/ai-platform
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest                         # 全部测试
uvicorn app.main:app --reload  # 本地起服务（需 PG）
```

## 配置

环境变量见 `app/config.py`。DB 连接：
- Phase A 临时用 `postgres` 超管账号跑通。
- **生产切换**：Plan 2 的 `V38__add_ai_anomaly_tables.sql` 创建只读账号后，设 `AI_DB_USER` 为该只读账号。

## 与 Java 后端的关系

Java 后端（`HealthAnomalyService`）经 HTTP 调本服务的 `/ai/health/analyze`，ai-platform 直连 PG 只读查询时序窗口、返回 `PredictResponse`，由 Java 端写库（见 design §3）。
