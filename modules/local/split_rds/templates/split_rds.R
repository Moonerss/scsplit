#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(SingleCellExperiment))
suppressPackageStartupMessages(library(SeuratObject))

input <- "${input}"
split_column <- "${split_column}"
name <- "${meta.name}"
metadata_object_type <- "${meta.input_object_type}"
output_dir <- 'rds_outputs'
manifest <- 'split_manifest.tsv'

obj <- readRDS(input)
if (inherits(obj, 'SingleCellExperiment')) {
  input_object_type <- 'SingleCellExperiment'
} else if (inherits(obj, 'Seurat')) {
  input_object_type <- 'Seurat'
} else {
  stop('ERROR: RDS object must be a SingleCellExperiment or Seurat object')
}
if (!identical(metadata_object_type, input_object_type)) {
  stop('ERROR: metadata input_object_type does not match the RDS object: ', metadata_object_type, ' vs ', input_object_type)
}

if (input_object_type == 'SingleCellExperiment') {
  n_features <- nrow(obj)
  n_cells <- ncol(obj)
  if (n_cells == 0L || n_features == 0L) stop('ERROR: input SingleCellExperiment must contain cells and features')
  if (!(split_column %in% colnames(colData(obj)))) stop('ERROR: split column not found in colData: ', split_column)
  values <- colData(obj)[[split_column]]
  cell_names <- colnames(obj)
} else {
  n_features <- nrow(obj)
  n_cells <- ncol(obj)
  if (n_cells == 0L || n_features == 0L) stop('ERROR: input Seurat object must contain cells and features')
  metadata <- obj[[]]
  if (!(split_column %in% colnames(metadata))) stop('ERROR: split column not found in Seurat metadata: ', split_column)
  values <- metadata[[split_column]]
  cell_names <- colnames(obj)
}
if (anyNA(values)) stop('ERROR: split column contains missing values')
group_values <- as.character(values)
groups <- unique(group_values)
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
    suffix <- 1L
    while (output_name %in% used) {
      output_name <- paste0(base, '__', digest, '_', suffix)
      suffix <- suffix + 1L
    }
  }
  used <- c(used, output_name)
  selected_cells <- cell_names[group_values == value]
  if (input_object_type == 'SingleCellExperiment') {
    subset <- obj[, selected_cells, drop = FALSE]
  } else {
    subset <- obj[, selected_cells]
  }
  output_path <- file.path(output_dir, paste0(output_name, '.rds'))
  saveRDS(subset, output_path)
  rows[[length(rows) + 1L]] <- data.frame(
    name = name,
    input_file = normalizePath(input, mustWork = TRUE),
    input_format = 'rds',
    input_object_type = input_object_type,
    split_column = split_column,
    split_value = value,
    output_format = 'rds',
    output_object_type = input_object_type,
    output_file = output_path,
    n_cells = length(selected_cells),
    n_features = nrow(subset),
    stringsAsFactors = FALSE
  )
}
manifest_rows <- do.call(rbind, rows)
write.table(manifest_rows, manifest, sep = intToUtf8(9L), quote = TRUE, row.names = FALSE)
writeLines(c(
  'SPLIT_RDS:',
  paste0('    r: ', R.version[['version.string']]),
  paste0('    SingleCellExperiment: ', packageVersion('SingleCellExperiment')),
  paste0('    SeuratObject: ', packageVersion('SeuratObject'))
), 'versions.yml')
