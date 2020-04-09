#!/usr/bin/python3

import json
from os import listdir
from os.path import isfile, join

SRC_DIR = '/home/jaja/wqz/prog/android/vfrManual/app/src/main/assets/json'
OUT_FILE = '/home/jaja/wqz/prog/android/ognCubeControl/assets/res/airfields.json'

if __name__ == '__main__':

    outList = []

    files = [f for f in listdir(SRC_DIR) if isfile(join(SRC_DIR, f)) and f.endswith('.json')]

    n = 0
    for filename in files:
        n += 1
        filePath = f"{SRC_DIR}/{filename}"

        with open(filePath, 'r') as f:
            j = json.load(f)

            d = dict()
            d['code'] = j['code']
            d['lat'] = float(j['coords'][0])
            d['lon'] = float(j['coords'][1])

            outList.append(d)

    # order the list by latitudes:
    outList.sort(key=lambda item: item['lat'])

    print(f"[INFO] Writing {n} airfields into '{OUT_FILE}'..")

    with open(OUT_FILE, 'w') as f:
        json.dump(outList, f)   # , indent=2

    print('Done.')
