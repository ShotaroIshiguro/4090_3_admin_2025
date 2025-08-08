import sys
import os.path
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# --- 設定項目 ---
CLIENT_SECRETS_FILE = ""
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
TOKEN_FILE = 'token.json'
SPREADSHEET_ID = '1oI2zM7loJsN-LNtxFO1VnpVop_PqMW00xR6ty_vYPbA'

def authenticate_sheets():
    """Google Sheets APIへの認証を行う"""
    creds = None
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRETS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
    return creds

def update_queue_and_get_next(service, name_to_remove):
    """指定された名前を削除し、新しい上位3名を返す"""
    try:
        sheet_metadata = service.spreadsheets().get(spreadsheetId=SPREADSHEET_ID).execute()
        sheet_name = sheet_metadata.get('sheets', [])[0].get("properties", {}).get("title", "Sheet1")
    except HttpError as err:
        print(f"シート名の取得に失敗: {err}", file=sys.stderr)
        return ""

    range_to_read = f"'{sheet_name}'!B2:C"
    try:
        result = service.spreadsheets().values().get(spreadsheetId=SPREADSHEET_ID, range=range_to_read).execute()
        values = result.get('values', [])
    except HttpError as err:
        print(f"データの読み込みに失敗: {err}", file=sys.stderr)
        return ""

    if not values:
        return ""

    row_index = -1
    for i, row in enumerate(values):
        if row and len(row) > 0 and row[0] == name_to_remove:
            row_index = i
            break
    
    if row_index == -1:
        print(f"警告: '{name_to_remove}' は待機列に見つかりませんでした。削除処理をスキップします。", file=sys.stderr)
        next_users = [row[0] for row in values[:3] if row and len(row) > 0 and row[0]]
        return ", ".join(next_users)

    sheet_row_number = row_index + 2
    values_to_shift = values[row_index + 1:]
    values_to_shift.append(['', ''])
    range_to_update = f"'{sheet_name}'!B{sheet_row_number}:C"
    body = {'values': values_to_shift}
    
    try:
        service.spreadsheets().values().update(
            spreadsheetId=SPREADSHEET_ID,
            range=range_to_update,
            valueInputOption='USER_ENTERED',
            body=body
        ).execute()
        print(f"'{name_to_remove}' を待機列から削除しました。")
    except HttpError as err:
        print(f"シートの更新に失敗: {err}", file=sys.stderr)

    next_users = [row[0] for row in values_to_shift[:3] if row and len(row) > 0 and row[0]]
    return ", ".join(next_users)

def main():
    # ★★★ ここが重要な変更点 ★★★
    # input()の代わりに、Bashスクリプトから渡された引数（ユーザー名）を取得
    if len(sys.argv) < 2:
        print("エラー: ユーザー名が指定されていません。", file=sys.stderr)
        sys.exit(1)
    
    user_name = sys.argv[1]
    
    creds = authenticate_sheets()
    service = build('sheets', 'v4', credentials=creds)
    
    # 次回実行者候補を取得して、標準出力に表示（Bash側で受け取る）
    next_executor_list = update_queue_and_get_next(service, user_name)
    print(next_executor_list)

if __name__ == '__main__':
    main()
