#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(SingleCellExperiment)
  library(Seurat)
})

output <- paste0("${input.simpleName}", '.seurat.rds')
manifest <- "${manifest}"
input <- "${input}"

sce <- readRDS(input)
if (!inherits(sce, 'SingleCellExperiment')) stop('ERROR: RDS object is not a SingleCellExperiment')
if (nrow(sce) == 0L || ncol(sce) == 0L) stop('ERROR: input SingleCellExperiment must contain cells and features')
if (!'counts' %in% assayNames(sce)) stop("ERROR: SingleCellExperiment has no 'counts' assay")
counts <- assay(sce, 'counts')
if (nrow(counts) != nrow(sce) || ncol(counts) != ncol(sce)) stop('ERROR: counts dimensions do not match SingleCellExperiment')
if (is.null(rownames(counts)) || is.null(colnames(counts))) stop('ERROR: counts must have feature and cell names')

seurat <- Seurat::as.Seurat(sce, counts = 'counts', data = NULL, project = 'scsplit')

if (!inherits(seurat, 'Seurat')) stop('ERROR: conversion did not produce a Seurat object')
if (ncol(seurat) != ncol(sce) || nrow(seurat) != nrow(sce)) stop('ERROR: converted Seurat dimensions do not match input')
if (!identical(colnames(seurat), colnames(sce))) stop('ERROR: converted Seurat cell names do not match input')
saveRDS(seurat, output)

manifest_data <- read.delim(manifest, sep = intToUtf8(9L), check.names = FALSE, stringsAsFactors = FALSE)
input_name <- basename(input)
manifest_data <- manifest_data[basename(manifest_data\$output_file) == input_name, , drop = FALSE]
if (nrow(manifest_data) != 1L) stop('ERROR: conversion manifest must contain exactly one row for ', input_name)
manifest_data\$input_object_type <- 'SingleCellExperiment'
manifest_data\$output_object_type <- 'Seurat'
manifest_data\$output_format <- 'seurat'
manifest_data\$output_file <- output
write.table(manifest_data, paste0(tools::file_path_sans_ext(output), '_split_manifest.tsv'), sep = intToUtf8(9L), quote = TRUE, row.names = FALSE)
writeLines(c(
  'CONVERT_SCE_TO_SEURAT:',
  paste0('    r: ', R.version[['version.string']]),
  paste0('    SingleCellExperiment: ', packageVersion('SingleCellExperiment')),
  paste0('    Seurat: ', packageVersion('Seurat'))
), 'versions.yml')
