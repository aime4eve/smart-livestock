#!/usr/bin/env bash
# NIX-324 造态/恢复成对脚本（dev 库；造态后必恢复——10-27 renewal_failed 并行冲突教训）
# 用法: ./nix324-seed-state-smoke.sh <state>
#   state ∈ trial|renewal_failed|suspended|cancelled|expired|expiring_13|expiring_6|expiring_soon|healthy|restore
#   expiring_13 = 临期 14 天级（info，有稍后提醒）；expiring_6 = 临期 7 天级（warn，有稍后提醒）；
#   expiring_soon = 临期 3 天级（danger，无稍后提醒）——NIX-334 验收用
# SSH 目标与 deploy.sh 一致；所有带 $ 的 SQL 走 stdin（ssh 传 hash 教训）
set -euo pipefail
REMOTE="agentic@172.22.1.123"
PSQL="docker exec -i sl-dev-postgres-1 psql -U postgres -d smart_livestock"
T=${1:?state required}
case "$T" in
  trial)          SQL="UPDATE subscriptions SET status='trial', trial_ends_at=now()+interval '20 days', expires_at=NULL WHERE tenant_id=1;";;
  renewal_failed) SQL="UPDATE subscriptions SET status='renewal_failed', expires_at=now()-interval '1 days' WHERE tenant_id=1;";;
  suspended)      SQL="UPDATE subscriptions SET status='suspended' WHERE tenant_id=1;";;
  cancelled)      SQL="UPDATE subscriptions SET status='cancelled', cancelled_at=now() WHERE tenant_id=1;";;
  expired)        SQL="UPDATE subscriptions SET status='expired', expires_at=now()-interval '10 days' WHERE tenant_id=1;";;
  expiring_13)    SQL="UPDATE subscriptions SET status='active', expires_at=now()+interval '13 days', cancelled_at=NULL, trial_ends_at=NULL WHERE tenant_id=1;";;
  expiring_6)     SQL="UPDATE subscriptions SET status='active', expires_at=now()+interval '6 days', cancelled_at=NULL, trial_ends_at=NULL WHERE tenant_id=1;";;
  expiring_soon)  SQL="UPDATE subscriptions SET status='active', expires_at=now()+interval '5 days' WHERE tenant_id=1;";;
  healthy)        SQL="UPDATE subscriptions SET status='active', expires_at=now()+interval '90 days' WHERE tenant_id=1;";;
  restore)        SQL="UPDATE subscriptions SET status='renewal_failed', expires_at=now()-interval '10 days', cancelled_at=NULL, trial_ends_at=NULL WHERE tenant_id=1;";;
  *) echo "unknown state $T"; exit 1;;
esac
echo "$SQL" | ssh "$REMOTE" "$PSQL"
echo "[OK] tenant1 → $T （走查完记得 ./nix324-seed-state-smoke.sh restore）"
