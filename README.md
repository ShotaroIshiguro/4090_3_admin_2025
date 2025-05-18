# 4090_3_admin_2025

GPUの共同利用を管理するためのリポジトリです。

<div style="text-align: right;">
早稲田大学大学院 基幹理工学研究科 電子物理システム学専攻 史研究室 M2 <BR>
<i>石黒将太郎</i>
</div>

## 初回利用時
1. 利用予約・通知用の[Slackグループ](https://join.slack.com/t/shilabgpunotify/shared_invite/zt-35hwn8cdv-uYu_utz~Q0S0zPpvEBri_g)に入る
2. [予約管理スプレッドシート](https://docs.google.com/spreadsheets/d/1oI2zM7loJsN-LNtxFO1VnpVop_PqMW00xR6ty_vYPbA/edit?gid=2081617412#gid=2081617412)の利用者一覧タブに自分の名前を記入<BR>
※ 利用者一覧に自分の名前を登録することで予約ができるようになります

## 通常利用時手順書
### 予約時
1. [予約管理スプレッドシート](https://docs.google.com/spreadsheets/d/1oI2zM7loJsN-LNtxFO1VnpVop_PqMW00xR6ty_vYPbA/edit?gid=2081617412#gid=2081617412)のGPU待機列タブに`名前`と`予約日`を記入
2. 自分の名前が`次回実行者候補`に乗るまで待機

### 実行時
1. 自分の番が回ってきたら、研究室内のパソコン上でwatch nvidia-smiを実行し、空いているGPU番号を確認
2. slackのnotifyチャネルで自分がパソコンを触り始めたことを通知(例: 実験を開始します)
3. `conda`で自分専用の環境を作成(venv非推奨)
4. `run_template.sh`の実行前記入欄を全て埋める
   - `YOUR_NAME`(自分の名前)
   - `GPU_NUM`(使用するGPUの番号)
   - `NEXT_EXECUTOR`(次の実行候補者3名を全て記入)
   - `EXECUTE_FILE_PATH`(実行したいファイルの絶対パス)
5. ターミナル上で`./run_template.sh`を実行
6. 実行30分後の▲実行中slack通知が届いたタイミングで、自分の名前が入っている行のE列にチェックを入れてください<BR>
※ 実行に不具合があった場合、実行後30分以内であれば中断・修正可能です。

## 注意事項
- スクリプト実行は次回実行者候補者3名から早い者勝ちです
- スプシ上の次回候補者枠に入ってから一週間以上実行しない場合、予約時の名前は自動削除されます
- 何か質問のある方はslack上のcomp係に聞いてください

## 禁止事項
- .shファイルの改変
- slack APIの他目的利用
- 一度に複数の予約を取ることは禁止です。次の予約は必ず１日以上空けてください
- condaのbase環境での作業、他人のconda環境の改変

## その他
- リポジトリの改善提案などは大歓迎です。プルリクエストでお知らせください。
- 自分のPCやGoogle Colaboratory、研究室内のその他GPUつきPCで実行可能であることを確認してから、GPUを使った作業に移ることを推奨します。
- USBメモリ・外付けSSD接続やファイルダウンロード、gitクローンなどの手段で、GPU付きPC内に自分の環境を構築することが可能です。
