#!/bin/zsh
set -euo pipefail

MSG="${1:-}"
if [[ -z "$MSG" ]]; then
  echo "Usage: ./push.sh <commit-message>"
  exit 1
fi

git add -A
git status --short
git commit -m "$MSG"
git push origin master
echo "Pushed to origin/master"
