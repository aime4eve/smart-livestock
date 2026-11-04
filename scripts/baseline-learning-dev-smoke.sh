#!/usr/bin/env bash
# Individual baseline auto-learning — dev end-to-end smoke (plan 2026-11-03 Task 6).
# Canonical, reproducible sequence. Executed step-by-step interactively on 2026-11-04;
# real outputs captured in the delivery record (plan file 交付记录 section).
#
# Usage: run ON the dev host (172.22.1.123) or export SSH_HOST and run remotely.
# Every phase is idempotent for the fixed smoke fixtures (livestock code
# BL-SMOKE-001, dev EUI BLSMK0000001). Night-sample times depend on the resolved
# farm zone (dev farm 1 = Asia/Shanghai → UTC 13:30/14:30/15:30), so phase_plant
# ships the exact SQL used during the 2026-11-04 run in /tmp/bl-smoke-plant.sql.
#
# Phases (match plan Task 6):
#   1 fixture    : livestock + capsule device + active install + snapshot(DEFAULT/38.50)
#   2 initial    : curl fever detail  -> baselineSource=DEFAULT, baseline=38.50
#   3 plant      : 8 days x 3 night samples (MANUAL_IMPORT) + 5 activity rows
#   4 recalc     : admin recalculate  -> learnedNow=true
#   5 verify     : curl fever detail  -> LEARNED + evidence fields
#   6 frames     : real telemetry via datagen pipeline (add device to
#                  datagen_device_assignments; frames flow ingest -> MQ ->
#                  health consumer) -> new log carries LEARNED baseline,
#                  estrus_scores row carries the audit columns
#   7 evaluate   : admin evaluations  -> DEFAULT vs LEARNED same-input comparison
#   8 history    : SQL assertion — zero rewrite of historical rows
#   9 rollback   : append SMARTLIVESTOCK_HEALTH_BASELINE_LEARNING_APPLY_LEARNED=false
#                  to .env.dev, recreate the app WITH --env-file .env.dev (plain
#                  `docker compose up -d app` would interpolate DATAGEN_ENABLED
#                  to false and silently stop the pipeline — 2026-11-04 lesson),
#                  assert new frames score/ingest on 38.50; revert and assert
#                  LEARNED resumes
#  10 cleanup    : delete smoke rows/assignment/device/livestock
set -euo pipefail

SSH_HOST="${SSH_HOST:-}"
SSH_PREFIX=""
[ -n "$SSH_HOST" ] && SSH_PREFIX="ssh $SSH_HOST"

DEV_PORT="${DEV_PORT:-19080}"
CODE="BL-SMOKE-001"
EUI="BLSMK0000001"
OWNER_TOKEN="${OWNER_TOKEN:?export OWNER_TOKEN=<seed owner jwt>}"
ADMIN_TOKEN="${ADMIN_TOKEN:?export ADMIN_TOKEN=<platform admin jwt>}"

# Run one SQL statement ($1) against the dev database inside its container;
# credentials are fixed by docker-compose.dev.yml (postgres/smart_livestock).
run_sql() {
  $SSH_PREFIX "docker exec -i sl-dev-postgres-1 psql -U postgres -d smart_livestock -Atc \"$1\""
}

