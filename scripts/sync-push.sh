#!/usr/bin/env bash
# 提交并推送知识库变更
set -euo pipefail
cd "$(dirname "$0")/.."
git add -A
if git diff --cached --quiet; then
  echo "No changes to push."
  exit 0
fi
msg="${1:-wiki: update $(date +%Y-%m-%d)}"
git commit -m "$msg"
if git remote get-url origin &>/dev/null; then
  git push
  echo "Pushed: $msg"
else
  echo "Committed locally: $msg"
  echo "Tip: 配置 remote 后可推送 — git remote add origin <your-repo-url>"
fi
