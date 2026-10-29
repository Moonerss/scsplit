#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(SingleCellExperiment))
suppressPackageStartupMessages(library(SeuratObject))

input <- "${input}"
name <- "${meta.name}"
split_column <- "${split_column}"

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
