#!/usr/bin/env python3
import os
import platform
import shutil
from importlib.metadata import version

os.environ['TMPDIR'] = '.'

import anndata2ri
import rpy2.robjects as ro
from rpy2.robjects.conversion import localconverter

input_path = "${input}"
output_path = "${input.simpleName}.h5ad"
manifest_path = "${manifest}"

sce = ro.r['readRDS'](input_path)
if not ro.r['inherits'](sce, 'SingleCellExperiment')[0]:
    raise SystemExit('ERROR: RDS object is not a SingleCellExperiment')
with localconverter(anndata2ri.converter):
    adata = ro.conversion.get_conversion().rpy2py(sce)
adata.obs.index = adata.obs.index.astype(str)
adata.var.index = adata.var.index.astype(str)
adata.write_h5ad(output_path)
shutil.copyfile(manifest_path, f'{os.path.splitext(output_path)[0]}_split_manifest.tsv')
with open('versions.yml', 'w', encoding='utf-8') as handle:
    handle.write(f'CONVERT_RDS_TO_H5AD:{chr(10)}    python: {platform.python_version()}{chr(10)}    anndata2ri: {version("anndata2ri")}{chr(10)}')
