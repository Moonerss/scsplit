#!/usr/bin/env python3
import csv
import os
import platform
import re

input_path = "${samplesheet}"
output_path = "${output}"

NAME = re.compile(r'[A-Za-z0-9_.-]+')
EXTENSIONS = {'.h5ad': 'h5ad', '.rds': 'rds'}

with open(input_path, newline='', encoding='utf-8') as handle:
    rows = list(csv.DictReader(handle))

if not rows or set(rows[0]) != {'name', 'input'}:
    raise SystemExit('ERROR: samplesheet must contain exactly the columns name,input and at least one row')

seen = set()
with open(output_path, 'w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter=chr(9), lineterminator=chr(10))
    writer.writerow(['name', 'input_file', 'input_format'])
    for index, row in enumerate(rows, start=2):
        name = (row.get('name') or '').strip()
        path = (row.get('input') or '').strip()
        if not NAME.fullmatch(name):
            raise SystemExit(f'ERROR: row {index}: name is not a safe dataset identifier: {name!r}')
        if name in seen:
            raise SystemExit(f'ERROR: row {index}: duplicate name: {name}')
        seen.add(name)
        if not os.path.isfile(path):
            raise SystemExit(f'ERROR: row {index}: input file does not exist: {path}')
        fmt = EXTENSIONS.get(os.path.splitext(path)[1].lower())
        if fmt is None:
            raise SystemExit(f'ERROR: row {index}: unsupported input extension: {path}')
        writer.writerow([name, os.path.abspath(path), fmt])

with open('versions.yml', 'w', encoding='utf-8') as handle:
    handle.write(f'VALIDATE_INPUT:{chr(10)}    python: {platform.python_version()}{chr(10)}')