phase_fixture() {
  # livestock + capsule device + active install + snapshot row (all defaults).
  # Farm 1 on dev; the resolved zone (farm → tenant chain) decides night hours.
  run_sql "
    INSERT INTO livestock (farm_id, livestock_code, breed, gender, birth_date, health_status)
    SELECT 1, '$CODE', 'ANGUS', 'FEMALE', NOW() - INTERVAL '3 years', 'HEALTHY'
    WHERE NOT EXISTS (SELECT 1 FROM livestock WHERE livestock_code='$CODE');
    INSERT INTO devices (tenant_id, device_code, device_type, status, dev_eui, runtime_status)
    SELECT (SELECT tenant_id FROM farms WHERE id=1), 'BL-SMOKE-DEV', 'CAPSULE', 'ACTIVE', '$EUI', 'offline'
    WHERE NOT EXISTS (SELECT 1 FROM devices WHERE dev_eui='$EUI');
    INSERT INTO installations (device_id, livestock_id, installed_at)
    SELECT d.id, l.id, NOW() FROM devices d, livestock l
    WHERE d.dev_eui='$EUI' AND l.livestock_code='$CODE'
      AND NOT EXISTS (SELECT 1 FROM installations i WHERE i.device_id=d.id AND i.removed_at IS NULL);
    INSERT INTO health_snapshots (livestock_id, farm_id)
    SELECT l.id, l.farm_id FROM livestock l WHERE l.livestock_code='$CODE'
    ON CONFLICT (livestock_id) DO NOTHING;
    SELECT 'livestock='||l.id||' device='||d.id||' snapshot='||s.baseline_temp||'/'||s.baseline_source
    FROM livestock l JOIN devices d ON d.dev_eui='$EUI'
    LEFT JOIN health_snapshots s ON s.livestock_id=l.id WHERE l.livestock_code='$CODE';"
}

phase_plant() {
  # 8 qualified days x 3 night samples (UTC 13:30/14:30/15:30 = Shanghai local
  # 21:30/22:30/23:30, values 39.30/39.40/39.50 so MAD=0.1 keeps every sample)
  # + 5 low-activity rows. The live id lookup keeps the phase re-runnable.
  $SSH_PREFIX "docker exec -i sl-dev-postgres-1 psql -U postgres -d smart_livestock -v ON_ERROR_STOP=1" <<'SQL'
INSERT INTO temperature_logs (livestock_id, device_id, temperature, baseline_temp, recorded_at, source)
SELECT l.id, d.id, v.temp, 38.50,
       (date_trunc('day', NOW() AT TIME ZONE 'UTC') - v.d * INTERVAL '1 day'
        + v.h * INTERVAL '1 hour' + INTERVAL '30 minutes'),
       'MANUAL_IMPORT'
FROM livestock l, devices d,
     (VALUES (1,13,39.30),(1,14,39.40),(1,15,39.50),
             (2,13,39.30),(2,14,39.40),(2,15,39.50),
             (3,13,39.30),(3,14,39.40),(3,15,39.50),
             (4,13,39.30),(4,14,39.40),(4,15,39.50),
             (5,13,39.30),(5,14,39.40),(5,15,39.50),
             (6,13,39.30),(6,14,39.40),(6,15,39.50),
             (7,13,39.30),(7,14,39.40),(7,15,39.50),
             (8,13,39.30),(8,14,39.40),(8,15,39.50)) AS v(d,h,temp)
WHERE l.livestock_code='BL-SMOKE-001' AND d.dev_eui='BLSMK0000001';
INSERT INTO activity_logs (livestock_id, device_id, step_count, activity_index, distance_meters, recorded_at, source)
SELECT l.id, d.id, 100, v.idx, 50.00,
       (date_trunc('day', NOW() AT TIME ZONE 'UTC') - v.d * INTERVAL '1 day' + INTERVAL '14 hours'),
       'MANUAL_IMPORT'
FROM livestock l, devices d,
     (VALUES (1,5.0),(2,8.0),(3,6.0),(4,7.0),(5,4.0)) AS v(d,idx)
WHERE l.livestock_code='BL-SMOKE-001' AND d.dev_eui='BLSMK0000001';
SELECT 'planted_temps='||count(*) FROM temperature_logs t JOIN livestock l ON l.id=t.livestock_id
WHERE l.livestock_code='BL-SMOKE-001' AND t.source='MANUAL_IMPORT';
SQL
}

phase_history_check() {
  # 8: historical rows are never rewritten — every MANUAL_IMPORT row must
  # still carry baseline_temp=38.50 and baseline_source='DEFAULT' (expect 0).
  run_sql "
    SELECT 'rewritten_history='||count(*)
    FROM temperature_logs t JOIN livestock l ON l.id=t.livestock_id
    WHERE l.livestock_code='$CODE' AND t.source='MANUAL_IMPORT'
      AND (t.baseline_temp <> 38.50 OR t.baseline_source <> 'DEFAULT');"
}

