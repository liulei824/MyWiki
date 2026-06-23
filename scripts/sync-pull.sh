#!/usr/bin/env bash
# 在 NPU Linux 上拉取最新知识库（需先 git clone 并配置 remote）
set -euo pipefail
cd "$(dirname "$0")/.."
git pull --rebase
echo "Wiki synced at $(date)"
