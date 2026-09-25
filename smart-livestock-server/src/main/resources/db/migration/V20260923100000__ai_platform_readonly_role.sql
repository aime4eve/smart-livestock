-- Read-only DB account for the ai-platform Python service (Phase A README
-- follow-up). Until now the service connected as the postgres superuser.
-- Created idempotently; password is also the compose default
-- (AI_DB_PASSWORD) — internal deployment credential, documented in
-- docs/reference/deployment.md like the seed accounts.

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ai_reader') THEN
        CREATE ROLE ai_reader LOGIN PASSWORD 'b979c55d2a617883163f9866be604431';
    END IF;
END
$$;

-- ai-platform only ever reads: health time series (temperature / motility /
-- activity) for /ai/health/analyze and behavior dataset tables for
-- /ai/behavior/*. SELECT-only, schema-wide.
GRANT USAGE ON SCHEMA public TO ai_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ai_reader;

-- PartitionMaintenanceService (and later Flyway migrations) create tables as
-- postgres; default privileges make those inherit the SELECT grant so new
-- monthly partitions and future tables stay readable without re-running this.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    GRANT SELECT ON TABLES TO ai_reader;
