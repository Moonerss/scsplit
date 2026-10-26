#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path

FIELDS = ['name', 'input_file', 'input_format', 'split_column', 'split_value',
          'output_format', 'output_file', 'n_cells', 'n_features']


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--manifests', nargs='+', required=True)
    parser.add_argument('--outputs', nargs='+', required=True)
    parser.add_argument('--formats', nargs='+', required=True)
    parser.add_argument('--name', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()

    records_by_stem = {}
    for manifest in dict.fromkeys(args.manifests):
        with open(manifest, newline='', encoding='utf-8') as source:
            for record in csv.DictReader(source, delimiter='\t'):
                records_by_stem[Path(record['output_file']).stem] = record

    with open(args.output, 'w', newline='', encoding='utf-8') as target:
        writer = csv.DictWriter(target, fieldnames=FIELDS, delimiter='\t', lineterminator='\n')
        writer.writeheader()
        for output, output_format in zip(args.outputs, args.formats, strict=True):
            record = records_by_stem.get(Path(output).stem)
            if record is None:
                raise SystemExit(f'ERROR: no split manifest record for output {output}')
            record = record.copy()
            record.update(name=args.name, output_format=output_format,
                          output_file=f'{output_format}/{Path(output).name}')
            writer.writerow(record)


if __name__ == '__main__':
    main()
