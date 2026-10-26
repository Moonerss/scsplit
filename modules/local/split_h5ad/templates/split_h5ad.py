#!/usr/bin/env python3
import argparse
import csv
import hashlib
import os
import re

import anndata as ad
import pandas as pd


def safe_name(value):
    text = str(value)
    text = re.sub(r'[^A-Za-z0-9_.-]+', '_', text).strip('._') or 'group'
    return text[:180]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True)
    parser.add_argument('--split-column', required=True)
    parser.add_argument('--name', required=True)
    parser.add_argument('--output-dir', required=True)
    parser.add_argument('--manifest', required=True)
    args = parser.parse_args()

    obj = ad.read_h5ad(args.input)
    if obj.n_obs == 0 or obj.n_vars == 0:
        raise SystemExit('ERROR: input AnnData object must contain cells and features')
    if args.split_column not in obj.obs.columns:
        raise SystemExit(f'ERROR: split column not found in adata.obs: {args.split_column}')
    values = obj.obs[args.split_column]
    if values.isna().any():
        raise SystemExit('ERROR: split column contains missing values')
    groups = list(pd.unique(values))
    if not groups:
        raise SystemExit('ERROR: split column contains no groups')

    os.makedirs(args.output_dir, exist_ok=True)
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
        output_path = os.path.join(args.output_dir, f'{output_name}.h5ad')
        subset.write_h5ad(output_path)
        records.append([args.name, os.path.abspath(args.input), 'h5ad', args.split_column,
                        str(value), 'h5ad', output_path, subset.n_obs, subset.n_vars])

    with open(args.manifest, 'w', newline='', encoding='utf-8') as handle:
        writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
        writer.writerow(['name', 'input_file', 'input_format', 'split_column', 'split_value',
                         'output_format', 'output_file', 'n_cells', 'n_features'])
        writer.writerows(records)


if __name__ == '__main__':
    main()
