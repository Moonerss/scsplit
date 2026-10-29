#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(SingleCellExperiment)
  library(Seurat)
})

output <- paste0("${input.simpleName}", '.sce.rds')
manifest <- "${manifest}"
input <- "${input}"

seurat <- readRDS(input)
if (!inherits(seurat, 'Seurat')) stop('ERROR: RDS object is not a Seurat object')
assay_name <- DefaultAssay(seurat)
sce <- Seurat::as.SingleCellExperiment(seurat, assay = assay_name)
if (!inherits(sce, 'SingleCellExperiment')) stop('ERROR: conversion did not produce a SingleCellExperiment')
if (!'counts' %in% assayNames(sce)) stop("ERROR: converted SingleCellExperiment has no 'counts' assay")
counts <- assay(sce, 'counts')
if (nrow(counts) == 0L || ncol(counts) == 0L) stop('ERROR: converted SingleCellExperiment counts must contain cells and features')
if (is.null(rownames(counts)) || is.null(colnames(counts))) stop('ERROR: converted SingleCellExperiment counts must have feature and cell names')
if (ncol(sce) != ncol(seurat) || nrow(sce) != nrow(seurat[[assay_name]])) stop('ERROR: converted SingleCellExperiment dimensions do not match input')
if (!identical(colnames(sce), colnames(seurat))) stop('ERROR: converted SingleCellExperiment cell names do not match input')
saveRDS(sce, output)

manifest_data <- read.delim(manifest, sep = intToUtf8(9L), check.names = FALSE, stringsAsFactors = FALSE)
input_name <- basename(input)
manifest_data <- manifest_data[basename(manifest_data\$output_file) == input_name, , drop = FALSE]
if (nrow(manifest_data) != 1L) stop('ERROR: conversion manifest must contain exactly one row for ', input_name)
manifest_data\$input_object_type <- 'Seurat'
manifest_data\$output_object_type <- 'SingleCellExperiment'
manifest_data\$output_format <- 'sce'
manifest_data\$output_file <- output
write.table(manifest_data, paste0(tools::file_path_sans_ext(output), '_split_manifest.tsv'), sep = intToUtf8(9L), quote = TRUE, row.names = FALSE)
writeLines(c(
  'CONVERT_SEURAT_TO_SCE:',
  paste0('    r: ', R.version[['version.string']]),
  paste0('    Seurat: ', packageVersion('Seurat')),
  paste0('    SingleCellExperiment: ', packageVersion('SingleCellExperiment'))
), 'versions.yml')
