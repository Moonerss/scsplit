#!/usr/bin/env python3
import csv
import json
import os
import platform
import shutil
from pathlib import Path

manifest_args = json.loads('''${manifest_args}''')
output_args = json.loads('''${output_args}''')
format_args = json.loads('''${format_args}''')
name = "${meta.name}"

fields = ['name', 'input_file', 'input_format', 'split_column', 'split_value',
          'output_format', 'output_file', 'n_cells', 'n_features']
records_by_stem = {}
for manifest in dict.fromkeys(manifest_args):
    with open(manifest, newline='', encoding='utf-8') as source:
        for record in csv.DictReader(source, delimiter=chr(9)):
            records_by_stem[Path(record['output_file']).stem] = record

os.makedirs(name, exist_ok=True)
for output, output_format in zip(output_args, format_args, strict=True):
    destination = Path(name) / output_format
    destination.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(output, destination / Path(output).name)

with open(Path(name) / 'split_manifest.tsv', 'w', newline='', encoding='utf-8') as target:
    writer = csv.DictWriter(target, fieldnames=fields, delimiter=chr(9), lineterminator=chr(10))
    writer.writeheader()
    for output, output_format in zip(output_args, format_args, strict=True):
        record = records_by_stem.get(Path(output).stem)
        if record is None:
            raise SystemExit(f'ERROR: no split manifest record for output {output}')
        record = record.copy()
        record.update(name=name, output_format=output_format,
                      output_file=f'{output_format}/{Path(output).name}')
        writer.writerow(record)

with open('versions.yml', 'w', encoding='utf-8') as handle:
    handle.write(f'COLLECT_OUTPUTS:{chr(10)}    python: {platform.python_version()}{chr(10)}')
