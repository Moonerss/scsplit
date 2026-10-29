#!/usr/bin/env Rscript
# Generate a deterministic Seurat fixture for scsplit.

suppressPackageStartupMessages(library(SeuratObject))

script_args <- commandArgs(trailingOnly = FALSE)
script_file <- script_args[startsWith(script_args, '--file=')][1]
if (is.na(script_file)) {
  output_dir <- normalizePath(getwd(), mustWork = TRUE)
} else {
  output_dir <- dirname(normalizePath(sub('^--file=', '', script_file), mustWork = TRUE))
}

cell_ids <- sprintf('cell_%02d', 1:12)
group_values <- c(rep('donor A', 4), rep('donor_A', 4), rep('donor/B', 4))
batch_values <- c(rep('batch_1', 6), rep('batch_2', 6))
counts <- matrix(seq_len(72), nrow = 6, ncol = 12,
                 dimnames = list(sprintf('gene%02d', 1:6), cell_ids))
metadata <- data.frame(
  donor = group_values,
  batch = batch_values,
  n_counts = colSums(counts),
  row.names = cell_ids,
  check.names = FALSE
)

seurat <- CreateSeuratObject(
  counts = counts,
  meta.data = metadata,
  assay = 'RNA',
  project = 'scsplit',
  min.cells = 0,
  min.features = 0
)
seurat[['RNA']] <- AddMetaData(
  object = seurat[['RNA']],
  metadata = data.frame(gene_symbol = paste0('Gene', seq_len(nrow(counts))), row.names = rownames(counts))
)
seurat@misc$simulated <- TRUE
seurat@misc$seed <- 20261027L

rds_path <- file.path(output_dir, 'simulated_seurat.rds')
saveRDS(seurat, rds_path)
write.csv(
  data.frame(name = 'simulated_seurat', input = normalizePath(rds_path, mustWork = TRUE)),
  file.path(output_dir, 'samplesheet_seurat.csv'),
  row.names = FALSE,
  quote = TRUE
)

h5ad_path <- file.path(output_dir, 'simulated_cells.h5ad')
sce_path <- file.path(output_dir, 'simulated_cells.rds')
if (file.exists(h5ad_path) && file.exists(sce_path)) {
  write.csv(
    data.frame(
      name = c('simulated_anndata', 'simulated_sce', 'simulated_seurat'),
      input = c(normalizePath(h5ad_path, mustWork = TRUE),
                normalizePath(sce_path, mustWork = TRUE),
                normalizePath(rds_path, mustWork = TRUE))
    ),
    file.path(output_dir, 'samplesheet_all.csv'),
    row.names = FALSE,
    quote = TRUE
  )
}
cat(sprintf('wrote %s (%d features x %d cells)\n', rds_path, nrow(seurat), ncol(seurat)))
cat(sprintf('wrote %s\n', file.path(output_dir, 'samplesheet_seurat.csv')))
if (file.exists(h5ad_path) && file.exists(sce_path)) cat(sprintf('wrote %s\n', file.path(output_dir, 'samplesheet_all.csv')))
