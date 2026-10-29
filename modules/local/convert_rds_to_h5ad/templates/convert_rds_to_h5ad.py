#!/usr/bin/env python3
import csv
import os
import platform
from importlib.metadata import version

os.environ['TMPDIR'] = '.'

import anndata2ri
import rpy2.robjects as ro
from rpy2.robjects.conversion import localconverter

input_path = "${input}"
output_path = "${input.simpleName}.h5ad"
manifest_path = "${manifest}"

obj = ro.r['readRDS'](input_path)
is_sce = bool(ro.r['inherits'](obj, 'SingleCellExperiment')[0])
is_seurat = bool(ro.r['inherits'](obj, 'Seurat')[0])
if not is_sce and not is_seurat:
    raise SystemExit('ERROR: RDS object is neither a SingleCellExperiment nor a Seurat object')

if is_seurat:
    to_sce = ro.r('''
    function(obj) {
        assay_name <- SeuratObject::DefaultAssay(obj)
        Seurat::as.SingleCellExperiment(obj, assay = assay_name)
    }
    ''')
    obj = to_sce(obj)

with localconverter(anndata2ri.converter):
    adata = ro.conversion.get_conversion().rpy2py(obj)
adata.obs.index = adata.obs.index.astype(str)
adata.var.index = adata.var.index.astype(str)
adata.write_h5ad(output_path)

input_object_type = 'Seurat' if is_seurat else 'SingleCellExperiment'
with open(manifest_path, newline='', encoding='utf-8') as source:
    reader = csv.DictReader(source, delimiter='\t')
    fieldnames = list(reader.fieldnames or [])
    for field in ('input_object_type', 'output_object_type', 'output_format', 'output_file'):
        if field not in fieldnames:
            fieldnames.append(field)
    records = list(reader)
input_name = os.path.basename(input_path)
records = [record for record in records if os.path.basename(record.get('output_file', '')) == input_name]
if len(records) != 1:
    raise SystemExit(f'ERROR: conversion manifest must contain exactly one row for {input_name}')
input_object_type = 'Seurat' if is_seurat else 'SingleCellExperiment'
for record in records:
    record['input_object_type'] = input_object_type
    record['output_object_type'] = 'AnnData'
    record['output_format'] = 'anndata'
    record['output_file'] = output_path
manifest_output = f'{os.path.splitext(output_path)[0]}_split_manifest.tsv'
with open(manifest_output, 'w', newline='', encoding='utf-8') as destination:
    writer = csv.DictWriter(destination, fieldnames=fieldnames, delimiter=chr(9), lineterminator=chr(10))
    writer.writeheader()
    writer.writerows(records)

seurat_version = str(ro.r('as.character(packageVersion("Seurat"))')[0]) if is_seurat else 'not used'
with open('versions.yml', 'w', encoding='utf-8') as handle:
    handle.write(f'CONVERT_RDS_TO_H5AD:{chr(10)}    python: {platform.python_version()}{chr(10)}    anndata2ri: {version("anndata2ri")}{chr(10)}    Seurat: {seurat_version}')
