#!/bin/bash
# Pre-commit hook: detect duplicate Flyway migration version numbers.
# Place at .git/hooks/pre-commit (or .git/core.hooksPath)
set -euo pipefail

MIGRATION_DIR="smart-livestock-server/src/main/resources/db/migration"

# Find all V*.sql files, extract version numbers, check for duplicates
dupes=$(find "$MIGRATION_DIR" -name 'V*.sql' -exec basename {} \; \
    | sed -E 's/^V([0-9]+)__.*/\1/' \
    | sort \
    | uniq -d)

if [ -n "$dupes" ]; then
    echo "ERROR: Duplicate Flyway migration version numbers detected:"
    for v in $dupes; do
        echo "  V${v}:"
        find "$MIGRATION_DIR" -name "V${v}__*.sql" -exec basename {} \;
    done
    echo ""
    echo "Fix: rename one of the conflicting files to a unique version number."
    echo "New migrations should use V{YYYYMMDDHHmmss}__description.sql format."
    exit 1
fi

exit 0
