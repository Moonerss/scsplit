#!/usr/bin/env python3
import csv
import hashlib
import os
import platform
import re

import anndata as ad
import pandas as pd

input_path = "${input}"
split_column = "${split_column}"
dataset_name = "${meta.name}"
output_dir = 'h5ad_outputs'
manifest_path = 'split_manifest.tsv'

obj = ad.read_h5ad(input_path)
if obj.n_obs == 0 or obj.n_vars == 0:
    raise SystemExit('ERROR: input AnnData object must contain cells and features')
if split_column not in obj.obs.columns:
    raise SystemExit(f'ERROR: split column not found in adata.obs: {split_column}')
values = obj.obs[split_column]
if values.isna().any():
    raise SystemExit('ERROR: split column contains missing values')
groups = list(pd.unique(values))
if not groups:
    raise SystemExit('ERROR: split column contains no groups')

def safe_name(value):
    text = re.sub(r'[^A-Za-z0-9_.-]+', '_', str(value)).strip('._') or 'group'
    return text[:180]

os.makedirs(output_dir, exist_ok=True)
used = {}
records = []
for value in groups:
    base = safe_name(value)
    output_name = base
    if output_name in used and used[output_name] != str(value):
        suffix = hashlib.sha256(str(value).encode('utf-8')).hexdigest()[:12]
        output_name = f'{base}__{suffix}'
    used[output_name] = str(value)
    subset = obj[values == value].copy()
    output_path = os.path.join(output_dir, f'{output_name}.h5ad')
    subset.write_h5ad(output_path)
    records.append([dataset_name, os.path.abspath(input_path), 'h5ad', split_column,
                    str(value), 'h5ad', output_path, subset.n_obs, subset.n_vars])

with open(manifest_path, 'w', newline='', encoding='utf-8') as handle:
    writer = csv.writer(handle, delimiter=chr(9), lineterminator=chr(10))
    writer.writerow(['name', 'input_file', 'input_format', 'split_column', 'split_value',
                     'output_format', 'output_file', 'n_cells', 'n_features'])
    writer.writerows(records)

with open('versions.yml', 'w', encoding='utf-8') as handle:
    handle.write(f'SPLIT_H5AD:{chr(10)}    python: {platform.python_version()}{chr(10)}    anndata: {ad.__version__}{chr(10)}')
