#!/usr/bin/env bash
# =============================================================================
# reset-admin-password.sh — emergency platform-admin password reset (NIX-191)
#
# Use case: an ONPREM customer lost the deployment administrator password.
# There is no email/SMS recovery on an air-gapped box, so an operator with
# server access runs this script locally. It sets a NEW temporary password
# (must satisfy the strength rule) and re-arms the forced password change so
# the administrator must personalize it at next login.
#
# Usage: sudo bash scripts/reset-admin-password.sh <phone> <new-temp-password>
# Requires: the release stack running on this host (uses the postgres
# container) and pgcrypto (present in the postgres image).
# Audit: the change is written to deployment_license_events-style audit? No —
# user changes are visible via the users table update time; keep an offline
# note per ops policy.
# =============================================================================
set -euo pipefail

PHONE="${1:?usage: reset-admin-password.sh <phone> <new-temp-password>}"
NEW_PASSWORD="${2:?usage: reset-admin-password.sh <phone> <new-temp-password>}"

if [[ ! ${PHONE} =~ ^[0-9]{5,20}$ ]]; then
  echo "[FAIL] 手机号必须是 5-20 位数字" >&2
  exit 1
fi
if [[ ${NEW_PASSWORD} == *[\'\\]* ]]; then
  echo "[FAIL] 新密码不能包含单引号或反斜杠" >&2
  exit 1
fi

if [[ ${#NEW_PASSWORD} -lt 10 ]]; then
  echo "[FAIL] 新密码至少 10 位（需含字母和数字）" >&2
  exit 1
fi
if ! [[ ${NEW_PASSWORD} =~ [A-Za-z] ]] || ! [[ ${NEW_PASSWORD} =~ [0-9] ]]; then
  echo "[FAIL] 新密码必须同时包含字母和数字" >&2
  exit 1
fi

PG_CONTAINER="$(docker ps --format '{{.Names}}' | grep -E 'release-postgres|postgres' | head -1)"
[[ -n ${PG_CONTAINER} ]] || { echo "[FAIL] 未找到 postgres 容器" >&2; exit 1; }

ROW="$(docker exec -i "${PG_CONTAINER}" psql -U postgres -d smart_livestock -t -A -c \
  "SELECT id FROM users WHERE phone='${PHONE}' AND role='PLATFORM_ADMIN' LIMIT 1;")"
[[ -n ${ROW} ]] || { echo "[FAIL] 未找到该手机号的管理员: ${PHONE}" >&2; exit 1; }

# bcrypt via pgcrypto; force a password change at next login.
docker exec -i "${PG_CONTAINER}" psql -U postgres -d smart_livestock -v ON_ERROR_STOP=1 <<SQL
UPDATE users
SET password_hash = encode( crypt('${NEW_PASSWORD}', gen_salt('bf', 10)), 'escape'),
    must_change_password = TRUE,
    updated_at = NOW()
WHERE id = ${ROW};
SQL

echo "[OK] 管理员 ${PHONE} 的密码已重置为临时密码，下次登录将被强制要求再次修改。"
