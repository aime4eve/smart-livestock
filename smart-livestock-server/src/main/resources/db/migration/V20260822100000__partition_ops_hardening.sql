-- Add query-path indexes missed by the initial schema reviews.
CREATE INDEX IF NOT EXISTS idx_notifications_user_created_at
    ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_livestock_id
    ON alerts(livestock_id);
CREATE INDEX IF NOT EXISTS idx_alerts_fence_id
    ON alerts(fence_id);

CREATE SCHEMA IF NOT EXISTS partition_ops;

-- Create one monthly partition and move any overlapping rows out of the
-- default partition first. PostgreSQL otherwise rejects the new partition.
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
            'INSERT INTO %I.%I SELECT * FROM pg_temp.%I',
            v_schema, v_parent, v_stage);
    END IF;

    RETURN v_moved;
END;
$$;

-- Route every month currently parked in the default partition to its real
-- monthly partition. This is safe to run repeatedly.
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

DO $$
DECLARE
    tables text[] := ARRAY[
        'temperature_logs',
        'rumen_motility_logs',
        'activity_logs',
        'device_telemetry_logs',
        'anomaly_scores'
    ];
    parent regclass;
    table_name text;
BEGIN
    FOREACH table_name IN ARRAY tables LOOP
        parent := to_regclass(format('public.%I', table_name));
        PERFORM partition_ops.rebalance_default_partition(parent);
        PERFORM partition_ops.ensure_month_partition(
            parent,
            (date_trunc('month', CURRENT_DATE) + INTERVAL '0 month')::date);
        PERFORM partition_ops.ensure_month_partition(
            parent,
            (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month')::date);
        PERFORM partition_ops.ensure_month_partition(
            parent,
            (date_trunc('month', CURRENT_DATE) + INTERVAL '2 month')::date);
    END LOOP;
END;
$$;
