#!/usr/bin/env python3
import argparse
import csv
import os
import re
import sys

NAME = re.compile(r'^[A-Za-z0-9_.-]+$')
EXTENSIONS = {'.h5ad': 'h5ad', '.rds': 'rds'}


def fail(message):
    raise SystemExit(f'ERROR: {message}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()

    with open(args.input, newline='', encoding='utf-8') as handle:
        rows = list(csv.DictReader(handle))

    if not rows or set(rows[0]) != {'name', 'input'}:
        fail('samplesheet must contain exactly the columns name,input and at least one row')

    seen = set()
    with open(args.output, 'w', encoding='utf-8', newline='') as handle:
        writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
        writer.writerow(['name', 'input_file', 'input_format'])
        for index, row in enumerate(rows, start=2):
            name = (row.get('name') or '').strip()
            path = (row.get('input') or '').strip()
            if not NAME.fullmatch(name):
                fail(f'row {index}: name is not a safe dataset identifier: {name!r}')
            if name in seen:
                fail(f'row {index}: duplicate name: {name}')
            seen.add(name)
            if not os.path.isfile(path):
                fail(f'row {index}: input file does not exist: {path}')
            fmt = EXTENSIONS.get(os.path.splitext(path)[1].lower())
            if fmt is None:
                fail(f'row {index}: unsupported input extension: {path}')
            writer.writerow([name, os.path.abspath(path), fmt])


if __name__ == '__main__':
    main()
