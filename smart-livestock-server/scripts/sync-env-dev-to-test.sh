#!/usr/bin/env bash
set -euo pipefail

# Controlled dev-to-test env sync. Never copies environment-specific secrets:
# DB password, blade configuration, and simulator API keys stay test-owned.
MODE="${1:-dry-run}"
REMOTE="agentic@172.22.1.123"
REMOTE_DIR='~/smart-livestock-server'

case "$MODE" in
  dry-run|apply) ;;
  *)
    echo "Usage: ./scripts/sync-env-dev-to-test.sh <dry-run|apply>" >&2
    exit 1
    ;;
esac

ssh "$REMOTE" "cd $REMOTE_DIR && python3 - '.env.dev' '.env' '$MODE' <<'PY'
from datetime import datetime, timezone
from pathlib import Path
from collections import OrderedDict
import secrets
import shutil
import sys

source_name, target_name, mode = sys.argv[1:4]
source = Path(source_name)
target = Path(target_name)

def read_env(path):
    result = OrderedDict()
    for raw in path.read_text(encoding='utf-8').splitlines():
        line = raw.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, value = line.split('=', 1)
        result[key.strip()] = value.strip().strip('\"')
    return result

def placeholder(value):
    if not value:
        return True
    return value.startswith(('your-', 'generate-', 'default-secret-'))

source_env = read_env(source)
target_env = read_env(target)
merged = OrderedDict(source_env)

# These values identify the test stack and its already-initialized resources.
for key, value in target_env.items():
    if key == 'DB_PASSWORD' or key.startswith(('AGENTIC_PLATFORM_', 'SIMULATOR_')):
        merged[key] = value

# Keep an existing valid test JWT. Replace a placeholder with a unique value.
if placeholder(target_env.get('JWT_SECRET')):
    merged['JWT_SECRET'] = secrets.token_urlsafe(48)

# Preserve any test-only keys not present in the dev template.
for key, value in target_env.items():
    merged.setdefault(key, value)

changed = sorted(key for key in set(merged) | set(target_env)
                 if target_env.get(key) != merged.get(key))
print('mode=' + mode)
print('source_keys=' + str(len(source_env)))
print('target_keys=' + str(len(target_env)))
print('merged_keys=' + str(len(merged)))
print('changed_keys=' + ','.join(changed))
print('generate_jwt=' + str(placeholder(target_env.get('JWT_SECRET'))).lower())

if mode != 'apply':
    print('dry_run_only=true')
    sys.exit(0)

timestamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
backup = target.with_name(f'.env.before-dev-sync-{timestamp}')
shutil.copy2(target, backup)
temporary = target.with_name(target.name + '.sync-tmp')
lines = [f'{key}={value}' for key, value in merged.items()]
temporary.write_text('\n'.join(lines) + '\n', encoding='utf-8')
temporary.chmod(0o600)
temporary.replace(target)
backup.chmod(0o600)
print('backup=' + backup.name)
print('applied=true')
PY"
