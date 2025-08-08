import os.path
from datetime import datetime
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# --- 設定項目 ---
# 認証情報のJSONファイルへのパス
CLIENT_SECRETS_FILE = ""
# スプレッドシートの読み書きを許可するスコープ
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
# 認証情報を保存するファイル名
TOKEN_FILE = 'token.json'
# 操作対象のスプレッドシートID
SPREADSHEET_ID = '1oI2zM7loJsN-LNtxFO1VnpVop_PqMW00xR6ty_vYPbA'

def authenticate_sheets():
    """
    Google Sheets APIへの認証を行う。
    """
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

def find_and_remove_name(service, name_to_remove):
    """
    指定された名前をB列から検索し、その行のB列とC列を削除して下の行を上に詰める。
    """
    try:
        sheet_metadata = service.spreadsheets().get(spreadsheetId=SPREADSHEET_ID).execute()
        sheet_name = sheet_metadata.get('sheets', [])[0].get("properties", {}).get("title", "Sheet1")
        print(f"操作対象シート: '{sheet_name}'")
    except HttpError as err:
        print(f"シート名の取得に失敗しました: {err}")
        return

    # ★★★ 変更点: B列とC列のデータを読み込む ★★★
    range_to_read = f"'{sheet_name}'!B2:C"
    try:
        result = service.spreadsheets().values().get(spreadsheetId=SPREADSHEET_ID, range=range_to_read).execute()
        values = result.get('values', [])
    except HttpError as err:
        print(f"データの読み込みに失敗しました: {err}")
        return

    if not values:
        print("対象範囲にデータがありません。")
        return

    # 削除する名前のインデックスを検索
    row_index = -1
    for i, row in enumerate(values):
        if row and len(row) > 0 and row[0] == name_to_remove:
            row_index = i
            break
    
    if row_index == -1:
        print(f"名前 '{name_to_remove}' は見つかりませんでした。")
        return

    # スプレッドシート上での実際の行番号
    sheet_row_number = row_index + 2
    
    # シフトアップするデータを準備
    values_to_shift = values[row_index + 1:]
    
    # ★★★ 変更点: 最後の行のB列とC列をクリアするための空の値 ★★★
    values_to_shift.append(['', ''])

    # ★★★ 変更点: 更新する範囲をB列とC列に限定 ★★★
    range_to_update = f"'{sheet_name}'!B{sheet_row_number}:C"

    body = {
        'values': values_to_shift
    }
    
    try:
        service.spreadsheets().values().update(
            spreadsheetId=SPREADSHEET_ID,
            range=range_to_update,
            valueInputOption='USER_ENTERED',
            body=body
        ).execute()
        print(f"'{name_to_remove}' の行を削除し、後続の行をシフトアップしました。")
    except HttpError as err:
        print(f"シートの更新に失敗しました: {err}")

def main():
    """メインの処理"""
    creds = authenticate_sheets()
    service = build('sheets', 'v4', credentials=creds)
    
    name_to_delete = input("削除したい名前を入力してください: ")
    if not name_to_delete:
        print("名前が入力されなかったので処理を終了します。")
        return
        
    find_and_remove_name(service, name_to_delete)

if __name__ == '__main__':
    main()
