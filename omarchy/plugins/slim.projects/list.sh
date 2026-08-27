#!/usr/bin/env python3
import json
import os
import sys

root = sys.argv[1] if len(sys.argv) > 1 else ''
limit = 250

if not root or not os.path.isdir(root):
    print('[]')
    raise SystemExit(0)

try:
    names = os.listdir(root)
except OSError:
    print('[]')
    raise SystemExit(0)

entries = []
for name in names:
    path = os.path.join(root, name)
    try:
        is_dir = os.path.isdir(path)
        is_link = os.path.islink(path)
    except OSError:
        continue
    entries.append({
        'name': name,
        'dir': bool(is_dir),
        'link': bool(is_link),
        'hidden': name.startswith('.'),
    })

entries.sort(key=lambda e: (not e['dir'], e['hidden'], e['name'].casefold()))
print(json.dumps(entries[:limit], ensure_ascii=False))
