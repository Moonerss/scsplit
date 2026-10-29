#!/usr/bin/env python3
import csv
import os
import platform
import re
from pathlib import Path

input_path = "${samplesheet}"
output_path = "${output}"

NAME = re.compile(r'[A-Za-z0-9_.-]+')
EXTENSIONS = {'.h5ad': 'h5ad', '.rds': 'rds'}

def resolve_input_path(raw_path: str) -> Path:
    """Resolve native and WSL-mounted Windows paths to an existing file."""
    normalized = raw_path.replace(chr(92), '/')
    windows_match = re.fullmatch(r'([A-Za-z]):/(.*)', normalized)
    if os.name != 'nt' and windows_match:
        mounted = Path('/mnt') / windows_match.group(1).lower() / windows_match.group(2)
        if mounted.is_file():
            return mounted
    return Path(raw_path)

with open(input_path, newline='', encoding='utf-8') as handle:
    rows = list(csv.DictReader(handle))

if not rows or set(rows[0]) != {'name', 'input'}:
    raise SystemExit('ERROR: samplesheet must contain exactly the columns name,input and at least one row')

seen = set()
with open(output_path, 'w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter=chr(9), lineterminator=chr(10))
    writer.writerow(['name', 'input_file', 'input_format', 'input_object_type'])
    for index, row in enumerate(rows, start=2):
        name = (row.get('name') or '').strip()
        raw_path = (row.get('input') or '').strip()
        if not NAME.fullmatch(name):
            raise SystemExit(f'ERROR: row {index}: name is not a safe dataset identifier: {name!r}')
        if name in seen:
            raise SystemExit(f'ERROR: row {index}: duplicate name: {name}')
        seen.add(name)
        input_path = resolve_input_path(raw_path)
        if not input_path.is_file():
            raise SystemExit(f'ERROR: row {index}: input file does not exist: {raw_path}')
        input_path = input_path.resolve()
        fmt = EXTENSIONS.get(input_path.suffix.lower())
        if fmt is None:
            raise SystemExit(f'ERROR: row {index}: unsupported input extension: {raw_path}')
        writer.writerow([name, str(input_path), fmt, 'AnnData' if fmt == 'h5ad' else 'unknown'])

with open('versions.yml', 'w', encoding='utf-8') as handle:
    handle.write(f'VALIDATE_INPUT:{chr(10)}    python: {platform.python_version()}{chr(10)}')
