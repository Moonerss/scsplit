#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(anndataR))

input <- "${input}"
output <- "${input.simpleName}.rds"
manifest <- "${manifest}"

adata <- read_h5ad(input)
sce <- adata\$as_SingleCellExperiment()
saveRDS(sce, output)
file.copy(manifest, "${input.simpleName}_split_manifest.tsv", overwrite = TRUE)
writeLines(c(
  'CONVERT_H5AD_TO_RDS:',
  paste0('    r: ', R.version\$version.string),
  paste0('    anndataR: ', as.character(packageVersion('anndataR')))
), 'versions.yml')
