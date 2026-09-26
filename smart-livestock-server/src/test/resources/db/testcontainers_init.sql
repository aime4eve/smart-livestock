-- The shared ai_reader migration grants default privileges for the role used
-- in deployed databases. Testcontainers creates its default "test" role, so
-- add the expected role before Flyway runs without changing its checksum.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
        CREATE ROLE postgres;
    END IF;
END
$$;
