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

fields = ['name', 'input_file', 'input_format', 'input_object_type', 'split_column', 'split_value',
          'output_format', 'output_object_type', 'output_file', 'n_cells', 'n_features']
records_by_key = {}
records_by_name = {}
for manifest in dict.fromkeys(manifest_args):
    with open(manifest, newline='', encoding='utf-8') as source:
        for record in csv.DictReader(source, delimiter=chr(9)):
            output_name = Path(record['output_file']).name
            output_format = record.get('output_format', '')
            records_by_key[(output_name, output_format)] = record
            records_by_name[output_name] = record

os.makedirs(name, exist_ok=True)
for output, output_format in zip(output_args, format_args, strict=True):
    destination = Path(name) / output_format
    destination.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(output, destination / Path(output).name)

with open(Path(name) / 'split_manifest.tsv', 'w', newline='', encoding='utf-8') as target:
    writer = csv.DictWriter(target, fieldnames=fields, delimiter=chr(9), lineterminator=chr(10), extrasaction='ignore')
    writer.writeheader()
    for output, output_format in zip(output_args, format_args, strict=True):
        key = (Path(output).name, output_format)
        record = records_by_key.get(key) or records_by_name.get(Path(output).name)
        if record is None:
            raise SystemExit(f'ERROR: no split manifest record for output {output} with format {output_format}')
        record = {field: record.get(field, '') for field in fields}
        record.update(name=name, output_format=output_format,
                      output_object_type={'anndata': 'AnnData', 'sce': 'SingleCellExperiment', 'seurat': 'Seurat'}[output_format],
                      output_file=f'{output_format}/{Path(output).name}')
        writer.writerow(record)

with open('versions.yml', 'w', encoding='utf-8') as handle:
    handle.write(f'COLLECT_OUTPUTS:{chr(10)}    python: {platform.python_version()}{chr(10)}')
