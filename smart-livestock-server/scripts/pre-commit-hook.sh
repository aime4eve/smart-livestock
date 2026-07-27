#!/usr/bin/env bash
# Pre-commit hook: AppleDouble cleanup + Flyway dedup + compile gate
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# 1. Remove ._ files from staging area
STAGED_DOTFILES=$(git diff --cached --name-only --diff-filter=ACM | grep '^\._\|/\._' || true)
if [ -n "$STAGED_DOTFILES" ]; then
    echo "pre-commit: removing AppleDouble (._*) files from staging"
    echo "$STAGED_DOTFILES" | while read -r f; do
        git reset -q -- "$f" 2>/dev/null || true
    done
fi

# 2. Clean ._ files from working tree (non-.git dirs)
find "$REPO_ROOT" -name '._*' -not -path '*/.git/*' -not -path '*/node_modules/*' -delete 2>/dev/null || true

# 3. Verify no ._ files remain in staging
REMAINING=$(git diff --cached --name-only | grep '^\._\|/\._' || true)
if [ -n "$REMAINING" ]; then
    echo "pre-commit: WARNING - ._ files still staged after cleanup:"
    echo "$REMAINING"
    exit 1
fi

# 4. Flyway migration duplicate version check
if [ -x "$REPO_ROOT/smart-livestock-server/scripts/check-flyway-duplicates.sh" ]; then
    "$REPO_ROOT/smart-livestock-server/scripts/check-flyway-duplicates.sh" || exit 1
fi

# 5. Compile gate: only when backend or frontend source is staged
STAGED=$(git diff --cached --name-only --diff-filter=ACM)
BACKEND_CHANGES=$(echo "$STAGED" | grep '^smart-livestock-server/src/.*\.java$' || true)
if [ -n "$BACKEND_CHANGES" ]; then
    echo "pre-commit: compiling backend (staged Java files detected)..."
    (cd "$REPO_ROOT/smart-livestock-server" && ./gradlew compileJava -q 2>&1 | tail -5) || {
        echo "pre-commit: BACKEND COMPILE FAILED — fix errors before committing"
        exit 1
    }
    echo "pre-commit: backend OK"
fi

exit 0
