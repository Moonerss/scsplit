#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(anndataR))

input <- "${input}"
output <- paste0("${input.simpleName}", '.rds')
manifest <- "${manifest}"

adata <- read_h5ad(input)
sce <- adata\$as_SingleCellExperiment()
if (!inherits(sce, 'SingleCellExperiment') || ncol(sce) == 0L || nrow(sce) == 0L) stop('ERROR: H5AD conversion did not produce a non-empty SingleCellExperiment')
saveRDS(sce, output)

manifest_data <- read.delim(manifest, sep = intToUtf8(9L), check.names = FALSE, stringsAsFactors = FALSE)
input_name <- basename(input)
manifest_data <- manifest_data[basename(manifest_data\$output_file) == input_name, , drop = FALSE]
if (nrow(manifest_data) != 1L) stop('ERROR: conversion manifest must contain exactly one row for ', input_name)
manifest_data\$input_object_type <- 'AnnData'
manifest_data\$output_object_type <- 'SingleCellExperiment'
manifest_data\$output_format <- 'sce'
manifest_data\$output_file <- output
write.table(manifest_data, paste0(tools::file_path_sans_ext(output), '_split_manifest.tsv'), sep = intToUtf8(9L), quote = TRUE, row.names = FALSE)
writeLines(c(
  'CONVERT_ANNDATA_TO_SCE:',
  paste0('    r: ', R.version\$version.string),
  paste0('    anndataR: ', as.character(packageVersion('anndataR')))
), 'versions.yml')
