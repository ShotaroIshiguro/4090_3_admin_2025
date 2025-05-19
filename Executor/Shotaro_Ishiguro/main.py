import time
import argparse

parser = argparse.ArgumentParser(description='このプログラムの説明')    # 2. パーサを作る

parser.add_argument('time_for_run')
parser.add_argument('-n', '--myname')

args = parser.parse_args()    # 3. 引数を取得する

for i in range(args.time_for_run):
    time.sleep(1)
    print(i)
    print("name: ", args.myname)
    # print('\a')

print("実行完了")
