#!/usr/bin/env Rscript
# Generate a small deterministic SingleCellExperiment fixture for scsplit.

suppressPackageStartupMessages({
  library(SingleCellExperiment)
  library(S4Vectors)
})

output_dir <- normalizePath(dirname(commandArgs(trailingOnly = FALSE)[grep("^--file=", commandArgs(trailingOnly = FALSE))] |> sub("^--file=", "")), mustWork = TRUE)

cell_ids <- sprintf("cell_%02d", 1:12)
group_values <- c(rep("donor A", 4), rep("donor_A", 4), rep("donor/B", 4))
batch_values <- c(rep("batch_1", 6), rep("batch_2", 6))
counts <- matrix(seq_len(72), nrow = 6, ncol = 12,
                 dimnames = list(sprintf("gene_%02d", 1:6), cell_ids))

col_data <- DataFrame(
  donor = group_values,
  batch = batch_values,
  n_counts = colSums(counts),
  row.names = cell_ids
)
row_data <- DataFrame(
  gene_symbol = paste0("Gene", 1:6),
  row.names = rownames(counts)
)
sce <- SingleCellExperiment(
  assays = list(counts = counts),
  rowData = row_data,
  colData = col_data
)
metadata(sce)$simulated <- TRUE
metadata(sce)$seed <- 20261027L

rds_path <- file.path(output_dir, "simulated_cells.rds")
saveRDS(sce, rds_path)

write_samplesheet <- function(path, rows) {
  write.csv(rows, path, row.names = FALSE, quote = TRUE)
}

h5ad_path <- file.path(output_dir, "simulated_cells.h5ad")
write_samplesheet(
  file.path(output_dir, "samplesheet_rds.csv"),
  data.frame(name = "simulated_rds", input = normalizePath(rds_path, mustWork = TRUE))
)
if (file.exists(h5ad_path)) {
  write_samplesheet(
    file.path(output_dir, "samplesheet_all.csv"),
    data.frame(
      name = c("simulated_h5ad", "simulated_rds"),
      input = c(normalizePath(h5ad_path, mustWork = TRUE), normalizePath(rds_path, mustWork = TRUE))
    )
  )
}

cat(sprintf("wrote %s (%d features x %d cells)\n", rds_path, nrow(sce), ncol(sce)))
cat(sprintf("wrote %s\n", file.path(output_dir, "samplesheet_rds.csv")))
if (file.exists(h5ad_path)) cat(sprintf("wrote %s\n", file.path(output_dir, "samplesheet_all.csv")))
