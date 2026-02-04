#!/bin/bash
# lab_status.sh - 学習進捗を表示
# Usage: ./scripts/lab_status.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
PROGRESS_FILE="$BASE_DIR/progress.yaml"
CURRICULUM_FILE="$BASE_DIR/curriculum.yaml"

if [ ! -f "$PROGRESS_FILE" ]; then
    echo "❌ progress.yaml が見つかりません"
    exit 1
fi

# yq or python fallback for YAML parsing
parse_yaml() {
    local file="$1"
    local query="$2"
    if command -v yq &> /dev/null; then
        yq eval "$query" "$file" 2>/dev/null
    elif command -v python3 &> /dev/null; then
        python3 -c "
import yaml, sys
with open('$file') as f:
    data = yaml.safe_load(f)
keys = '$query'.strip('.').split('.')
result = data
for k in keys:
    if result is None:
        break
    result = result.get(k) if isinstance(result, dict) else None
print(result if result is not None else '')
" 2>/dev/null
    else
        echo "(yq or python3 required)"
    fi
}

# ドメイン名を取得
DOMAIN=$(parse_yaml "$CURRICULUM_FILE" ".domain" 2>/dev/null || echo "")
if [ -z "$DOMAIN" ] || [ "$DOMAIN" = "null" ] || [ "$DOMAIN" = "" ]; then
    DOMAIN="Learning"
fi

# 統計情報を取得
TOTAL=$(parse_yaml "$PROGRESS_FILE" ".stats.total_labs")
COMPLETED=$(parse_yaml "$PROGRESS_FILE" ".stats.completed")
IN_PROGRESS=$(parse_yaml "$PROGRESS_FILE" ".stats.in_progress")
TOTAL_TIME=$(parse_yaml "$PROGRESS_FILE" ".stats.total_time_spent")

[ -z "$TOTAL" ] || [ "$TOTAL" = "null" ] && TOTAL=0
[ -z "$COMPLETED" ] || [ "$COMPLETED" = "null" ] && COMPLETED=0
[ -z "$IN_PROGRESS" ] || [ "$IN_PROGRESS" = "null" ] && IN_PROGRESS=0
[ -z "$TOTAL_TIME" ] || [ "$TOTAL_TIME" = "null" ] && TOTAL_TIME="0h"

# 進捗率の計算
if [ "$TOTAL" -gt 0 ] 2>/dev/null; then
    PERCENT=$((COMPLETED * 100 / TOTAL))
else
    PERCENT=0
fi

echo "📊 学習進捗: ${DOMAIN^} Dojo"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo "完了: $COMPLETED/$TOTAL ($PERCENT%)"
echo "進行中: $IN_PROGRESS"
echo "合計時間: $TOTAL_TIME"

# ラボごとの状態を表示
echo ""
echo "最近のラボ:"

if command -v yq &> /dev/null; then
    yq eval '.labs | to_entries | .[] | .key + " " + .value.status + " " + (.value.difficulty_felt // "n/a") + " " + ((.value.hints_used // 0) | tostring)' "$PROGRESS_FILE" 2>/dev/null | while read -r lab_id status difficulty hints; do
        case "$status" in
            completed)    icon="✅" ;;
            in_progress)  icon="🔄" ;;
            review_pending|review_done) icon="📝" ;;
            *)            icon="⬜" ;;
        esac
        if [ "$status" = "completed" ]; then
            echo "  $icon $lab_id ($difficulty, $hints hints)"
        elif [ "$status" = "in_progress" ]; then
            attempts=$(parse_yaml "$PROGRESS_FILE" ".labs.${lab_id}.attempts" 2>/dev/null || echo "0")
            echo "  $icon $lab_id (attempts: $attempts)"
        fi
    done
elif command -v python3 &> /dev/null; then
    python3 -c "
import yaml
with open('$PROGRESS_FILE') as f:
    data = yaml.safe_load(f)
labs = data.get('labs', {})
if not labs or not isinstance(labs, dict):
    print('  (まだラボがありません)')
else:
    for lab_id, info in labs.items():
        if not isinstance(info, dict):
            continue
        status = info.get('status', 'not_started')
        difficulty = info.get('difficulty_felt', 'n/a')
        hints = info.get('hints_used', 0)
        attempts = info.get('attempts', 0)
        icons = {'completed': '✅', 'in_progress': '🔄', 'review_pending': '📝', 'review_done': '📝'}
        icon = icons.get(status, '⬜')
        if status == 'completed':
            print(f'  {icon} {lab_id} ({difficulty}, {hints} hints)')
        elif status == 'in_progress':
            print(f'  {icon} {lab_id} (attempts: {attempts})')
" 2>/dev/null
else
    echo "  (yq or python3 required to display lab details)"
fi

# 次の推奨
echo ""
if [ "$IN_PROGRESS" -gt 0 ] 2>/dev/null; then
    echo "次の推奨: 進行中のラボを継続してください"
else
    echo "次の推奨: 「次の課題」でスタートしてください"
fi
