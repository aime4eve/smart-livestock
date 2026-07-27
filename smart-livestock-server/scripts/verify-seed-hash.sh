#!/bin/bash
# Seed BCrypt hash verifier — Step 1 of the three-step seed password validation.
# Usage:
#   ./scripts/verify-seed-hash.sh <plaintext> <bcrypt_hash>
#   ./scripts/verify-seed-hash.sh 123 '$2a$10$N9qo8uLOickgx2ZMRZoMy...'
# Ensures hash matches plaintext before writing into a Flyway migration.
# For steps 2 (write migration) and 3 (curl /auth/login after deploy), see AGENTS.md §7.2.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <plaintext_password> <bcrypt_hash>"
  echo "Example: $0 123 '\$2a\$10\$N9qo8uLOickgx2ZMRZoMy...'"
  exit 1
fi

PLAINTEXT="$1"
HASH="$2"

python3 -c "
import sys
try:
    import bcrypt
except ImportError:
    print('ERROR: bcrypt not installed. Install with: pip3 install bcrypt', file=sys.stderr)
    sys.exit(2)

plaintext = sys.argv[1].encode()
hash_val = sys.argv[2].encode()

if bcrypt.checkpw(plaintext, hash_val):
    print('PASS: hash matches plaintext')
    sys.exit(0)
else:
    print('FAIL: hash does NOT match plaintext', file=sys.stderr)
    sys.exit(1)
" "$PLAINTEXT" "$HASH"
