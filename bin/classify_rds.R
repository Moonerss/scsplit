#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(SingleCellExperiment))
suppressPackageStartupMessages(library(SeuratObject))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) stop('Usage: classify_rds.R INPUT DATASET_NAME SPLIT_COLUMN')
input <- args[[1L]]
name <- args[[2L]]
split_column <- args[[3L]]
obj <- readRDS(input)
if (inherits(obj, 'SingleCellExperiment')) {
  input_object_type <- 'SingleCellExperiment'
} else if (inherits(obj, 'Seurat')) {
  input_object_type <- 'Seurat'
} else {
  stop('ERROR: RDS object must be a SingleCellExperiment or Seurat object')
}

write.table(
  data.frame(
    name = name,
    input_file = normalizePath(input, mustWork = TRUE),
    input_format = 'rds',
    input_object_type = input_object_type,
    split_column = split_column,
    stringsAsFactors = FALSE
  ),
  'classified_metadata.tsv', sep = intToUtf8(9L), quote = TRUE, row.names = FALSE
)
writeLines(c(
  'CLASSIFY_RDS:',
  paste0('    r: ', R.version[['version.string']]),
  paste0('    SingleCellExperiment: ', packageVersion('SingleCellExperiment')),
  paste0('    SeuratObject: ', packageVersion('SeuratObject'))
), 'versions.yml')
