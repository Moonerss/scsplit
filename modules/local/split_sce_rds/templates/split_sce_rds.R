#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(SingleCellExperiment))

input <- "${input}"
split_column <- "${split_column}"
name <- "${meta.name}"
output_dir <- 'rds_outputs'
manifest <- 'split_manifest.tsv'

sce <- readRDS(input)
if (!inherits(sce, 'SingleCellExperiment')) stop('ERROR: RDS object is not a SingleCellExperiment')
if (ncol(sce) == 0L || nrow(sce) == 0L) stop('ERROR: input SingleCellExperiment must contain cells and features')
if (!(split_column %in% colnames(colData(sce)))) stop('ERROR: split column not found in colData: ', split_column)
values <- colData(sce)[[split_column]]
if (anyNA(values)) stop('ERROR: split column contains missing values')
groups <- unique(as.character(values))
if (!length(groups)) stop('ERROR: split column contains no groups')
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

safe_name <- function(x) {
  value <- gsub('[^A-Za-z0-9_.-]+', '_', as.character(x))
  value <- trimws(value, whitespace = '[._]')
  if (!nzchar(value)) value <- 'group'
  substr(value, 1L, 180L)
}
used <- character()
rows <- list()
for (value in groups) {
  base <- safe_name(value)
  output_name <- base
  if (output_name %in% used) {
    digest <- substr(as.character(openssl::sha256(charToRaw(value))), 1L, 12L)
    output_name <- paste0(base, '__', digest)
  }
  used <- c(used, output_name)
  subset <- sce[, as.character(values) == value, drop = FALSE]
  output_path <- file.path(output_dir, paste0(output_name, '.rds'))
  saveRDS(subset, output_path)
  rows[[length(rows) + 1L]] <- data.frame(
    name = name, input_file = normalizePath(input, mustWork = TRUE), input_format = 'rds',
    split_column = split_column, split_value = value, output_format = 'rds',
    output_file = output_path, n_cells = ncol(subset), n_features = nrow(subset),
    stringsAsFactors = FALSE
  )
}
write.table(do.call(rbind, rows), manifest, sep = intToUtf8(9L), quote = TRUE, row.names = FALSE)
writeLines(c(
  'SPLIT_SCE_RDS:',
  paste0('    r: ', R.version[['version.string']]),
  paste0('    SingleCellExperiment: ', packageVersion('SingleCellExperiment'))
), 'versions.yml')
