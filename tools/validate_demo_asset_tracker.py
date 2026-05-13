#!/usr/bin/env python3
import json, sys
from pathlib import Path
p = Path('data/production/demo_asset_tracker.json')
if not p.exists():
    p = Path('demo_asset_tracker.json')
if not p.exists():
    print('FAIL: tracker JSON not found')
    sys.exit(1)
data = json.loads(p.read_text(encoding='utf-8'))
status_values = set(data.get('status_values', []))
required_asset_fields = {'id','category','name','lane','status','priority','need','acceptance'}
required_system_fields = {'id','name','lane','status','priority','need','acceptance'}
errors=[]
for section, fields in [('assets', required_asset_fields), ('systems', required_system_fields)]:
    ids=set()
    for item in data.get(section, []):
        missing = fields - set(item.keys())
        if missing:
            errors.append(f'{section}:{item.get("id","<no id>")} missing {sorted(missing)}')
        if item.get('id') in ids:
            errors.append(f'{section}: duplicate id {item.get("id")}')
        ids.add(item.get('id'))
        if item.get('status') not in status_values:
            errors.append(f'{section}:{item.get("id")} invalid status {item.get("status")}')
if not data.get('phases'):
    errors.append('missing phases')
if errors:
    print('FAIL:')
    for e in errors:
        print(' -', e)
    sys.exit(1)
print(f'OK: {len(data.get("systems", []))} systems, {len(data.get("assets", []))} assets, {len(data.get("phases", []))} phases')
