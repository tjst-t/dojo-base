#!/bin/bash
# check_lab.sh - ラボの検証スクリプトを実行するラッパー
# Usage: ./scripts/check_lab.sh <lab-number-or-name>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LABS_DIR="$BASE_DIR/labs"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <lab-number-or-name>"
    echo "Example: $0 01"
    echo "Example: $0 01-vlan-basic"
    exit 1
fi

QUERY="$1"

# ラボディレクトリを検索
LAB_DIR=$(find "$LABS_DIR" -maxdepth 1 -type d -name "${QUERY}*" | head -1)

if [ -z "$LAB_DIR" ]; then
    echo "❌ ラボが見つかりません: $QUERY"
    echo "利用可能なラボ:"
    ls -1 "$LABS_DIR" | grep -v "^\.gitkeep$" || echo "  (まだラボがありません)"
    exit 1
fi

LAB_NAME=$(basename "$LAB_DIR")
CHECK_SCRIPT="$LAB_DIR/check.sh"

if [ ! -f "$CHECK_SCRIPT" ]; then
    echo "❌ 検証スクリプトが見つかりません: $LAB_NAME/check.sh"
    echo "このラボにはcheck.shが含まれていません。"
    echo "analytical型の場合は evaluate_lab.sh を使用してください。"
    exit 1
fi

echo "🔍 検証中: $LAB_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$CHECK_SCRIPT"
