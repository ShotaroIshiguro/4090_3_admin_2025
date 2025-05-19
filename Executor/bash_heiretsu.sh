#!/bin/bash

# --- 記入必須項目 ---
USER_NAME="Shotaro_Ishiguro"
GPU_NUM=0
NEXT_EXECUTOR="Ohmori_Nariaki, Noguchi_Hayata, Tochiki_Ohno"
EXECUTE_FILE_PATH="/Shotaro_Ishiguro/main.py"



# 以降の改変禁止！！！！！！！！
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓   Do not touch!!!!!!   ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓




















# --- 固定設定項目 ---
WEBHOOK_URL="https://hooks.slack.com/services/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"
EXECUTE_EXECUTE_FILE_PATH="${USER_NAME}/main.py"
TIME_LIMIT=5  # 秒（本来は1800秒＝30分）

# --- 開始時刻記録 ---
START_TIME=$(date +%s)
START_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# --- 状態管理フラグ ---
OVER_TIME_FLAG=false
PROCESS_EXITED=false
EXIT_CODE=-1

# --- シグナルを無視して監視を続けるようにtrap ---
trap '' SIGINT SIGTERM

# --- 30分経過後に通知（バックグラウンド） ---
(
    sleep $TIME_LIMIT
    if ! $PROCESS_EXITED; then
        OVER_TIME_FLAG=true
        curl -X POST -H 'Content-type: application/json' \
          --data "{\"text\":\"⚠️ *実行中(30min経過)*\n*実行者*: \`${USER_NAME}\`\n*スクリプト*: \`${EXECUTE_FILE_PATH}\`\n*開始時間*: ${START_TIMESTAMP}\n\n*次回実行者候補*: \`${NEXT_EXECUTOR}\`\"}" \
          "$WEBHOOK_URL"
    fi
) &
WATCHER_PID=$!

# --- 実行 ---
export CUDA_VISIBLE_DEVICES=${GPU_NUM}
python3 "$EXECUTE_EXECUTE_FILE_PATH"
EXIT_CODE=$?
PROCESS_EXITED=true
END_TIME=$(date +%s)
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DURATION=$((END_TIME - START_TIME))

# --- 監視プロセスを終了 ---
kill "$WATCHER_PID" 2>/dev/null

# --- 実行時間によってステータスを決定 ---
if [ "$EXIT_CODE" -eq 0 ]; then
    if [ "$DURATION" -gt "$TIME_LIMIT" ]; then
        STATUS="✅ 成功"
    else
        STATUS="✅ 正常終了（${TIME_LIMIT}min以内）"
    fi
    MESSAGE="*${STATUS}*\n*実行者*: \`${USER_NAME}\`\n*GPU番号*: \`${GPU_NUM}\`\n*スクリプト*: \`${EXECUTE_FILE_PATH}\`\n*開始時間*: ${START_TIMESTAMP}\n*終了時間*: ${END_TIMESTAMP}\n*実行時間*: ${DURATION} 秒\n\n*次回実行者候補*: \`${NEXT_EXECUTOR}\`"
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"${MESSAGE}\"}" \
      "$WEBHOOK_URL"
else
    if [ "$DURATION" -gt "$TIME_LIMIT" ]; then
        STATUS="❌ 中断・失敗（${TIME_LIMIT}秒超）"
        MESSAGE="*${STATUS}*\n*実行者*: \`${USER_NAME}\`\n*GPU番号*: \`${GPU_NUM}\`\n*スクリプト*: \`${EXECUTE_FILE_PATH}\`\n*開始時間*: ${START_TIMESTAMP}\n*終了時間*: ${END_TIMESTAMP}\n*実行時間*: ${DURATION} 秒\n\n*次回実行者候補*: \`${NEXT_EXECUTOR}\`"
        curl -X POST -H 'Content-type: application/json' \
          --data "{\"text\":\"${MESSAGE}\"}" \
          "$WEBHOOK_URL"
    fi
fi

