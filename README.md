# scsplit

Nextflow workflow that splits H5AD/AnnData or SingleCellExperiment RDS inputs by one cell metadata column.

## Inputs

`--input` is a CSV samplesheet with exactly these columns:

```csv
name,input
pbmc_01,/data/pbmc_01.h5ad
pbmc_02,/data/pbmc_02.rds
```

Dataset names must be unique and contain only letters, digits, `_`, `-`, and `.`. Inputs must end in `.h5ad` or `.rds`; RDS objects are checked at runtime and must be `SingleCellExperiment`.

## Execution Environments

Choose exactly one profile for task environments:

```bash
# Conda
nextflow run . -profile conda --input samplesheet.csv --split_column donor

# Docker
nextflow run . -profile docker --input samplesheet.csv --split_column donor

# Singularity
nextflow run . -profile singularity --input samplesheet.csv --split_column donor

# Apptainer
nextflow run . -profile apptainer --input samplesheet.csv --split_column donor
```

Each module declares its Conda environment and container image next to its process in `modules/local/<module>/main.nf`; Conda dependency lists live in that module's `environment.yml`. Docker and Singularity/Apptainer image references follow the module pattern used by nf-core, including engine-specific Singularity image URLs where supplied. The profiles enable the selected runtime. Install that runtime on the execution host; Nextflow does not install Docker or Singularity/Apptainer. Configure the site executor separately on clusters and use a shared container cache where required.

Use one profile per run. The Conda profile activates module environments; Docker and Singularity/Apptainer profiles use module containers.

## Run

```bash
nextflow run . -profile conda --input samplesheet.csv --split_column donor --output_format h5ad --outdir results
```

`--output_format` accepts `h5ad` (default), `rds`, or `both`. The workflow preserves native formats when requested and converts only for requested cross-format outputs. Missing split columns, missing group values, and empty cell/feature dimensions fail the task.

Each dataset is published to `results/<name>/`. H5AD and RDS files are placed in `h5ad/` and `rds/` respectively. `split_manifest.tsv` records source format, original split value, final format/path, cell count, and feature count. Unsafe group values are sanitized for filenames; manifest values remain unchanged and sanitized-name collisions receive a stable digest suffix.

Pipeline execution reports are published in `results/pipeline_info/`.
