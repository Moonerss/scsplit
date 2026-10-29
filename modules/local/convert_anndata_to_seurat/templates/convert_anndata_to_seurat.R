#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(anndataR)
  library(SingleCellExperiment)
  library(Seurat)
})

input <- "${input}"
output <- paste0("${input.simpleName}", '.seurat.rds')
manifest <- "${manifest}"

adata <- read_h5ad(input)
sce <- adata\$as_SingleCellExperiment()
if (!inherits(sce, 'SingleCellExperiment') || nrow(sce) == 0L || ncol(sce) == 0L) {
  stop('ERROR: H5AD conversion did not produce a non-empty SingleCellExperiment')
}
assay_name <- if ('counts' %in% assayNames(sce)) 'counts' else assayNames(sce)[1]
if (is.na(assay_name) || !nzchar(assay_name)) stop('ERROR: H5AD conversion produced no assay')
counts <- assay(sce, assay_name)
if (is.null(rownames(counts)) || is.null(colnames(counts))) stop('ERROR: H5AD counts must have feature and cell names')
seurat <- Seurat::as.Seurat(sce, counts = assay_name, data = NULL, project = 'scsplit')
if (!inherits(seurat, 'Seurat')) stop('ERROR: conversion did not produce a Seurat object')
if (nrow(seurat) != nrow(sce) || ncol(seurat) != ncol(sce)) stop('ERROR: converted Seurat dimensions do not match input')
saveRDS(seurat, output)

manifest_data <- read.delim(manifest, sep = intToUtf8(9L), check.names = FALSE, stringsAsFactors = FALSE)
input_name <- basename(input)
manifest_data <- manifest_data[basename(manifest_data\$output_file) == input_name, , drop = FALSE]
if (nrow(manifest_data) != 1L) stop('ERROR: conversion manifest must contain exactly one row for ', input_name)
manifest_data\$input_object_type <- 'AnnData'
manifest_data\$output_object_type <- 'Seurat'
manifest_data\$output_format <- 'seurat'
manifest_data\$output_file <- output
write.table(manifest_data, paste0(tools::file_path_sans_ext(output), '_split_manifest.tsv'), sep = intToUtf8(9L), quote = TRUE, row.names = FALSE)
writeLines(c(
  'CONVERT_ANNDATA_TO_SEURAT:',
  paste0('    r: ', R.version\$version.string),
  paste0('    anndataR: ', as.character(packageVersion('anndataR'))),
  paste0('    Seurat: ', packageVersion('Seurat'))
), 'versions.yml')
