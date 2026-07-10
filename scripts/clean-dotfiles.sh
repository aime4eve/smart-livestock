#!/usr/bin/env bash
# Clean macOS AppleDouble (._*) metadata files from .git and build directories.
# These are created automatically on exFAT volumes and cause noise in git output
# and break Gradle/Flutter incremental builds.
#
# Usage: bash scripts/clean-dotfiles.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLEANED=0

for dir in "$REPO_ROOT/.git" "$REPO_ROOT/smart-livestock-server/build" "$REPO_ROOT/Mobile/mobile_app/build" "$REPO_ROOT/Mobile/mobile_app/.dart_tool"; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -name '._*' -type f 2>/dev/null | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            find "$dir" -name '._*' -type f -delete 2>/dev/null || true
            # Some ._ files in .git/objects/pack have restricted perms; retry
            remaining=$(find "$dir" -name '._*' -type f 2>/dev/null | wc -l | tr -d ' ')
            if [ "$remaining" -gt 0 ]; then
                find "$dir" -name '._*' -type f -exec rm -f {} + 2>/dev/null || true
            fi
            final=$(find "$dir" -name '._*' -type f 2>/dev/null | wc -l | tr -d ' ')
            cleaned=$((count - final))
            if [ "$cleaned" -gt 0 ]; then
                echo "  cleaned $cleaned ._ files from $dir"
                CLEANED=$((CLEANED + cleaned))
            fi
            if [ "$final" -gt 0 ]; then
                echo "  WARNING: $final ._ files in $dir require elevated permissions (run with sudo)"
            fi
        fi
    fi
done

echo "Done: removed $CLEANED ._ files"