phase_cleanup() {
  # Order matters: telemetry frames FK-block the device delete; the datagen
  # assignment FK-blocks it too. Assignment first (or removed_at), then
  # business rows, then frames, then device/livestock.
  run_sql "
    DELETE FROM datagen_device_assignments WHERE device_id = (SELECT id FROM devices WHERE dev_eui='$EUI');
    DELETE FROM estrus_scores WHERE livestock_id IN (SELECT id FROM livestock WHERE livestock_code='$CODE');
    DELETE FROM temperature_logs WHERE livestock_id IN (SELECT id FROM livestock WHERE livestock_code='$CODE');
    DELETE FROM activity_logs  WHERE livestock_id IN (SELECT id FROM livestock WHERE livestock_code='$CODE');
    DELETE FROM health_snapshots WHERE livestock_id IN (SELECT id FROM livestock WHERE livestock_code='$CODE');
    DELETE FROM installations WHERE livestock_id IN (SELECT id FROM livestock WHERE livestock_code='$CODE');
    DELETE FROM device_telemetry_logs WHERE device_id IN (SELECT id FROM devices WHERE dev_eui='$EUI');
    DELETE FROM devices WHERE dev_eui='$EUI';
    DELETE FROM livestock WHERE livestock_code='$CODE';
    SELECT 'leftover_devices='||count(*) FROM devices WHERE dev_eui='$EUI';
    SELECT 'leftover_livestock='||count(*) FROM livestock WHERE livestock_code='$CODE';"
}

# curl helpers (run from the dev host so localhost:19080 applies; set SSH_HOST
# to also tunnel — plain remote curl targets 172.22.1.123:$DEV_PORT instead).
fever_detail() {
  local host="localhost"; [ -n "$SSH_HOST" ] && host="172.22.1.123"
  curl -s -H "Authorization: Bearer $OWNER_TOKEN" \
    "http://$host:$DEV_PORT/api/v1/farms/1/health/fever/$1"
}
admin_recalc() {
  local host="localhost"; [ -n "$SSH_HOST" ] && host="172.22.1.123"
  curl -s -X POST -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
    -d "{\"livestockId\": $1}" \
    "http://$host:$DEV_PORT/api/v1/admin/health/baseline-learning/recalculate"
}
admin_evaluations() {
  local host="localhost"; [ -n "$SSH_HOST" ] && host="172.22.1.123"
  curl -s -X POST -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
    -d "{\"livestockId\": $1}" \
    "http://$host:$DEV_PORT/api/v1/admin/health/baseline-learning/evaluations"
}

# Real-frame source (phase 6): datagen pipeline. RocketMQ 5.1 tools.sh has no
# `producer sendMessage`, so frames are produced by adding the smoke device to
# the farm's datagen assignment set; ingest → MQ → health consumer stay real.
phase_frames_enable() {
  run_sql "
    INSERT INTO datagen_device_assignments (control_id, device_id)
    SELECT (SELECT id FROM datagen_farm_controls WHERE farm_id=1 AND enabled),
           (SELECT id FROM devices WHERE dev_eui='$EUI')
    WHERE NOT EXISTS (
      SELECT 1 FROM datagen_device_assignments a
      WHERE a.device_id=(SELECT id FROM devices WHERE dev_eui='$EUI') AND a.removed_at IS NULL);
    SELECT 'assigned='||count(*) FROM datagen_device_assignments a
    JOIN devices d ON d.id=a.device_id WHERE d.dev_eui='$EUI' AND a.removed_at IS NULL;"
}

case "${1:-}" in
  fixture)  phase_fixture ;;
  plant)    phase_plant ;;
  history)  phase_history_check ;;
  frames)   phase_frames_enable ;;
  cleanup)  phase_cleanup ;;
  fever)    fever_detail "$2" ;;
  recalc)   admin_recalc "$2" ;;
  evaluate) admin_evaluations "$2" ;;
  *) echo "usage: $0 {fixture|plant|history|frames|cleanup|fever <id>|recalc <id>|evaluate <id>}" ;;
esac
