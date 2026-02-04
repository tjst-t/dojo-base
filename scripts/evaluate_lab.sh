#!/bin/bash
# evaluate_lab.sh - ラボの総合評価を実行
# Usage: ./scripts/evaluate_lab.sh <lab-number-or-name>
# - check.sh があれば実行（hands-on / computational）
# - check_criteria.yaml があれば内容を表示（Claude Code評価用）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LABS_DIR="$BASE_DIR/labs"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <lab-number-or-name>"
    exit 1
fi

QUERY="$1"

# ラボディレクトリを検索
LAB_DIR=$(find "$LABS_DIR" -maxdepth 1 -type d -name "${QUERY}*" | head -1)

if [ -z "$LAB_DIR" ]; then
    echo "❌ ラボが見つかりません: $QUERY"
    exit 1
fi

LAB_NAME=$(basename "$LAB_DIR")
CHECK_SCRIPT="$LAB_DIR/check.sh"
CRITERIA_FILE="$LAB_DIR/check_criteria.yaml"

echo "📋 評価: $LAB_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"

# check.sh があれば実行
if [ -f "$CHECK_SCRIPT" ]; then
    echo ""
    echo "▶ 自動検証を実行中..."
    echo ""
    if bash "$CHECK_SCRIPT"; then
        echo ""
        echo "✅ 自動検証: すべてPASS"
    else
        echo ""
        echo "❌ 自動検証: 一部FAILがあります"
        echo "FAILを解決してから再度実行してください。"
        exit 1
    fi
fi

# check_criteria.yaml があれば表示
if [ -f "$CRITERIA_FILE" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 概念理解の評価基準:"
    echo ""
    cat "$CRITERIA_FILE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 この評価はClaude Codeが対話的に行います。"
    echo "   Claude Codeに「チェックして」と伝えてください。"
fi

if [ ! -f "$CHECK_SCRIPT" ] && [ ! -f "$CRITERIA_FILE" ]; then
    echo "⚠️  このラボには検証スクリプトも評価基準もありません。"
fi
