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

Build the shared runtime image from the repository root:

```bash
docker build -f containers/Dockerfile -t scsplit:0.1.0 .
apptainer build containers/scsplit.sif containers/scsplit.def
```

The Dockerfile and Singularity/Apptainer definition use the shared dependency list in `containers/environment.yml`. The unified image includes Python 3.11, R 4.5, AnnData, SingleCellExperiment, anndataR, anndata2ri, rpy2, and the libraries needed by all local modules. Module-specific `environment.yml` files remain the source for the Conda profile.

Choose one profile per run:

```bash
# Conda creates module environments from their environment.yml files.
nextflow run . -profile conda --input samplesheet.csv --split_column donor

# Docker uses the local image built above. Override the default if needed.
nextflow run . -profile docker --container_image scsplit:0.1.0 --input samplesheet.csv --split_column donor

# Singularity and Apptainer use containers/scsplit.sif.
nextflow run . -profile singularity --input samplesheet.csv --split_column donor
nextflow run . -profile apptainer --input samplesheet.csv --split_column donor
```

Install the selected runtime on the execution host; Nextflow does not install Docker, Singularity, or Apptainer. For clusters, configure the executor and a suitable shared container cache separately.

## Run

```bash
nextflow run . -profile docker --input samplesheet.csv --split_column donor --output_format h5ad --outdir results
```

`--output_format` accepts `h5ad` (default), `rds`, or `both`. The workflow preserves native formats when requested and converts only for requested cross-format outputs. Missing split columns, missing group values, and empty cell/feature dimensions fail the task.

Each dataset is published to `results/<name>/`. H5AD and RDS files are placed in `h5ad/` and `rds/` respectively. `split_manifest.tsv` records source format, original split value, final format/path, cell count, and feature count. Unsafe group values are sanitized for filenames; manifest values remain unchanged and sanitized-name collisions receive a stable digest suffix.

Pipeline execution reports are published in `results/pipeline_info/`.
