#!/bin/bash

# --- 記入必須項目 ---
USER_NAME="Shotaro_Ishiguro"
GPU_NUM=0
EXECUTE_FILE_PATH="Shotaro_Ishiguro/main.py"
EXECUTE_ARGS="--time_for_run 10 -n 石黒"
SHEET_UPDATER_SCRIPT="update_sheet.py" 


# 以降の改変禁止！！！！！！！！
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓   Do not touch!!!!!!   ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓


echo "--- スプレッドシートの待機列を更新中... ---"
# Pythonスクリプトを実行し、その出力（次回実行者リスト）を変数に格納
NEXT_EXECUTOR=$(python3 "$SHEET_UPDATER_SCRIPT" "$USER_NAME")
if [ -z "$NEXT_EXECUTOR" ]; then
    echo "警告: 次回実行者候補の取得に失敗しました。"
    NEXT_EXECUTOR="取得失敗"
fi
echo "--- 更新完了。次回実行者候補: ${NEXT_EXECUTOR} ---"


# --- 固定設定項目 ---
WEBHOOK_URL=""
TIME_LIMIT=1800  # 秒（本来は1800秒＝30分）

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
echo "--- Pythonスクリプトの実行を開始します ---"
export CUDA_VISIBLE_DEVICES=${GPU_NUM}
eval python3 "$EXECUTE_FILE_PATH" $EXECUTE_ARGS
EXIT_CODE=$?
PROCESS_EXITED=true
END_TIME=$(date +%s)
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DURATION=$((END_TIME - START_TIME))

# --- 監視プロセスを終了 ---
kill "$WATCHER_PID" 2>/dev/null

# --- 実行時間によってステータスを決定 ---
if [ "$EXIT_CODE" -eq 0 ]; then
    STATUS="✅ 成功"
    MESSAGE="*${STATUS}*\n*実行者*: \`${USER_NAME}\`\n*GPU番号*: \`${GPU_NUM}\`\n*スクリプト*: \`${EXECUTE_FILE_PATH} ${EXECUTE_ARGS}\`\n*開始時間*: ${START_TIMESTAMP}\n*終了時間*: ${END_TIMESTAMP}\n*実行時間*: ${DURATION} 秒\n\n*次回実行者候補*: \`${NEXT_EXECUTOR}\`"
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"${MESSAGE}\"}" \
      "$WEBHOOK_URL"
else
    STATUS="❌ 失敗"
    MESSAGE="*${STATUS}*\n*実行者*: \`${USER_NAME}\`\n*GPU番号*: \`${GPU_NUM}\`\n*スクリプト*: \`${EXECUTE_FILE_PATH} ${EXECUTE_ARGS}\`\n*終了コード*: ${EXIT_CODE}\n*開始時間*: ${START_TIMESTAMP}\n*終了時間*: ${END_TIMESTAMP}\n*実行時間*: ${DURATION} 秒\n\n*次回実行者候補*: \`${NEXT_EXECUTOR}\`"
    curl -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"${MESSAGE}\"}" \
      "$WEBHOOK_URL"
fi
