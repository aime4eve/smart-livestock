-- Refresh partition_ops functions on databases that predate NIX-184.
--
-- V20260822100000 was edited IN PLACE on 2026-09-04 (NIX-184 "fresh-database
-- migration chain") to make the default-partition row move generated-column-
-- safe: GENERATED ALWAYS stored columns (temperature_logs.delta) reject
-- explicit values on re-insert, so the move must round-trip without them.
-- Databases that had already applied the migration (dev/test, applied
-- 2026-08-22) kept the OLD whole-row-copy function: applied migrations never
-- re-run, and the checksum reconciliation that keeps Flyway validate green
-- updates history, not the database objects. On such databases the first
-- rebalance that actually has rows to move crashes application startup via
-- PartitionMaintenanceService ("cannot insert a non-DEFAULT value into
-- column delta").
--
-- This migration re-issues both functions with the definitions below,
-- identical to the current V20260822100000 content. On databases provisioned
-- after 2026-09-04 this replaces identical definitions (a no-op); on older
-- ones it converges them onto the fixed move. The row movement itself is
-- left to PartitionMaintenanceService, which rebalances on every startup.

CREATE SCHEMA IF NOT EXISTS partition_ops;

CREATE OR REPLACE FUNCTION partition_ops.ensure_month_partition(
    p_parent regclass,
    p_month date
) RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    v_schema text;
    v_parent text;
    v_partition text;
    v_default text;
    v_stage text;
    v_column text;
    v_cols text;
    v_end date;
    v_moved bigint;
BEGIN
    SELECT n.nspname, c.relname, a.attname
      INTO v_schema, v_parent, v_column
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      LEFT JOIN pg_attribute a
        ON a.attrelid = c.oid
       AND a.attnum = (
            SELECT pt.partattrs[0]
              FROM pg_partitioned_table pt
             WHERE pt.partrelid = c.oid
       )
       AND NOT a.attisdropped
     WHERE c.oid = p_parent;

    IF v_column IS NULL THEN
        RAISE EXCEPTION 'table % is not range-partitioned on one column', p_parent;
    END IF;

    -- GENERATED ALWAYS columns (e.g. temperature_logs.delta) reject explicit
    -- values on re-insert, so row moves must round-trip without them.
    SELECT string_agg(format('%I', a.attname), ', ' ORDER BY a.attnum)
      INTO v_cols
      FROM pg_attribute a
     WHERE a.attrelid = p_parent
       AND a.attnum > 0
       AND NOT a.attisdropped
       AND a.attgenerated = '';

    v_end := (date_trunc('month', p_month) + INTERVAL '1 month')::date;
    v_partition := v_parent || '_' || to_char(p_month, 'YYYY_MM');
    v_default := v_parent || '_default';
    v_stage := v_partition || '_stage';

    IF to_regclass(format('%I.%I', v_schema, v_partition)) IS NOT NULL THEN
        RETURN 0;
    END IF;

    EXECUTE format('DROP TABLE IF EXISTS pg_temp.%I', v_stage);
    EXECUTE format(
        'CREATE TEMP TABLE %I ON COMMIT DROP AS TABLE %I.%I WITH NO DATA',
        v_stage, v_schema, v_default);
    EXECUTE format(
        'INSERT INTO pg_temp.%I SELECT * FROM %I.%I WHERE %I >= %L AND %I < %L',
        v_stage, v_schema, v_default, v_column, p_month, v_column, v_end);
    GET DIAGNOSTICS v_moved = ROW_COUNT;

    IF v_moved > 0 THEN
        EXECUTE format(
            'DELETE FROM %I.%I WHERE %I >= %L AND %I < %L',
            v_schema, v_default, v_column, p_month, v_column, v_end);
    END IF;

    EXECUTE format(
        'CREATE TABLE %I.%I PARTITION OF %I.%I FOR VALUES FROM (%L) TO (%L)',
        v_schema, v_partition, v_schema, v_parent, p_month, v_end);

    IF v_moved > 0 THEN
        EXECUTE format(
            'INSERT INTO %I.%I (%s) SELECT %s FROM pg_temp.%I',
            v_schema, v_parent, v_cols, v_cols, v_stage);
    END IF;

    RETURN v_moved;
END;
$$;

CREATE OR REPLACE FUNCTION partition_ops.rebalance_default_partition(
    p_parent regclass
) RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    v_schema text;
    v_parent text;
    v_default text;
    v_column text;
    v_moved bigint := 0;
    v_month date;
BEGIN
    SELECT n.nspname, c.relname, a.attname
      INTO v_schema, v_parent, v_column
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      LEFT JOIN pg_attribute a
        ON a.attrelid = c.oid
       AND a.attnum = (
            SELECT pt.partattrs[0]
              FROM pg_partitioned_table pt
             WHERE pt.partrelid = c.oid
       )
       AND NOT a.attisdropped
     WHERE c.oid = p_parent;

    IF v_column IS NULL THEN
        RAISE EXCEPTION 'table % is not range-partitioned on one column', p_parent;
    END IF;

    v_default := v_parent || '_default';

    FOR v_month IN
        EXECUTE format(
            'SELECT DISTINCT date_trunc(''month'', %I)::date FROM %I.%I ORDER BY 1',
            v_column, v_schema, v_default)
    LOOP
        v_moved := v_moved + partition_ops.ensure_month_partition(p_parent, v_month);
    END LOOP;

    RETURN v_moved;
END;
$$;
