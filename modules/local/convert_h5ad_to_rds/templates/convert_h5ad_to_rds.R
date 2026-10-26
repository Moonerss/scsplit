#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(anndataR))

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag) {
  index <- match(flag, args)
  if (is.na(index) || index == length(args)) stop('Missing argument: ', flag)
  args[[index + 1L]]
}
input <- get_arg('--input')
output <- get_arg('--output')
adata <- read_h5ad(input)
sce <- adata$as_SingleCellExperiment()
saveRDS(sce, output)
writeLines(c(
  'CONVERT_H5AD_TO_RDS:',
  paste0('    anndataR: ', as.character(packageVersion('anndataR')))
), 'conversion_versions.yml')
