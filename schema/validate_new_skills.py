import json
import os
import sys

BASE = os.path.dirname(__file__)
CATEGORIES_PATH = os.path.join(BASE, 'skill_categories.json')
SKILLS_DIR = os.path.join(BASE, 'skills')

errors = []

with open(CATEGORIES_PATH, 'r') as f:
    categories = json.load(f)['attributes']

category_keys = set(categories.keys())

# Build allowed parent names: top-level categories + root skill class names + subcategory root names.
allowed_parents = set(category_keys)
allowed_parents.add('base_skill')  # global root prototype

skills_root = os.path.join(BASE, 'skills')
if os.path.isdir(skills_root):
    for category_dir in os.listdir(skills_root):
        cpath = os.path.join(skills_root, category_dir)
        if not os.path.isdir(cpath):
            continue
        root_json = os.path.join(cpath, f"{category_dir}.json")
        if os.path.isfile(root_json):
            try:
                data = json.loads(open(root_json, 'r').read())
                name = data.get('name') or category_dir
                allowed_parents.add(name)
            except Exception:
                pass
        # subcategories
        for sub in os.listdir(cpath):
            spath = os.path.join(cpath, sub)
            if os.path.isdir(spath):
                sub_root = os.path.join(spath, f"{sub}.json")
                if os.path.isfile(sub_root):
                    try:
                        sdata = json.loads(open(sub_root, 'r').read())
                        sname = sdata.get('name') or sub
                        allowed_parents.add(sname)
                    except Exception:
                        pass

leaf_names_global = {}

for root, dirs, files in os.walk(SKILLS_DIR):
    for fn in files:
        if not fn.endswith('.json'):
            continue
        path = os.path.join(root, fn)
        with open(path, 'r') as f:
            try:
                data = json.load(f)
            except Exception as e:
                errors.append(f'Invalid JSON: {path}: {e}')
                continue
        parent = data.get('extends')
        name = data.get('name')
        # base_skill may intentionally omit extends
        if not parent and name != 'base_skill':
            errors.append(f'Missing extends: {path}')
        elif parent and parent not in allowed_parents:
            errors.append(f'Unknown parent "{parent}" in {path}')
        if not name:
            errors.append(f'Missing name in {path}')
        else:
            if name in leaf_names_global:
                errors.append(f'Duplicate leaf skill name {name} (already in {leaf_names_global[name]}) at {path}')
            else:
                leaf_names_global[name] = path

if errors:
    print('VALIDATION FAILED')
    for e in errors:
        print(' -', e)
    sys.exit(1)
else:
    print('VALIDATION PASSED:')
    print(f' Categories: {len(category_keys)}')
    print(f' Leaf skills: {len(leaf_names_global)}')
