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
- 已切换只读账号 `ai_reader`（迁移 `V20260923100000__ai_platform_readonly_role.sql` 创建，SELECT-only + 未来分区默认权限）；compose 默认 `AI_DB_USER=ai_reader`，凭据见 `docs/reference/deployment.md`。
- 触发方式（NIX-243）：Java 侧 `HealthAnomalyScheduler` 每 5 分钟对近 2h 有温度数据的牲畜逐头调用 `/ai/health/analyze`，Redis 去重限频每头每小时一次；不再挂在遥测消费事务内（2026-06-30 REQUIRES_NEW 事故教训）。

## 与 Java 后端的关系

Java 后端（`HealthAnomalyService`）经 HTTP 调本服务的 `/ai/health/analyze`，ai-platform 直连 PG 只读查询时序窗口、返回 `PredictResponse`，由 Java 端写库（见 design §3）。

## Docker 部署（docker-compose）

ai-platform 已加入 `smart-livestock-server/docker-compose.yml`，端口 `18000:8000`，依赖 `postgres` 健康检查。Java 端 `depends_on` 联调留待 Plan 2。

```bash
# 构建 + 启动（需 Docker）
cd smart-livestock-server && docker compose build ai-platform && docker compose up -d ai-platform
# 探活
curl -s http://localhost:18000/ai/health/live   # 期望 {"status":"ok"}
```

> Phase A 本地无 Docker（环境限制），由部署阶段（172.22.1.123）验证。
