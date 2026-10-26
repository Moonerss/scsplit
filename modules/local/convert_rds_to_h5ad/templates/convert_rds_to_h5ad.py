#!/usr/bin/env python3
import argparse
import os

os.environ['TMPDIR'] = '.'

import anndata2ri
import rpy2.robjects as ro


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()

    sce = ro.r['readRDS'](args.input)
    if not ro.r['inherits'](sce, 'SingleCellExperiment')[0]:
        raise SystemExit('ERROR: RDS object is not a SingleCellExperiment')
    adata = anndata2ri.rpy2py(sce)
    adata.obs.index = adata.obs.index.astype(str)
    adata.var.index = adata.var.index.astype(str)
    adata.write_h5ad(args.output)


if __name__ == '__main__':
    main()
